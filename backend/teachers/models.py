from django.db import models


class Teacher(models.Model):

    teacher_id = models.AutoField(primary_key=True)
    user_id = models.IntegerField(unique=True)
    employee_id = models.CharField(max_length=11, unique=True)
    full_name = models.CharField(max_length=12)
    email = models.CharField(max_length=12, null=True, blank=True)
    phone = models.CharField(max_length=11, null=True, blank=True)
    department_id = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'teachers'

    def __str__(self):
        return self.full_name