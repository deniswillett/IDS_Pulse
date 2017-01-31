from uber_rides.session import Session
from uber_rides.client import UberRidesClient
import pandas as pd
import datetime
import time
import csv
import os

outFile = "output/ubersfcost1.csv"

nhoods = pd.read_csv('input/SF_CensusTracts.csv')

uber_token = os.environment('UBER_TOKEN')

def getData():
	session = Session(server_token = uber_token)
	client = UberRidesClient(session)

	outLines = []

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

		outStr = [geoID, timeStamp, outperc, low, high, etaSeconds]

		outLines.append(outStr);


	with open(outFile, 'a') as f:
	    writer = csv.writer(f)
	    writer.writerows(outLines)





while True:
	getData()

	ts = time.time()
	timeStamp = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
	print("Got data at: " + timeStamp)

	time.sleep(600)







