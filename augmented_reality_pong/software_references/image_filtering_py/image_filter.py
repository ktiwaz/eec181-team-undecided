import cv2
import numpy as np
import matplotlib.pyplot as plt
import time

ITERATIONS = 120

FILTER_SIZE = 5
W = FILTER_SIZE//2

folder = "./hps_img_process_model/"
file = "d8m_paddle_640x480.png"
file2 = "d8m_paddle2.png"

path = folder + file
path2 = folder + file2

NEIGHBOR_THRESHOLD = 22

def convertToHSV(R,G,B):
	maxRG = max(R, G)
	maxRGB = max(maxRG, B)

	minRG = min(R, G)
	minRGB = min(minRG, B)

	diff = maxRGB - minRGB

	if (maxRGB == 0):
		H = 0
	elif(maxRGB == R):
		H = G - B
	elif(maxRGB == G):
		H = (2 * diff) + B - R
	elif(maxRGB == B):
		H = (4 * diff) + R - G
	else:
		H = 4 * diff + R - G

	S = diff
	V = maxRGB

	return H, S, V

def processImage(img):
	v,h,c = img.shape

	imgColorFiltered = np.zeros((v,h), dtype=np.uint8)
	imgOut = np.zeros((v,h), dtype=np.uint8)
	countArr = np.zeros((v,h), dtype=np.uint8)

	#print("Image Shape: ", img.shape)
	startColorLoop = time.time()

	for i in range(v):
		for j in range(h):
			H, S, V = convertToHSV(int(img[i,j,0]), int(img[i,j,1]), int(img[i,j,2]))

			Hu_R = 0.25 * S
			Hd_R = 0

			#Hu_G = 2.25 * S
			#Hd_G = 1.75 * S

			Vthresh_R = 0.5 * V
			#Vthresh_G = 0.25 * V

			if(H > Hd_R and H < Hu_R and V>=65 and S>Vthresh_R):
				imgColorFiltered[i,j] = 1
			else:
				imgColorFiltered[i,j] = 0
	
	endColorLoop = time.time()
	startFilterLoop = time.time()

	for i in range(v):
		if (i<W):
			startR = 0
		else:
			startR = i-W

		if (i>v-W-1):
			endR = v-1
		else:
			endR = i+W+1
		

		for j in range(h):
			if (j<W):
				startC = 0
			else:
				startC = j-W

			if (j>h-W-1):
				endC = h-1
			else:
				endC = j+W+1
			
			count = 0

			neighborhood = imgColorFiltered[startR:endR, startC:endC]
			n = neighborhood.flatten()

			
			count = np.sum(n)
			#countArr[i,j] = count
		
			if count >= NEIGHBOR_THRESHOLD:  # something off here; I'm keeping the wrong pixels
				imgOut[i,j] = 1
			#else:
			#	imgOut[i,j] = 0
	
	endFilterLoop = time.time()

	if (print):
		colorFilterTime = endColorLoop - startColorLoop
		morphFilterTime = endFilterLoop - startFilterLoop

		overallTime = colorFilterTime + morphFilterTime

		print(f"Elapsed time total: {overallTime} s")
		print(f"Color Filter time total: {colorFilterTime} s")
		print(f"Morphological Filter time total: {morphFilterTime} s")
	
	return imgOut

start = time.time()

img = cv2.imread(path)
img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

img2 = cv2.imread(path2)
img2 = cv2.cvtColor(img2, cv2.COLOR_BGR2RGB)


startItrs = time.time()
for i in range(ITERATIONS):
	if (i % 2 == 0):
		processImage(img)
	else:
		processImage(img2)

endItrs = time.time()


overallTime = endItrs - start
ItrTime = endItrs - startItrs

print(f"Elapsed time total: {overallTime} s")
print(f"Elapsed time total: {ItrTime} s")


imgOut = processImage(img)

plt.axis('off')
plt.imshow(imgOut, cmap="gray")
plt.savefig(folder+"./outputFiltered.png")
