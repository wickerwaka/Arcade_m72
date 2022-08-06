import sys

low = open(sys.argv[1], "rb").read()
high = open(sys.argv[2], "rb").read()

with open(sys.argv[3], "wb") as fp:
    for l, h in zip(low, high):
        fp.write(bytes([l]))
        fp.write(bytes([h]))

