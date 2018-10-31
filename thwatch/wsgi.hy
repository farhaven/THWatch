(import os
        [django.core.wsgi [get-wsgi-application]])

(os.environ.setdefault
  "DJANGO_SETTINGS_MODULE"
  "thwatch.settings")

(setv application (get-wsgi-application))
