from rest_framework import serializers
from .models import Teacher


class TeacherSerializer(serializers.ModelSerializer):

    class Meta:
        model = Teacher
        fields = [
            'teacher_id',
            'user_id',
            'employee_id',
            'full_name',
            'email',
            'phone',
            'department_id',
        ]
        read_only_fields = ['teacher_id']