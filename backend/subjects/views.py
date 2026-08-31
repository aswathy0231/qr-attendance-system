from django.db import IntegrityError
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Subject
from .serializers import SubjectSerializer


class SubjectListCreateView(APIView):

    def get(self, request):
        subjects = Subject.objects.all()
        serializer = SubjectSerializer(subjects, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = SubjectSerializer(data=request.data)

        if serializer.is_valid():
            try:
                serializer.save()
                return Response(
                    serializer.data,
                    status=status.HTTP_201_CREATED
                )
            except IntegrityError:
                return Response(
                    {'error': 'Subject code already exists'},
                    status=status.HTTP_400_BAD_REQUEST
                )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )


class SubjectDetailView(APIView):

    def get_object(self, subject_id):
        try:
            return Subject.objects.get(subject_id=subject_id)
        except Subject.DoesNotExist:
            return None

    def get(self, request, subject_id):
        subject = self.get_object(subject_id)

        if subject is None:
            return Response(
                {'error': 'Subject not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = SubjectSerializer(subject)
        return Response(serializer.data)

    def put(self, request, subject_id):
        subject = self.get_object(subject_id)

        if subject is None:
            return Response(
                {'error': 'Subject not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = SubjectSerializer(
            subject,
            data=request.data
        )

        if serializer.is_valid():
            try:
                serializer.save()
                return Response(serializer.data)
            except IntegrityError:
                return Response(
                    {'error': 'Subject code already exists'},
                    status=status.HTTP_400_BAD_REQUEST
                )

        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )

    def delete(self, request, subject_id):
        subject = self.get_object(subject_id)

        if subject is None:
            return Response(
                {'error': 'Subject not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        subject.delete()

        return Response(
            {'message': 'Subject deleted successfully'},
            status=status.HTTP_204_NO_CONTENT
        )