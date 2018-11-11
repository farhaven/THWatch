(import [django.http [HttpResponse HttpResponseRedirect]]
        [django.conf [settings]]
        [django.contrib.auth [logout]]
        [django.contrib.auth.views [LoginView PasswordChangeView PasswordResetView PasswordResetConfirmView]]
        [django.contrib.auth.mixins [LoginRequiredMixin]]
        [django.contrib.auth.models [User]]
        [django.core.mail [send-mail mail-admins]]
        [django.template.response [TemplateResponse]]
        [django.urls [reverse reverse-lazy]]
        [django.views.generic [TemplateView FormView View]])

(import [frontend.models :as models]
        [frontend.forms [RequestAccountForm]]
        frontend.tasks
        backend.tasks)


(defclass Settings [LoginRequiredMixin TemplateView]
  [template-name "settings.html.j2"]

  (defn get-context-data [self]
    (setv context (.get-context-data (super)))
    (assoc context "active_page"
           (.get self.request.GET "page" "notifications"))
    (try
      (assoc context "settings"
             (models.UserSettings.objects.get :owner self.request.user))
      (except [models.UserSettings.DoesNotExist]
        (assoc context "settings" {"pushover_user" ""})))
    context)

  (defn post [self request]
    (setv context (self.get-context-data))
    (setv settings (try
                     (models.UserSettings.objects.get :owner request.user)
                     (except [models.UserSettings.DoesNotExist]
                       (models.UserSettings :owner request.user
                                            :pushover-user ""
                                            :notify-via-mail False)))
          settings.pushover-user (get request.POST "pushover-user")
          settings.notify-via-mail (= (.get request.POST "notify-mail" "off") "on"))
    (settings.save)
    (assoc context "saved_settings" True)
    (assoc context "settings" settings)
    (TemplateResponse request self.template-name context)))


(defclass Home [LoginRequiredMixin TemplateView]
  (setv login-url (reverse-lazy "frontend.login"))
  (setv template-name "home.html.j2")

  (defn get-context-data [self]
    (setv context (.get-context-data (super)))
    (assoc context "active_page"
           (.get self.request.GET "page" "patterns"))
    (assoc context "patterns"
           (models.Pattern.objects.filter :owner self.request.user))
    context)

  (defn post [self request]
    (setv context (self.get-context-data))
    (cond
      [(= (get request.POST "action") "add-pattern")
       (do
         (setv (, p created) (models.Pattern.objects.get-or-create :owner request.user
                                                                   :name (get request.POST "name")
                                                                   :pattern (get request.POST "pattern")))
         (p.save)
         (assoc context "active_page" "patterns"))]
      [(= (get request.POST "action") "delete-pattern")
       (.delete (models.Pattern.objects.get :pk (get request.POST "pk")))])
    (setv resp (HttpResponseRedirect (reverse-lazy "frontend.home")))
    (assoc resp "Location" (+ (get resp "Location") "?page=" (get context "active_page")))
    resp))


(defclass RequestAccount [FormView]
  [template-name "request-account.html.j2"
   template-success "request-account-done.html.j2"
   form-class RequestAccountForm]

  (defn form-valid [self form]
    (setv user (User.objects.create-user (get form.cleaned-data 'name)
                                         (get form.cleaned-data 'email)
                                         (get form.cleaned-data 'password1)))
    (setv user.is-active False)
    (user.save)
    (mail-admins :subject "New THWatch user"
                 :message (.format "{name} ({email}) created a new account on THWatch."
                                   :name (get form.cleaned-data 'name)
                                   :email (get form.cleaned-data 'email)))
    (TemplateResponse self.request self.template-success {"form" form})))


(defclass TestEmail [LoginRequiredMixin View]
  (defn get [self request]
    (print "Sending test email to" request.user "now")
    (send-mail :subject "Test"
               :message "This is a test"
               :from-email settings.DEFAULT-FROM-EMAIL
               :recipient-list [request.user.email])
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
