(import [django.http [HttpResponse]]
        [django.views.generic [TemplateView]])


(defclass Index [TemplateView]
  (setv template_name "index.html.j2"))
