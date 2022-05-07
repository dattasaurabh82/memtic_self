#!/usr/bin/env python

'''
Outputs a labeled image along with a JSON snippet that includes
each label and its coordinates within the image

1st argument while running the script: input image file
2nd argument while running the scripr: output json file

Note: 
1. Create an account in deepai.org
2. Choose "densecap API" and get API KEY
3. Create a ".env" file in this location
4. add DenseCapKey=<YOUR API KEY>

----------------------------------------------------- 
Author: Saurabh Datta
Date: 03/11/2020
Loc: Beijing, China.
Project: https://www.dattasaurabh.com/mi-e-metic-self
git: https://github.com/dattasaurabh82/memtic_self
License: MIT
-----------------------------------------------------
'''


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


