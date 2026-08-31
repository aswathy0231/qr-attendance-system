from rest_framework.permissions import BasePermission


class IsRole(BasePermission):

    required_role = None

    def has_permission(self, request, view):
        if not request.auth:
            return False

        return request.auth.get('role') == self.required_role


class IsAdmin(IsRole):
    required_role = 'admin'


class IsTeacher(IsRole):
    required_role = 'teacher'


class IsStudent(IsRole):
    required_role = 'student'