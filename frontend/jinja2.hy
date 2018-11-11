(import [django.contrib.staticfiles.storage [staticfiles_storage]]
        [django.utils [translation]]
        [django.urls [reverse]]
        [jinja2 [Environment]])

(defn environment [&kwargs options]
  (assoc options 'extensions ["jinja2.ext.i18n" "jinja2.ext.with_"])
  (setv env (Environment #** options))
  (env.globals.update
    {"static" staticfiles_storage.url
     "str" str
     "url" reverse})
  (env.install-gettext-translations translation)
  env)
