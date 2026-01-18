import gab.opencv.*;
import processing.video.*;
import javax.sound.sampled.AudioFormat;
import processing.video.*;
import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress myRemoteLocation;

import processing.sound.*;
FFT fft;
AudioIn in;
int bands = 512;
float[] spectrum = new float[bands];
String input_device = "BlackHole 16ch";

PImage img, sobel;
//PGraphics img;
Capture video;
OpenCV opencv;
int bufferSize = 512;
int reducedSize = 64;
int sampleRate = 44100;
float[] samples = new float[bufferSize];
float inc = 1;

float xoff=0, yoff=0, zoff= 0;

float[] exp = new float[bufferSize];

// Define the scale and rate parameters for the exponential function
float a = 25;
float b = (float) Math.log(16000.0 / a);

int sliceX = 0;
int x = 0;

boolean IS_3D = false;

void setup() {
  //size(512, 512, P3D);
  size(512, 512);


  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this, 57120);
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);

  for (int i = 0; i < bufferSize; i++) {
    float x = i / (float) (bufferSize - 1);  // Linear space between 0 and 1
    exp[i] = a * (float) Math.exp(b * x);
  }
  //String[] deviceNames = Sound.list();
  //for (int i = 0; i < deviceNames.length; i++) {
  //    println("Found a multi-channel device: " + deviceNames[i]);
  //}
  Sound s = new Sound(this);
  s.inputDevice(input_device);
  // Create an Input stream which is routed into the Amplitude analyzer
  fft = new FFT(this, bands);
  in = new AudioIn(this, 0);
  in.start();
  fft.input(in);
  String webcam = "pipeline:avfvideosrc device-index=";
  String[] cameras = Capture.list();
  int index = 0;
  for(int i = 0; i < cameras.length; i++){
    String camera = cameras[i];
    println(camera, i);
    if(camera.equals("SandbergCapture")){
      index = i;
      println(webcam + index);
      webcam = webcam + index;
      break;
    }else{
      webcam = webcam + 0;
    }
  }
  
  //video = new Capture(this, width, width, cameras[1]);
  
  video = new Capture(this, 
  width, height, webcam);
  // Start capturing the images from the camera
  video.start();

  img = loadImage("test.jpeg");
  img.resize(height, height);

  //img = createGraphics(height / 2, height / 2, P3D);
  opencv = new OpenCV(this, img);
  opencv.loadImage(img);
  opencv.findSobelEdges(0, 1);
  img = opencv.getSnapshot();

  //opencv.loadImage(img);
  //opencv.findScharrEdges(OpenCV.HORIZONTAL);
  //img = opencv.getSnapshot();
  frameRate(30);
  background(0);
}
int threshold = 220;
void draw() {
  //background(0);
  //ortho();
  if (video.available()) {
    video.read();
    video.loadPixels();
    //opencv.loadImage(video);
    //opencv.findSobelEdges(1, 0);
    //img = opencv.getSnapshot();
    //image(video, 0, 0);
    img = video;
    show_threshold(threshold);
  }


  // PVector[] f_data = imageData(sliceX);

  // float w = width / float(bufferSize);
  // for (int i = 0; i < exp.length; i++) {
  // float freq = exp[i];
  // float ff = 0;
  // float value = 0;
  // for (int j = 0; j < f_data.length; j++) {
  // float this_f = f_data[j].y;
  // if (this_f == freq) {
  // value = f_data[j].x;
  // ff = this_f;
  // break;
  //  }
  //  }
  // rect(i*w, phase_y, w, -value);
  //  }

  //spectrogram(x);

  //use3d();
  read_pixels(threshold);
}

void show_threshold(int t) {
  opencv.loadImage(video);
  opencv.findSobelEdges(1, 0);
  PImage sobel = opencv.getSnapshot();
  img.loadPixels();
  for (int px = 0; px < img.width; px++) {
    for (int py = 0; py < img.height; py++) {
      int index = px + py * img.width;
      color original = img.pixels[index];
      color s_pixel = sobel.pixels[index];
      float r = (s_pixel >> 16) & 0xFF;
      float g = (s_pixel >> 8) & 0xFF;
      float b = s_pixel & 0xFF;
      color black = color(r, g, b);
      color white = color(255, 255, 255);
      color bw = brightness(original) > t ? white : black;
      //color bw = brightness(original) > t ? black : white;
      img.pixels[index] = bw;
    }
  }
  img.updatePixels();
  image(img, 0, 0);
}

void use3d() {
  lights();
  noFill();
  strokeWeight(2);
  int num = 3;
  int box_size = round((width * 0.95) / ((num * 2) + 1));
  //int centerX = round(width - (width * 0.25));
  //int centerX = round(width * 0.5);
  int centerX = round(box_size/2);

  //int centerY = round(height * 0.5);
  //int centerY = round(height * 0.5);
  int centerY = round(box_size/2);

  translate(width / 2, height / 2);
  rotateY(frameCount * 0.01);
  rotateX(frameCount * 0.01);
  for (int xx = -num; xx < num; xx++) {
    for (int y = -num; y < num; y++) {
      for (int z = -num; z < num; z++) {
        pushMatrix();
        float n_val = noise(xoff, yoff, zoff);
        float col = n_val>0.25?0:1;
        stroke(255);
        int px = (xx * box_size) + centerX;
        //int px = (xx * box_size) + centerY;
        int py = (y * box_size) + centerY;
        int pz = z * box_size;
        translate(px, py, pz);
        rotateX(x * 0.01 + PI*n_val);
        rotateY(x * 0.001);
        box((box_size * n_val) * 0.5);
        //box(box_size  * 0.5);

        popMatrix();
        zoff += 0.00001;
      }
      yoff += 0.0001;
    }
    xoff += 0.001;
  }

  set_image();
}

void read_pixels(int t) {
  //generateSound(x, ceil(map(mouseY, 0, height, 0, 255)));
  generateSound(x, t);

  //image(img, 0, 0);
  stroke(255, 0, 0);
  noFill();
  //pushMatrix();
  if (IS_3D) {
    translate(x-width/2, -height/2);
    rect(0, 0, 1, width);
  } else {
    rect(x, 0, 1, width);
  }
  //popMatrix();
  x+=inc;
  if (x >= 512) {
    x = 0;
    inc = floor(random(1, 6));
  }
  image_modulation(x);
}

void set_image() {
  loadPixels();
  img = get(0, 0, 512, 512);
  updatePixels();
}
// DEPRECATED


//void mouseMoved() {
//  float rate = map(mouseY, height, 0, PI / 10000, PI / 50);
//  inc += rate;
//  sliceX = constrain(mouseX, 0, img.width - 1);
//  generateSound(sliceX, 80);
//}


void generateSound(int sliceX, int threshold) {
  float[] data = imageDataFFT(sliceX, threshold);
  OscMessage msg = new OscMessage("/image");
  for (int i = 0; i < data.length; i++) {
    float mag_result = data[i];
    msg.add(mag_result);
  }
  // println(msg);
  oscP5.send(msg, myRemoteLocation);
}

float [] imageDataFFT(int sliceX, int threshold) {
  //reduce size to match smaller fft size in SC
  // THIS BELOW CAN CAUSE BUGS IN THE FUTURE
  float [] result = new float[bufferSize];
  for (int y = 0; y < img.height; y++) {
    color pixelColor = img.get(sliceX, y);
    float b = brightness(pixelColor);
    result[y] = b > threshold ? 1.0: 0;
    //result[y] = b / 255;
  }
  return result;
}

void image_modulation(int sliceX){
  int waves = 16;
  int chunk = round(img.height / waves);
  int half_chunk = round((img.height / waves)/2);
  float [] values = new float[waves];
  for (int  i = 0; i < values.length; ++i) {
    values[i] = 0;
  }
  int index = 0;
  for (int y = 0; y < img.height; y+=chunk) {
    float sum1 = 0;
    float sum3 = 0;
    for (int i = y; i < y + chunk; i++){
      // println("chunk: ", y, "line: ", i);
      color pixelColor = img.get(sliceX, i);
      float b = brightness(pixelColor);
      sum3 += b;
      int zero = i - y;
      if(zero < half_chunk){
        sum1 += b;
      }
    }
    if(sum3 > 0){
      float top = sum1 / sum3;
      // float bottom = sum2 / sum3;
      // println("top: ", top, "bottom: ", bottom, "sum3; ", sum3, "sum: ", sum1 + sum2);
      values[index] = top;
      int pos = round(float(chunk) * top) + y;
      stroke(0, 255, 0);
      strokeWeight(5);
      //point(sliceX, pos);
    }
    OscMessage msg = new OscMessage("/image2");
    for (int i = 0; i < values.length; i++) {
        float val = values[i];
        msg.add(val);
      }
    // println(msg);
    oscP5.send(msg, myRemoteLocation);
    //println(index);
    index++;
  }
}

PVector [] imageData(int sliceX) {
  PVector [] result = new PVector[reducedSize];
  for (int i = 0; i < reducedSize; i++) {
    result[i] = new PVector(0, 25);
  }
  int index = 0;
  for (int y = 0; y < img.height; y++) {
    int pixelColor = img.get(sliceX, y);
    float b = brightness(pixelColor);

    if (b > 127) {
      float value = b;
      float freq = exp[y];
      result[index] = new PVector(value, freq);
      index++;
      if (index > result.length -1) {
        break;
      }
    }
    //float magnitude = brightness(pixelColor) / 255.0;
    //float phase = map(green(pixelColor), 0, 255, 0, TWO_PI); // Map hue to phase
    //freqData[index] = new PVector(magnitude, phase);
  }
  return result;
}

int nextPowerOfTwo(int n) {
  int power = 1;
  while (power < n) {
    power *= 2;
  }
  return power;
}

void spectrogram(int x) {
  //println(x);
  int pos_x = 512 + x;
  int new_width = height;
  //fft.analyze(samples);
  //noStroke();
  //println(fft.spectrum[100] * 50.0);
  //for (int i = 0; i < bands; i++) {
  //  // sum[i] += (fft.spectrum[i] - sum[i]) * smoothingFactor;
  //  float val = fft.spectrum[i] * 50;
  //  //println(val);
  //  fill(val);
  //  rect(pos_x, i, 1, 1);
  //}

  fft.analyze(spectrum);

  for (int i = 0; i < bands; i++) {
    // The result of the FFT is normalized
    // draw the line for frequency band i scaling it up by 5 to get more amplitude.

    float val = spectrum[i] * 255 * 100;
    //float val = map(spectrum[i], 0, TWO_PI, 0, 255);
    stroke(val, 255);
    line(i, height, i, height - spectrum[i]*height*5 );
    point(pos_x, i);
  }
}
