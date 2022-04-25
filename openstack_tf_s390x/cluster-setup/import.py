#!/usr/bin/env python3
"""
python3 import.py -a import -c cluster_ABC
python3 import.py -a check  -c cluster_ABC
"""

import os
import argparse
import requests
from time import sleep
from urllib3.exceptions import InsecureRequestWarning
from urllib import request

# Suppress only the single warning from urllib3 needed
requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)

# For request.urlretrieve insecure https
import ssl
ssl._create_default_https_context = ssl._create_unverified_context

# from http.client import HTTPConnection
# HTTPConnection.debuglevel = 1

URL = os.getenv("RANCHER_URL") or "" # https://10.161.129.12.nip.io

# allowed chars are [.-a-z0-9]
def getClusterName(dirName):
	return "cluster-" + dirName[-3:].lower()

# Create session and login
def login():
	global s

	# === Setup session
	s = requests.Session()
	s.verify = False
	s.headers = {"Accept": "application/json", "Content-Type": "application/json"}

	# === Login
	loginUrl = f'{URL}/v3-public/localProviders/local?action=login'
	loginData = {'username' : 'admin', 'password' :  'sa', 'responseType' : 'cookie'}
	r = s.post(loginUrl, json = loginData)

	# === Set server-url
	serverUrl = f'{URL}/v3/settings/server-url'
	serverData = {'name' : '"server-url"', 'value' :  URL}
	r = s.put(serverUrl, json = serverData)


# Create imported cluster and get kubectl import command
def action_import(dirName):
	name = getClusterName(dirName)
	# === Create import yaml
	importData = {'type': 'provisioning.cattle.io.cluster', 'metadata': { 'namespace': 'fleet-default', 'name': name }, 'spec': {}}
	r = s.post(f'{URL}/v1/provisioning.cattle.io.clusters', json = importData)
	sleep(10)

	# Translate cluster (name) -> clusterName (c-m-4lxvqrm6) -> insecureCommand (kubectl apply -f ...)
	r = s.get(f'{URL}/v1/provisioning.cattle.io.clusters/fleet-default/{name}')
	clusterName = r.json()["status"]["clusterName"]

	# Save import yaml
	r = s.get(f'{URL}/v3/clusterRegistrationTokens/{clusterName}:default-token')
	yamlUrl = r.json()["command"].split(' ')[-1]	# kubectl apply -f <yamlUrl>
	request.urlretrieve(yamlUrl, 'import.yaml')

	# print(os.getcwd(), '..', dirName, 'import.yaml') # replacement for bash mv


# Check cluster was imported and is active
def action_check(dirName):
	name = getClusterName(dirName)
	# pending -> waiting -> active
	for i in range(10):
		r = s.get(f'{URL}/v1/provisioning.cattle.io.clusters/fleet-default/{name}')
		state = r.json()["metadata"]["state"]["name"]
		print(f'{name}: {state}')
		if state == "active":
			exit(0)
		else:
			sleep(10)
	exit(2)


""" Main entry point of the app """
def main(args):
	login()
	if args.action == 'import': action_import(args.cluster)
	elif args.action == 'check': action_check(args.cluster)
	else: exit(2)


if __name__ == "__main__":
	# Input parameters
	parser = argparse.ArgumentParser()
	parser.add_argument("-a", "--action", help="Rancher action to execute [import|check]", required=True)
	parser.add_argument("-c", "--cluster", help="Imported cluster from dir <cluster_ABC>", required=True)
	args = parser.parse_args()
	main(args)
