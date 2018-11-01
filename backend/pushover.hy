" This module deals with pushover notifications "

(import logging
        json
        [enum [Enum unique]])

(import requests)

(with [fh (open "conf.json" "r")]
  (setv conf (json.load fh)
        PUSHOVER-API-TOKEN (get conf "api_token")
        PUSHOVER-USER-KEY (get conf "target_user")))

(logging.basicConfig)
(setv log (logging.getLogger --name--))
(log.setLevel logging.DEBUG)

(with-decorator unique
  (defclass Priority [Enum]
    "Names for Pushover message priorities"
    (setv Lowest -2
          Low -1
          Normal 0
          High 1
          Emergency 2)))

(defn -push [target text title &optional [do-html True] [img None] [priority Priority.Low]]
  (setv reqdata {"token" PUSHOVER-API-TOKEN
                 "user" target
                 "title" title
                 "message" text
                 "priority" priority.value
                 "html" (if do-html 1 0)})
  (setv r (if (is img None)
              (requests.post "https://api.pushover.net/1/messages.json" :data reqdata)
              (requests.post "https://api.pushover.net/1/messages.json"
                             :data reqdata
                             :files {"attachment" (, "plot.png" img "image/png")})))

  (log.debug "Message to %s pushed: '%s', reply: %s" target text r)
  r)

(defn push [text title &optional [target PUSHOVER-USER-KEY] [priority Priority.Low]]
  ; TODO: Dedup messages?
  (-push target text title :priority priority))

(defmain [&rest args]
  (log.debug "Testing push now")
  (setv r (-push PUSHOVER-USER-KEY "This is a test" "THWatch push test"))
  (log.debug "Push done: %s: %s" r r.text))
