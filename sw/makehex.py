#!/usr/bin/env python3
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.

import sys

if len(sys.argv) < 2:
    sys.stderr.write("usage: makehex.py <bin> [nwords]\n")
    sys.exit(1)

nwords = int(sys.argv[2]) if len(sys.argv) > 2 else None

words = []
with open(sys.argv[1], "rb") as f:
    cnt = 3
    s = ["00"] * 4
    while True:
        data = f.read(1)
        if not data:
            words.append("".join(s))
            break
        s[cnt] = "{:02X}".format(data[0])
        if cnt == 0:
            words.append("".join(s))
            s = ["00"] * 4
            cnt = 4
        cnt -= 1

if nwords is not None:
    if len(words) > nwords:
        sys.stderr.write("image has {} words; max is {}\n".format(len(words), nwords))
        sys.exit(1)
    words.extend(["00000000"] * (nwords - len(words)))

for w in words:
    print(w)
