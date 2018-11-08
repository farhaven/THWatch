; This module contains models

(import re)
(import [django.db [models]]
        [django.contrib.auth.models [User]])

(defclass UserSettings [models.Model]
  ; TODO: Add validation
  [owner (models.ForeignKey User :on-delete models.CASCADE)
   pushover-user (models.CharField "Pushover User Key"
                                   :max-length 200
                                   :blank True)
   notify-via-mail (models.BooleanField "Notify via email")])

(defclass Pattern [models.Model]
  (setv owner (models.ForeignKey User :on-delete models.CASCADE))
  (setv name (models.CharField :max-length 80))
  (setv pattern (models.CharField :max-length 200))

  (defn regex [self]
    "Returns a compiled regex for this pattern"
    (re.compile self.pattern)))
