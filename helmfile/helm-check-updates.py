import re
import base64
import zlib
import json
import subprocess
import argparse
from semver import Version

def get_current_charts(n, **kwargs):
    status = subprocess.run(["helm", "-n", n, "list", "-o", "json"], capture_output=True)

    return json.loads(status.stdout.decode("utf-8"))

def get_chart_release(name, **kwargs):
    status = subprocess.run(["helm", "search", "repo", "-r",  name, "-o", "json"], capture_output=True)

    data = json.loads(status.stdout.decode("utf-8"))

    return [(x["name"], Version.parse(x["version"])) for x in data]

parser = argparse.ArgumentParser()

parser.add_argument("-n", help="Namespace to check", default="default")

args = vars(parser.parse_args())

subprocess.run(["helm", "repo", "update"], capture_output=True)

current = get_current_charts(**args)

for x in current:
    candidates = get_chart_release(x["name"])

    current_version = Version.parse(x["chart"].split("-")[-1])

    for name, version in candidates:
        if version > current_version:
            print(f"Chart {x['name']!r} has possible update from {name!r} version {version!s}")
