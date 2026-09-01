from django.db import models
from django.contrib.auth.models import AbstractBaseUser
from django.contrib.auth.base_user import BaseUserManager
from django.utils import timezone


class UserManager(BaseUserManager):

    def create_user(self, username, password=None, **extra_fields):
        if not username:
            raise ValueError('Username is required')

        user = self.model(
            username=username,
            created_at=timezone.now(),
            **extra_fields
        )

        if password:
            user.set_password(password)

        user.save(using=self._db)

        return user

    def create_superuser(self, username, password=None, **extra_fields):
        user = self.create_user(
            username=username,
            password=password,
            **extra_fields
        )

        return user


class User(AbstractBaseUser):

    # AbstractBaseUser normally provides last_login.
    # Your database does not have this column.
    last_login = None

    user_id = models.AutoField(
        primary_key=True
    )

    username = models.CharField(
        max_length=50,
        unique=True
    )

    password = models.CharField(
        max_length=255
    )

    role = models.CharField(
        max_length=7
    )

    first_login = models.IntegerField(
        null=True,
        blank=True
    )

    status = models.CharField(
        max_length=8,
        null=True,
        blank=True
    )

    created_at = models.DateTimeField()

    objects = UserManager()

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = []

    class Meta:
        managed = False
        db_table = 'users'

    def __str__(self):
        return self.username