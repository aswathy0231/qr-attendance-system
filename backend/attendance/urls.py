from django.urls import path
from .views import MarkAttendanceView, CreateAttendanceSessionView


urlpatterns = [
    path(
        'mark/',
        MarkAttendanceView.as_view(),
        name='mark-attendance'
    ),

    path(
        'sessions/create/',
        CreateAttendanceSessionView.as_view(),
        name='create-attendance-session'
    ),
]