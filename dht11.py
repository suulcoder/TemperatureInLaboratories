#------------------------------------------------------------------------------
import sys
import Adafruit_DHT
import csv
import random
import datetime
#------------------------------------------------------------------------------
with open('data.csv', mode='w') as data_file:
	data_file = csv.writer(data_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
	data_file.writerow(['date','temperature'])
	while True:
		humidity, temperature = Adafruit_DHT.read_retry(11,4)
		temperature = temperature + random.uniform(-0.5, 0.5)
		data_file.writerow([str(datetime.datetime.now()),str(temperature)])
		print('Date: ' + str(datetime.datetime.now()) + ' |temperature: ' + str(temperature))