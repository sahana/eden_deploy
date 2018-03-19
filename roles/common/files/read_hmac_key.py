#!/usr/bin/env python
# -*- coding: utf-8 -*-
output = os.path.join("/", "tmp", "hmac_key")
outputFile = open(output, "w")
outputFile.write(settings.get_auth_hmac_key())
outputFile.close()
