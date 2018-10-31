; This module contains models

(import [django.db [models]]
        [django.contrib.auth.models [User]])

(defclass Pattern [models.Model]
  (setv owner (models.ForeignKey User :on-delete models.CASCADE))
  (setv name (models.CharField :max-length 80))
  (setv pattern (models.CharField :max-length 200)))
