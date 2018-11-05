(import [django.contrib [admin]]
        [frontend.models [Pattern UserSettings]])

(defclass PatternAdmin [admin.ModelAdmin])
(admin.site.register Pattern PatternAdmin)

(defclass UserSettingsAdmin [admin.ModelAdmin])
(admin.site.register UserSettings UserSettingsAdmin)
