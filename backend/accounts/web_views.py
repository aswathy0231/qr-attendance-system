from django.contrib.auth.hashers import check_password
from django.shortcuts import render, redirect

from .models import User


def teacher_login(request):

    error_message = None

    if request.method == 'POST':

        username = request.POST.get('username')
        password = request.POST.get('password')

        try:
            user = User.objects.get(username=username)

            if user.status and user.status.lower() != 'active':
                error_message = 'User account is inactive.'

            elif user.role != 'teacher':
                error_message = 'This account is not a teacher account.'

            elif not check_password(password, user.password):
                error_message = 'Invalid username or password.'

            else:
                request.session['teacher_user_id'] = user.user_id
                request.session['teacher_username'] = user.username

                return redirect('/teacher/dashboard/')

        except User.DoesNotExist:
            error_message = 'Invalid username or password.'

    return render(
        request,
        'login/teacher_login.html',
        {
            'error_message': error_message,
        }
    )