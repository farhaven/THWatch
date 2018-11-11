#!/bin/ksh
set -exu

if [[ "$1" == "extract" ]]; then
    mkdir -p thwatch/locale
    pybabel extract \
            -F babel.cfg \
            -o thwatch/locale/messages.pot \
            backend frontend thwatch
elif [[ "$1" == "init" ]]; then
    pybabel init -i thwatch/locale/messages.pot -d thwatch/locale -l de
elif [[ "$1" == "update" ]]; then
    pybabel update -i thwatch/locale/messages.pot -d thwatch/locale
elif [[ "$1" == "compile" ]]; then
    pybabel compile -f -d thwatch/locale
    # Fix up names for translations so that django can find them
    find thwatch/locale -type f -name '*.mo' | while read p; do
        ln -fs $(basename "${p}") $(dirname "$p")/django.mo
    done
    find thwatch/locale -type f -name '*.po' | while read p; do
        ln -fs $(basename "${p}") $(dirname "$p")/django.po
    done
fi
