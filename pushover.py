""" This module deals with pushover notifications """
import logging
import json

from enum import Enum, unique

import requests

with open('conf.json', 'r') as fh:
    conf = json.load(fh)
    PUSHOVER_API_TOKEN = conf['api_token']
    PUSHOVER_USER_KEY = conf['target_user']

logging.basicConfig()
log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)


@unique
class Priority(Enum):
    """ Names for Pushover message priorites """
    Lowest = -2  # No audible alert
    Low = -1
    Normal = 0
    High = 1
    Emergency = 2


def _push(target, text, title, do_html=True, img=None, priority=Priority.Low):
    reqdata = {
        "token": PUSHOVER_API_TOKEN,
        "user": target,
        "title": title,
        "message": text,
        "priority": priority.value,
        "html": 1 if do_html else 0,
    }

    if img is None:
        r = requests.post("https://api.pushover.net/1/messages.json", data=reqdata)
    else:
        r = requests.post("https://api.pushover.net/1/messages.json",
                          data=reqdata,
                          files={"attachment": ("plot.png", img, "image/png")})

    log.debug("Message to %s pushed: '%s', reply: %s", target, text, r)
    return r


def push(*, target=PUSHOVER_USER_KEY, text, title, priority=Priority.Low):
    # TODO: Dedup messages
    return _push(target, text, title, priority=priority)


log.debug("Done loading")

if __name__ == "__main__":
    log.debug("Testing push now.")
    r = _push(PUSHOVER_USER_KEY, "This is a test", "THWatch push test.")
    log.debug("Push done: %s: %s", r, r.text)
