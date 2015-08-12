#!/usr/bin/python
# Always use the system Python; it has PyObjC bundled

import sys
import argparse

import CoreFoundation as CF

arg_parser = argparse.ArgumentParser(
    description='Set iTerm2 profile preferences.')
arg_parser.add_argument('--should-run', action='store_true',
                        help="don't set; perform idempotence test")
arg_parser.add_argument('bg_path', help='background image path')
args = arg_parser.parse_args()

APP_ID = 'com.googlecode.iterm2'
KEY = 'New Bookmarks'
FONT = 'InconsolataForPowerline 20'
ESC_PLUS_KEY = 2
PREFS = {
    'Background Image Location': args.bg_path,
    'Blend': 0.4,
    'Non Ascii Font': FONT,
    'Normal Font': FONT,
    'Option Key Sends': ESC_PLUS_KEY,
    'Right Option Key Sends': ESC_PLUS_KEY,
    'Use Canonical Parser': True,
}

default_profile = dict(CF.CFPreferencesCopyAppValue(KEY, APP_ID)[0])

if args.should_run:
    sys.exit(
        0 if any(default_profile[k] != v for k, v in PREFS.items()) else 1)

default_profile.update(PREFS)
CF.CFPreferencesSetAppValue(KEY, [default_profile], APP_ID)
