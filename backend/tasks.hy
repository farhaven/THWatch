(import [datetime [timedelta]])

(import [celery.task.base [Task]]
        [celery.task.schedules [schedule crontab]]
        [celery.utils.log [get-task-logger]])

(import redis)

(import [backend.thwbus :as thwbus]
        [thwatch.celery [app]])

(setv logger (get-task-logger --name--))

(defclass PeriodicPoll [Task]
  (setv run-every 10)
  (setv ignore-result True)

  (defn --init-- [self]
    (.--init-- (super))
    (setv self.redis-conn (redis.StrictRedis :host "localhost"
                                             :port 6379
                                             :db 0))
    )

  (defn add-offer-to-db [self offers]
    (self.redis-conn.sadd "known-offers" (lfor x offers (hash x))))

  (defn is-offer-known? [self offer]
    (self.redis-conn.sismember "known-offers" (hash offer)))

  (defn run [self &rest args]
    (setv new-offers (thwbus.get-last-minute-offers))
    (for [o new-offers]
      (when (not (self.is-offer-known? o))
        ;; TODO: Notify users
        (logger.info "Notifying users of %s" o)
        ))
    (self.add-offer-to-db new-offers)))

(assoc app.conf.beat-schedule PeriodicPoll.name
       {"task" PeriodicPoll.name
        "schedule" PeriodicPoll.run-every})
