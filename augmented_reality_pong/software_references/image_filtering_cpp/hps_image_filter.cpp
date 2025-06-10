
#include <iostream>

#include <chrono>
#include <ratio>

#include <cmath>
#include <string>
#include <algorithm>
#include <stdio.h>

#include <iostream>
#include <iomanip>
#include <fstream>

#include <string>
#include <initializer_list>
#include <cstdint>
#include <sstream>

// Type Aliases
typedef std::chrono::duration<double> timespan;

// Sim parameters
const int ITERATIONS = 120;
const int NEIGHBOR_THRESHOLD = 22;
const int FILTER_SIZE = 5;
const int W = FILTER_SIZE / 2;

const std::string folder = "./";

// Struct & Function Declarations
struct HSV{
    float H;
    float S;
    float V;
};


HSV convertToHSV(int R, int G, int B);
uint8_t* read_image_into_memory(std::string& path, int* r, int* c);
uint8_t* process_image(uint8_t* img, int rows, int cols, bool print, std::chrono::system_clock& Clock);
void write_final_image_to_csv(std::string& path, uint8_t* final_image, int rows, int cols);


int main(){
    
    // Initialize clock
    auto Clock = std::chrono::system_clock();

    auto startTime = Clock.now();

    // Image names and file paths
    std::string file1 = "d8m_paddle_640x480.txt";
    std::string file2 = "d8m_paddle2.txt";

    std::string path1 = folder + file1;
    std::string path2 = folder + file2;

    // Row and Col indices in image
    int rows;
    int cols;

    int rows2;
    int cols2;

    // Memory Allocation & Loading Image Data
    uint8_t* img = nullptr;  
    uint8_t* img2 = nullptr;
    uint8_t* final_img = nullptr;
    uint8_t* final_img2 = nullptr;
    
    img = read_image_into_memory(path1, &rows, &cols);
    img2 = read_image_into_memory(path2, &rows2, &cols2);


    // Tests
    auto itrsBegin = Clock.now();

    for (int i = 0; i < ITERATIONS; ++i){
        if (i % 2 == 0){
            final_img = process_image(img, rows, cols, true, Clock);
            delete [] final_img;
        }
        else{
            final_img2 = process_image(img2, rows2, cols2, true, Clock);
            delete [] final_img2;
        }
    }

    auto itrsEnd = Clock.now();

    //Process a final image (unclocked) to verify output visually
    final_img = process_image(img2, rows2, cols2, true, Clock);

    // writing output image data to CSV
    std::string outpath = folder + file2 + "_result.csv";
    write_final_image_to_csv(outpath, final_img, rows, cols);

    auto endTime = Clock.now();

    // Output Test Runtime (time spent on the ITERATIONS loop only)
    timespan itrsRuntime = std::chrono::duration_cast<timespan>(itrsEnd-itrsBegin);
    std::cout << "Test Runtime: " << itrsRuntime.count() << " seconds."<< std::endl;

    // Record Total Runtime (not particularly relevant, initially wanted to see impact of reading in data to memory)
    timespan totalRuntime = std::chrono::duration_cast<timespan>(endTime-startTime);
    std::cout << "Total Runtime: " << totalRuntime.count() << " seconds."<< std::endl;

    // Clean memory:
    delete[] img;
    delete[] img2;
    delete[] final_img;

    return 0;
};


HSV convertToHSV(int R, int G, int B) {
    HSV color;
    
    int max = std::max(R,G);
    max = std::max(max, B);

    int min = std::min(R,G);
    min = std::min(B, min);

    int diff = max - min;

    if (max == 0){
        color.H = 0;
    }
    else if (max == R){
        color.H = G - B;
    }
    else if (max == G){
        color.H = 2*diff + B - R;
    }
    else if (max == B) {
        color.H = 4*diff + R - G;
    }
    else{
        color.H = 4*diff + R - G;
    }
    
    color.S = diff;
    color.V = max;

    return color;
}

uint8_t* read_image_into_memory(std::string& path, int* r, int* c) {
     // Open file, and get file format
    std::ifstream pFilePtr(path.c_str());

    if (!pFilePtr){
        std::cout << "Unable to open file " << path << std::endl;
        exit(1);
    }
    
    // Read size from file
    std::string settingsBuffer;

    std::getline(pFilePtr, settingsBuffer);

    std::string shapeLine(settingsBuffer);
    auto pos = shapeLine.find(",");
    int rows = std::stoi(shapeLine.substr(0, pos));
    int cols = std::stoi(shapeLine.substr(pos+1, shapeLine.length()));

    *r = rows;
    *c = cols;  // saves row & col counts to ptrs for future reference

    std::cout << rows << "," << cols << std::endl;

    std::string pixel;

    // Read file data
    uint8_t* img = new uint8_t[rows*cols*3];

    int img_index = 0;
    int img_rows = 0;
    int img_col_entries = 0;

    std::string line;

    // load image
    std::getline(pFilePtr, line);
    while (!pFilePtr.eof()){
        ++img_rows;
        img_col_entries = 0;
        std::stringstream ss(line);
        
        std::getline(ss, pixel, ',');  // gets content up to comma from line

        while (!ss.eof()){  // cycle until end of line is reached
            ++img_col_entries;
            int pxl = std::stoi(pixel);
            uint8_t pxl_8 = (uint8_t) pxl;

            
            img[img_index] = pxl_8;
            img_index += 1;
            std::getline(ss, pixel, ',');
        }
        ++img_col_entries;  // remaining content after last comma is processed
        int pxl = std::stoi(pixel);
        uint8_t pxl_8 = (uint8_t) pxl;

        
        img[img_index] = pxl_8;
        img_index += 1;
        
        // Check for unexpected row size
        if (img_col_entries != 3*cols){
            std::cout << "Unexpected entries on row " << img_rows << ".";
            std::cout << "Expected " << 3*cols << ", got " << img_col_entries << std::endl;
        }

        std::getline(pFilePtr, line);
    }

    if (img_rows != rows){
    std::cout << "Unexpected row count: Got " << img_rows << ", expected " << rows << std::endl;
    }

    pFilePtr.close();

    return img;

};


uint8_t* process_image(uint8_t* img, int rows, int cols, bool print, std::chrono::system_clock& Clock){
    /* 
    Convert RGB Data to HSV and filter for target pixel color (red)
    */

    uint8_t red;
    uint8_t green;
    uint8_t blue;

    int index = 0;
    int colorFilteredIndex = 0;

    uint8_t* colorfiltedimg = new uint8_t[rows*cols];
    uint8_t* finalimg = new uint8_t[rows*cols];

    auto colorProcessStartTime = Clock.now();

    // Color Filtering
    for (int r = 0; r < rows; ++r){
        for (int c = 0; c < cols; ++c){
            red = img[r*cols*3 + c*3];
            green = img[index+1];
            blue = img[index+2];

            HSV hsv = convertToHSV(red, green, blue);

            float Hu_R = 0.25 * hsv.S;
            float Hd_R = 0;

            float Vthresh_R = 0.5 * hsv.V;

            if (hsv.H > Hd_R && hsv.H < Hu_R && hsv.S > Vthresh_R) {
                colorfiltedimg[colorFilteredIndex] = (uint8_t) 1;
            }
            else {
                colorfiltedimg[r*cols + c] = (uint8_t) red;
            }

            index += 3;
            colorFilteredIndex += 1;
        }
    }
    auto colorProcessEndTime = Clock.now();


    /*
    Morphological filtering of outputs
    */
    int startR;
    int endR;
    int startC;
    int endC;
    int count;
    int readVal;

    for (int r = 0; r < rows; ++r){
        startR = std::max(0, r-W);
        endR = std::min(rows-1, r+W);
        for (int c = 0; c < cols; ++c){
            startC = std::max(0, c-W);
            endC = std::min(cols-1, c+W);

            count = 0; // reset count
 
            for (int ic = startR; ic <= endR; ++ic){
                for (int jc = startC; jc <= endC; ++jc){
                    int index = ic * cols + jc;
                    readVal = colorfiltedimg[index];
                    if (readVal == 1){
                        ++count;
                    }
                }
            }


            uint8_t result = 0;
            if (count >= NEIGHBOR_THRESHOLD) {
                result = 1;
            }
            finalimg[r*cols+c] = result;

        }
    }

    auto morphologicalEndTime = Clock.now();

    // Timing information for individual tests
    if (print==true){
        timespan colorFilterRuntime = std::chrono::duration_cast<timespan>(colorProcessEndTime-colorProcessStartTime);
        timespan morphRuntime = std::chrono::duration_cast<timespan>(morphologicalEndTime-colorProcessEndTime);

        timespan filterRuntime = std::chrono::duration_cast<timespan>(morphologicalEndTime-colorProcessStartTime);

        std::cout << "Color Filter Runtime: " << colorFilterRuntime.count() << " seconds."<< std::endl;
        std::cout << "Morphological Filter Runtime: " << morphRuntime.count() << " seconds."<< std::endl;
        std::cout << "Filter Runtime: " << filterRuntime.count() << " seconds."<< std::endl;

    }

    delete[] colorfiltedimg; // clears the color filtered image; img and final image remain for future reference

    return finalimg;
}

void write_final_image_to_csv(std::string& path, uint8_t* final_image, int rows, int cols){
     // writing output image data to CSV

    std::string outpath = path;
    std::ofstream outFilePtr(outpath.c_str());

    if (!outFilePtr.is_open()){
        std::cout << "Unable to open file " << path << std::endl;
        exit(1);
    }

    for (int r = 0; r < rows; ++r) {
        for (int c = 0; c < cols; ++c){
            outFilePtr <<  (int) final_image[r*cols+c];
            if (c == cols - 1) {
                outFilePtr << std::endl;
                outFilePtr.flush();
            }
            else {
                outFilePtr << ",";
            }

        }
    }

     outFilePtr.close();
}
