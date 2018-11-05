(import re
        logging
        [hashlib [sha256]]
        [datetime [datetime]])

(import requests
        [bs4 [BeautifulSoup]])

(setv baseurl "https://www.thw-bundesschule.de/THW-BuS/DE/Ausbildungsangebot/Lehrgangskalender/lehrgangskalender_node.html?sort=lastMinute"
      basehost (.join "/" (cut (baseurl.split "/" 3) None 3))
      RE_LAST_MINUTE (re.compile r"^Noch ([0-9]+) Last\-Minute\-Plätze verfügbar$"))

(logging.basicConfig)
(setv log (logging.getLogger --name--))
(log.setLevel logging.INFO)

(defclass LastMinuteOffer []
  (defn --init-- [self &kwonly title meta reservation dates remaining-places]
    (setv self.title title
          self.meta meta
          self.begin (min dates)
          self.end (max dates)
          self.reservation (.join "/" [basehost reservation])
          self.remaining-places remaining-places))

  (defn --str-- [self]
    (.format
      "<b>{title}</b>\n{meta}\nVon: {begin}\nBis: {end}\nFreie Plätze: {remaining_places}\n<a href=\"{reservation}\">Reservieren</a>"
      :title self.title
      :meta self.meta
      :begin self.begin
      :end self.end
      :remaining-places self.remaining-places
      :reservation self.reservation))

  (defn stable-hash [self]
    "Stable hash usable over process boundaries"
    (.hexdigest
      (sha256 (.join b"|" (lfor x [self.title
                                   self.meta
                                   (self.begin.strftime "%y-%m-%d %h:%m")
                                   (self.end.strftime "%y-%m-%d %h:%m")
                                   (str self.remaining-places)]
                                (x.encode 'utf-8))))))

  (defn --hash-- [self]
    (hash (, self.title
             self.meta
             self.begin
             self.end
             self.remaining-places)))

  (defn --eq-- [self other]
    (= (hash self) (hash other)))

  (defn to-serializable-dict [self]
    {"title" self.title
     "meta" self.meta
     "begin" (self.begin.strftime "%Y-%m-%d %H:%M")
     "end" (self.end.strftime "%Y-%m-%d %H:%M")
     "reservation" self.reservation
     "remaining-places" self.remaining-places})

  (with-decorator classmethod
    (defn from-serializable-dict [cls data]
      (log.debug "Reconstructing %s from %s" cls data)
      (cls :title (get data "title")
           :meta (get data "meta")
           :dates [(datetime.strptime (get data "begin") "%Y-%m-%d %H:%M")
                   (datetime.strptime (get data "end") "%Y-%m-%d %H:%M")]
           :reservation (get data "reservation")
           :remaining-places (get data "remaining-places")))))

(defn parse-single-result-page [text]
  " Extract offers from a single result page.

    Returns:

    (offers, forward)

    With:
        offers::  List of LastMinuteOffer
        forward:: URL for next page, if the last course teaser on this page was a last
                  minute teaser. Otherwise, None.
    "

  (log.debug "parsing %s bytes of text" (len text))

  (setv soup (BeautifulSoup text :features "html.parser")
        teasers (soup.find-all :class_ "teaser course")
        offers [])

  (defn is-last-minute? [course]
    (setv action (course.find :class_ "courseAction"))
    (lif-not action.a ; No "reserve last minute place" link
             (return None))

    (setv m (RE-LAST-MINUTE.match action.a.text))

    (lif-not m
             (do
               (log.debug "Action text '%s' does not match RE" action.a.text)
               (return None)))

    (m.group 1))

  (for [course teasers]
    (setv m (is-last-minute? course))
    (lif-not m (continue))

    (setv remaining-places (try
                             (int m)
                             (except [ValueError]
                               (log.debug "Can't parse number of remaining places")
                               0)))

    (setv action (course.find :class_ "courseAction")
          dates
          (lfor
            d
            (.find-all (course.find "dl" :class_ "docData") "dd")
            (datetime.strptime (get (d.text.split " " 1) 1)
                               "%d.%m.%Y, %H:%M Uhr"))
          o (LastMinuteOffer :title course.h2.text
                             :meta (. (course.find "span" :class_ "metadata") text)
                             :dates dates
                             :remaining-places remaining-places
                             :reservation (get action.a.attrs "href")))

    (offers.append o))

  (if (is-last-minute? (get teasers -1))
      (do
        (setv forward (get (. (soup.find "a" :class_ "forward") attrs) "href"))
        (, offers (.join "/" [basehost forward])))
      (, offers None)))

(defn get-last-minute-offers []
  (setv headers {"Referrer" basehost
                 "User-Agent" "Here Be Dragons"}
        url baseurl
        offers [])

  (while (not (none? url))
    (log.debug "Requesting url %s" url)
    (setv resp (requests.get url :headers headers))
    (log.debug "Got response %s" resp)
    (setv (, pageoffers url) (parse-single-result-page resp.text))
    (log.debug "Got %s page offers" (len pageoffers))
    (offers.extend pageoffers))

  offers)

(defmain [&rest args]
  (setv offers (get-last-minute-offers))

  (print "Got" (len offers) "offers")

  (for [o offers]
    (print o.title)
    (print "\t" o.meta)
    (print "\t" o.begin o.end)))
