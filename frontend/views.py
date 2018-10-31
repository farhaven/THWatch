from django.http import HttpResponse
from django.views.generic import View


class Index(View):
    def get(self, request):
        return HttpResponse("Foo")
