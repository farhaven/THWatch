(import [django.http [HttpResponse HttpResponseRedirect]]
        [django.contrib.auth [logout]]
        [django.contrib.auth.views [LoginView PasswordChangeView PasswordResetView PasswordResetConfirmView]]
        [django.contrib.auth.mixins [LoginRequiredMixin]]
        [django.template.response [TemplateResponse]]
        [django.urls [reverse reverse-lazy]]
        [django.views.generic [TemplateView View]])

(import [frontend.models :as models]
        frontend.tasks
        backend.tasks)


(defclass Settings [LoginRequiredMixin TemplateView]
  [template-name "settings.html.j2"]

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
    (HttpResponseRedirect (reverse-lazy "frontend.home"))))


(defclass PasswordChange [LoginRequiredMixin PasswordChangeView]
  [template-name "password-change.html.j2"])

(defclass PasswordChangeDone [LoginRequiredMixin TemplateView]
  [template-name "password-change-done.html.j2"])

(defclass PasswordReset [PasswordResetView]
  [template-name "password-reset.html.j2"])

(defclass PasswordResetDone [TemplateView]
  [template-name "password-reset-done.html.j2"])

(defclass PasswordResetConfirm [PasswordResetConfirmView]
  [template-name "password-reset-confirm.html.j2"])

(defclass PasswordResetComplete [TemplateView]
  [template-name "password-reset-complete.html.j2"])

(defclass Login [LoginView]
  (setv template-name "login.html.j2"))

(defclass Logout [View]
  (defn get [self request]
    (logout request)
    (HttpResponseRedirect (reverse "frontend.login"))))
