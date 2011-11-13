import processing.video.*;
import processing.serial.*;

int gridSizeX = 4;
int gridSizeY = 3;
int freqMin = 1;
int freqMax = 75;
int framesPerSec = 30;
// String mapping = "average";
String mapping = "linear";
//String mapping = "exponential";
int historySize = 15;
boolean movingAverage = false;
boolean useBinning = true;
int binSize = 255;
boolean useDifference = true;
boolean useSerial = true;


Capture v;
Serial serial;

int historyIndex = 0;
float[][][] cellHistory = new float[gridSizeX][gridSizeY][historySize];
float[][] processedCells = new float[gridSizeX][gridSizeY];
//float[][] lastProcessedCells = new float[gridSizeX][gridSizeY];
float[][] cells = new float[gridSizeX][gridSizeY];
//int[] lastPixels = new int[v.width * v.height];
int cellW,cellH,halfCellW,halfCellH,quartCellW,quartCellH;
int xcell,ycell;
int logFreqMax;
boolean isCapturing;
float e=2.71828;
float lightThreshold = .4;

/*
int[] updateDifferenceMatrix() {
  new int
  for (int i = 0; i < v.width*v.height; i++) { // For each pixel in the video frame...
      // Fetch the current color in that location, and also the color
      // of the background in that spot
      color currColor = v.pixels[i];
      color lastColor = lastPixels[i];
      // Extract the red, green, and blue components of the current pixel’s color
      int currR = (currColor >> 16) & 0xFF;
      int currG = (currColor >> 8) & 0xFF;
      int currB = currColor & 0xFF;
      // Extract the red, green, and blue components of the background pixel’s color
      int lastR = (lastColor >> 16) & 0xFF;
      int lastG = (lastColor >> 8) & 0xFF;
      int lastB = lastColor & 0xFF;
      // Compute the difference of the red, green, and blue values
      int diffR = abs(currR - lastR);
      int diffG = abs(currG - lastG);
      int diffB = abs(currB - lastB);
      // Add these differences to the running tally
      //presenceSum += diffR + diffG + diffB;
      // Render the difference image to the screen
      //pixels[i] = color(diffR, diffG, diffB);
      // The following line does the same thing much faster, but is more technical
      pixels[i] = 0xFF000000 | (diffR << 16) | (diffG << 8) | diffB;
    }
}
*/
void setup() {
// size(1280, 480);
 size(640, 480);

 logFreqMax = (int) log(freqMax);

 cellW = width/gridSizeX;
 cellH = height/gridSizeY;
 halfCellW = cellW/2;
 halfCellH = cellH/2;
 quartCellW = cellW/4;
 quartCellH = cellH/4;

 //  println(Capture.list()); //will print list of different camera choices. to use different one replace the quoted name below
 //v = new Capture(this, width, height, "USB Video Class Video", framesPerSec);
 v = new Capture(this, width, height, framesPerSec); //to use built in camera
 isCapturing = true;

 println(Serial.list());
 if (useSerial) {
   serial = new Serial(this, Serial.list()[0], 57600);
 }  
}

void draw() {
 //map transmit to tactile
 mapAndTransmit();
 //visualize
  image(v,0,0);
//  tint(255, 153);
   for (int x = 0; x < gridSizeX; x++) {
     for (int y = 0; y < gridSizeY; y++) {
       fill(cells[x][y],127);
       rect(x*cellW,y*cellH,cellW,cellH);
     }
   }
 
 
}

void captureEvent(Capture c) {
 if (isCapturing) {
   c.read(); //grab video frame
   //fill cell array with brightnesses in corresponding sections of the image
   historyIndex = (historyIndex+1) % historySize;
   for (int x = 0; x < gridSizeX; x++) {
     for (int y = 0; y < gridSizeY; y++) {
 //      System.out.printf("%d,%d\n",halfCellW+x*cellW,halfCellH+y*cellH);
       //get pixels in center, left, right, up and down parts of this cell and average
       color cC = v.pixels[(halfCellW+x*cellW) + (halfCellH+y*cellH)*width];
       color cL = v.pixels[(halfCellW+x*cellW)-quartCellW + (halfCellH+y*cellH)*width];
       color cR = v.pixels[(halfCellW+x*cellW)+quartCellW + (halfCellH+y*cellH)*width];
       color cU = v.pixels[(halfCellW+x*cellW) + (halfCellH+y*cellH-quartCellH)*width];
       color cD = v.pixels[(halfCellW+x*cellW) + (halfCellH+y*cellH+quartCellH)*width];
       //cells[x][y] = (brightness(cC)+brightness(cL)+brightness(cR)+brightness(cU)+brightness(cD))/5;
       cellHistory[x][y][historyIndex] = (brightness(cC)+brightness(cL)+brightness(cR)+brightness(cU)+brightness(cD))/5;
     }
   }
   
  /* for (int x=0; x<v.pixels.width; x++) {
     for (int y=0; y<v.pixels.width; y++) {
       lastPixels[x][y] = pixels[x][y];
     }
   }*/
 }
}

void mapAndTransmit() {
 int[] f = mapLightToFreq();
 //for (int i=0; i<12; i++) f[i] = 75;
//debug  System.out.printf("%d %d %d %d %d %d %d %d %d %d %d %d\n",f[0],f[1],f[2],f[3],f[4],f[5],f[6],f[7],f[8],f[9],f[10],f[11]);
 String out = String.format("%d %d %d %d %d %d %d %d %d %d %d %d",f[0],f[1],f[2],f[3],f[4],f[5],f[6],f[7],f[8],f[9],f[10],f[11]);
 //println(out);
 if (useSerial){
   serial.write(out);
   serial.write("\n");
 }  
}

int[] mapLightToFreq(){
 for (int xcell = 0; xcell < gridSizeX; xcell++) {
   for (int ycell = 0; ycell < gridSizeY; ycell++) {
     processedCells[xcell][ycell] = cellHistory[xcell][ycell][historyIndex];
     if (movingAverage) {
       for (int i=0; i<historySize; i++) {
         processedCells[xcell][ycell] += cellHistory[xcell][ycell][i];
       }
       processedCells[xcell][ycell] /= historySize;
     }
     
     if (useBinning) {
       println((processedCells[xcell][ycell] / binSize));
       if ((processedCells[xcell][ycell] / binSize) > lightThreshold) {
         processedCells[xcell][ycell] = 255;
       } else {
         processedCells[xcell][ycell] = 0;
         print("FALSE");
       } 
       
     }  
     
     cells[xcell][ycell] = processedCells[xcell][ycell];
     /*if (useDifference) {
       cells[xcell][ycell] = abs(processedCells[xcell][ycell] - lastProcessedCells[xcell][ycell]);
       cells[xcell][ycell] = constrain(map(cells[xcell][ycell], 0, 30, 0, 255), 0, 255);
     }*/
     
     //lastProcessedCells[xcell][ycell] = processedCells[xcell][ycell];
   }
 }
 
 int[] f = new int[gridSizeX*gridSizeY]; //frequencies
 if (mapping == "average") { //average all pixels per cell in attempt to reduce noise
   for (int xcell = 0; xcell < gridSizeX; xcell++){
      for (int ycell = 0; ycell < gridSizeY; ycell++){
         for (int y = 0; y < cellH; y++) {
           for (int x = 0; x < cellW; x++) {
             f[gridSizeX-1-xcell+ycell*gridSizeX] += (int)(freqMin+(freqMax-freqMin)*v.pixels[x+xcell*gridSizeX+(y+ycell*gridSizeY)*width]); //sum pixels in cell
           }
         }
         f[gridSizeX-1-xcell+ycell*gridSizeX] = (int) (f[xcell+ycell*gridSizeX]/(cellH*cellW*256)); //divide by number of pixels per cell
       }
     }
  } else if (mapping == "linear") {
   for (int y = 0; y < gridSizeY; y++) {
     for (int x = 0; x < gridSizeX; x++) {
       f[gridSizeX-1-x+y*gridSizeX] = (int) (freqMin+(freqMax-freqMin)*cells[x][y]/256);
     }
     //debug System.out.printf("%f,%f,%f\n",cells[0][y]/256,cells[1][y]/256,cells[2][y]/256);
   }
 } else if (mapping == "exponential") {
   for (int y = 0; y < gridSizeY; y++) {
     for (int x = 0; x < gridSizeX; x++) {
       f[gridSizeX-1-x+y*gridSizeX] = (int) pow(e,freqMin+(logFreqMax-freqMin)*cellHistory[x][y][historyIndex]/256);
     }
//debug      System.out.printf("%f,%f,%f\n",cells[0][y]/256,cells[1][y]/256,cells[2][y]/256);
   }
 } //else if (mapping = "logarithmic") {
 // }
 return f;
}

// catch space bar presses to pause/restart program
void keyPressed() {
 if (key == ' ') {
   isCapturing = !isCapturing;
 }
}

// Other potentially useful bits:
//    // Extract the red, green, and blue components from current pixel
//    int r = (c >> 16) & 0xFF; // Like red(), but faster
//    int g = (c >> 8) & 0xFF;
//    int b = c & 0xFF;
//    fill(c);
//    rect(0,0,width,height);
