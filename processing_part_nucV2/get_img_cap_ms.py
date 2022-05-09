#!/usr/bin/env python3

'''
New python script to use Microsoft Azure computer vision API
1. Caption generation
2. Object detection
as alternative method to, previously used and now deprecated
densecap api (https://deepai.org/machine-learning-model/densecap)

It returns the output json in the same schema as densecap api returned. 
This way we do not have to change anything for parsing data 
in processing sketch side.

1st argument while running the script: input image file
2nd argument while running the scripr: output json file

Note: 
1. Create an Computer visison APP in Microsoft Azure cloud. 
2. Get the API key. 
3. Create a (or use the existing) ".env" file in this location. 
4. add AzureKey=<YOUR API KEY>

----------------------------------------------------- 
Author: Saurabh Datta
Date: 07/05/2022
Loc: Beijing, China.
Project: https://www.dattasaurabh.com/mi-e-metic-self
git: https://github.com/dattasaurabh82/memtic_self
License: MIT
-----------------------------------------------------
'''

import requests
import sys
import json
from time import sleep
import logging


import os

# Load the keys from env
from dotenv import load_dotenv 
load_dotenv()  


input_img_file_path = sys.argv[1]
merged_output_file = sys.argv[2]

curr_dir = os.path.dirname(os.path.realpath(__file__)) + "/"
caption_res_file = curr_dir + "img_cap_data.json"
object_detection_res_file = curr_dir + "img_od_data.json"

log_file = curr_dir + 'pyscpt.log'
logging.basicConfig(
	level=logging.DEBUG,
	filename=log_file, 
	filemode='w', 
	format='%(process)d - %(asctime)s - %(levelname)s - %(message)s'
)


# MS Azure Vision API related props
subs_key = os.environ.get('AzureKey')
assert subs_key
region = 'eastasia'
max_candidates='10'
language='en'


# -- caption generation API call params -- #
cap_service_base_url = "https://"+region+".api.cognitive.microsoft.com/vision/v3.2/describe?%s"
cap_service_params={
	'maxCandidates': max_candidates, 
	'language': language, 
	'model-version': 'latest'
	}

# -- object detection API call params -- #
od_service_base_url = "https://"+region+".api.cognitive.microsoft.com/vision/v3.2/detect?%s"
od_service_params={'model-version': 'latest'}


# -- common headers for both API calls -- #
headers={
	'Ocp-Apim-Subscription-Key':subs_key, 
	'Content-Type':'application/octet-stream'
	}


def post_req(_base_url, _headers, _params, _input_data_path, _res_out_file):
	data_file = None
	try:
		data_file = open(_input_data_path, 'rb')
		try:
			req = requests.post(
				_base_url, 
				headers=_headers, 
				params=_params, 
				data=data_file
			)

			if (req.raise_for_status() is None and 
			req.raise_for_status() is not False and 
			req.status_code == 200):
				res = req.json()
				with open(_res_out_file, 'w') as f:
					json.dump(res, f, indent=4, sort_keys=True)
				return True
			else:
				# --> err or bad response
				logging.error("Bad POST request's response")
				print("Bad POST request's response")
				return False
		except requests.exceptions.RequestException as err:
			# --> exception during making request (POST)
			logging.exception("Bad POST request: unsuccessful!")
			print("Bad POST request: unsuccessful!")
			print("----------------\n")
			print (err)
			return False
	except IOError as err:
		# --> file open error
		logging.exception("Image file loading err")
		print("Image file loading err")
		print("----------------------\n")
		print(err)
		return False



def got_captions(_input_file_path, _captions_res_file):
	# -------------------------------- #
	# -- image caption REST methods -- #
	# -------------------------------- #
	global headers
	global cap_service_base_url
	global cap_service_params

	made_captions_api_req = post_req(
		cap_service_base_url, 
		headers, 
		cap_service_params, 
		_input_file_path, 
		_captions_res_file
	)

	if (made_captions_api_req):
		# ----------------------------------------------------- #
		# -- check if we have, atleast, more than 0 captions -- #
		# ----------------------------------------------------- #
		# 1. load the file to which API post req data was written to
		# 2. Check the length of the captions list
		# 3. Based on that make adjustments and handle edge cases
		try:
			cap_data_jf = open(_captions_res_file)
			cap_data = json.load(cap_data_jf)
			if len(cap_data["description"]["captions"]) > 0:
				
				# Handle [EDGE CASE] "no image" when returned as the only caption
				# Note: We can still use it for the gif :)
				# So return True in any case & no need to add anything
				if (len(cap_data["description"]["captions"]) == 1 and 
					cap_data["description"]["captions"][0]["text"] == "no image"):
					logging.warning("No caption/s found!")
					logging.info("Returned caption in captions array, says: \"no image\"")
					print("No caption/s found!")
					print("Returned caption in captions array, says: \"no image\"")
				else:
					logging.info("Verified, we have captions!")
					print("Verified, we have captions!")
				return True
			else:
				# Handle [EDGE CASE], captions array empty
				logging.warning("We don't have captions ... [returned captions array empty]")
				logging.info("Generating placeholder empty caption...")
				print("We don't have captions ... [returned captions array empty]")
				print("Generating placeholder empty caption...")
	
				cap_data["description"]["captions"][0]["text"] = "no image"
				cap_data["description"]["captions"][0]["confidence"] = 1.00
				# After adjustment write back
				with open(_captions_res_file, 'w') as f:
					json.dump(cap_data, f, indent=4, sort_keys=True)
				return True
		except IOError as err:
			# --> the prev written file can't be loaded & read from
			logging.exception("Failed to load gathered captions response file")
			print("[",got_captions.__name__, "] Failed to load gathered \
				captions response file\n\
				to check if we have captions or not!\n")
			print (err)
			return False
	else:
		return False



def got_bounding_boxes(_input_file_path, _bb_res_file):
	# ---------------------------------------- #
	# -- object bounding boxes REST methods -- #
	# ---------------------------------------- #
	global headers
	global od_service_base_url
	global od_service_params

	made_object_detection_api_req = post_req(
		od_service_base_url,
		headers,
		od_service_params,
		_input_file_path,
		_bb_res_file
	)

	if (made_object_detection_api_req):
		# ------------------------------------------------------------ #
		# -- check if we have, atleast, more than 0 object detected -- #
		# ------------------------------------------------------------ #
		# 1. load the file to which API post req data was written to
		# 2. Check the length of the object's list
		# 3. Based on that make adjustments and handle edge cases
		try:
			bb_data_jf = open(_bb_res_file)
			bb_data = json.load(bb_data_jf)
			if len(bb_data["objects"]) > 0:
				logging.info("Verified, we have bounding boxes from object detection!")
				print("Verified, we have bounding boxes from object detection!")
			else:
				# Handle [EDGE CASE], objects array empty
				logging.warning("No objects detected ... [returned object's array empty]")
				print("No objects detected ... [returned object's array empty]")
				logging.info("Generating placeholder empty fixed object ...")
				print("Generating placeholder empty fixed object ...")
				
				rect_data = {}
				rect_data["rectangle"] = {}
				rect_data["rectangle"]["x"] = 10  # fixed loc
				rect_data["rectangle"]["y"] = 10  # fixed loc
				rect_data["rectangle"]["w"] = 100 # fixed size
				rect_data["rectangle"]["h"] = 100 # fixed size
				bb_data["objects"].append(rect_data)
				bb_data["objects"][0]["object"] = "None"
				bb_data["objects"][0]["confidence"] = 1.00
				# After adjustment write back
				with open(_bb_res_file, 'w') as f:
					json.dump(bb_data, f, indent=4, sort_keys=True)
			return True
		except IOError as err:
			# --> the prev written file can't be loaded & read from
			logging.exception("Failed to load gathered object detection response file")
			print("[",got_bounding_boxes.__name__, "] Failed to load gathered \
				object detection response file\n\
				to check if we have cobjects and respective bounding boxes!\n")
			print (err)
			return False
	else:
		return False


def load_and_merge_data(_captions_res_file, _bb_res_file, _merged_output_file):
	# ---------------------------------------------------------- #
	# Load and merge data from both files into 1, by reshaping it 
	# into ** suspended deepai densecap API's response pattern
	# ---------------------------------------------------------- #
	try:
		cap_data_jf = open(_captions_res_file)
		cap_data = json.load(cap_data_jf)
		cap_data_jf.close()
	except IOError as err:
		#  --> the prev written file can't be loaded & read from
		logging.exception("Failed to load gathered captions response file")
		print("[",load_and_merge_data.__name__, "] Failed to load gathered \
			captions response file\n\
			to check if we have captions or not!\n")
		print (err)
	
	try:
		bb_data_jf = open(_bb_res_file)
		bb_data = json.load(bb_data_jf)
		bb_data_jf.close()
	except IOError as err:
		# --> the prev written file can't be loaded & read from
		logging.exception("Failed to load gathered object detection response file")
		print("[",load_and_merge_data.__name__, "] Failed to load gathered \
			object detection response file\n\
			to check if we have cobjects and respective bounding boxes!\n")
		print (err)

	# --- FOR DEBUGGING --- #
	# print("\nAzure Cloud Captions API raw response")
	# print("\n")
	# print(json.dump(cap_data, indent=4, sort_keys=True))
	# print("\nAzure Cloud Object detection API raw response")
	# print(json.dump(bb_data, indent=4, sort_keys=True))
	# print("\n")
	# --------------------- #

	# -------------------------------------------------------------------------- #
	# --- Cleanup & rename some unnecessary fields to match old api repsonse --- #
	# -------------------------------------------------------------------------- #
	# 1. change "description" to "output"
	cap_data["output"] = cap_data.pop("description")
	# 2. change "requestId" to "id"
	cap_data["id"] = cap_data.pop("requestId")
	# 3. change all output.captions.text to output.captions.caption
	for cd in cap_data["output"]["captions"]:
		cd["caption"] = cd.pop("text")
	# 4. remove key: metadata and it's values
	del cap_data["metadata"]
	# 5. remove key: modelVersion and it's values
	del cap_data["modelVersion"]
	# 6. remove key: output.tags and it's values
	del cap_data["output"]["tags"]

	# -------------------------------------------------------------------------- #
	# --- [WIP] resolve for unqual numbers of captions and object detections --- #
	# -------------------------------------------------------------------------- #
	if len(bb_data["objects"]) >= len(cap_data["output"]["captions"]):
		# Take the bounding box data of objects detected and add as new entry to the captions
		if len(bb_data["objects"]) == len(cap_data["output"]["captions"]):
			logging.info("Objects detected and captions generated are of same quantity")
			print("Objects detected and captions generated are of same quantity")
			logging.info("Adding detected object's bounding box data to json")
			print("Adding detected object's bounding box data to json")
			
			for i in range(0, len(cap_data["output"]["captions"])):
				cap_data["output"]["captions"][i]["bounding_box"] = [
					bb_data["objects"][i]["rectangle"]["x"],
					bb_data["objects"][i]["rectangle"]["y"],
					bb_data["objects"][i]["rectangle"]["w"],
					bb_data["objects"][i]["rectangle"]["h"]
				]
		if len(bb_data["objects"]) > len(cap_data["output"]["captions"]):
			logging.info("Objects detected are more than generated captions")
			print("Objects detected are more than generated captions")
			
			# transfer all the bounding box data to the final reshaped json data
			logging.info("Reshaping output json based on length of objects")
			print("Reshaping output json based on length of objects")		
			
			# Create multiple duplicate entries of of a json object of captions and confidence
			# So that the length of captions array is same a bounding box data array
			# ** Just repeat the first caption in those entries, for caption's value.  
			logging.info("Duplicating captions to make captions array len same as objects detected len")
			print("Duplicating captions to make captions array len same as objects detected len")
			
			rem_caps_count = len(bb_data["objects"]) - len(cap_data["output"]["captions"])
			for i in range(0, rem_caps_count):
				dup_cap = cap_data["output"]["captions"][0]["caption"]
				dup_conf = cap_data["output"]["captions"][0]["confidence"]
				cap_data["output"]["captions"].append({"caption": dup_cap, "confidence": dup_conf})
			
			logging.info("Adding detected object's bounding box data to json")
			print("Adding detected object's bounding box data to json")
			
			for i in range(0, len(cap_data["output"]["captions"])):
				cap_data["output"]["captions"][i]["bounding_box"] = [
					bb_data["objects"][i]["rectangle"]["x"],
					bb_data["objects"][i]["rectangle"]["y"],
					bb_data["objects"][i]["rectangle"]["w"],
					bb_data["objects"][i]["rectangle"]["h"]
				]
	if len(bb_data["objects"]) < len(cap_data["output"]["captions"]):
		# 1. Transfer bounding box data to captions till length of bounding box
		# 2. Delete rest of entry of captions
		logging.info("Captions generated are more than objects detected")
		print("Captions generated are more than objects detected")
		logging.info("Reshaping output json based on length of objects")
		print("Reshaping output json based on length of objects")
		
		for i in range(0, len(bb_data["objects"])):
			cap_data["output"]["captions"][i]["bounding_box"] = [
				bb_data["objects"][i]["rectangle"]["x"],
				bb_data["objects"][i]["rectangle"]["y"],
				bb_data["objects"][i]["rectangle"]["w"],
				bb_data["objects"][i]["rectangle"]["h"]
			]
		rem_caps_count = len(cap_data["output"]["captions"]) - len(bb_data["objects"])
		del_start_entry_id = len(cap_data["output"]["captions"])-rem_caps_count
		for i in range(del_start_entry_id, len(cap_data["output"]["captions"])-1):
			del cap_data["output"]["captions"][i]
			# cap_data["output"]["captions"].pop(i) # alt-method
		# Delete the last item
		del cap_data["output"]["captions"][len(cap_data["output"]["captions"])-1]

	# Finally write the newly reshaped and merged data as json to the output file
	with open(_merged_output_file, "w") as jf:
		json.dump(cap_data, jf, indent=4, sort_keys=True)





def main():
	global input_img_file_path
	global caption_res_file
	global object_detection_res_file
	global merged_output_file

	# ** comment out For files merge test only
	if (got_captions(input_img_file_path, caption_res_file) is True and 
		got_bounding_boxes(input_img_file_path, object_detection_res_file) is True):
			# Load and merge data from both files into 1, by reshaping it 
			# into ** suspended deepai densecap API's response pattern
			load_and_merge_data(caption_res_file, 
				object_detection_res_file, 
				merged_output_file
			)

	# ** TEST ONLY: uncomment For files merge and reshaping output test 
	# load_and_merge_data(caption_res_file, object_detection_res_file, merged_output_file)



if __name__ == '__main__':
	main()

