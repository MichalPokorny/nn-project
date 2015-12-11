#!/usr/bin/python2

import csv
import datetime
import itertools
import numpy
import os
import os.path


SCANCODE_VALUES = {
    8: 'Backspace',
    9: 'Tab',
    13: 'Enter',
    16: 'Shift',
    17: 'Ctrl',
    32: ' ',
    20: 'CapsLock',
    33: 'PgUp',
    34: 'PgDn',
    35: '#',
    36: 'Home/$',
    37: '%',
    38: '&',
    40: '(',
    46: 'Delete',
    59: '^;', # TODO: browser-specific
    61: '=?', # TODO: browser-specific
    91: '[', # TODO: browser-specific
    106: 'Numpad_*',
    107: '?\\', # TODO: browser-specific
    188: ';,<',
    190: ':.',
    191: "?'",
    222: "'", # TODO: Opera-only
    226: '>|', # TODO: browser-specific
}

KEY_SECTORS = [
    ['qQ', 'wW', 'eE', 'rR', 'tT'],
    ['yY', 'uU', 'iI', 'oO', 'pP'],
    ['aA', 'sS', 'dD', 'fF', 'gG'],
    ['hH', 'jJ', 'kK', 'lL'],
    ['zZ', 'xX', 'cC', 'vV'],
    ['bB', 'nN', 'mM', ';,<', ':.']
]


def sector_of_key(key):
    for i, sector in enumerate(KEY_SECTORS):
        if key in sector:
            return i
    return -1


class Event(object):
    def __init__(self, sentence_id, user_id, timestamp, dn_up, key):
        self.sentence_id = sentence_id
        self.user_id = user_id
        self.timestamp = timestamp
        self.dn_up = dn_up
        self.key = key


def parse_scancode(scancode):
    if scancode in range(48, 58):
        return chr(ord('0') + scancode - 48)
    if scancode in range(65, 91):
        return chr(ord('a') + scancode - 65) + chr(ord('A') + scancode - 65)
    if scancode in SCANCODE_VALUES:
        return SCANCODE_VALUES[scancode]

    print "Unknown scancode:", scancode
    return scancode


def load_file(path):
    events = []
    with open(path, 'r') as f:
        paused = False
        user_id = None

        for line in f:
            line = line.strip()

            if line.startswith(';'):
                # header line (first in file, and after every unpause)
                header = line.split(';') # header line
                user_id = header[4]
                continue

            if line == '':
                continue

            if line == '---------END---------':
                break

            if line == '---------PAUSED---------':
                paused = not paused
                continue

            if paused:
                continue

            if line in ['invalid-data-start', 'invalid-data-end']:
                continue

            sentence_id, timestamp, dn_up, scancode = line.split()
            timestamp = datetime.datetime.fromtimestamp(float(timestamp) / 1000.0)
            key = parse_scancode(int(scancode))
            assert dn_up in ['dn', 'up']

            # sentence_id
            events.append(Event(sentence_id, user_id, timestamp, dn_up, key))
    return events


def window_to_features(window):
    features = {}

    # writing speed: keydowns per window size
    keydowns = len([event for event in window if event.dn_up == 'dn'])
    span_s = (window[-1].timestamp - window[0].timestamp).total_seconds()
    features['speed'] = keydowns / span_s

    # overlaps
    keys_down = {}
    overlaps = {}

    key_intervals = []

    for event in window:
        if event.dn_up == 'dn':
            if event.key in keys_down:
                continue  # repeated keydown event

            if len(keys_down) not in overlaps:
                overlaps[len(keys_down)] = 0
            overlaps[len(keys_down)] += 1

            keys_down[event.key] = event.timestamp

        if event.dn_up == 'up':
            if event.key in keys_down:  # may not be down (if windowed)
                key_down_at = keys_down[event.key]
                key_up_at = event.timestamp

                key_intervals.append((key_down_at, key_up_at, event.key))

                del keys_down[event.key]


    for overlap_count in overlaps:
        overlaps[overlap_count] /= float(len(window))

    for overlap_count in [0, 1, 2, 3, 4]:
        if overlap_count in overlaps:
            features['overlaps_%d' % overlap_count] = overlaps[overlap_count]
        else:
            features['overlaps_%d' % overlap_count] = 0

    key_press_times_ms = [(up - down).total_seconds() * 1000 for down, up, _key in key_intervals]
    features['key_press_ms_avg'] = numpy.mean(key_press_times_ms)
    features['key_press_ms_sd'] = numpy.std(key_press_times_ms)

    space_lengths_ms = []
    sector_space_lengths_ms = {}
    key_intervals = list(sorted(key_intervals))
    for i in range(1, len(key_intervals)):
        time = (key_intervals[i][0] - key_intervals[i - 1][1]).total_seconds() * 1000
        space_lengths_ms.append(time)

        key_from = key_intervals[i - 1][2]
        key_to = key_intervals[i][2]
        sector_from = sector_of_key(key_from)
        sector_to = sector_of_key(key_to)
        key = (sector_from, sector_to)
        if key not in sector_space_lengths_ms:
            sector_space_lengths_ms[key] = []
        sector_space_lengths_ms[key].append(time)

    features['space_length_ms_avg'] = numpy.mean(space_lengths_ms)
    features['space_length_ms_sd'] = numpy.std(space_lengths_ms)

    for sector_from in range(-1, len(KEY_SECTORS)):
        for sector_to in range(-1, len(KEY_SECTORS)):
            key = (sector_from, sector_to)
            if key in sector_space_lengths_ms:
                avg = numpy.mean(sector_space_lengths_ms[key])
            else:
                # impute missing values
                # TODO: maybe do this in matlab?
                avg = numpy.mean(space_lengths_ms)
            features['sector_%d_to_%d_ms_avg' % key] = avg

    features['backspaces_deletes'] = sum(1 for event in window if event.key in
                                         ['Backspace', 'Delete']) / float(len(window))

    return features

FEATURE_NAMES = ['speed', 'overlaps_0', 'overlaps_1', 'overlaps_2',
                 'overlaps_3', 'overlaps_4', 'key_press_ms_avg',
                 'key_press_ms_sd', 'space_length_ms_avg',
                 'space_length_ms_sd', 'backspaces_deletes']
for sector_from in range(-1, len(KEY_SECTORS)):
    for sector_to in range(-1, len(KEY_SECTORS)):
        FEATURE_NAMES.append('sector_%d_to_%d_ms_avg' % (sector_from, sector_to))

DIR = '../data/kprofiler-20100716-1442/'

with open('samples.csv', 'w') as csvfile:
    csvwriter = csv.writer(csvfile)
    csvwriter.writerow(['user_id', 'sentence_id'] + FEATURE_NAMES)

    for filename in os.listdir(DIR):

        path = os.path.join(DIR, filename)
        if os.path.isfile(path):
            events = load_file(path)
            for sentence_id, sentence_events in itertools.groupby(events, key=lambda event: event.sentence_id):
                sentence_events = list(sentence_events)
                features = window_to_features(sentence_events)

                values = [sentence_events[0].user_id, sentence_id]
                for feature_name in FEATURE_NAMES:
                    values.append(features[feature_name])

                csvwriter.writerow(values)
