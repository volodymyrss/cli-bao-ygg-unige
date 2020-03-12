#!/usr/bin/env python

import binascii
import jwt
import json
import sys
import time
import pytest
import requests
import keyring

import click

@click.command()
@click.option("-o","--output", default=None)
def gen(output):
    secret=binascii.unhexlify(keyring.get_password("dataapi", "secret").strip())
    #secret=binascii.unhexlify(open("secret","r").read().strip())


    data = {
    }

    data['lastName']="myself"
    data['emailAddress']="v@odahub.io"

    data['exp']=int(time.time()+700000)

    cjwt=jwt.encode(data, key=secret)

    if output is None:
        f=sys.stdout
    else:
        f=open(output,"wt")

    f.write(cjwt.decode())

    payload={"action": "new token", "event": "done"}

    r=requests.post("https://data.odahub.io/secure/log", cookies=dict(rampartjwt=cjwt.decode()), data=json.dumps(payload), headers={'content-type': 'application/json'})
    print(r.status_code)
    print(r.content)
    print(r.headers)



if __name__ == "__main__":
    gen()
