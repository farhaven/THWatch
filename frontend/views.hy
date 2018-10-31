(import [django.http [HttpResponse HttpResponseRedirect]]
        [django.contrib.auth [logout]]
        [django.contrib.auth.views [LoginView]]
        [django.contrib.auth.mixins [LoginRequiredMixin]]
        [django.urls [reverse reverse-lazy]]
        [django.views.generic [TemplateView View]])

(import [frontend.models :as models])


(defclass Index [LoginRequiredMixin TemplateView]
  (setv login-url (reverse-lazy "frontend.login"))
  (setv template-name "index.html.j2")

  (defn get-context-data [self]
    (print "Returning context data")
    (setv context (.get-context-data (super)))
    (assoc context "patterns"
           (models.Pattern.objects.filter :owner self.request.user))
    context))


(defclass Login [LoginView]
  (setv template-name "login.html.j2"))

(defclass Logout [View]
  (defn get [self request]
    (logout request)
    (HttpResponseRedirect (reverse "frontend.login"))))
