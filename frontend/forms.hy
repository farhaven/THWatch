(import [django [forms]]
        [django.contrib.auth.models [User]])

(defclass RequestAccountForm [forms.Form]
  [name (forms.CharField)
   email (forms.CharField)
   password1 (forms.CharField :widget forms.PasswordInput)
   password2 (forms.CharField :widget forms.PasswordInput)]

  (defn clean [self]
    (setv cleaned-data (.clean (super))
          name (cleaned-data.get 'name)
          passwd1 (cleaned-data.get 'password1)
          passwd2 (cleaned-data.get 'password2))
    (print "Cleaned data: " cleaned-data)
    (unless (and (= passwd1 passwd2) (not (none? passwd1)) (!= (len passwd1) 0))
      (raise (forms.ValidationError "Passwords don't match!")))
    cleaned-data)

  (defn clean-name [self]
    (setv name (get self.cleaned-data "name"))
    (try
      (User.objects.get :username name)
      (except [User.DoesNotExist]) ; Do nothing.
      (else
        (raise (forms.ValidationError "User name already exists!"))))
    name))
