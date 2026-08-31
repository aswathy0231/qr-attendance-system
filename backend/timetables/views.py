from rest_framework import generics
from .models import Timetable
from .serializers import TimetableSerializer


class TimetableListCreateView(generics.ListCreateAPIView):
    queryset = Timetable.objects.all()
    serializer_class = TimetableSerializer


class TimetableDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Timetable.objects.all()
    serializer_class = TimetableSerializer