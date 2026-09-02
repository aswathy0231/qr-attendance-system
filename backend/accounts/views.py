from django.contrib.auth.hashers import check_password

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from rest_framework_simplejwt.tokens import RefreshToken

from .models import User
from .serializers import LoginSerializer
from .permissions import IsStudent

from students.models import Student
from teachers.models import Teacher


class LoginView(APIView):

    def post(self, request):

        # Validate request data
        serializer = LoginSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(
                serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )

        username = serializer.validated_data['username']
        password = serializer.validated_data['password']

        # Find user
        try:
            user = User.objects.get(username=username)

        except User.DoesNotExist:
            return Response(
                {'error': 'Invalid username or password'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Check account status
        if user.status and user.status.lower() != 'active':
            return Response(
                {'error': 'User account is inactive'},
                status=status.HTTP_403_FORBIDDEN
            )

        # Check password
        if not check_password(password, user.password):
            return Response(
                {'error': 'Invalid username or password'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # Get the student's or teacher's ID
        student_id = None
        teacher_id = None

        if user.role.lower() == 'student':
            try:
                student = Student.objects.get(user_id=user.user_id)
                student_id = student.student_id

            except Student.DoesNotExist:
                return Response(
                    {'error': 'Student record not found'},
                    status=status.HTTP_404_NOT_FOUND
                )

        elif user.role.lower() == 'teacher':
            try:
                teacher = Teacher.objects.get(user_id=user.user_id)
                teacher_id = teacher.teacher_id

            except Teacher.DoesNotExist:
                return Response(
                    {'error': 'Teacher record not found'},
                    status=status.HTTP_404_NOT_FOUND
                )

        # Create JWT
        refresh = RefreshToken()

        refresh['user_id'] = user.user_id
        refresh['username'] = user.username
        refresh['role'] = user.role

        access_token = refresh.access_token

        return Response({
            'message': 'Login successful',
            'user_id': user.user_id,
            'student_id': student_id,
            'teacher_id': teacher_id,
            'username': user.username,
            'role': user.role,
            'access': str(access_token),
            'refresh': str(refresh),
        })


class ProfileView(APIView):

    # Only students can access this API
    permission_classes = [IsStudent]

    def get(self, request):

        user = request.user

        # Get the student's student_id
        student_id = None

        if user.role.lower() == 'student':
            try:
                student = Student.objects.get(user_id=user.user_id)
                student_id = student.student_id

            except Student.DoesNotExist:
                return Response(
                    {'error': 'Student record not found'},
                    status=status.HTTP_404_NOT_FOUND
                )

        return Response({
            'message': 'Authentication successful',
            'user_id': user.user_id,
            'student_id': student_id,
            'username': user.username,
            'role': user.role
        })