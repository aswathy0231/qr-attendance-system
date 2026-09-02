from django.urls import path

from .views import (
    CreateAttendanceSessionView,
    EndAttendanceSessionView,
    MarkAttendanceView,
    AttendanceHistoryView,
    TeacherAttendanceView,
)

urlpatterns = [
    path(
        'sessions/create/',
        CreateAttendanceSessionView.as_view(),
        name='create-attendance-session',
    ),

    path(
        'sessions/end/',
        EndAttendanceSessionView.as_view(),
        name='end-attendance-session',
    ),

    path(
        'mark/',
        MarkAttendanceView.as_view(),
        name='mark-attendance',
    ),

    path(
        'history/',
        AttendanceHistoryView.as_view(),
        name='attendance-history',
    ),

    path(
        'teacher/<int:teacher_id>/session/<int:session_id>/',
        TeacherAttendanceView.as_view(),
        name='teacher-attendance',
    ),
]