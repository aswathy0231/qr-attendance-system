from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Teacher
from .serializers import TeacherSerializer

from admins.models import SubjectAssignment
from subjects.models import Subject
from classes.models import Class


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


class TeacherAssignmentsView(APIView):

    def get(self, request, teacher_id):

        # Check that the teacher exists
        try:
            Teacher.objects.get(teacher_id=teacher_id)
        except Teacher.DoesNotExist:
            return Response(
                {'error': 'Teacher not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get all assignments for this teacher
        assignments = SubjectAssignment.objects.filter(
            teacher_id=teacher_id
        )

        result = []

        for assignment in assignments:

            try:
                subject = Subject.objects.get(
                    subject_id=assignment.subject_id
                )

                class_obj = Class.objects.get(
                    class_id=assignment.class_id
                )

                result.append({
                    'assignment_id': assignment.assignment_id,
                    'subject_id': assignment.subject_id,
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

        return Response(
            result,
            status=status.HTTP_200_OK
        )