(import [datetime [timedelta]])

(import [celery.task.base [Task]]
        [celery.task.schedules [schedule crontab]]
        [celery.utils.log [get-task-logger]])

(import redis)

(import [frontend.models :as models]
        [backend.thwbus :as thwbus]
        [thwatch.celery [app]])

(setv logger (get-task-logger --name--))

(defclass NotificationTask [Task]
  (defn run [self user offer]
    (logger.info "Notifying %s of %s now" user (offer.stable-hash))

    ))

(defclass NotificationDispatcher [Task]
  "This tasks decides who gets notified of an offer and in what way. It then spawns a bunch of
   NotificationTasks to do the actual notification."
  (setv ignore-result True)

  (defn run [self offer-data]
    (setv offer (thwbus.LastMinuteOffer.from-serializable-dict offer-data))
    (setv patterns (models.Pattern.objects.all)) ;; TODO: This is ugly. Filter somehow in DB?
    (for [p patterns]
      (when (.match (p.regex) offer.title)
        (NotificationTask.delay p.owner offer)))))

(defclass PeriodicPoll [Task]
  (setv run-every 10)
  (setv ignore-result True)

  (defn --init-- [self]
    (.--init-- (super))
    (setv self.redis-conn (redis.StrictRedis :host "localhost"
                                             :port 6379
                                             :db 0)))

  (defn add-offer-to-db [self offers]
    (self.redis-conn.sadd "known-offers" #* (lfor x offers (x.stable-hash))))

  (defn is-offer-known? [self offer]
    (self.redis-conn.sismember "known-offers" (offer.stable-hash)))

  (defn run [self &rest args]
    (setv new-offers (thwbus.get-last-minute-offers))
    (for [o new-offers]
      (when (not (self.is-offer-known? o))
        (logger.info "A Notifying of offer with ID %s" (o.stable-hash))
        (NotificationDispatcher.delay (o.to-serializable-dict))))
    (self.add-offer-to-db new-offers)))

(assoc app.conf.beat-schedule PeriodicPoll.name
       {"task" PeriodicPoll.name
        "schedule" PeriodicPoll.run-every})
