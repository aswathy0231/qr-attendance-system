from django.urls import path

from .views import (
    CreateAttendanceSessionView,
    RefreshAttendanceQRView,
    EndAttendanceSessionView,
    MarkAttendanceView,
    AttendanceHistoryView,
    TeacherAttendanceView,
    FaceRegistrationStatusView,
    FaceRegistrationView,
    FaceVerificationView,
    DeviceRegistrationStatusView,
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
        'face/status/',
        FaceRegistrationStatusView.as_view(),
        name='face-registration-status',
    ),  
    
    path(
        'face/register/',
        FaceRegistrationView.as_view(),
        name='face-register',
    ),

    # --------------------------------------------------------
    # FACE VERIFICATION
    # --------------------------------------------------------

    path(
        'face/verify/',
        FaceVerificationView.as_view(),
        name='face-verification',
    ),

    # --------------------------------------------------------
    # DEVICE REGISTRATION
    # --------------------------------------------------------

    path(
    'device/status/',
    DeviceRegistrationStatusView.as_view(),
    name='device-registration-status',
),
    
    path(
        'device/register/',
        DeviceRegistrationView.as_view(),
        name='device-registration',
    ),

]