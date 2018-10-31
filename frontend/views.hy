(import [django.http [HttpResponse HttpResponseRedirect]]
        [django.contrib.auth [logout]]
        [django.contrib.auth.views [LoginView]]
        [django.contrib.auth.mixins [LoginRequiredMixin]]
        [django.urls [reverse reverse-lazy]]
        [django.views.generic [TemplateView View]])


(defclass Index [LoginRequiredMixin TemplateView]
  (setv login-url (reverse-lazy "frontend.login"))
  (setv template-name "index.html.j2"))


(defclass Login [LoginView]
  (setv template-name "login.html.j2"))

(defclass Logout [View]
  (defn get [self request]
    (logout request)
    (HttpResponseRedirect (reverse "frontend.login"))))
