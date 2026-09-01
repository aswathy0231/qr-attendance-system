from django.db import models


class AttendanceSession(models.Model):

    session_id = models.AutoField(primary_key=True)
    assignment_id = models.IntegerField()

    qr_token = models.CharField(
        max_length=255,
        unique=True
    )

    start_time = models.DateTimeField()
    end_time = models.DateTimeField()

    status = models.CharField(
        max_length=10,
        default='Running'
    )

    class Meta:
        managed = False
        db_table = 'attendance_sessions'

    def __str__(self):
        return f"Session {self.session_id}"


class Attendance(models.Model):

    attendance_id = models.AutoField(primary_key=True)

    session_id = models.IntegerField()
    student_id = models.IntegerField()

    attendance_time = models.DateTimeField(
        null=True,
        blank=True
    )

    face_verified = models.BooleanField(
        default=False,
        null=True,
        blank=True
    )

    ble_verified = models.BooleanField(
        default=False,
        null=True,
        blank=True
    )

    status = models.CharField(
        max_length=10,
        default='Present',
        null=True,
        blank=True
    )

    class Meta:
        managed = False
        db_table = 'attendance'

    def __str__(self):
        return f"Attendance {self.attendance_id}"