from django.shortcuts import render

# Create your views here.
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import AttendanceSession, Attendance


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