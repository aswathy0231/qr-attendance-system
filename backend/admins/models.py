from django.db import models


class SubjectAssignment(models.Model):

    assignment_id = models.AutoField(primary_key=True)
    teacher_id = models.IntegerField()
    subject_id = models.IntegerField()
    class_id = models.IntegerField()
    academic_year = models.CharField(max_length=20)
    semester = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'subject_assignments'

    def __str__(self):
        return f"Assignment {self.assignment_id}"