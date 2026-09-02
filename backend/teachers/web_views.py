from django.shortcuts import render, redirect

from .models import Teacher

from admins.models import SubjectAssignment
from subjects.models import Subject
from classes.models import Class

from attendance.models import AttendanceSession
from attendance.models import Attendance


def teacher_dashboard(request):

    # Check whether a teacher is logged in
    if 'teacher_user_id' not in request.session:
        return redirect('/api/teacher-login/')

    # Get the logged-in teacher's user ID
    teacher_user_id = request.session['teacher_user_id']

    # Find the teacher record
    try:
        teacher = Teacher.objects.get(
            user_id=teacher_user_id
        )

    except Teacher.DoesNotExist:
        return redirect('/api/teacher-login/')

    # Get all assignments for this teacher
    assignments = SubjectAssignment.objects.filter(
        teacher_id=teacher.teacher_id
    )

    assignment_list = []

    for assignment in assignments:

        try:
            subject = Subject.objects.get(
                subject_id=assignment.subject_id
            )

            class_obj = Class.objects.get(
                class_id=assignment.class_id
            )

            assignment_list.append({
                'assignment_id': assignment.assignment_id,
                'subject_code': subject.subject_code,
                'subject_name': subject.subject_name,
                'class_id': assignment.class_id,
                'class_name': class_obj.class_name,
                'section': class_obj.section,
                'semester': assignment.semester,
                'academic_year': assignment.academic_year,
            })

        except (
            Subject.DoesNotExist,
            Class.DoesNotExist
        ):
            continue

    return render(
        request,
        'teacher/dashboard.html',
        {
            'teacher': teacher,
            'assignments': assignment_list,
        }
    )


def teacher_attendance(request, session_id):

    # Check whether a teacher is logged in
    if 'teacher_user_id' not in request.session:
        return redirect('/api/teacher-login/')

    # Get the logged-in teacher's user ID
    teacher_user_id = request.session['teacher_user_id']

    # Find the teacher record
    try:
        teacher = Teacher.objects.get(
            user_id=teacher_user_id
        )

    except Teacher.DoesNotExist:
        return redirect('/api/teacher-login/')

    # Find the attendance session
    try:
        session = AttendanceSession.objects.get(
            session_id=session_id
        )

    except AttendanceSession.DoesNotExist:
        return redirect('/teacher/dashboard/')

    # Find the assignment
    try:
        assignment = SubjectAssignment.objects.get(
            assignment_id=session.assignment_id,
            teacher_id=teacher.teacher_id
        )

    except SubjectAssignment.DoesNotExist:
        return redirect('/teacher/dashboard/')

    # Find the subject
    try:
        subject = Subject.objects.get(
            subject_id=assignment.subject_id
        )

    except Subject.DoesNotExist:
        return redirect('/teacher/dashboard/')

    # Open attendance page
    return render(
        request,
        'teacher/attendance.html',
        {
            'teacher': teacher,
            'session': session,
            'subject': subject,
        }
    )


def teacher_attendance_history(request):

    # Check whether a teacher is logged in
    if 'teacher_user_id' not in request.session:
        return redirect('/api/teacher-login/')

    # Get the logged-in teacher's user ID
    teacher_user_id = request.session['teacher_user_id']

    # Find the teacher record
    try:
        teacher = Teacher.objects.get(
            user_id=teacher_user_id
        )

    except Teacher.DoesNotExist:
        return redirect('/api/teacher-login/')

    # Get all assignments belonging to this teacher
    assignments = SubjectAssignment.objects.filter(
        teacher_id=teacher.teacher_id
    )

    # Store assignment IDs
    assignment_ids = [
        assignment.assignment_id
        for assignment in assignments
    ]

    # Get all attendance sessions for these assignments
    sessions = AttendanceSession.objects.filter(
        assignment_id__in=assignment_ids
    ).order_by('-start_time')

    history = []

    for session in sessions:

        try:
            # Get assignment
            assignment = SubjectAssignment.objects.get(
                assignment_id=session.assignment_id
            )

            # Get subject
            subject = Subject.objects.get(
                subject_id=assignment.subject_id
            )

            # Get class
            class_obj = Class.objects.get(
                class_id=assignment.class_id
            )

            # Count students present
            total_present = Attendance.objects.filter(
                session_id=session.session_id,
                status='Present'
            ).count()

            history.append({
                'session_id': session.session_id,
                'subject_code': subject.subject_code,
                'subject_name': subject.subject_name,
                'class_name': class_obj.class_name,
                'section': class_obj.section,
                'semester': assignment.semester,
                'academic_year': assignment.academic_year,
                'start_time': session.start_time,
                'end_time': session.end_time,
                'status': session.status,
                'total_present': total_present,
            })

        except (
            SubjectAssignment.DoesNotExist,
            Subject.DoesNotExist,
            Class.DoesNotExist
        ):
            continue

    return render(
        request,
        'teacher/attendance_history.html',
        {
            'teacher': teacher,
            'history': history,
        }
    )