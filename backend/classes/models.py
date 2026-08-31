from django.db import models


class Class(models.Model):

    class_id = models.AutoField(primary_key=True)
    class_name = models.CharField(max_length=100)
    semester = models.IntegerField()
    section = models.CharField(max_length=10)
    department_id = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'classes'

    def __str__(self):
        return self.class_name