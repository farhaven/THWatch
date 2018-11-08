(import [django.urls [path include]]
        [django.contrib.auth.views [LoginView]]
        [. [views]])

(setv urlpatterns [(path "" (views.Home.as_view) :name "frontend.home")
                   (path "settings" (views.Settings.as_view) :name "frontend.settings")
                   (path "users/" (include "django.contrib.auth.urls"))
                   (path "users/login" (views.Login.as_view) :name "frontend.login")
                   (path "users/logout" (views.Logout.as_view) :name "frontend.logout")])
