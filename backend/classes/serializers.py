from rest_framework import serializers
from .models import Class


class ClassSerializer(serializers.ModelSerializer):

    class Meta:
        model = Class
        fields = [
            'class_id',
            'class_name',
            'semester',
            'section',
            'department_id',
        ]
        read_only_fields = ['class_id']