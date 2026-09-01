from django.urls import path

from .views import (
    TeacherListCreateView,
    TeacherDetailView,
)

from .web_views import teacher_dashboard


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

    # Teacher web dashboard
    path(
        'dashboard/',
        teacher_dashboard,
        name='teacher-dashboard',
    ),
]