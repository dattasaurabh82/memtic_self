#!/usr/bin/env python

import urllib
import requests
import sys
import json
import os

# Load the keys from env
from dotenv import load_dotenv 
load_dotenv() 

search_item = sys.argv[1]
# handle: Querry string too long (Maximum length: 50 chars)
if len(search_item) > 50:
	search_item = search_item[:50]
search_item = search_item.replace(' ', '+') # prepare for the api uri endpoint

output_file = sys.argv[2]
search_res_quan = 1


giphy_search_header_url = 'http://api.giphy.com/v1/gifs/search?q=' + search_item
giphy_api_key = os.environ.get('GiphyKey')
giphy_search_end_point = '&api_key=' + giphy_api_key + '&limit=' + str(search_res_quan)
api_call_uri = giphy_search_header_url + giphy_search_end_point



def main():
	global api_call_uri
	
	try:
		response = requests.get(api_call_uri)
		data = response.json()
		# print(json.dumps(data, sort_keys=True, indent=4))
		if (response.raise_for_status() is None and
			response.status_code == 200 and 
			data["meta"]["msg"] == "OK"):
			try: 
				with open(output_file, 'w') as jf:
					json.dump(data, jf, indent=4, sort_keys=True)
				print ("Worked!")
			except IOError as err:
				print("Failed to write giphy's response to output file")
				print(err)
		else:
			print ("Didn't work!")
			res = '{"result":"error"}'
			print(res)
			# TBD
	except requests.exceptions.RequestException as err:
		print(err)
		res = '{"result":"error"}'
		print(res)



if __name__ == '__main__':
	main()

