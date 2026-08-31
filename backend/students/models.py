from django.db import models


class Student(models.Model):

    student_id = models.AutoField(primary_key=True)
    user_id = models.IntegerField(unique=True)
    register_no = models.CharField(max_length=11, unique=True)
    full_name = models.CharField(max_length=12)
    email = models.CharField(max_length=12, null=True, blank=True)
    phone = models.CharField(max_length=11, null=True, blank=True)
    class_id = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'students'

    def __str__(self):
        return self.full_name