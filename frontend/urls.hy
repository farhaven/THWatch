(import [django.urls [path include]]
        [django.contrib.auth.views [LoginView PasswordResetCompleteView]]
        [. [views]])

(setv urlpatterns [(path "" (views.Home.as_view) :name "frontend.home")
                   (path "settings" (views.Settings.as_view) :name "frontend.settings")
                   (path "test-email" (views.TestEmail.as_view) :name "frontend.test-email")
                   (path "users/password_change" (views.PasswordChange.as_view) :name "frontend.password-change")
                   (path "users/password_change/done/" (views.PasswordChangeDone.as_view) :name "password_change_done")
                   (path "users/password_reset/" (views.PasswordReset.as_view) :name "password_reset")
                   (path "users/password_reset_done" (views.PasswordResetDone.as_view) :name "password_reset_done")
                   (path "users/reset/<uidb64>/<token>/" (views.PasswordResetConfirm.as_view) :name "password_reset_confirm")
                   (path "users/reset/done/" (views.PasswordResetComplete.as_view) :name "password_reset_complete")
                   (path "users/login" (views.Login.as_view) :name "frontend.login")
                   (path "users/logout" (views.Logout.as_view) :name "frontend.logout")])
