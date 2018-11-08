(import [django.urls [path include]]
        [django.contrib.auth.views [LoginView]]
        [. [views]])

(setv urlpatterns [(path "" (views.Home.as_view) :name "frontend.home")
                   (path "settings" (views.Settings.as_view) :name "frontend.settings")
                   (path "users/password_change" (views.PasswordChange.as_view) :name "frontend.password-change")
                   (path "users/password_change/done/" (views.PasswordChangeDone.as_view) :name "password_change_done")
                   (path "users/password_reset/" (views.PasswordReset.as_view) :name "password_reset")
                   (path "users/password_reset_done" (views.PasswordResetDone.as_view) :name "password_reset_done")
                   ; (path "users/" (include "django.contrib.auth.urls"))
                   (path "users/login" (views.Login.as_view) :name "frontend.login")
                   (path "users/logout" (views.Logout.as_view) :name "frontend.logout")])
