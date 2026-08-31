from django.urls import path
from .views import StudentListCreateView, StudentDetailView

urlpatterns = [
    path('', StudentListCreateView.as_view(), name='student-list-create'),
    path('<int:student_id>/', StudentDetailView.as_view(), name='student-detail'),
]