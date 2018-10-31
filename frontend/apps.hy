(import django.apps [AppConfig])

(defclass FrontendConfig [AppConfig]
  (setv name "frontend"))
