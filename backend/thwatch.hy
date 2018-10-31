(import re
        time
        logging)

(import pushover
        thwbus)

(logging.basicConfig)
(setv log (logging.getLogger --name--))
(log.setLevel logging.DEBUG)

(setv ROUTING {(re.compile r".*") [pushover.PUSHOVER-USER-KEY]})

(defn push-offer [target offer]
  (setv res (pushover.push :target target
                           :text (str offer)
                           :title "Neuer Last-Minute-Platz verfügbar"
                           :priority pushover.Priority.Normal))
  (when (!= res.status-code 200)
    (log.error "Failed to push message to %s: %s" target res.text)))

(defn handle-new-offer [offer]
  "Handle signalling for a new offer, determine who's interested in that and push to them."
  (for [(, rkey targets) (ROUTING.items)]
    (when (rkey.match offer.title)
      (for [t targets]
        (push-offer t offer)))))

(when (= --name-- "__main__")
  ; Init set of known offers
  (setv known-offers
        (set (thwbus.get-last-minute-offers)))

  (log.debug "got %s known offers: %s" (len known_offers) known_offers)

  (while True
    (log.debug "Known offers: %s (%s)"
               (sorted
                 (lfor
                   o
                   known_offers
                   (hash o)))
               (len known-offers))

    (setv offers (thwbus.get-last-minute-offers))

    (for [o offers]
      (when (in o known-offers)
        (continue))

      (log.debug "Got new offer %s" o)

      (known-offers.add o)
      (handle-new-offer o))

    (log.debug "Waiting for 10 minutes before polling again")
    (time.sleep 600)))
