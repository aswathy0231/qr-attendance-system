from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Teacher
from .serializers import TeacherSerializer


class TeacherListCreateView(APIView):

    def get(self, request):
        teachers = Teacher.objects.all()
        serializer = TeacherSerializer(teachers, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = TeacherSerializer(data=request.data)

        if serializer.is_valid():
            serializer.save()
            return Response(
                serializer.data,
                status=status.HTTP_201_CREATED
            )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )


class TeacherDetailView(APIView):

    def get_object(self, teacher_id):
        try:
            return Teacher.objects.get(teacher_id=teacher_id)
        except Teacher.DoesNotExist:
            return None

    def get(self, request, teacher_id):
        teacher = self.get_object(teacher_id)

        if teacher is None:
            return Response(
                {'error': 'Teacher not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = TeacherSerializer(teacher)
        return Response(serializer.data)

    def put(self, request, teacher_id):
        teacher = self.get_object(teacher_id)

        if teacher is None:
            return Response(
                {'error': 'Teacher not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = TeacherSerializer(
            teacher,
            data=request.data
        )

        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )

    def delete(self, request, teacher_id):
        teacher = self.get_object(teacher_id)

        if teacher is None:
            return Response(
                {'error': 'Teacher not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        teacher.delete()

        return Response(
            {'message': 'Teacher deleted successfully'},
            status=status.HTTP_204_NO_CONTENT
        )