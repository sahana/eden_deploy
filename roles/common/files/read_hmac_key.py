#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Assumes default appname for setup!
input = os.path.join("/", "home", "setup", "applications", "eden", "models", "000_config.py")
inputFile = open(input, "r")
output = os.path.join("/", "tmp", "hmac_key")
outputFile = open(output, "w")

key = 'settings.auth.hmac_key = "'
for line in inputFile:
    if line.startswith(key):
        hmac_key = line.split(key)[1].split('"')[0]
        outputFile.write(hmac_key)
        break

inputFile.close()
outputFile.close()
