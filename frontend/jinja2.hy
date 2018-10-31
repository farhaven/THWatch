(import [django.contrib.staticfiles.storage [staticfiles_storage]]
        [django.urls [reverse]]
        [jinja2 [Environment]])

(defn environment [&kwargs options]
  (print "Creating Jinja2 environment")
  (setv env (Environment (unpack-mapping options)))
  (env.globals.update
    {:static staticfiles_storage.url
     :url reverse})
  env)
