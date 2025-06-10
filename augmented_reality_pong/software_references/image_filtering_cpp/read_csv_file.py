import numpy as np
import matplotlib.pyplot as plt

folder = "./"

csv_file = "d8m_paddle_640x480.txt_result.csv"
filteredImg = np.loadtxt(folder+csv_file, delimiter=',', dtype=int)
print(filteredImg.shape)

plt.axis('off')
plt.imshow(filteredImg, cmap="gray")

plt.savefig(folder+"./d8m_paddle_640x480_Cpp.png")

