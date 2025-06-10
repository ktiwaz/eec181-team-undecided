import numpy as np

import cv2
import matplotlib.pyplot as plt
import time


folder = "./"
file = "d8m_paddle_480x640.png"
outfile_name = "d8m_paddle_480x640"

inpath = folder + file
outpath = folder + outfile_name + ".txt"

img = cv2.imread(inpath)
img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

v,h,c = img.shape
print("Image Shape: ", img.shape)

outfile = open(outpath, "w")

settingStr = str(v)+","+str(h)+"\n"

outfile.write(settingStr)

for i in range(v):
	row_pixels = img[i].reshape(-1).tolist()  # flatten each row
	row_str = ",".join(map(str, row_pixels))
	outfile.write(row_str + "\n")
