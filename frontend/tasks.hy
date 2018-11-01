(import [celery.decorators [task]]
        [celery.utils.log [get-task-logger]])

(setv logger (get-task-logger --name--))

(with-decorator (task :name "test-task" :bind True)
  (defn test-task [&rest args]
    (logger.info "Would do some thing now %s" args)))
