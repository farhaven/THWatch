(import [django.http [HttpResponse HttpResponseRedirect]]
        [django.contrib.auth [logout]]
        [django.contrib.auth.views [LoginView]]
        [django.contrib.auth.mixins [LoginRequiredMixin]]
        [django.urls [reverse reverse-lazy]]
        [django.views.generic [TemplateView View]])

(import [frontend.models :as models]
        frontend.tasks
        backend.tasks)


(defclass Index [LoginRequiredMixin TemplateView]
  (setv login-url (reverse-lazy "frontend.login"))
  (setv template-name "index.html.j2")

  (defn get-context-data [self]
    (setv context (.get-context-data (super)))
    (assoc context "patterns"
           (models.Pattern.objects.filter :owner self.request.user))
    (try
      (assoc context "settings"
             (models.UserSettings.objects.get :owner self.request.user))
      (except [models.UserSettings.DoesNotExist]
        (assoc context "settings" {"pushover_user" ""})))

    context)

  (defn post [self request]
    (print request.POST)
    (setv (, settings created) (models.UserSettings.objects.get-or-create :owner request.user))
    (setv settings.pushover-user (get request.POST "pushover-user"))
    (settings.save)
    (HttpResponseRedirect (reverse-lazy "frontend.index"))
    ))


(defclass Test [LoginRequiredMixin View]
  (setv login-url (reverse-lazy "frontend.login"))
  (defn get [self request]
    (print "Test GET")
    (frontend.tasks.test-task.delay "a" "b" "c")
    (backend.tasks.test-task.delay "test")
    (HttpResponseRedirect (reverse "frontend.index"))))


(defclass Login [LoginView]
  (setv template-name "login.html.j2"))

(defclass Logout [View]
  (defn get [self request]
    (logout request)
    (HttpResponseRedirect (reverse "frontend.login"))))
