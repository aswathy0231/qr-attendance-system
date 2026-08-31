from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Department
from .serializers import DepartmentSerializer


class DepartmentListCreateView(APIView):

    def get(self, request):
        departments = Department.objects.all()
        serializer = DepartmentSerializer(departments, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = DepartmentSerializer(data=request.data)

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


class DepartmentDetailView(APIView):

    def get_object(self, department_id):
        try:
            return Department.objects.get(department_id=department_id)
        except Department.DoesNotExist:
            return None

    def get(self, request, department_id):
        department = self.get_object(department_id)

        if department is None:
            return Response(
                {'error': 'Department not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = DepartmentSerializer(department)
        return Response(serializer.data)

    def put(self, request, department_id):
        department = self.get_object(department_id)

        if department is None:
            return Response(
                {'error': 'Department not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = DepartmentSerializer(
            department,
            data=request.data
        )

        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )

    def delete(self, request, department_id):
        department = self.get_object(department_id)

        if department is None:
            return Response(
                {'error': 'Department not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        department.delete()

        return Response(
            {'message': 'Department deleted successfully'},
            status=status.HTTP_204_NO_CONTENT
        )