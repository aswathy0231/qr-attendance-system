from django.urls import path
from .views import TimetableListCreateView, TimetableDetailView


urlpatterns = [
    path('', TimetableListCreateView.as_view()),
    path('<int:pk>/', TimetableDetailView.as_view()),
]