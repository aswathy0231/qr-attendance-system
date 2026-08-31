from django.db import models


class Subject(models.Model):

    subject_id = models.AutoField(primary_key=True)
    subject_code = models.CharField(max_length=11, unique=True)
    subject_name = models.CharField(max_length=12)
    credits = models.IntegerField(null=True, blank=True)

    class Meta:
        managed = False
        db_table = 'subjects'

    def __str__(self):
        return self.subject_name