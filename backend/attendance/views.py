import base64
import secrets
from datetime import timedelta

from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

import qrcode
from io import BytesIO

from .models import AttendanceSession, Attendance
from .serializers import AttendanceSessionSerializer

from admins.models import SubjectAssignment
from subjects.models import Subject
from teachers.models import Teacher
from students.models import Student


class CreateAttendanceSessionView(APIView):

    def post(self, request):

        assignment_id = request.data.get('assignment_id')
        duration_minutes = request.data.get('duration_minutes', 10)

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
                    'error': 'duration_minutes must be a positive number'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create session times
        start_time = timezone.now()
        end_time = start_time + timedelta(minutes=duration_minutes)

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

        return Response(
            AttendanceSessionSerializer(session).data,
            status=status.HTTP_201_CREATED
        )


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
                    'error': 'Attendance session not found or already ended'
                },
                status=status.HTTP_404_NOT_FOUND
            )

        # Check whether the session has expired
        if timezone.now() >= session.end_time:

            session.status = 'Ended'

            session.save(
                update_fields=['status']
            )

            return Response(
                {
                    'error': 'Attendance session has expired'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # Generate a completely new QR token
        new_qr_token = secrets.token_urlsafe(32)

        # Replace the old token
        session.qr_token = new_qr_token

        session.save(
            update_fields=['qr_token']
        )

        # Generate QR image from the new token
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

        # Find the running session
        try:
            session = AttendanceSession.objects.get(
                session_id=session_id,
                status='Running'
            )

        except AttendanceSession.DoesNotExist:
            return Response(
                {
                    'error': 'Attendance session not found or already ended'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # End the session
        session.status = 'Ended'
        session.end_time = timezone.now()

        session.save(
            update_fields=[
                'status',
                'end_time'
            ]
        )

        return Response(
            {
                'message': 'Attendance session ended successfully',
                'session_id': session.session_id,
                'status': session.status,
                'end_time': session.end_time
            },
            status=status.HTTP_200_OK
        )


class MarkAttendanceView(APIView):

    def post(self, request):

        student_id = request.data.get('student_id')
        qr_token = request.data.get('qr_token')

        # Check required data
        if not student_id or not qr_token:
            return Response(
                {
                    'error': 'student_id and qr_token are required'
                },
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

        # Check whether the attendance session has expired
        if timezone.now() >= session.end_time:

            session.status = 'Ended'

            session.save(
                update_fields=['status']
            )

            return Response(
                {
                    'error': 'QR code has expired'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

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
            face_verified=False,
            ble_verified=False,
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
                    'error': 'Subject information not found'
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        # Convert attendance time to local timezone
        local_attendance_time = timezone.localtime(
            attendance.attendance_time
        )

        return Response(
            {
                'message': 'Attendance marked successfully',
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


class AttendanceHistoryView(APIView):

    def get(self, request):

        student_id = request.query_params.get('student_id')

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
                    'error': 'student_id must be a number'
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

                # Convert UTC time to local Django timezone
                local_attendance_time = (
                    timezone.localtime(attendance.attendance_time)
                    if attendance.attendance_time
                    else None
                )

                history.append({
                    'attendance_id': attendance.attendance_id,
                    'subject': subject.subject_name,
                    'professor': teacher.full_name,

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

                    'status': attendance.status,
                })

            except (
                AttendanceSession.DoesNotExist,
                SubjectAssignment.DoesNotExist,
                Subject.DoesNotExist,
                Teacher.DoesNotExist
            ):
                # Skip incomplete attendance relationships
                continue

        return Response(
            history,
            status=status.HTTP_200_OK
        )


class TeacherAttendanceView(APIView):

    def get(self, request, teacher_id, session_id):

        # Find the attendance session
        try:
            session = AttendanceSession.objects.get(
                session_id=session_id
            )

        except AttendanceSession.DoesNotExist:
            return Response(
                {
                    'error': 'Attendance session not found'
                },
                status=status.HTTP_404_NOT_FOUND
            )

        # Check that this session belongs to this teacher
        try:
            assignment = SubjectAssignment.objects.get(
                assignment_id=session.assignment_id,
                teacher_id=teacher_id
            )

        except SubjectAssignment.DoesNotExist:
            return Response(
                {
                    'error': 'This attendance session does not belong to this teacher'
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

                # Convert UTC time to local Django timezone
                local_attendance_time = (
                    timezone.localtime(
                        attendance.attendance_time
                    )
                    if attendance.attendance_time
                    else None
                )

                attendance_list.append({
                    'attendance_id': attendance.attendance_id,
                    'student_id': student.student_id,
                    'student_name': student.full_name,

                    'attendance_time': (
                        local_attendance_time.strftime(
                            '%d %B %Y, %I:%M %p'
                        )
                        if local_attendance_time
                        else ''
                    ),

                    'face_verified': attendance.face_verified,
                    'ble_verified': attendance.ble_verified,
                    'status': attendance.status,
                })

            except Student.DoesNotExist:
                # Skip attendance records whose student
                # record cannot be found
                continue

        return Response(
            {
                'session_id': session.session_id,
                'assignment_id': assignment.assignment_id,

                'subject_code': subject.subject_code,
                'subject_name': subject.subject_name,

                'session_status': session.status,

                'start_time': session.start_time,
                'end_time': session.end_time,

                'total_present': len(attendance_list),

                'attendance': attendance_list,
            },
            status=status.HTTP_200_OK
        )