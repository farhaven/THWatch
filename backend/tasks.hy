(import [datetime [timedelta]])

(import [celery.task.base [Task]]
        [celery.task.schedules [schedule crontab]]
        [celery.utils.log [get-task-logger]])

(import redis)

(import [frontend.models :as models]
        [backend.thwbus :as thwbus]
        [backend.pushover [push :as pushover]]
        [thwatch.celery [app]])

(setv logger (get-task-logger --name--))

(defclass NotificationTask [Task]
  (setv ignore-result True)
  (defn run [self settings-pk offer-data]
    (setv settings (models.UserSettings.objects.get :pk settings-pk))
    (setv offer (thwbus.LastMinuteOffer.from-serializable-dict offer-data))
    (logger.info "Notifying %s of %s now" settings (offer.stable-hash))
    (setv res (pushover :text (str offer)
                        :title "Neuer Last-Minute-Platz verfügbar" ;; TODO: i18n
                        :target settings.pushover-user
                        ; TODO: Priority?
                        ))
    (logger.debug "Result: %s" res)))

(defclass NotificationDispatcher [Task]
  "This tasks decides who gets notified of an offer and in what way. It then spawns a bunch of
   NotificationTasks to do the actual notification."
  (setv ignore-result True)

  (defn run [self offer-data]
    (setv offer (thwbus.LastMinuteOffer.from-serializable-dict offer-data))
    (setv patterns (models.Pattern.objects.all)) ;; TODO: This is ugly. Filter somehow in DB?
    (for [p patterns]
      (when (.match (p.regex) offer.title)
        (try
          (setv settings (models.UserSettings.objects.get :owner p.owner))
          (except [models.UserSettings.DoesNotExist]
            ; No settings, so we can't notify the user anyway
            (continue)))
        (NotificationTask.delay settings.pk offer-data)))))

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
