from django.urls import path

from .web_views import (
    admin_login,
    admin_dashboard,
    manage_students,
    add_student,
    edit_student,
    delete_student,
    manage_teachers,
    add_teacher,
    edit_teacher,
    delete_teacher,
    manage_classes,
    add_class,
    edit_class,
    delete_class,
    manage_subjects,
    add_subject,
    edit_subject,
    delete_subject,
    manage_subject_assignments,
    add_subject_assignment,
    edit_subject_assignment,
    delete_subject_assignment,
    manage_timetables,
    add_timetable,
    edit_timetable,
    delete_timetable,
)


urlpatterns = [
    path('login/', admin_login, name='admin_login'),
    path('dashboard/', admin_dashboard, name='admin_dashboard'),

    # Student management
    path('students/', manage_students, name='manage_students'),
    path('students/add/', add_student, name='add_student'),
    path(
        'students/<int:student_id>/edit/',
        edit_student,
        name='edit_student'
    ),
    path(
        'students/<int:student_id>/delete/',
        delete_student,
        name='delete_student'
    ),

    # Teacher management
    path(
        'teachers/',
        manage_teachers,
        name='manage_teachers'
    ),
    path(
    'teachers/add/',
    add_teacher,
    name='add_teacher'
    ),
    path(
    'teachers/<int:teacher_id>/edit/',
    edit_teacher,
    name='edit_teacher'
),
    path(
    'teachers/<int:teacher_id>/delete/',
    delete_teacher,
    name='delete_teacher'
),
    path('classes/', manage_classes, name='manage_classes'),
path('classes/add/', add_class, name='add_class'),
path(
    'classes/<int:class_id>/edit/',
    edit_class,
    name='edit_class'
),
path(
    'classes/<int:class_id>/delete/',
    delete_class,
    name='delete_class'
),
path('subjects/', manage_subjects, name='manage_subjects'),
path('subjects/add/', add_subject, name='add_subject'),
path(
    'subjects/<int:subject_id>/edit/',
    edit_subject,
    name='edit_subject'
),
path(
    'subjects/<int:subject_id>/delete/',
    delete_subject,
    name='delete_subject'
),
path(
    'subject-assignments/',
    manage_subject_assignments,
    name='manage_subject_assignments'
),
path(
    'subject-assignments/add/',
    add_subject_assignment,
    name='add_subject_assignment'
),
path(
    'subject-assignments/<int:assignment_id>/edit/',
    edit_subject_assignment,
    name='edit_subject_assignment'
),
path(
    'subject-assignments/<int:assignment_id>/delete/',
    delete_subject_assignment,
    name='delete_subject_assignment'
),
path(
    'timetables/',
    manage_timetables,
    name='manage_timetables'
),
path(
    'timetables/add/',
    add_timetable,
    name='add_timetable'
),
path(
    'timetables/<int:timetable_id>/edit/',
    edit_timetable,
    name='edit_timetable'
),
path(
    'timetables/<int:timetable_id>/delete/',
    delete_timetable,
    name='delete_timetable'
),
]