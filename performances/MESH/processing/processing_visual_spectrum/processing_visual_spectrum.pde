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
// Capture video;
OpenCV opencv;
int bufferSize = 512;
int reducedSize = 64;
int sampleRate = 44100;
float[] samples = new float[bufferSize];
float inc = 1;

float[] exp = new float[bufferSize];

// Define the scale and rate parameters for the exponential function
float a = 25;
float b = (float) Math.log(16000.0 / a);

int sliceX = 0;
int x = 0;

void setup() {
  size(1024, 512);

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


  // video = new Capture(this, width, width);

  // Start capturing the images from the camera
  // video.start();

  img = loadImage("test.jpeg");
  img.resize(height, height);
   opencv = new OpenCV(this, img);
  // opencv.loadImage(img);
  // opencv.findSobelEdges(0, 1);
  // img = opencv.getSnapshot();

  opencv.loadImage(img);
  opencv.findScharrEdges(OpenCV.HORIZONTAL);
  img = opencv.getSnapshot();
  frameRate(30);
  background(0);
}

void draw() {
  //if (video.available()) {
  //  video.read();
  //  video.loadPixels();

  //  image(video, 0, 0);
  //}


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

  spectrogram(x);
  generateSound(x, ceil(map(mouseY, 0, height, 0, 255)));
  image(img, 0, 0);
  stroke(255, 0, 0);
  noFill();
  rect(x, 0, 1, width);
  x+=inc;
  if (x >= 512) {
    x = 0;
    inc = floor(random(1, 6));
  }
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
  float [] result = new float[bufferSize];
  for (int y = 0; y < img.height; y++) {
    int pixelColor = img.get(sliceX, y);
    float b = brightness(pixelColor);
    result[y] = b > threshold ? 1.0: 0.0;
    //result[y] = b / 255;
  }
  return result;
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
