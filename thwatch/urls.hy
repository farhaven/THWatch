(import [django.contrib [admin]]
        [django.urls [path include]]
        [django.views.generic [RedirectView]]
        [django.conf.urls.static [static]]
        [django.conf [settings]])

(setv urlpatterns [(path "admin/" admin.site.urls)
                   (path "frontend/" (include "frontend.urls"))
                   (path "" (RedirectView.as-view :pattern-name "frontend.home"
                                                  :permanent False))])
