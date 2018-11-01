(import os)

(import [celery [Celery]]
        [django.conf [settings]])

(os.environ.setdefault "DJANGO_SETTINGS_MODULE" "thwatch.settings")

(setv app (Celery "thwatch"))

(app.config-from-object "django.conf:settings")
(app.autodiscover-tasks (fn [] settings.INSTALLED-APPS))

(with-decorator (app.task :bind True)
  (defn debug-task [self]
    (print (.format "Request: {0!r}" self.request))))
