from django.urls import path
from .views import DepartmentListCreateView, DepartmentDetailView

urlpatterns = [
    path('', DepartmentListCreateView.as_view(), name='department-list-create'),
    path('<int:department_id>/', DepartmentDetailView.as_view(), name='department-detail'),
]