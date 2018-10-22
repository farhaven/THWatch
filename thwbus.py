import re
import logging

from datetime import datetime

import requests

from bs4 import BeautifulSoup

baseurl = "https://www.thw-bundesschule.de/THW-BuS/DE/Ausbildungsangebot/Lehrgangskalender/lehrgangskalender_node.html?sort=lastMinute"
basehost = '/'.join(baseurl.split('/', 3)[:3])

RE_LAST_MINUTE = re.compile(r'^Noch ([0-9]+) Last\-Minute\-Plätze verfügbar$')

logging.basicConfig()
log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)


class LastMinuteOffer:
    """ Represents a last minute offer in a course """

    def __init__(self, *, title, meta, reservation, dates, remaining_places):
        self.title = title
        self.meta = meta
        self.begin = min(dates)
        self.end = max(dates)
        self.reservation = "/".join((basehost, reservation))
        self.remaining_places = remaining_places

    def __str__(self):
        return f"<b>{self.title}</b>\n{self.meta}\nVon: {self.begin}\nBis: {self.end}\nFreie Plätze: {self.remaining_places}\n<a href=\"{self.reservation}\">Reservieren</a>"

    def __hash__(self):
        return hash((self.title, self.meta, self.begin, self.end, self.remaining_places))

    def __eq__(self, other):
        return hash(self) == hash(other)


def parse_single_result_page(text):
    """ Extract offers from a single result page.

    Returns:

    (offers, forward)

    With:
        offers::  List of LastMinuteOffer
        forward:: URL for next page, if the last course teaser on this page was a last
                  minute teaser. Otherwise, None.
    """

    log.debug("parsing %s bytes of text", len(text))

    soup = BeautifulSoup(text, features='html.parser')

    teasers = soup.find_all(class_="teaser course")

    offers = []

    def is_last_minute(course):
        action = course.find(class_="courseAction")
        if action.a is None:
            # No "reserve last minute place" link
            return None
        m = RE_LAST_MINUTE.match(action.a.text)
        if m is None:
            log.debug("Action text '%s' does not match RE", action.a.text)
            return None
        return m.group(1)

    for course in teasers:
        m = is_last_minute(course)
        if m is None:
            continue
        try:
            remaining_places = int(m)
        except ValueError:
            remaining_places = 0
            log.exception("Can't parse number of remaining places")

        action = course.find(class_="courseAction")
        dates = course.find('dl', class_='docData')
        dates = [d.text for d in dates.find_all('dd')]
        dates = [datetime.strptime(d.split(' ', 1)[1], '%d.%m.%Y, %H:%M Uhr') for d in dates]

        o = LastMinuteOffer(title=course.h2.text,
                            meta=course.find('span', class_='metadata').text,
                            dates=dates,
                            remaining_places=int(remaining_places),
                            reservation=action.a.attrs['href'])
        offers.append(o)

    if is_last_minute(teasers[-1]):
        forward = soup.find('a', class_='forward').attrs['href']
        return offers, '/'.join((basehost, forward))
    return offers, None


def get_last_minute_offers():
    headers = {
        "Referrer": basehost,
        "User-Agent": "Here Be Dragons"
    }

    url = baseurl
    offers = []

    while url is not None:
        log.debug("Requesting %s", url)
        resp = requests.get(url, headers=headers)
        log.debug("Got response: %s", resp)
        pageoffers, url = parse_single_result_page(resp.text)
        log.debug("Got %s page offers", len(pageoffers))
        offers.extend(pageoffers)

    return offers


if __name__ == "__main__":
    offers = get_last_minute_offers()

    print("Got", len(offers), "offers")
    for o in offers:
        print(o.title)
        print('\t', o.meta)
        print('\t', o.begin, o.end)
