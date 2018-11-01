"""
Django settings for thwatch project.

Generated by 'django-admin startproject' using Django 2.1.2.

For more information on this file, see
https://docs.djangoproject.com/en/2.1/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/2.1/ref/settings/
"""

(import os)

; Build paths inside the project like this: os.path.join(BASE_DIR, ...)
(setv BASE-DIR
      (os.path.dirname
        (os.path.dirname
          (os.path.abspath --file--))))

; Quick-start development settings - unsuitable for production
; See https://docs.djangoproject.com/en/2.1/howto/deployment/checklist/

; SECURITY WARNING: keep the secret key used in production secret!
(setv SECRET-KEY "fw5r-^6t@grrc74@bmh5@2==^9a*@*1+#!_o(ltj_*ym2u#8z3"
      DEBUG True ; SECURITY WARNING: don't run with debug turned on in production!
      ALLOWED_HOSTS [])

; Application definition

(setv INSTALLED_APPS ["django.contrib.admin"
                      "django.contrib.auth"
                      "django.contrib.contenttypes"
                      "django.contrib.sessions"
                      "django.contrib.messages"
                      "django.contrib.staticfiles"
                      "frontend"
                      "backend"])

(setv MIDDLEWARE ["django.middleware.security.SecurityMiddleware"
                  "django.contrib.sessions.middleware.SessionMiddleware"
                  "django.middleware.common.CommonMiddleware"
                  "django.middleware.csrf.CsrfViewMiddleware"
                  "django.contrib.auth.middleware.AuthenticationMiddleware"
                  "django.contrib.messages.middleware.MessageMiddleware"
                  "django.middleware.clickjacking.XFrameOptionsMiddleware"])

(setv ROOT_URLCONF "thwatch.urls")

(setv TEMPLATES [{"BACKEND" "django.template.backends.jinja2.Jinja2"
                  "DIRS" ["frontend/templates"]
                  "APP_DIRS" True
                  "OPTIONS" {"environment" "frontend.jinja2.environment"}}
                 {"BACKEND" "django.template.backends.django.DjangoTemplates"
                  "DIRS" []
                  "APP_DIRS" True
                  "OPTIONS" {"context_processors" ["django.template.context_processors.debug"
                                                   "django.template.context_processors.request"
                                                   "django.contrib.auth.context_processors.auth"
                                                   "django.contrib.messages.context_processors.messages"]}}])

(setv WSGI_APPLICATION "thwatch.wsgi.application")


; Database
; https://docs.djangoproject.com/en/2.1/ref/settings/#databases

(setv DATABASES {"default" {"ENGINE" "django.db.backends.sqlite3"
                            "NAME" "db.sqlite3"}})


; Password validation
; https://docs.djangoproject.com/en/2.1/ref/settings/#auth-password-validators

(setv AUTH-PASSWORD-VALIDATORS [{"NAME" "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"}
                                {"NAME" "django.contrib.auth.password_validation.MinimumLengthValidator"}
                                {"NAME" "django.contrib.auth.password_validation.CommonPasswordValidator"}
                                {"NAME" "django.contrib.auth.password_validation.NumericPasswordValidator"}])


; Internationalization
; https://docs.djangoproject.com/en/2.1/topics/i18n/

(setv LANGUAGE-CODE "en-us"
      TIME-ZONE "UTC"
      USE-I18N True
      USE-L10N True
      USE-TZ True)


; Static files (CSS, JavaScript, Images)
; https://docs.djangoproject.com/en/2.1/howto/static-files/

(setv STATIC_URL "/static/")

; Authentication
(setv LOGIN-REDIRECT-URL "/frontend/")


; Broker for Celery task scheduler
(setv BROKER_URL "redis://localhost:6379"
      CELERY_RESULT_BACKEND "redis://localhost:6379"
      CELERY_ACCEPT_CONTENT ["application/json"]
      CELERY_TASK_SERIALIZER "json"
      CELERY_RESULT_SERIALIZER "json"
      CELERY_TIMEZONE "UTC")
