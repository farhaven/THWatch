(import time
        random
        [datetime [timedelta]])

(import [django.core.mail [send-mail]]
        [celery.task.base [Task]]
        [celery.task.schedules [schedule crontab]]
        [celery.utils.log [get-task-logger]])

(import redis)

(import [frontend.models :as models]
        [backend.thwbus :as thwbus]
        [backend.pushover [push :as pushover]]
        [thwatch.celery [app]])

(setv logger (get-task-logger --name--))

(defclass RedisLock []
  "Context manager that uses a redis value as a simple spin lock."
  (defn --init-- [self conn marker myself]
    (setv self.-marker marker
          self.-conn conn
          self.-myself myself))

  (defn --enter-- [self]
    (while True
      (setv old (self.-conn.getset self.-marker self.-myself))
      (if (= old b"unlocked")
          (break)
          (time.sleep (random.randint 1 3))))
    self)

  (defn --exit-- [self &rest args]
    (self.-conn.set self.-marker "unlocked")))


(defclass MailPoll [Task]
  "This task periodically checks the redis DB to see if there are any pending emails. If so, it combines them and sends them out
   in a single mail"
  [run-every 300 ; Poll for mail every 5 minutes
   ignore-result True]

  (defn --init-- [self]
    (.--init-- (super))
    (setv self.redis-conn (redis.StrictRedis :host "localhost"
                                             :port 6379
                                             :db 0)))

  (defn notify-user [self r]
    (logger.info "Sending email to %s now" r)
    (try
      (setv r (r.decode 'utf-8)
            messages (self.redis-conn.smembers (.format "messages-{}" r))
            text (.join (+ "\n" (* "-" 70) "\n")
                        (lfor m
                              messages
                              (m.decode 'utf-8))))
      (send-mail :subject "Neue Lehrgänge"
                 :message text
                 :from-email "thwatch@unobtanium.de" ; XXX
                 :recipient-list [r])
      (self.redis-conn.srem "recipients" r)
      (self.redis-conn.delete (.format "messages-{}" r))
      (self.redis-conn.delete (.format "marker-{}" r))
      (except [e Exception]
        (logger.exception "E: %s" e)
        (raise))))

  (defn run [self]
    (with [l (RedisLock self.redis-conn "email-lock" "mailpoll")]
      (logger.info "Mail poll: r=%s"
                   (self.redis-conn.smembers "recipients"))
      (for [r (self.redis-conn.smembers "recipients")]
        (try
          (setv marker (float (.decode (self.redis-conn.get (.format "marker-{}" (r.decode 'utf-8))) 'utf-8)))
          (except [v ValueError]
            (logger.exception "Can't get marker value: %s" v)
            (continue)))
        (logger.info "Marker: %s Now: %s Delta: %s" marker (time.time) (- (time.time) marker))
        (when (>= (- (time.time) marker) self.run-every)
          (self.notify-user r))))))

(assoc app.conf.beat-schedule MailPoll.name
       {"task" MailPoll.name
        "schedule" MailPoll.run-every})

(defclass NotificationTaskMail [Task]
  "This task enqueues an email notification.
   These are then collected after 10 minutes of no new notifications and sent out to avoid spam."
  [ignore-result True]

  (defn --init-- [self]
    (.--init-- (super))
    (setv self.redis-conn (redis.StrictRedis :host "localhost"
                                             :port 6379
                                             :db 0)))

  (defn enqueue-offer [self offer recipient]
    (with [l (RedisLock self.redis-conn "email-lock" "enqueue")]
      (self.redis-conn.set (.format "marker-{}" recipient) (time.time))
      (self.redis-conn.sadd "recipients" recipient)
      (self.redis-conn.sadd (.format "messages-{}" recipient)
                            (.format "{title}\n{meta}\n{begin} -- {end}\n{remaining-places} freie Plätze\n{reservation}\n"
                                     #** (offer.to-serializable-dict)))))

  (defn run [self settings-pk offer-data]
    ; Notify user via mail, after collecting a few messages
    (setv usersettings (models.UserSettings.objects.get :pk settings-pk)
          user usersettings.owner
          offer (thwbus.LastMinuteOffer.from-serializable-dict offer-data))
    (logger.info "Enqueueing mail to %s now" user.email)
    (self.enqueue-offer offer user.email)))


(defclass NotificationTaskPushover [Task]
  (setv ignore-result True)
  (defn run [self settings-pk offer-data]
    (setv settings (models.UserSettings.objects.get :pk settings-pk))
    (setv offer (thwbus.LastMinuteOffer.from-serializable-dict offer-data))
    (logger.debug "Notifying %s of %s now" settings (offer.stable-hash))
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
    (logger.debug "Dispatching notification")
    (setv offer (thwbus.LastMinuteOffer.from-serializable-dict offer-data))
    (setv patterns (models.Pattern.objects.all)) ;; TODO: This is ugly. Filter somehow in DB?
    (for [p patterns]
      (when (.match (p.regex) offer.title)
        (try
          (setv settings (models.UserSettings.objects.get :owner p.owner))
          (logger.debug "User settings %s" settings)
          (except [models.UserSettings.DoesNotExist]
            (logger.debug "User %s has no settings." p.owner)
            ; No settings, so we can't notify the user anyway
            (continue)))
        (unless p.owner.is-active
          (logger.info "Not sending any messages to %s, they are not active" p.owner)
          (continue))
        (when (!= (len settings.pushover-user) 0)
          (NotificationTaskPushover.delay settings.pk offer-data))
        (when settings.notify-via-mail
          (NotificationTaskMail.delay settings.pk offer-data))))))


(defclass PeriodicPoll [Task]
  [run-every 600 ; Poll every 10 minutes
   ignore-result True
   debug True]

  (defn --init-- [self]
    (.--init-- (super))
    (setv self.redis-conn (redis.StrictRedis :host "localhost"
                                             :port 6379
                                             :db 0)))

  (defn add-offer-to-db [self offers]
    (self.redis-conn.sadd "known-offers" #* (lfor x offers (x.stable-hash))))

  (defn is-offer-known? [self offer]
    (if self.debug
        False
        (self.redis-conn.sismember "known-offers" (offer.stable-hash))))

  (defn run [self &rest args]
    (setv new-offers (thwbus.get-last-minute-offers))
    (logger.debug "Got %s new last minute offers" (len new-offers))
    (for [o new-offers]
      (when (not (self.is-offer-known? o))
        (logger.debug "A Notifying of offer with ID %s" (o.stable-hash))
        (NotificationDispatcher.delay (o.to-serializable-dict))))
    (self.add-offer-to-db new-offers)))

(assoc app.conf.beat-schedule PeriodicPoll.name
       {"task" PeriodicPoll.name
        "schedule" PeriodicPoll.run-every})

(setv main-redis-conn (redis.StrictRedis))
(main-redis-conn.set "email-lock" 'unlocked)
(del main-redis-conn)
