import sys
import Adafruit_DHT
import csv
import random
with open('data.csv', mode='w') as data_file:
	data_file = csv.writer(data_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
	data_file.writerow(['temperature'])
	while True:
		humidity, temperature = Adafruit_DHT.read_retry(22,4)
		temperature = temperature + random.uniform(-0.5, 0.5)
		data_file.writerow([str(temperature)])
		print('temperature: ' + str(temperature) +  ' °C | Humidity: ' + str(humidity))