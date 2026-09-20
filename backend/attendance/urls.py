from django.urls import path

from .views import (
    CreateAttendanceSessionView,
    RefreshAttendanceQRView,
    EndAttendanceSessionView,
    MarkAttendanceView,
    AttendanceHistoryView,
    TeacherAttendanceView,
    FaceRegistrationView,
    DeviceRegistrationView,
)


urlpatterns = [

    # --------------------------------------------------------
    # CREATE ATTENDANCE SESSION
    # --------------------------------------------------------

    path(
        'sessions/create/',
        CreateAttendanceSessionView.as_view(),
        name='create-attendance-session',
    ),

    # --------------------------------------------------------
    # REFRESH QR CODE
    # --------------------------------------------------------

    path(
        'sessions/<int:session_id>/qr/',
        RefreshAttendanceQRView.as_view(),
        name='refresh-attendance-qr',
    ),

    # --------------------------------------------------------
    # END ATTENDANCE SESSION
    # --------------------------------------------------------

    path(
        'sessions/end/',
        EndAttendanceSessionView.as_view(),
        name='end-attendance-session',
    ),

    # --------------------------------------------------------
    # MARK ATTENDANCE
    # --------------------------------------------------------

    path(
        'mark/',
        MarkAttendanceView.as_view(),
        name='mark-attendance',
    ),

    # --------------------------------------------------------
    # STUDENT ATTENDANCE HISTORY
    # --------------------------------------------------------

    path(
        'history/',
        AttendanceHistoryView.as_view(),
        name='attendance-history',
    ),

    # --------------------------------------------------------
    # TEACHER ATTENDANCE DETAILS
    # --------------------------------------------------------

    path(
        'teacher/<int:teacher_id>/session/<int:session_id>/',
        TeacherAttendanceView.as_view(),
        name='teacher-attendance',
    ),

    # --------------------------------------------------------
    # FACE REGISTRATION
    # --------------------------------------------------------

    path(
        'face/register/',
        FaceRegistrationView.as_view(),
        name='face-register',
    ),

    # --------------------------------------------------------
    # DEVICE REGISTRATION
    # --------------------------------------------------------

    path(
        'device/register/',
        DeviceRegistrationView.as_view(),
        name='device-registration',
    ),

]

    