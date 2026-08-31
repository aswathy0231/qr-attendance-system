from django.db import models


class Timetable(models.Model):

    timetable_id = models.AutoField(primary_key=True)
    class_id = models.IntegerField()
    subject_id = models.IntegerField()
    teacher_id = models.IntegerField()
    day = models.CharField(max_length=10)
    start_time = models.TimeField()
    end_time = models.TimeField()

    class Meta:
        managed = False
        db_table = 'timetables'

    def __str__(self):
        return f"{self.day} - {self.start_time}"