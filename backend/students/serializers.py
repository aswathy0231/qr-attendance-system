from rest_framework import serializers

from .models import Student
from classes.models import Class
from departments.models import Department


class StudentSerializer(serializers.ModelSerializer):

    class_name = serializers.SerializerMethodField()
    semester = serializers.SerializerMethodField()
    section = serializers.SerializerMethodField()
    department_name = serializers.SerializerMethodField()

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

            # Academic information
            'class_name',
            'semester',
            'section',
            'department_name',
        ]

        read_only_fields = [
            'student_id',
            'class_name',
            'semester',
            'section',
            'department_name',
        ]

    def _get_class(self, obj):
        try:
            return Class.objects.get(
                class_id=obj.class_id
            )
        except Class.DoesNotExist:
            return None

    def get_class_name(self, obj):
        student_class = self._get_class(obj)

        if student_class is None:
            return ''

        return student_class.class_name

    def get_semester(self, obj):
        student_class = self._get_class(obj)

        if student_class is None:
            return 0

        return student_class.semester

    def get_section(self, obj):
        student_class = self._get_class(obj)

        if student_class is None:
            return ''

        return student_class.section

    def get_department_name(self, obj):
        student_class = self._get_class(obj)

        if student_class is None:
            return ''

        try:
            department = Department.objects.get(
                department_id=student_class.department_id
            )
        except Department.DoesNotExist:
            return ''

        return department.department_name