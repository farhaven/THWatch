(import [datetime [timedelta]])

(import [celery.task.base [Task]]
        [celery.task.schedules [schedule crontab]]
        [celery.utils.log [get-task-logger]])

(import redis)

(import [backend.thwbus :as thwbus]
        [thwatch.celery [app]])

(setv logger (get-task-logger --name--))

(defclass NotificationTask [Task]
  (setv ignore-result True)

  (defn run [self offer-data]
    (setv offer (thwbus.LastMinuteOffer.from-serializable-dict offer-data))
    (logger.info "B Notifying users of %s" (offer.stable-hash))
    ))

(defclass PeriodicPoll [Task]
  (setv run-every 10)
  (setv ignore-result True)

  (defn --init-- [self]
    (.--init-- (super))
    (setv self.redis-conn (redis.StrictRedis :host "localhost"
                                             :port 6379
                                             :db 0)))

  (defn add-offer-to-db [self offers]
    (self.redis-conn.sadd "known-offers" (lfor x offers (x.stable-hash))))

  (defn is-offer-known? [self offer]
    (setv res (self.redis-conn.sismember "known-offers" (offer.stable-hash)))
    (logger.info "%s: %s (%s)" (offer.stable-hash) res (type res))
    res)

  (defn run [self &rest args]
    (setv new-offers (thwbus.get-last-minute-offers))
    (for [o new-offers]
      (when (not (self.is-offer-known? o))
        (logger.info "A Notifying of offer with ID %s" (o.stable-hash))
        (NotificationTask.delay (o.to-serializable-dict))))
    (self.add-offer-to-db new-offers)))

(assoc app.conf.beat-schedule PeriodicPoll.name
       {"task" PeriodicPoll.name
        "schedule" PeriodicPoll.run-every})
