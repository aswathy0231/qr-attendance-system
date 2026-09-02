from django.contrib import admin
from django.urls import path, include

from teachers.web_views import (
    teacher_dashboard,
    teacher_attendance,
    teacher_attendance_history,
)


urlpatterns = [

    path(
        'admin/',
        admin.site.urls
    ),

    path(
        'admin-web/',
        include('admins.web_urls')
    ),

    # Week 2 - Authentication
    path(
        'api/',
        include('accounts.urls')
    ),

    # Week 3 - Student CRUD
    path(
        'api/students/',
        include('students.urls')
    ),

    # Week 3 - Teacher CRUD
    path(
        'api/teachers/',
        include('teachers.urls')
    ),

    # Week 3 - Department CRUD
    path(
        'api/departments/',
        include('departments.urls')
    ),

    # Week 3 - Classes CRUD
    path(
        'api/classes/',
        include('classes.urls')
    ),

    # Week 3 - Subject CRUD
    path(
        'api/subjects/',
        include('subjects.urls')
    ),

    # Week 3 - Timetables CRUD
    path(
        'api/timetables/',
        include('timetables.urls')
    ),

    # Week 3 - Attendance CRUD
    path(
        'api/attendance/',
        include('attendance.urls')
    ),

    # Teacher web dashboard
    path(
        'teacher/dashboard/',
        teacher_dashboard,
        name='teacher_dashboard'
    ),

    # Teacher attendance management page
    path(
        'teacher/attendance/<int:session_id>/',
        teacher_attendance,
        name='teacher_attendance'
    ),

    # Teacher attendance history page
    path(
        'teacher/attendance-history/',
        teacher_attendance_history,
        name='teacher_attendance_history'
    ),

]