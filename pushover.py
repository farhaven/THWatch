""" This module deals with pushover notifications """
import logging

import requests

PUSHOVER_API_TOKEN = "HereBeDragons"
PUSHOVER_USER_KEY  = "FooBar"

logging.basicConfig()
log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)


class Priority:
    """ Names for Pushover message priorites """
    Lowest = -2  # No audible alert
    Low = -1
    Normal = 0
    High = 1
    Emergency = 2


def _push(target, text, title, img=None, priority=Priority.Lowest):
    reqdata = {
        "token": PUSHOVER_API_TOKEN,
        "user": target,
        "title": title,
        "message": text,
        "priority": priority
    }

    if img is None:
        r = requests.post("https://api.pushover.net/1/messages.json", data=reqdata)
    else:
        r = requests.post("https://api.pushover.net/1/messages.json",
                          data=reqdata,
                          files={"attachment": ("plot.png", img, "image/png")})

    log.debug("Message to %s pushed: '%s', reply: %s", target, text, r)
    return r


log.debug("Done loading")

if __name__ == "__main__":
    log.debug("Testing push now.")
    r = _push(PUSHOVER_USER_KEY, "This is a test", "Stockalert pushover test")
    log.debug("Push done: %s: %s", r, r.text)
