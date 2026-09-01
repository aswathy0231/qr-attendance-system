from django.shortcuts import render, redirect


def teacher_dashboard(request):

    # Check whether a teacher is logged in
    if 'teacher_user_id' not in request.session:
        return redirect('/api/teacher-login/')

    return render(
        request,
        'teacher/dashboard.html'
    )