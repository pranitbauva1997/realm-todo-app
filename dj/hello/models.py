from django.db import models


class Counter(models.Model):
    count = models.IntegerField(default=0)


class ToDo(models.Model):
    title = models.CharField(max_length=50)
    done = models.IntegerField(default=0)
