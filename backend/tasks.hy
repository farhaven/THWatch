(import [datetime [timedelta]])

(import [celery.task.base [Task]]
        [celery.task.schedules [schedule crontab]]
        [celery.utils.log [get-task-logger]])

(import [backend.thwbus :as thwbus]
        [thwatch.celery [app]])

(setv logger (get-task-logger --name--))

(defclass PeriodicPoll [Task]
  (setv run-every 10)
  (setv ignore-result True)
  (setv known-offers None)

  (defn run [self &rest args]
    (logger.info "Backend test task with args %s on %s" args self)
    (if (none? self.known-offers)
        (do
          (setv self.known-offers (thwbus.get-last-minute-offers)))
        (do
          (logger.info "Would update now")))))

(assoc app.conf.beat-schedule PeriodicPoll.name
       {"task" PeriodicPoll.name
        "schedule" PeriodicPoll.run-every})
