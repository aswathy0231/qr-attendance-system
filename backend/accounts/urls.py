from django.urls import path

from .views import LoginView, ProfileView
from .web_views import teacher_login


urlpatterns = [
    # Existing API login
    path(
        'login/',
        LoginView.as_view(),
        name='login'
    ),

    # Existing student profile API
    path(
        'profile/',
        ProfileView.as_view(),
        name='profile'
    ),

    # Teacher web login
    path(
        'teacher-login/',
        teacher_login,
        name='teacher-login'
    ),
]