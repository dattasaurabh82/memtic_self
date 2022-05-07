#!/usr/bin/env python

import sys
import os
import paho.mqtt.client as mqtt
import time


mounted = False

network_loc = "192.168.10.60:/home/nuc/GIF"
mount_point = "/home/pi/gifs"

def mount_gif_dir():
	global network_loc
	global mount_point
	# "sudo mount -o rw,soft 192.168.10.60:/home/nuc/GIF /home/pi/gifs"
	# mount_cmd = "sudo mount -a"
	mount_cmd = "sudo mount -o rw,soft" + " " + network_loc + " " + mount_point
	os.system(mount_cmd)
	time.sleep(2)


def kill_omxplayer():
	# kill old oma player instances
	os.system("pkill omxplayer")
	# time.sleep(1)
	os.system("pkill omxplayer.bin")
	# time.sleep(1)


def clean_start_OMX_PLayer():
	# start and loop an instance of omx player
	# os.system("/usr/bin/omxplayer --no-osd --fps 1 --timeout 20 --loop /home/pi/gifs/gif.mp4 &")
	os.system("/usr/bin/omxplayer --no-osd --loop /home/pi/gifs/gif.mp4 &")


def show_downloadFailureGIF():
	os.system("pkill omxplayer")
	os.system("pkill omxplayer.bin")
	os.system("/usr/bin/omxplayer --no-osd --loop /home/pi/gifs/download_failed.mp4 &")

def show_imgDataFailureGIF():
	os.system("pkill omxplayer")
	os.system("pkill omxplayer.bin")
	os.system("/usr/bin/omxplayer --no-osd --loop /home/pi/gifs/caption_api_failed.mp4 &")




def on_connect(client, userdata, flags, rc):
	# print("Connected with result code "+str(rc))
	# Subscribing in on_connect() means that if we lose the connection and
	# reconnect then subscriptions will be renewed.
	client.subscribe("NUC_SERVER")


def on_message(client, userdata, msg):
	payload = str(msg.payload.decode("utf-8"))
	print(payload)
	if payload == "downloading":
		# kill all omx player
		kill_omxplayer()
	if payload == "mount":
		# print("mount ntfs drive")
		mount_gif_dir()
		time.sleep(1)
		client.publish("PI_TV", "mounted");
	if payload == "play":
		client.publish("PI_TV", "playing GIF");
		# time.sleep(1)
		clean_start_OMX_PLayer()
		# print("looping omx player")
	if payload == "scene_recognition_failed":
		# show a default gif
		show_imgDataFailureGIF()
	if payload == "download_failed":
		# show a default gif
		show_downloadFailureGIF()





CLIENT_ID = "omx_player_manager"
BROKER_ADDR = "192.168.10.61"
BROKER_PORT = 1560




def main():
	global CLIENT_ID
	global BROKER_ADDR
	global BROKER_PORT

	client = mqtt.Client(CLIENT_ID)

	client.on_connect = on_connect
	client.on_message = on_message

	client.connect(BROKER_ADDR, port=BROKER_PORT, keepalive=60, bind_address="")

	client.loop_start()

	while True:
		test = 1


if __name__ == '__main__':
	main()

