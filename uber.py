from uber_rides.session import Session
from uber_rides.client import UberRidesClient
import pandas as pd
import datetime
import time
import csv
import os
import numpy
from psycopg2.extensions import register_adapter, AsIs

def addapt_numpy_int64(numpy_int64):
  return AsIs(numpy_int64)
register_adapter(numpy.int64, addapt_numpy_int64)

from sqlalchemy import create_engine
from sqlalchemy_utils import database_exists, create_database
import psycopg2


def getData(uber_token, hoods, username, pswd):
	session = Session(server_token = uber_token)
	client = UberRidesClient(session)

	
	con = psycopg2.connect("dbname='Pulse' user='%s' host='localhost' password='%s'" % (username, pswd))
	cur = con.cursor()

	for row in range(len(nhoods.index)):
		lat = nhoods.iloc[row]['lat']
		lon = nhoods.iloc[row]['lon']
		geoID = nhoods.iloc[row]['geoid']


		response = client.get_price_estimates(lat, lon, 
			37.468051, -122.447088)
		prices = response.json.get('prices')
		for p in prices:
			if p['localized_display_name'] == 'uberX':
				low = p['low_estimate']
				high = p['high_estimate']
				if 'surge_multiplier' in p:
					outperc = p['surge_multiplier']
				else:
					outperc = 1

		response = client.get_pickup_time_estimates(lat, lon)
		timeEstimate = response.json.get('times')
		for t in timeEstimate:
			if t['localized_display_name'] == 'uberX':
				etaSeconds = t['estimate']


		ts = time.time()
		timeStamp = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')

		query =  "INSERT INTO uber_sf (geoid, time, outperc, low, high, etaseconds) VALUES (%s, %s, %s, %s,%s,%s);"
		data = (geoID, timeStamp, outperc, low, high, etaSeconds)
		cur.execute(query, data)
	con.commit()
	print('Wrote data')
	con.close()




nhoods = pd.read_csv('input/SF_CensusTracts.csv')

uber_token = os.environ['UBER_TOKEN']
username = os.environ['DB_USERNAME']
pswd = os.environ['DB_PSWD']

while True:
	try:
		getData(uber_token, nhoods, username, pswd)

		ts = time.time()
		timeStamp = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
		print("Got data at: " + timeStamp)

	except:
		ts = time.time()
		timeStamp = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
		print("Error: " + timeStamp)

	time.sleep(500)







