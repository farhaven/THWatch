import re
import time
import logging

import pushover
import thwbus


logging.basicConfig()
log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)

# Dict mapping regular expressions for offer titles to pushover user keys interested in them.
ROUTING = {
    re.compile(r'.*'): [pushover.PUSHOVER_USER_KEY]
}


def push_offer(target, offer):
    res = pushover.push(target=target,
                        text=str(offer),
                        title="Neuer Last-Minute-Platz verfügbar",
                        priority=pushover.Priority.Normal)
    if res.status_code != 200:
        log.error("Failed to push message to %s: %s", target, res.text)


def handle_new_offer(offer):
    """ Handle signalling for a new offer, determine who's interested in that and push to them. """
    for rkey, targets in ROUTING.items():
        if rkey.match(offer.title):
            for t in targets:
                push_offer(t, offer)


if __name__ == "__main__":
    known_offers = set(thwbus.get_last_minute_offers())  # Initialize set of known offers

    log.debug("got %s known offers: %s", len(known_offers), known_offers)

    while True:
        log.debug("Known offers: %s (%s)", sorted([hash(o) for o in known_offers]), len(known_offers))

        offers = thwbus.get_last_minute_offers()
        log.debug("Got %s offers", len(offers))

        for o in offers:
            if o in known_offers:
                continue

            log.debug("Got new offer %s", o)
            known_offers.add(o)
            handle_new_offer(o)

        log.debug("waiting 10 seconds before polling again.")
        time.sleep(60)
