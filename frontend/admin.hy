(import [django.contrib [admin]]
        [frontend.models [Pattern]])

(defclass PatternAdmin [admin.ModelAdmin])

(admin.site.register Pattern PatternAdmin)
