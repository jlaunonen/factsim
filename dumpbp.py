#!/usr/bin/env python

import base64
import json
import sys
import zlib


def main():
    if sys.stdin.isatty():
        print("usage: cat blueprint.bp | ./dumpbp.py")
        exit(1)

    i = sys.stdin.read().strip()
    if not i:
        print("Invalid blueprint string on stdin")
        exit(1)

    if i[0] != "0":
        print("Unknown blueprint string format")
        exit(1)

    zl = base64.b64decode(i[1:])
    json_bytes = zlib.decompress(zl)
    doc = json.loads(json_bytes.decode("utf-8"))

    print(json.dumps(doc, indent=4))


if __name__ == "__main__":
    main()
