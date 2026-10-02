import base64
import secrets
import json
import os
import subprocess
import tempfile

from datetime import timedelta

from django.utils import timezone
from django.conf import settings
from django.core import signing

from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

import qrcode
from io import BytesIO

from .models import (
    AttendanceSession,
    Attendance,
    FaceRegistration,
    DeviceRegistration
)

from .serializers import AttendanceSessionSerializer

from admins.models import SubjectAssignment
from subjects.models import Subject
from teachers.models import Teacher
from students.models import Student

from accounts.permissions import IsStudent


# ============================================================
# BLE COMMAND HELPER
# ============================================================

def send_ble_command(command):
    token = getattr(
        settings,
        "BLE_CONTROL_TOKEN",
        ""
    )

    base_url = getattr(
        settings,
        "BLE_CONTROL_URL",
        "http://127.0.0.1:8765"
    )

    if not token:
        return (
            False,
            "BLE control token is not configured."
        )

    if command not in ("start", "stop"):
        return (
            False,
            "Invalid BLE command."
        )

    def send_request():
        request = Request(
            f"{base_url}/{command}",
            data=b"",
            headers={
                "X-BLE-Token": token
            },
            method="POST"
        )

        with urlopen(
            request,
            timeout=3
        ) as response:

            if response.status == 200:
                return (
                    True,
                    None
                )

            return (
                False,
                f"BLE app returned HTTP {response.status}."
            )

    try:

        return send_request()

    except HTTPError as exc:

        return (
            False,
            f"BLE app returned HTTP {exc.code}."
        )

    except (
        URLError,
        TimeoutError,
        OSError
    ) as exc:

        # Only start the BLE application automatically
        # when the start command cannot reach it.
        if command != "start":

            return (
                False,
                f"Could not contact BLE app: {exc}"
            )

        ble_exe = getattr(
            settings,
            "BLE_CONTROL_EXE",
            None
        )

        if not ble_exe:

            return (
                False,
                "BLE executable path is not configured."
            )

        if not os.path.exists(ble_exe):

            return (
                False,
                f"BLE executable not found: {ble_exe}"
            )

        try:

            subprocess.Popen(
                [str(ble_exe)],
                env=os.environ.copy()
            )

        except OSError as launch_error:

            return (
                False,
                f"Could not launch BLE app: {launch_error}"
            )

        # Give the BLE application's HTTP server time
        # to start, then retry the command.
        import time

        for _ in range(10):

            time.sleep(0.5)

            try:

                return send_request()

            except (
                URLError,
                TimeoutError,
                OSError
            ):

                continue

            except HTTPError as retry_error:

                return (
                    False,
                    f"BLE app returned HTTP {retry_error.code}."
                )

        return (
            False,
            "BLE app started, but its command server did not become ready."
        )


# ============================================================
# SESSION EXPIRY HELPER
# ============================================================

def expire_session_if_needed(session):
    """
    Automatically change a running attendance session
    to Ended when its end time has been reached.
    """

    if (
        session.status == 'Running'
        and timezone.now() >= session.end_time
    ):
        session.status = 'Ended'

        session.save(
            update_fields=['status']
        )

        # Stop BLE when the backend detects session expiry.
        send_ble_command("stop")

        return True

    return False


# ============================================================
# CREATE ATTENDANCE SESSION
# ============================================================

class CreateAttendanceSessionView(APIView):

    def post(self, request):

        assignment_id = request.data.get('assignment_id')

        duration_minutes = request.data.get(
            'duration_minutes',
            10
        )

        # Check required data
        if not assignment_id:
            return Response(
                {
                    'error': 'assignment_id is required'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate duration
        try:
            duration_minutes = int(duration_minutes)

            if duration_minutes <= 0:
                raise ValueError

        except (ValueError, TypeError):

            return Response(
                {
                    'error': (
                        'duration_minutes must be '
                        'a positive number'
                    )
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create session times
        start_time = timezone.now()

        end_time = (
            start_time
            + timedelta(minutes=duration_minutes)
        )

        # Generate unique QR token
        qr_token = secrets.token_urlsafe(32)

        # Create attendance session
        session = AttendanceSession.objects.create(
            assignment_id=assignment_id,
            qr_token=qr_token,
            start_time=start_time,
            end_time=end_time,
            status='Running'
        )

        # Start BLE beacon
        ble_started, ble_error = send_ble_command("start")

        if not ble_started:

            session.status = 'Ended'
            session.end_time = timezone.now()
            session.save(
                update_fields=['status', 'end_time']
            )

            return Response(
                {
                    'error': 'Could not start BLE beacon',
                    'details': ble_error
                },
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        return Response(
            AttendanceSessionSerializer(session).data,
            status=status.HTTP_201_CREATED
        )


# ============================================================
# REFRESH QR CODE
# ============================================================

class RefreshAttendanceQRView(APIView):

    def post(self, request, session_id):

        # Find the running attendance session
        try:
            session = AttendanceSession.objects.get(
                session_id=session_id,
                status='Running'
            )

        except AttendanceSession.DoesNotExist:

            return Response(
                {
                    'error': (
                        'Attendance session not found '
                        'or already ended'
                    )
                },
                status=status.HTTP_404_NOT_FOUND
            )

        # Check whether the session has expired
        if expire_session_if_needed(session):

            return Response(
                {
                    'error': (
                        'Attendance session has expired'
                    )
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Generate a new QR token
        new_qr_token = secrets.token_urlsafe(32)

        # Replace the old token
        session.qr_token = new_qr_token

        session.save(
            update_fields=['qr_token']
        )

        # Generate QR image
        qr = qrcode.make(new_qr_token)

        buffer = BytesIO()

        qr.save(
            buffer,
            format='PNG'
        )

        encoded_image = base64.b64encode(
            buffer.getvalue()
        ).decode('utf-8')

        qr_image = (
            f'data:image/png;base64,{encoded_image}'
        )

        return Response(
            {
                'session_id': session.session_id,
                'qr_token': session.qr_token,
                'qr_image': qr_image,
                'start_time': session.start_time,
                'end_time': session.end_time,
                'status': session.status,
            },
            status=status.HTTP_200_OK
        )


# ============================================================
# END ATTENDANCE SESSION
# ============================================================

class EndAttendanceSessionView(APIView):

    def post(self, request):

        session_id = request.data.get('session_id')

        # Check required data
        if not session_id:

            return Response(
                {
                    'error': 'session_id is required'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Find the session
        try:
            session = AttendanceSession.objects.get(
                session_id=session_id,
                status='Running'
            )

        except AttendanceSession.DoesNotExist:

            return Response(
                {
                    'error': (
                        'Attendance session not found '
                        'or already ended'
                    )
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if it has already expired
        if expire_session_if_needed(session):

            return Response(
                {
                    'error': (
                        'Attendance session has already expired'
                    ),
                    'session_id': session.session_id,
                    'status': session.status,
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # End the session manually
        session.status = 'Ended'
        session.end_time = timezone.now()

        session.save(
            update_fields=[
                'status',
                'end_time'
            ]
        )

        # Stop BLE advertising
        ble_stopped, ble_error = send_ble_command("stop")

        response_data = {
            'message': (
                'Attendance session ended successfully'
            ),
            'session_id': session.session_id,
            'status': session.status,
            'end_time': session.end_time,
            'ble_stopped': ble_stopped,
        }

        if not ble_stopped:
            response_data['warning'] = (
                'The session ended, but BLE could not be stopped. '
                'Please stop the beacon manually.'
            )

            response_data['ble_error'] = ble_error

        return Response(
            response_data,
            status=status.HTTP_200_OK
        )


# ============================================================
# MARK ATTENDANCE
# ============================================================

class MarkAttendanceView(APIView):

    def post(self, request):

        student_id = request.data.get('student_id')
        qr_token = request.data.get('qr_token')
        face_proof = request.data.get(
            'face_proof'
        )
        ble_verified = request.data.get(
            'ble_verified',
            False
        )

        # Check required data
        if not student_id or not qr_token:

            return Response(
                {
                    'error': (
                        'student_id and qr_token '
                        'are required'
                    )
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        #Check BLE verification
        if ble_verified is not True:
            return Response(
                {'error': 'Teacher BLE verification is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Find the attendance session using QR token
        try:
            session = AttendanceSession.objects.get(
                qr_token=qr_token,
                status='Running'
            )

        except AttendanceSession.DoesNotExist:

            return Response(
                {
                    'error': 'Invalid or inactive QR code'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check whether the session has expired
        if expire_session_if_needed(session):

            return Response(
                {
                    'error': 'QR code has expired'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check BLE verification
        if ble_verified is not True:

            return Response(
                {
                    'error': (
                        'Teacher BLE verification is required'
                    )
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # ----------------------------------------------------
        # Validate face verification proof
        # ----------------------------------------------------

        if not face_proof:

            return Response(
                {
                    'error': 'Face verification is required'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        try:

            face_data = signing.loads(
                face_proof,
                max_age=120
            )

        except signing.BadSignature:

            return Response(
                {
                    'error': (
                        'Invalid or expired face verification'
                    )
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if (
            face_data.get('student_id') != int(student_id)
            or
            face_data.get('session_id') != session.session_id
            or
            face_data.get('qr_token') != qr_token
            or
            face_data.get('face_verified') is not True
        ):

            return Response(
                {
                    'error': 'Face verification proof is invalid'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        face_verified = True

        # Check whether the student already marked attendance
        already_marked = Attendance.objects.filter(
            session_id=session.session_id,
            student_id=student_id
        ).exists()

        if already_marked:

            return Response(
                {
                    'error': 'Attendance already marked'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create attendance record
        attendance = Attendance.objects.create(
            session_id=session.session_id,
            student_id=student_id,
            attendance_time=timezone.now(),
            face_verified=face_verified,
            ble_verified=ble_verified,
            status='Present'
        )

        # Get subject information
        try:

            assignment = SubjectAssignment.objects.get(
                assignment_id=session.assignment_id
            )

            subject = Subject.objects.get(
                subject_id=assignment.subject_id
            )

        except (
            SubjectAssignment.DoesNotExist,
            Subject.DoesNotExist
        ):

            return Response(
                {
                    'error': (
                        'Subject information not found'
                    )
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        # Convert attendance time to local timezone
        local_attendance_time = timezone.localtime(
            attendance.attendance_time
        )

        return Response(
            {
                'message': (
                    'Attendance marked successfully'
                ),
                'attendance_id': attendance.attendance_id,
                'student_id': attendance.student_id,
                'session_id': attendance.session_id,
                'status': attendance.status,

                # Data for Attendance Result screen
                'subject': subject.subject_name,

                'date': local_attendance_time.strftime(
                    '%d %B %Y'
                ),

                'time': local_attendance_time.strftime(
                    '%I:%M %p'
                ),
            },
            status=status.HTTP_201_CREATED
        )


# ============================================================
# STUDENT ATTENDANCE HISTORY
# ============================================================

class AttendanceHistoryView(APIView):

    def get(self, request):

        student_id = request.query_params.get(
            'student_id'
        )

        # Check required data
        if not student_id:

            return Response(
                {
                    'error': 'student_id is required'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate student ID
        try:

            student_id = int(student_id)

        except (ValueError, TypeError):

            return Response(
                {
                    'error': (
                        'student_id must be a number'
                    )
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get attendance records for this student
        attendance_records = Attendance.objects.filter(
            student_id=student_id
        ).order_by('-attendance_time')

        history = []

        for attendance in attendance_records:

            try:

                # Get attendance session
                session = AttendanceSession.objects.get(
                    session_id=attendance.session_id
                )

                # Get subject assignment
                assignment = SubjectAssignment.objects.get(
                    assignment_id=session.assignment_id
                )

                # Get subject
                subject = Subject.objects.get(
                    subject_id=assignment.subject_id
                )

                # Get teacher
                teacher = Teacher.objects.get(
                    teacher_id=assignment.teacher_id
                )

                # Convert UTC time to local timezone
                local_attendance_time = (
                    timezone.localtime(
                        attendance.attendance_time
                    )
                    if attendance.attendance_time
                    else None
                )

                history.append(
                    {
                        'attendance_id':
                            attendance.attendance_id,

                        'subject':
                            subject.subject_name,

                        'professor':
                            teacher.full_name,

                        'date': (
                            local_attendance_time.strftime(
                                '%d %B %Y'
                            )
                            if local_attendance_time
                            else ''
                        ),

                        'time': (
                            local_attendance_time.strftime(
                                '%I:%M %p'
                            )
                            if local_attendance_time
                            else ''
                        ),

                        'status':
                            attendance.status,
                    }
                )

            except (
                AttendanceSession.DoesNotExist,
                SubjectAssignment.DoesNotExist,
                Subject.DoesNotExist,
                Teacher.DoesNotExist
            ):

                continue

        return Response(
            history,
            status=status.HTTP_200_OK
        )


# ============================================================
# TEACHER ATTENDANCE DETAILS
# ============================================================

class TeacherAttendanceView(APIView):

    def get(
        self,
        request,
        teacher_id,
        session_id
    ):

        # Find the attendance session
        try:

            session = AttendanceSession.objects.get(
                session_id=session_id
            )

        except AttendanceSession.DoesNotExist:

            return Response(
                {
                    'error': (
                        'Attendance session not found'
                    )
                },
                status=status.HTTP_404_NOT_FOUND
            )

        # Check whether the session has expired
        expire_session_if_needed(session)

        # Check that this session belongs to this teacher
        try:

            assignment = SubjectAssignment.objects.get(
                assignment_id=session.assignment_id,
                teacher_id=teacher_id
            )

        except SubjectAssignment.DoesNotExist:

            return Response(
                {
                    'error': (
                        'This attendance session does not '
                        'belong to this teacher'
                    )
                },
                status=status.HTTP_403_FORBIDDEN
            )

        # Get subject
        try:

            subject = Subject.objects.get(
                subject_id=assignment.subject_id
            )

        except Subject.DoesNotExist:

            return Response(
                {
                    'error': 'Subject not found'
                },
                status=status.HTTP_404_NOT_FOUND
            )

        # Get all attendance records for this session
        attendance_records = Attendance.objects.filter(
            session_id=session.session_id
        ).order_by('attendance_time')

        attendance_list = []

        for attendance in attendance_records:

            try:

                # Get student
                student = Student.objects.get(
                    student_id=attendance.student_id
                )

                # Convert UTC time to local timezone
                local_attendance_time = (
                    timezone.localtime(
                        attendance.attendance_time
                    )
                    if attendance.attendance_time
                    else None
                )

                attendance_list.append(
                    {
                        'attendance_id':
                            attendance.attendance_id,

                        'student_id':
                            student.student_id,

                        'student_name':
                            student.full_name,

                        'attendance_time': (
                            local_attendance_time.strftime(
                                '%d %B %Y, %I:%M %p'
                            )
                            if local_attendance_time
                            else ''
                        ),

                        'face_verified':
                            attendance.face_verified,

                        'ble_verified':
                            attendance.ble_verified,

                        'status':
                            attendance.status,
                    }
                )

            except Student.DoesNotExist:

                continue

        return Response(
            {
                'session_id':
                    session.session_id,

                'assignment_id':
                    assignment.assignment_id,

                'subject_code':
                    subject.subject_code,

                'subject_name':
                    subject.subject_name,

                'session_status':
                    session.status,

                'start_time':
                    session.start_time,

                'end_time':
                    session.end_time,

                'total_present':
                    len(attendance_list),

                'attendance':
                    attendance_list,
            },
            status=status.HTTP_200_OK
        )


# ============================================================
# FACE REGISTRATION
# ============================================================

class FaceRegistrationView(APIView):

    permission_classes = [IsStudent]

    def post(self, request):

        # ----------------------------------------------------
        # Get the authenticated user's ID from JWT
        # ----------------------------------------------------

        user_id = request.auth.get('user_id')

        if not user_id:

            return Response(
                {
                    'error': 'User information not found'
                },
                status=status.HTTP_401_UNAUTHORIZED
            )

        # ----------------------------------------------------
        # Find the student linked to this user
        # ----------------------------------------------------

        try:

            student = Student.objects.get(
                user_id=user_id
            )

        except Student.DoesNotExist:

            return Response(
                {
                    'error': 'Student record not found'
                },
                status=status.HTTP_404_NOT_FOUND
            )

        # ----------------------------------------------------
        # Check whether a face is already registered
        # ----------------------------------------------------

        if FaceRegistration.objects.filter(
            student_id=student.student_id
        ).exists():

            return Response(
                {
                    'error': 'Face is already registered'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # ----------------------------------------------------
        # Get the three uploaded images
        # ----------------------------------------------------

        front_image = request.FILES.get('front_image')
        left_image = request.FILES.get('left_image')
        right_image = request.FILES.get('right_image')

        if not front_image:

            return Response(
                {
                    'error': 'Front face image is required'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if not left_image:

            return Response(
                {
                    'error': 'Left face image is required'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if not right_image:

            return Response(
                {
                    'error': 'Right face image is required'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # ----------------------------------------------------
        # Validate uploaded images
        # ----------------------------------------------------

        allowed_types = [
            'image/jpeg',
            'image/png'
        ]

        images = {
            'front': front_image,
            'left': left_image,
            'right': right_image,
        }

        for view_name, image in images.items():

            if image.size > 5 * 1024 * 1024:

                return Response(
                    {
                        'error': (
                            f'{view_name.capitalize()} face image '
                            'must be less than 5 MB'
                        )
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

            if image.content_type not in allowed_types:

                return Response(
                    {
                        'error': (
                            f'{view_name.capitalize()} face image '
                            'must be JPEG or PNG'
                        )
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

        # ----------------------------------------------------
        # Locate face_env Python
        # ----------------------------------------------------

        backend_directory = os.path.dirname(
            os.path.dirname(
                os.path.abspath(__file__)
            )
        )

        face_python = os.path.join(
            backend_directory,
            'face_env',
            'Scripts',
            'python.exe'
        )

        face_encoder_script = os.path.join(
            backend_directory,
            'attendance',
            'face_encoder.py'
        )

        # ----------------------------------------------------
        # Check face environment
        # ----------------------------------------------------

        if not os.path.exists(face_python):

            return Response(
                {
                    'error': (
                        'Face recognition environment '
                        'was not found'
                    )
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        if not os.path.exists(face_encoder_script):

            return Response(
                {
                    'error': (
                        'Face encoder script was not found'
                    )
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        temporary_files = []

        try:

            encodings = {}

            # ------------------------------------------------
            # Process each face view
            # ------------------------------------------------

            for view_name, image in images.items():

                temporary_file = tempfile.NamedTemporaryFile(
                    delete=False,
                    suffix='.jpg'
                )

                temporary_image_path = temporary_file.name

                temporary_files.append(
                    temporary_image_path
                )

                # Save uploaded image
                for chunk in image.chunks():

                    temporary_file.write(chunk)

                temporary_file.close()

                print(
                    f'PROCESSING {view_name.upper()} FACE: '
                    f'{temporary_image_path}'
                )

                # ------------------------------------------------
                # Run face encoder
                # ------------------------------------------------

                result = subprocess.run(
                    [
                        face_python,
                        face_encoder_script,
                        temporary_image_path
                    ],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    universal_newlines=True,
                    timeout=30
                )

                # ------------------------------------------------
                # Check encoder process
                # ------------------------------------------------

                if result.returncode != 0:

                    print(
                        f'FACE ENCODER ERROR '
                        f'({view_name}): '
                        f'{result.stderr}'
                    )

                    return Response(
                        {
                            'error': (
                                f'{view_name.capitalize()} face '
                                'processing failed'
                            )
                        },
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )

                output = result.stdout.strip()

                if not output:

                    return Response(
                        {
                            'error': (
                                f'No response from face '
                                f'recognition service for '
                                f'{view_name} face'
                            )
                        },
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )

                # ------------------------------------------------
                # Convert JSON result
                # ------------------------------------------------

                try:

                    face_result = json.loads(output)

                except json.JSONDecodeError:

                    print(
                        f'INVALID FACE ENCODER OUTPUT '
                        f'({view_name}): {output}'
                    )

                    return Response(
                        {
                            'error': (
                                f'Invalid response from face '
                                f'recognition service for '
                                f'{view_name} face'
                            )
                        },
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )

                # ------------------------------------------------
                # Check face processing result
                # ------------------------------------------------

                if not face_result.get('success'):

                    face_error = face_result.get(
                        'error',
                        'Face could not be processed'
                    )

                    return Response(
                        {
                            'error': (
                                f'{view_name.capitalize()} face: '
                                f'{face_error}'
                            )
                        },
                        status=status.HTTP_400_BAD_REQUEST
                    )

                encoding = face_result.get('encoding')

                # ------------------------------------------------
                # Validate 128-dimensional encoding
                # ------------------------------------------------

                if not encoding or len(encoding) != 128:

                    return Response(
                        {
                            'error': (
                                f'Invalid {view_name} face '
                                'encoding'
                            )
                        },
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )

                encodings[view_name] = encoding

            # ----------------------------------------------------
            # Store all three face encodings
            # ----------------------------------------------------

            face_data = json.dumps(
                {
                    'front': encodings['front'],
                    'left': encodings['left'],
                    'right': encodings['right'],
                }
            )

            face_registration = FaceRegistration.objects.create(
                student_id=student.student_id,
                face_data=face_data,
                registered_at=timezone.now()
            )

            # ----------------------------------------------------
            # Successful registration
            # ----------------------------------------------------

            return Response(
                {
                    'message': (
                        'Face registration completed successfully'
                    ),
                    'face_id':
                        face_registration.face_id,
                    'student_id':
                        student.student_id,
                    'views_registered': [
                        'front',
                        'left',
                        'right',
                    ],
                },
                status=status.HTTP_201_CREATED
            )

        except subprocess.TimeoutExpired:

            return Response(
                {
                    'error': (
                        'Face processing timed out'
                    )
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        except Exception as e:

            print(
                f'FACE REGISTRATION ERROR: {e}'
            )

            return Response(
                {
                    'error': (
                        'An error occurred during '
                        'face registration'
                    )
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        finally:

            # ------------------------------------------------
            # Remove all temporary images
            # ------------------------------------------------

            for temporary_image_path in temporary_files:

                if os.path.exists(
                    temporary_image_path
                ):

                    try:

                        os.remove(
                            temporary_image_path
                        )

                    except OSError:

                        pass


# ============================================================
# FACE VERIFICATION
# ============================================================

class FaceRegistrationStatusView(APIView):

    permission_classes = [IsStudent]

    def get(self, request):

        # ----------------------------------------------------
        # Get authenticated user's ID from JWT
        # ----------------------------------------------------

        user_id = request.auth.get('user_id')

        if not user_id:
            return Response(
                {
                    'error': 'User information not found'
                },
                status=status.HTTP_401_UNAUTHORIZED
            )

        # ----------------------------------------------------
        # Find the student linked to this user
        # ----------------------------------------------------

        try:
            student = Student.objects.get(
                user_id=user_id
            )

        except Student.DoesNotExist:
            return Response(
                {
                    'error': 'Student record not found'
                },
                status=status.HTTP_404_NOT_FOUND
            )

        # ----------------------------------------------------
        # Check face registration
        # ----------------------------------------------------

        registered = FaceRegistration.objects.filter(
            student_id=student.student_id
        ).exists()

        return Response(
            {
                'registered': registered,
                'student_id': student.student_id,
            },
            status=status.HTTP_200_OK
        )

class FaceVerificationView(APIView):

    permission_classes = [IsStudent]

    def post(self, request):

        # ----------------------------------------------------
        # Get the authenticated user's ID from JWT
        # ----------------------------------------------------

        user_id = request.auth.get('user_id')

        if not user_id:

            return Response(
                {
                    'error': 'User information not found'
                },
                status=status.HTTP_401_UNAUTHORIZED
            )

        # ----------------------------------------------------
        # Find the authenticated student
        # ----------------------------------------------------

        try:

            student = Student.objects.get(
                user_id=user_id
            )

        except Student.DoesNotExist:

            return Response(
                {
                    'error': 'Student record not found'
                },
                status=status.HTTP_404_NOT_FOUND
            )

        # ----------------------------------------------------
        # Get attendance QR token
        # ----------------------------------------------------

        qr_token = request.data.get(
            'qr_token'
        )

        if not qr_token:

            return Response(
                {
                    'error': 'QR token is required'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

                # ----------------------------------------------------
        # Validate attendance session
        # ----------------------------------------------------

        try:

            session = AttendanceSession.objects.get(
                qr_token=qr_token,
                status='Running'
            )

        except AttendanceSession.DoesNotExist:

            return Response(
                {
                    'error': 'Invalid or inactive QR code'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # ----------------------------------------------------
        # Check whether the session has expired
        # ----------------------------------------------------

        if expire_session_if_needed(session):

            return Response(
                {
                    'error': 'QR code has expired'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # ----------------------------------------------------
        # Get live face image
        # ----------------------------------------------------

        live_image = request.FILES.get(
            'live_image'
        )

        if not live_image:

            return Response(
                {
                    'error': 'Live face image is required'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # ----------------------------------------------------
        # Find registered face
        # ----------------------------------------------------

        try:

            face_registration = FaceRegistration.objects.get(
                student_id=student.student_id
            )

        except FaceRegistration.DoesNotExist:

            return Response(
                {
                    'error': (
                        'Face is not registered for '
                        'this student'
                    )
                },
                status=status.HTTP_404_NOT_FOUND
            )

        # ----------------------------------------------------
        # Validate uploaded image
        # ----------------------------------------------------

        allowed_types = [
            'image/jpeg',
            'image/png'
        ]

        if live_image.size > 5 * 1024 * 1024:

            return Response(
                {
                    'error': (
                        'Face image must be less than 5 MB'
                    )
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        if live_image.content_type not in allowed_types:

            return Response(
                {
                    'error': (
                        'Face image must be JPEG or PNG'
                    )
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # ----------------------------------------------------
        # Locate face recognition environment
        # ----------------------------------------------------

        backend_directory = os.path.dirname(
            os.path.dirname(
                os.path.abspath(__file__)
            )
        )

        face_python = os.path.join(
            backend_directory,
            'face_env',
            'Scripts',
            'python.exe'
        )

        face_verifier_script = os.path.join(
            backend_directory,
            'attendance',
            'face_verifier.py'
        )

        if not os.path.exists(face_python):

            return Response(
                {
                    'error': (
                        'Face recognition environment '
                        'was not found'
                    )
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        if not os.path.exists(face_verifier_script):

            return Response(
                {
                    'error': (
                        'Face verifier script was not found'
                    )
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        temporary_image_path = None

        try:

            # ------------------------------------------------
            # Save uploaded image temporarily
            # ------------------------------------------------

            temporary_file = tempfile.NamedTemporaryFile(
                delete=False,
                suffix='.jpg'
            )

            temporary_image_path = temporary_file.name

            for chunk in live_image.chunks():

                temporary_file.write(chunk)

            temporary_file.close()

            # ------------------------------------------------
            # Load registered face data
            # ------------------------------------------------

            try:

                registered_encodings = json.loads(
                    face_registration.face_data
                )

            except json.JSONDecodeError:

                return Response(
                    {
                        'error': (
                            'Invalid registered face data'
                        )
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

            # ------------------------------------------------
            # Run face verifier
            # ------------------------------------------------

            result = subprocess.run(
                [
                    face_python,
                    face_verifier_script,
                    temporary_image_path,
                    json.dumps(registered_encodings)
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True,
                timeout=30
            )

            # ------------------------------------------------
            # Check verifier process
            # ------------------------------------------------

            if result.returncode != 0:

                print(
                    'FACE VERIFIER ERROR:',
                    result.stderr
                )

                return Response(
                    {
                        'error': (
                            'Face verification failed'
                        )
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

            output = result.stdout.strip()

            if not output:

                return Response(
                    {
                        'error': (
                            'No response from face '
                            'verification service'
                        )
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

            # ------------------------------------------------
            # Convert verifier output to JSON
            # ------------------------------------------------

            try:

                verification_result = json.loads(
                    output
                )

            except json.JSONDecodeError:

                print(
                    'INVALID FACE VERIFIER OUTPUT:',
                    output
                )

                return Response(
                    {
                        'error': (
                            'Invalid response from face '
                            'verification service'
                        )
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

            # ------------------------------------------------
            # Check verification result
            # ------------------------------------------------

            if not verification_result.get(
                'success'
            ):

                return Response(
                    {
                        'verified': False,
                        'error': verification_result.get(
                            'error',
                            'Face could not be verified'
                        )
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

            # ------------------------------------------------
            # Return verification result
            # ------------------------------------------------

            verified = verification_result.get(
                'verified',
                False
            )

            response_data = {
                'verified': verified,

                'matched_view':
                    verification_result.get(
                        'matched_view'
                    ),

                'distance':
                    verification_result.get(
                        'distance'
                    ),

                'tolerance':
                    verification_result.get(
                        'tolerance'
                    ),
            }

            # ------------------------------------------------
            # Create signed face verification proof
            # ------------------------------------------------

            if verified:

                response_data['face_proof'] = signing.dumps(
                    {
                        'student_id': student.student_id,
                        'session_id': session.session_id,
                        'qr_token': qr_token,
                        'face_verified': True,
                    }
                )

            return Response(
                response_data,
                status=status.HTTP_200_OK
            )

        except subprocess.TimeoutExpired:

            return Response(
                {
                    'error': (
                        'Face verification timed out'
                    )
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        except Exception as e:

            print(
                'FACE VERIFICATION ERROR:',
                e
            )

            return Response(
                {
                    'error': (
                        'An error occurred during '
                        'face verification'
                    )
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        finally:

            # ------------------------------------------------
            # Remove temporary image
            # ------------------------------------------------

            if (
                temporary_image_path
                and os.path.exists(
                    temporary_image_path
                )
            ):

                try:

                    os.remove(
                        temporary_image_path
                    )

                except OSError:

                    pass


# ============================================================
# DEVICE REGISTRATION
# ============================================================

class DeviceRegistrationStatusView(APIView):

    permission_classes = [IsStudent]

    def get(self, request):

        user_id = request.auth.get('user_id')

        if not user_id:
            return Response(
                {
                    'error': 'User information not found'
                },
                status=status.HTTP_401_UNAUTHORIZED
            )

        try:
            student = Student.objects.get(
                user_id=user_id
            )

        except Student.DoesNotExist:
            return Response(
                {
                    'error': 'Student record not found'
                },
                status=status.HTTP_404_NOT_FOUND
            )

        registered = DeviceRegistration.objects.filter(
            student_id=student.student_id
        ).exists()

        return Response(
            {
                'registered': registered,
                'student_id': student.student_id,
            },
            status=status.HTTP_200_OK
        )

class DeviceRegistrationView(APIView):

    permission_classes = [IsStudent]

    def post(self, request):

        user_id = request.auth.get('user_id')

        try:

            student = Student.objects.get(
                user_id=user_id
            )

        except Student.DoesNotExist:

            return Response(
                {
                    'error': 'Student not found'
                },
                status=status.HTTP_404_NOT_FOUND
            )

        device_uuid = request.data.get(
            'device_uuid'
        )

        device_name = request.data.get(
            'device_name'
        )

        if not device_uuid:

            return Response(
                {
                    'error': 'device_uuid is required'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # ----------------------------------------------------
        # Check whether this student already has a device
        # ----------------------------------------------------

        existing_registration = (
            DeviceRegistration.objects.filter(
                student_id=student.student_id
            ).first()
        )

        if existing_registration:

            # Same student + same device
            if (
                existing_registration.device_uuid
                == device_uuid
            ):

                return Response(
                    {
                        'message':
                            'Device is already registered',

                        'device_registration_id':
                            existing_registration
                            .device_registration_id,

                        'student_id':
                            existing_registration
                            .student_id,

                        'device_uuid':
                            existing_registration
                            .device_uuid,

                        'device_name':
                            existing_registration
                            .device_name,

                        'registered_at':
                            existing_registration
                            .registered_at,
                    },
                    status=status.HTTP_200_OK
                )

            # Same student trying another device
            return Response(
                {
                    'error':
                        'This student already has a '
                        'registered device'
                },
                status=status.HTTP_409_CONFLICT
            )

        # ----------------------------------------------------
        # Check whether this device belongs to another student
        # ----------------------------------------------------

        device_already_registered = (
            DeviceRegistration.objects.filter(
                device_uuid=device_uuid
            ).first()
        )

        if device_already_registered:

            return Response(
                {
                    'error':
                        'This device is already registered '
                        'to another student'
                },
                status=status.HTTP_409_CONFLICT
            )

        # ----------------------------------------------------
        # Register new device
        # ----------------------------------------------------

        device_registration = (
            DeviceRegistration.objects.create(
                student_id=student.student_id,
                device_uuid=device_uuid,
                device_name=device_name,
                registered_at=timezone.now()
            )
        )

        return Response(
            {
                'message':
                    'Device registered successfully',

                'device_registration_id':
                    device_registration
                    .device_registration_id,

                'student_id':
                    device_registration
                    .student_id,

                'device_uuid':
                    device_registration
                    .device_uuid,

                'device_name':
                    device_registration
                    .device_name,

                'registered_at':
                    device_registration
                    .registered_at,
            },
            status=status.HTTP_201_CREATED
        )
