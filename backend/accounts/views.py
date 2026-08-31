from django.contrib.auth.hashers import check_password

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from rest_framework_simplejwt.tokens import RefreshToken

from .models import User
from .serializers import LoginSerializer
from .permissions import IsStudent


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

        # Create JWT
        refresh = RefreshToken()

        refresh['user_id'] = user.user_id
        refresh['username'] = user.username
        refresh['role'] = user.role

        access_token = refresh.access_token

        return Response({
            'message': 'Login successful',
            'user_id': user.user_id,
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

        return Response({
            'message': 'Authentication successful',
            'user_id': user.user_id,
            'username': user.username,
            'role': user.role
        })