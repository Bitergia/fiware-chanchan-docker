#!/usr/bin/env python
# -*- coding: utf-8 -*-

from pysqlite2 import dbapi2 as sqlite3
import json, os, argparse

parser = argparse.ArgumentParser(description='This is a demo script by nixCraft.')
parser.add_argument('-n','--name', help='Name of the app to search',required=True)
parser.add_argument('-f','--file',help='File where to output the results', required=True)
parser.add_argument('-db','--database',help='Databse from where to extract the data', required=True)
args = parser.parse_args()

def dict_factory(cursor, row):
    d = {}
    for idx, col in enumerate(cursor.description):
        d[col[0]] = row[idx]
    return d

# dict to be shared with chanchan using a JSON file
chanchan_config = {}

# Connect to the database

con = sqlite3.connect("/opt/fi-ware-idm/keystone/keystone.db")
con.row_factory = dict_factory
cur = con.cursor()

# Define the app name to search

symbol = args.name
t = (symbol,)

# Extract the Oauth2 client ID

cur.execute("select id as a from consumer_oauth2 where name=?", t)
idr = cur.fetchone()["a"]

# Extract the Oauth2 secret ID
cur.execute("select secret as b from consumer_oauth2 where name=?", t)
secretr = cur.fetchone()["b"]

chanchan_config = {'id': idr, 'secret': secretr}

# Extract the organizations names
cur.execute("select name from project where name like '%organization%'")
orgs = cur.fetchall()
orgs_list = []
for org in orgs:
	orgs_list.append(org['name'])

chanchan_config['orgs'] = orgs_list;

# Write the JSON file
f = open(args.file, 'w')
f.writelines(json.dumps(chanchan_config,
                        sort_keys=True,
                        indent=4, separators=(',', ': ')))
f.close()


con.close()
