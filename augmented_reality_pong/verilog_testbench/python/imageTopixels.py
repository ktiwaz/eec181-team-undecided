import sys

import numpy as np
import cv2

inputFile = ""
outputFile = ""

if len(sys.argv) <= 1:
	print("No input file given")
	quit()

elif (len(sys.argv) == 1):
	inputFile = sys.argv[1]
	outputFile = "verilog_pixels.txt"



outFD = open(outputFile, "w")


img = np.empty(1)

img = cv2.imread(inputFile)


if img is None:
	print("Error opening img at ", inputFile)
	sys.exit(1)

img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

v,h,c = img.shape

printStr = f"Loaded image of size {v}, {h} of type {img.dtype}"

for i in range(v):
	for j in range(h):
		r = img[i][j][0]
		g = img[i][j][1]
		b = img[i][j][2]

		r = hex(r)
		g = hex(g)
		b = hex(b)

		outFD.write(f"{r}, {g}, {b}\n")

outFD.close()


