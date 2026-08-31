from rest_framework import serializers
from .models import Student


class StudentSerializer(serializers.ModelSerializer):

    class Meta:
        model = Student
        fields = [
            'student_id',
            'user_id',
            'register_no',
            'full_name',
            'email',
            'phone',
            'class_id',
        ]
        read_only_fields = ['student_id']