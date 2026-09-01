import base64
from io import BytesIO

import qrcode
from rest_framework import serializers

from .models import AttendanceSession


class AttendanceSessionSerializer(serializers.ModelSerializer):

    qr_image = serializers.SerializerMethodField()

    class Meta:
        model = AttendanceSession
        fields = [
            'session_id',
            'assignment_id',
            'qr_token',
            'qr_image',
            'start_time',
            'end_time',
            'status',
        ]

        read_only_fields = [
            'session_id',
            'qr_token',
            'qr_image',
            'start_time',
            'status',
        ]

    def get_qr_image(self, obj):

        qr = qrcode.make(obj.qr_token)

        buffer = BytesIO()
        qr.save(buffer, format='PNG')

        encoded_image = base64.b64encode(
            buffer.getvalue()
        ).decode('utf-8')

        return f'data:image/png;base64,{encoded_image}'