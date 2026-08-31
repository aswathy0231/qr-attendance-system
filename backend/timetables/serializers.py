from rest_framework import serializers
from .models import Timetable


class TimetableSerializer(serializers.ModelSerializer):

    class Meta:
        model = Timetable
        fields = [
            'timetable_id',
            'class_id',
            'subject_id',
            'teacher_id',
            'day',
            'start_time',
            'end_time',
        ]
        read_only_fields = ['timetable_id']