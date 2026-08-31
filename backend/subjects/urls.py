from django.urls import path
from .views import SubjectListCreateView, SubjectDetailView


urlpatterns = [
    path('', SubjectListCreateView.as_view()),
    path('<int:subject_id>/', SubjectDetailView.as_view()),
]