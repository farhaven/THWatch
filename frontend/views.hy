(import [django.http [HttpResponse HttpResponseRedirect]]
        [django.contrib.auth [logout]]
        [django.contrib.auth.views [LoginView]]
        [django.contrib.auth.mixins [LoginRequiredMixin]]
        [django.template.response [TemplateResponse]]
        [django.urls [reverse reverse-lazy]]
        [django.views.generic [TemplateView View]])

(import [frontend.models :as models]
        frontend.tasks
        backend.tasks)


(defclass Notifications [LoginRequiredMixin TemplateView]
  [template-name "notifications.html.j2"]

  (defn get-context-data [self]
    (setv context (.get-context-data (super)))
    (try
      (assoc context "settings"
             (models.UserSettings.objects.get :owner self.request.user))
      (except [models.UserSettings.DoesNotExist]
        (assoc context "settings" {"pushover_user" ""})))
    context)

  (defn post [self request]
    (setv context (self.get-context-data))
    (setv (, settings created) (models.UserSettings.objects.get-or-create :owner request.user)
          settings.pushover-user (get request.POST "pushover-user"))
    (settings.save)
    (assoc context "saved_settings" True)
    (TemplateResponse request self.template-name context)))


(defclass Home [LoginRequiredMixin TemplateView]
  (setv login-url (reverse-lazy "frontend.login"))
  (setv template-name "home.html.j2")

  (defn get-context-data [self]
    (setv context (.get-context-data (super)))
    (assoc context "patterns"
           (models.Pattern.objects.filter :owner self.request.user))
    context)

  (defn post [self request]
    (cond
      [(= (get request.POST "action") "add-pattern")
       (do
         (setv (, p created) (models.Pattern.objects.get-or-create :owner request.user
                                                                   :name (get request.POST "name")
                                                                   :pattern (get request.POST "pattern")))
         (p.save))]
      [(= (get request.POST "action") "delete-pattern")
       (.delete (models.Pattern.objects.get :pk (get request.POST "pk")))])
    (HttpResponseRedirect (reverse-lazy "frontend.home"))
    ))


(defclass Test [LoginRequiredMixin View]
  (setv login-url (reverse-lazy "frontend.login"))
  (defn get [self request]
    (print "Test GET")
    (frontend.tasks.test-task.delay "a" "b" "c")
    (backend.tasks.test-task.delay "test")
    (HttpResponseRedirect (reverse "frontend.home"))))


(defclass Login [LoginView]
  (setv template-name "login.html.j2"))

(defclass Logout [View]
  (defn get [self request]
    (logout request)
    (HttpResponseRedirect (reverse "frontend.login"))))
