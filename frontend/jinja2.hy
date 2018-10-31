(import [django.contrib.staticfiles.storage [staticfiles_storage]]
        [django.urls [reverse]]
        [jinja2 [Environment]])

(defn environment [&kwargs options]
  (setv env (Environment (unpack-mapping options)))
  (env.globals.update
    {"static" staticfiles_storage.url
     "url" reverse})
  (print "Generated env" env.globals)
  env)
