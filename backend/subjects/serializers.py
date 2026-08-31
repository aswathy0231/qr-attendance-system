from rest_framework import serializers
from .models import Subject


class SubjectSerializer(serializers.ModelSerializer):

    class Meta:
        model = Subject
        fields = [
            'subject_id',
            'subject_code',
            'subject_name',
            'credits',
        ]
        read_only_fields = ['subject_id']