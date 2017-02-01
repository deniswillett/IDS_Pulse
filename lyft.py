from lyft_rides.auth import ClientCredentialGrant
from lyft_rides.session import Session
from lyft_rides.client import LyftRidesClient
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


def getData(nhoods, client_id, client_secret, username, pswd):
	auth_flow = ClientCredentialGrant(
		client_id=client_id, 
		client_secret=client_secret, 
		scopes = 'public')
	session = auth_flow.get_session()
	client = LyftRidesClient(session)

	con = psycopg2.connect("dbname='Pulse' user='%s' host='localhost' password='%s'" % (username, pswd))
	cur = con.cursor()

	for row in range(len(nhoods.index)):
		lat = nhoods.iloc[row]['lat']
		lon = nhoods.iloc[row]['lon']

		response = client.get_cost_estimates(lat, lon, 37.468051, -122.447088, ride_type='lyft')
		costs = response.json.get('cost_estimates')
		geoID = nhoods.iloc[row]['geoid']

		low = costs[0]['estimated_cost_cents_min']	
		high = costs[0]['estimated_cost_cents_max']

		percent = costs[0]['primetime_percentage']
		perc = percent.replace('%','')
		outperc = int(perc)/100 + 1

		response = client.get_pickup_time_estimates(lat, lon, ride_type='lyft')
		timeEstimate = response.json.get('eta_estimates')

		etaSeconds = timeEstimate[0]['eta_seconds']

		ts = time.time()
		timeStamp = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')

		query =  "INSERT INTO lyft_sf (geoid, time, outperc, low, high, etaseconds) VALUES (%s, %s, %s, %s,%s,%s);"
		data = (geoID, timeStamp, outperc, low, high, etaSeconds)
		cur.execute(query, data)
	con.commit()
	print('Wrote data')
	con.close()


client_id = os.environ['LYFT_CLIENT_ID']
client_secret = os.environ['LYFT_CLIENT_SECRET']
username = os.environ['DB_USERNAME']
pswd = os.environ['DB_PSWD']
print(client_id)

nhoods = pd.read_csv('input/SF_CensusTracts.csv')

while True:
	try:
		getData(nhoods, client_id, client_secret, username, pswd)

		ts = time.time()
		timeStamp = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
		print("Got data at: " + timeStamp)
	except:
		ts = time.time()
		timeStamp = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
		print("Error: " + timeStamp)

	time.sleep(240)

