import logging
import random

import pushover
import thwbus


logging.basicConfig()
log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)


def push_offer(target, offer):
    res = pushover.push(target=target,
                        text=str(offer),
                        title="Neuer Last-Minute-Platz verfügbar")
    if res.status_code != 200:
        log.error("Failed to push message to %s: %s", target, res.text)


if __name__ == "__main__":
    offers = thwbus.get_last_minute_offers()
    for o in offers:
        log.debug("%s", o)
    push_offer(pushover.PUSHOVER_USER_KEY, random.choice(offers))
    # pushover.push(text=f"Got {len(offers)} last minute offers",
    #               title="New last minute offers at BuS")
