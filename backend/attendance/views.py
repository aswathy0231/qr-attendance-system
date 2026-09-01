import secrets
from datetime import timedelta

from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

import qrcode
from django.core.files.base import ContentFile
from io import BytesIO

from .models import AttendanceSession, Attendance
from .serializers import AttendanceSessionSerializer


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

        return Response(
            {
                'message': 'Attendance marked successfully',
                'attendance_id': attendance.attendance_id,
                'student_id': attendance.student_id,
                'session_id': attendance.session_id,
                'status': attendance.status
            },
            status=status.HTTP_201_CREATED
        )