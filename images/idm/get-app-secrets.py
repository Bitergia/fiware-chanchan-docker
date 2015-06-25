#!/usr/bin/env python
# -*- coding: utf-8 -*-

from pysqlite2 import dbapi2 as sqlite3
import anyjson, os

def dict_factory(cursor, row):
    d = {}
    for idx, col in enumerate(cursor.description):
        d[col[0]] = row[idx]
    return d

# Connect to the database

con = sqlite3.connect("/opt/fi-ware-idm/keystone/keystone.db")
con.row_factory = dict_factory
cur = con.cursor()

# Define the app name to search

symbol = 'Chanchan'
t = (symbol,)


# Extract the Oauth2 client ID

cur.execute("select id as a from consumer_oauth2 where name=?", t)
idr = cur.fetchone()["a"]

# Extract the Oauth2 secret ID

cur.execute("select secret as b from consumer_oauth2 where name=?", t)
secretr = cur.fetchone()["b"]

# Export it to a json file

f = open('/config/app.json', 'w')
f.writelines(anyjson.serialize({"id": idr, "secret": secretr}))
f.close()

con.close()
