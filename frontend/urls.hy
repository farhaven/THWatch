(import [django.urls [path]]
        [django.contrib.auth.views [LoginView]]
        [. [views]])

(setv urlpatterns [(path "" (views.Index.as_view) :name "frontend.index")
                   (path "test" (views.Test.as_view) :name "frontend.test")
                   (path "login" (views.Login.as_view) :name "frontend.login")
                   (path "logout" (views.Logout.as_view) :name "frontend.logout")
                   ])
