from django.urls import path

from .views import (
    CreateAttendanceSessionView,
    EndAttendanceSessionView,
    MarkAttendanceView,
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
]