from django.urls import path
from .views import TeacherListCreateView, TeacherDetailView

urlpatterns = [
    path('', TeacherListCreateView.as_view(), name='teacher-list-create'),
    path('<int:teacher_id>/', TeacherDetailView.as_view(), name='teacher-detail'),
]