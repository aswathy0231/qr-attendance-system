from django.contrib.auth.hashers import check_password
from django.shortcuts import render, redirect
from django.db import transaction

from accounts.models import User
from students.models import Student
from teachers.models import Teacher
from classes.models import Class
from subjects.models import Subject
from timetables.models import Timetable
from departments.models import Department
from .models import SubjectAssignment


def admin_login(request):

    error_message = None

    if request.method == 'POST':

        username = request.POST.get('username')
        password = request.POST.get('password')

        try:
            user = User.objects.get(username=username)

            if user.status and user.status.lower() != 'active':
                error_message = 'User account is inactive.'

            elif user.role != 'admin':
                error_message = 'This account is not an admin account.'

            elif not check_password(password, user.password):
                error_message = 'Invalid username or password.'

            else:
                request.session['admin_user_id'] = user.user_id
                request.session['admin_username'] = user.username

                return redirect('/admin-web/dashboard/')

        except User.DoesNotExist:
            error_message = 'Invalid username or password.'

    return render(
        request,
        'login/admin_login.html',
        {
            'error_message': error_message,
        }
    )


def admin_dashboard(request):

    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    context = {
        'admin_username': request.session.get(
            'admin_username',
            'Administrator'
        ),
        'student_count': Student.objects.count(),
        'teacher_count': Teacher.objects.count(),
        'class_count': Class.objects.count(),
        'subject_count': Subject.objects.count(),
        'timetable_count': Timetable.objects.count(),
    }

    return render(
        request,
        'admin/dashboard.html',
        context
    )


def manage_students(request):

    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    students = Student.objects.all()

    return render(
        request,
        'admin/students.html',
        {
            'students': students,
        }
    )


def add_student(request):

    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    error_message = None

    if request.method == 'POST':

        username = request.POST.get('username')
        password = request.POST.get('password')
        class_id = request.POST.get('class_id')

        try:
            # Check that the selected class exists
            if not class_id:
                raise ValueError('Class ID is required.')

            if not Class.objects.filter(class_id=class_id).exists():
                raise ValueError(f'Class ID {class_id} does not exist.')

            with transaction.atomic():

                user = User.objects.create_user(
                    username=username,
                    password=password,
                    role='student',
                    status='Active'
                )

                Student.objects.create(
                    user_id=user.user_id,
                    register_no=request.POST.get('register_no'),
                    full_name=request.POST.get('full_name'),
                    email=request.POST.get('email'),
                    phone=request.POST.get('phone'),
                    class_id=class_id,
                )

            return redirect('/admin-web/students/')

        except Exception as e:
            error_message = str(e)

    return render(
        request,
        'admin/add_student.html',
        {
            'error_message': error_message,
        }
    )
    
def edit_student(request, student_id):

    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    try:
        student = Student.objects.get(student_id=student_id)
    except Student.DoesNotExist:
        return redirect('/admin-web/students/')

    error_message = None

    if request.method == 'POST':

        try:
            student.register_no = request.POST.get('register_no')
            student.full_name = request.POST.get('full_name')
            student.email = request.POST.get('email')
            student.phone = request.POST.get('phone')
            student.class_id = request.POST.get('class_id')

            student.save()

            return redirect('/admin-web/students/')

        except Exception as e:
            error_message = str(e)

    return render(
        request,
        'admin/edit_student.html',
        {
            'student': student,
            'error_message': error_message,
        }
    )
def delete_student(request, student_id):

    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    if request.method == 'POST':

        try:
            with transaction.atomic():

                student = Student.objects.get(student_id=student_id)

                user_id = student.user_id

                student.delete()

                User.objects.filter(user_id=user_id).delete()

        except Student.DoesNotExist:
            pass

    return redirect('/admin-web/students/')

def manage_teachers(request):

    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    teachers = Teacher.objects.all()

    return render(
        request,
        'admin/teachers.html',
        {
            'teachers': teachers,
        }
    )
    
def add_teacher(request):

    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    error_message = None

    if request.method == 'POST':

        username = request.POST.get('username')
        password = request.POST.get('password')
        department_id = request.POST.get('department_id')

        try:
            # Check that the selected department exists
            if not department_id:
                raise ValueError('Department ID is required.')

            if not Department.objects.filter(
                department_id=department_id
            ).exists():
                raise ValueError(
                    f'Department ID {department_id} does not exist.'
                )

            with transaction.atomic():

                user = User.objects.create_user(
                    username=username,
                    password=password,
                    role='teacher',
                    status='Active'
                )

                Teacher.objects.create(
                    user_id=user.user_id,
                    employee_id=request.POST.get('employee_id'),
                    full_name=request.POST.get('full_name'),
                    email=request.POST.get('email'),
                    phone=request.POST.get('phone'),
                    department_id=department_id,
                )

            return redirect('/admin-web/teachers/')

        except Exception as e:
            error_message = str(e)

    return render(
        request,
        'admin/add_teacher.html',
        {
            'error_message': error_message,
        }
    )
    
def edit_teacher(request, teacher_id):

    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    try:
        teacher = Teacher.objects.get(teacher_id=teacher_id)
    except Teacher.DoesNotExist:
        return redirect('/admin-web/teachers/')

    error_message = None

    if request.method == 'POST':

        try:
            department_id = request.POST.get('department_id')

            # Check that the selected department exists
            if not department_id:
                raise ValueError('Department ID is required.')

            if not Department.objects.filter(
                department_id=department_id
            ).exists():
                raise ValueError(
                    f'Department ID {department_id} does not exist.'
                )

            # Keep the existing user_id unchanged
            teacher.employee_id = request.POST.get('employee_id')
            teacher.full_name = request.POST.get('full_name')
            teacher.email = request.POST.get('email')
            teacher.phone = request.POST.get('phone')
            teacher.department_id = department_id

            teacher.save()

            return redirect('/admin-web/teachers/')

        except Exception as e:
            error_message = str(e)

    return render(
        request,
        'admin/edit_teacher.html',
        {
            'teacher': teacher,
            'error_message': error_message,
        }
    )
    
def delete_teacher(request, teacher_id):

    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    if request.method == 'POST':

        try:
            with transaction.atomic():

                teacher = Teacher.objects.get(
                    teacher_id=teacher_id
                )

                user_id = teacher.user_id

                teacher.delete()

                User.objects.filter(
                    user_id=user_id
                ).delete()

        except Teacher.DoesNotExist:
            pass

    return redirect('/admin-web/teachers/')

def manage_classes(request):

    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    classes = Class.objects.all()

    return render(
        request,
        'admin/classes.html',
        {
            'classes': classes,
        }
    )


def add_class(request):

    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    error_message = None
    departments = Department.objects.all()

    if request.method == 'POST':

        try:
            Class.objects.create(
                class_name=request.POST.get('class_name'),
                semester=request.POST.get('semester'),
                section=request.POST.get('section'),
                department_id=request.POST.get('department_id'),
            )

            return redirect('/admin-web/classes/')

        except Exception as e:
            error_message = str(e)

    return render(
        request,
        'admin/add_class.html',
        {
            'departments': departments,
            'error_message': error_message,
        }
    )


def edit_class(request, class_id):

    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    try:
        class_obj = Class.objects.get(class_id=class_id)
    except Class.DoesNotExist:
        return redirect('/admin-web/classes/')

    departments = Department.objects.all()
    error_message = None

    if request.method == 'POST':

        try:
            class_obj.class_name = request.POST.get('class_name')
            class_obj.semester = request.POST.get('semester')
            class_obj.section = request.POST.get('section')
            class_obj.department_id = request.POST.get('department_id')

            class_obj.save()

            return redirect('/admin-web/classes/')

        except Exception as e:
            error_message = str(e)

    return render(
        request,
        'admin/edit_class.html',
        {
            'class_obj': class_obj,
            'departments': departments,
            'error_message': error_message,
        }
    )


def delete_class(request, class_id):

    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    if request.method == 'POST':

        try:
            class_obj = Class.objects.get(class_id=class_id)
            class_obj.delete()

        except Class.DoesNotExist:
            pass

    return redirect('/admin-web/classes/')

def manage_subjects(request):
    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    subjects = Subject.objects.all()

    return render(request, 'admin/subjects.html', {
        'subjects': subjects,
    })
    
def add_subject(request):
    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    error_message = None

    if request.method == 'POST':
        try:
            Subject.objects.create(
                subject_code=request.POST.get('subject_code'),
                subject_name=request.POST.get('subject_name'),
                credits=request.POST.get('credits'),
            )

            return redirect('/admin-web/subjects/')

        except Exception as e:
            error_message = str(e)

    return render(request, 'admin/add_subject.html', {
        'error_message': error_message,
    })
    
def edit_subject(request, subject_id):
    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    try:
        subject = Subject.objects.get(subject_id=subject_id)
    except Subject.DoesNotExist:
        return redirect('/admin-web/subjects/')

    error_message = None

    if request.method == 'POST':
        try:
            subject.subject_code = request.POST.get('subject_code')
            subject.subject_name = request.POST.get('subject_name')
            subject.credits = request.POST.get('credits')

            subject.save()

            return redirect('/admin-web/subjects/')

        except Exception as e:
            error_message = str(e)

    return render(request, 'admin/edit_subject.html', {
        'subject': subject,
        'error_message': error_message,
    })
    
def delete_subject(request, subject_id):
    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    if request.method == 'POST':
        try:
            subject = Subject.objects.get(subject_id=subject_id)
            subject.delete()
        except Subject.DoesNotExist:
            pass

    return redirect('/admin-web/subjects/')

def manage_subject_assignments(request):
    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    assignments = SubjectAssignment.objects.all()

    return render(request, 'admin/subject_assignments.html', {
        'assignments': assignments,
    })
    
def manage_subject_assignments(request):
    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    assignments = SubjectAssignment.objects.all()

    return render(request, 'admin/subject_assignments.html', {
        'assignments': assignments,
    })
    
def add_subject_assignment(request):
    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    error_message = None

    teachers = Teacher.objects.all()
    subjects = Subject.objects.all()
    classes = Class.objects.all()

    if request.method == 'POST':
        try:
            SubjectAssignment.objects.create(
                teacher_id=request.POST.get('teacher_id'),
                subject_id=request.POST.get('subject_id'),
                class_id=request.POST.get('class_id'),
                academic_year=request.POST.get('academic_year'),
                semester=request.POST.get('semester'),
            )

            return redirect('/admin-web/subject-assignments/')

        except Exception as e:
            error_message = str(e)

    return render(request, 'admin/add_subject_assignment.html', {
        'teachers': teachers,
        'subjects': subjects,
        'classes': classes,
        'error_message': error_message,
    })
    
def edit_subject_assignment(request, assignment_id):
    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    try:
        assignment = SubjectAssignment.objects.get(
            assignment_id=assignment_id
        )
    except SubjectAssignment.DoesNotExist:
        return redirect('/admin-web/subject-assignments/')

    error_message = None

    teachers = Teacher.objects.all()
    subjects = Subject.objects.all()
    classes = Class.objects.all()

    if request.method == 'POST':
        try:
            assignment.teacher_id = request.POST.get('teacher_id')
            assignment.subject_id = request.POST.get('subject_id')
            assignment.class_id = request.POST.get('class_id')
            assignment.academic_year = request.POST.get('academic_year')
            assignment.semester = request.POST.get('semester')

            assignment.save()

            return redirect('/admin-web/subject-assignments/')

        except Exception as e:
            error_message = str(e)

    return render(request, 'admin/edit_subject_assignment.html', {
        'assignment': assignment,
        'teachers': teachers,
        'subjects': subjects,
        'classes': classes,
        'error_message': error_message,
    })
    
def delete_subject_assignment(request, assignment_id):
    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    if request.method == 'POST':
        try:
            assignment = SubjectAssignment.objects.get(
                assignment_id=assignment_id
            )
            assignment.delete()
        except SubjectAssignment.DoesNotExist:
            pass

    return redirect('/admin-web/subject-assignments/')

def manage_timetables(request):
    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    timetables = Timetable.objects.all()

    return render(request, 'admin/timetables.html', {
        'timetables': timetables,
    })
    
def add_timetable(request):
    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    error_message = None

    teachers = Teacher.objects.all()
    subjects = Subject.objects.all()
    classes = Class.objects.all()

    if request.method == 'POST':
        try:
            Timetable.objects.create(
                class_id=request.POST.get('class_id'),
                subject_id=request.POST.get('subject_id'),
                teacher_id=request.POST.get('teacher_id'),
                day=request.POST.get('day'),
                start_time=request.POST.get('start_time'),
                end_time=request.POST.get('end_time'),
            )

            return redirect('/admin-web/timetables/')

        except Exception as e:
            error_message = str(e)

    return render(request, 'admin/add_timetable.html', {
        'teachers': teachers,
        'subjects': subjects,
        'classes': classes,
        'error_message': error_message,
    })
    
def edit_timetable(request, timetable_id):
    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    try:
        timetable = Timetable.objects.get(
            timetable_id=timetable_id
        )
    except Timetable.DoesNotExist:
        return redirect('/admin-web/timetables/')

    error_message = None

    teachers = Teacher.objects.all()
    subjects = Subject.objects.all()
    classes = Class.objects.all()

    if request.method == 'POST':
        try:
            timetable.class_id = request.POST.get('class_id')
            timetable.subject_id = request.POST.get('subject_id')
            timetable.teacher_id = request.POST.get('teacher_id')
            timetable.day = request.POST.get('day')
            timetable.start_time = request.POST.get('start_time')
            timetable.end_time = request.POST.get('end_time')

            timetable.save()

            return redirect('/admin-web/timetables/')

        except Exception as e:
            error_message = str(e)

    return render(request, 'admin/edit_timetable.html', {
        'timetable': timetable,
        'teachers': teachers,
        'subjects': subjects,
        'classes': classes,
        'error_message': error_message,
    })
    
def delete_timetable(request, timetable_id):
    if 'admin_user_id' not in request.session:
        return redirect('/admin-web/login/')

    if request.method == 'POST':
        try:
            timetable = Timetable.objects.get(
                timetable_id=timetable_id
            )
            timetable.delete()
        except Timetable.DoesNotExist:
            pass

    return redirect('/admin-web/timetables/')