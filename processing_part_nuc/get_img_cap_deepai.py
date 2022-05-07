#!/usr/bin/env python

import requests
import sys
import json
import os

# Load the keys from env
from dotenv import load_dotenv 
load_dotenv()  

dense_cap_end_point = 'https://api.deepai.org/api/densecap'
dense_cap_api_key = os.environ.get('DenseCapKey')


input_file_path = sys.argv[1]
output_file = sys.argv[2]

img_file = open(input_file_path, 'rb')



def main():
	global img_file
	global dense_cap_api_key
	global dense_cap_end_point

	try:
		r = requests.post(
			dense_cap_end_point, 
			files={
				'image': img_file,
			}, 
			headers={
				'api-key': dense_cap_api_key
			}
		)
	
		res = r.json()
		print (json.dumps(res, indent=4, sort_keys=True))
		with open(output_file, 'w') as jf:
			json.dump(res, jf, indent=4, sort_keys=True)
		print ("worked")
	except:
		res = '{"result":"error"}'
		print(res)




if __name__ == '__main__':
	main()


