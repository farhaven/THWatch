(import [django.urls [path]]
        [. [views]])

(setv urlpatterns [(path "" (views.Index.as_view) :name "frontend.index")])
