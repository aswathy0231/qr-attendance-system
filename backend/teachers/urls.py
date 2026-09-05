from django.urls import path

from .views import (
    TeacherListCreateView,
    TeacherDetailView,
    TeacherAssignmentsView,
)

from .web_views import (
    teacher_dashboard,
    teacher_attendance,
    teacher_attendance_history,
)


urlpatterns = [

    # Teacher CRUD API
    path(
        '',
        TeacherListCreateView.as_view(),
        name='teacher-list-create',
    ),

    path(
        '<int:teacher_id>/',
        TeacherDetailView.as_view(),
        name='teacher-detail',
    ),

    # Teacher assignments API
    path(
        '<int:teacher_id>/assignments/',
        TeacherAssignmentsView.as_view(),
        name='teacher-assignments',
    ),

    # Teacher web dashboard
    path(
        'dashboard/',
        teacher_dashboard,
        name='teacher-dashboard',
    ),

    # Teacher attendance management page
    path(
        'attendance/<int:session_id>/',
        teacher_attendance,
        name='teacher-attendance',
    ),

    # Teacher attendance history
    path(
        'attendance-history/',
        teacher_attendance_history,
        name='teacher-attendance-history',
    ),
]