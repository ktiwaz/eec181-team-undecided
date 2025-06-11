import sys

import numpy as np
import cv2
import matplotlib.pyplot as plt

import imageFunctions as imFunc


def createBitfileForTestbench(inputFile, outputDir="."):
	outputFile = outputDir + "/verilog_pixels.txt"

	outFD = open(outputFile, "w")

	img = np.empty()
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

	print("File saved at ", outputFile)


def createBitfileForTestbenchFromArray(array, outputDir="."):
	outputFile = outputDir + "/verilog_pixels.txt"

	outFD = open(outputFile, "w")

	img = array.copy()

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

	print("File saved at ", outputFile)


def translateDumpfileToImg(dumpFile, inputImage):

	simFD = open(dumpFile, "r")

	imgOut = np.zeros_like(inputImage)

	v,h,c = imgOut.shape

	i = 0
	j = 0

	for line in simFD:
		data = line.split(",")
		if len(data) != 3:
			print(f"Error reading pixel at row {i}, col {j}")
		
		r = int(data[0], 16)
		g = int(data[1], 16)
		b = int(data[2], 16)
		
		imgOut[i][j][0] = r
		imgOut[i][j][1] = g
		imgOut[i][j][2] = b

		j += 1

		if (j >= h):
			j = 0
			i += 1
		

	print(f"Saved {i} rows of {h} pixels with {j} pixels left over")

	simFD.close()

	return imgOut


