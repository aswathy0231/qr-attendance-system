from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Class
from .serializers import ClassSerializer


class ClassListCreateView(APIView):

    def get(self, request):
        classes = Class.objects.all()
        serializer = ClassSerializer(classes, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = ClassSerializer(data=request.data)

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


class ClassDetailView(APIView):

    def get_object(self, class_id):
        try:
            return Class.objects.get(class_id=class_id)
        except Class.DoesNotExist:
            return None

    def get(self, request, class_id):
        class_obj = self.get_object(class_id)

        if class_obj is None:
            return Response(
                {'error': 'Class not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = ClassSerializer(class_obj)
        return Response(serializer.data)

    def put(self, request, class_id):
        class_obj = self.get_object(class_id)

        if class_obj is None:
            return Response(
                {'error': 'Class not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = ClassSerializer(
            class_obj,
            data=request.data
        )

        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )

    def delete(self, request, class_id):
        class_obj = self.get_object(class_id)

        if class_obj is None:
            return Response(
                {'error': 'Class not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        class_obj.delete()

        return Response(
            {'message': 'Class deleted successfully'},
            status=status.HTTP_204_NO_CONTENT
        )