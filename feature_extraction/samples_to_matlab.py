#!/usr/bin/python2

import csv

with open('samples.csv', 'r') as inputcsv:
    with open('matlab.csv', 'w') as outputcsv:
        csvreader = csv.reader(inputcsv)
        csvwriter = csv.writer(outputcsv)
        for row in csvreader:
            if row[0] == 'user_id':
                continue

            user_id = int(row[0].split('_')[1])
            features = row[2:]
            csvwriter.writerow([user_id] + features)
