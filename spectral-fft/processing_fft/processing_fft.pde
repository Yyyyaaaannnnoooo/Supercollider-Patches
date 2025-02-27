import ddf.minim.*;
import ddf.minim.analysis.*;
//import ddf.minim.effects.*;
import ddf.minim.signals.*;
//import ddf.minim.spi.*;
import ddf.minim.ugens.*;

//import processing.sound.*;
import gab.opencv.*;
import processing.video.*;
import javax.sound.sampled.AudioFormat;
import processing.video.*;

PImage img;
Capture video;
OpenCV opencv;
//SoundFile soundFile;
Minim minim;
AudioOutput output;
AudioOutput out;
AudioPlayer player;
AudioSample sample;
Sampler sampler;
MultiChannelBuffer buffer;
int columns = 2;
int bufferSize = 512 * columns;
int sampleRate = 44100;
float[] samples;
float inc = 0;
FFT fft;
//private FFT fft;

void setup() {
  size(512, 900);
  // This the default video input, see the GettingStartedCapture
  // example if it creates an error
  video = new Capture(this, width, width);

  // Start capturing the images from the camera
  video.start();
  minim = new Minim(this);
  out = minim.getLineOut();
  out.setVolume(1);
  // Load image and convert to grayscale
  img = loadImage("test4.jpeg");
  img.resize(width, width);
  //opencv = new OpenCV(this, img);
  //opencv.gray();
  //img = opencv.getOutput();
  buffer = new MultiChannelBuffer(bufferSize+2, 2);
  println(buffer.getBufferSize());
  buffer.setSample(0, 0, 0);
  buffer.setSample(1, 0, 0);
  for (int i = 1; i < bufferSize-1; i++) {
    float val = random(-1, 1);
    buffer.setSample(0, i, val);
    buffer.setSample(1, i, val);
  }
  buffer.setSample(0, bufferSize-1, 0);
  buffer.setSample(1, bufferSize-1, 0);
  sampler = new Sampler(buffer, sampleRate, 1);
  sampler.looping = true;
  sampler.patch(out);
  sampler.trigger();

  //out.addSignal(buffer);
  // Initial sound generation
  output = minim.getLineOut(Minim.STEREO, 512);
  //generateSound(mouseX);
}

void draw() {
  background(0);
  //if (video.available()) {
  //  video.read();
  //  video.loadPixels();

  //  image(video, 0, 0);
  //}
  
  
  
  
  
  
  image(img, 0, 0);
  float rate = map(mouseY, height, 0, PI / 10000, PI / 50);
  inc += rate;
  int sliceX = constrain(mouseX, 0, img.width - (1 + columns));
  //int sliceX = floor(map(sin(inc), -1, 1, 0, img.width - (1 + columns)));
  stroke(255, 0, 0);
  noFill();
  //line(sliceX, 0, sliceX, height);
  rect(sliceX, 0, columns, width);

  generateSound(sliceX);
  
  int zero = 512;
  int new_height = height - width;
  int margin = 10;
  int graph_h = (new_height + margin) / 2;
  int mag_y = zero + graph_h;
  int phase_y = height;
  
  PVector[] f_data = getFrequencyDataAVG(sliceX, 5);
  float w = width / float(f_data.length);
  println(w, width, f_data.length, f_data[120]);
  for(int i = 0; i < f_data.length; i++){
    float mag = f_data[i].x * 255;
    float h = map(mag, 0, 255, 0, graph_h);
    if(i%2==0){
      stroke(0,255,0);
    }
    rect(i*w, mag_y, w, -h);
    float phase = map(f_data[i].y, 0, TWO_PI, 0, 255);
    h = map(phase, 0, 255, 0, graph_h);
    rect(i*w, phase_y, w, -h);
  }
  
  //sampler.amplitude = rate;
  if (inc >= TWO_PI) {
    inc = 0;
  }
}
int sampleIndex = 0;
void generateSound(int sliceX) {
  //if (player != null) {
  //    player.close();
  //}

  PVector[] freqData = getFrequencyDataAVG(sliceX, 20);
  println("freq: " + freqData.length);
  int paddedSize = nextPowerOfTwo(freqData.length);
  println(paddedSize);
  float[] real = new float[paddedSize];
  float[] imag = new float[paddedSize];
  for (int i = 0; i < freqData.length; i++) {
    real[i] = freqData[i].x * cos(freqData[i].y); // Magnitude * cos(phase)
    imag[i] = freqData[i].x * sin(freqData[i].y); // Magnitude * sin(phase)
  }

  // Perform inverse FFT
  fft = new FFT(paddedSize, sampleRate);
  samples = new float[paddedSize];
  fft.inverse(real, imag, samples);

  // Play sound
  if (sample != null) {
    sample.close();
  }
  // Define audio format
  //AudioFormat format = new AudioFormat(sampleRate, 16, 1, true, true);

  for (int i = 1; i < bufferSize-1; i++) {
    buffer.setSample(0, i, samples[i]);
    buffer.setSample(1, i, samples[i]);
  }
  sampler.setSample(buffer, sampleRate);
  sampleIndex++;
  if (sampleIndex >= bufferSize) {
    sampleIndex = 0;
  }
}

PVector[] getFrequencyData(int sliceX) {
  PVector[] freqData = new PVector[bufferSize];
  int index = 0;
  for (int x = sliceX; x < sliceX + columns; x++) {
    for (int y = 0; y < img.height; y++) {
      int pixelColor = img.get(sliceX, y);
      float magnitude = brightness(pixelColor) / 255.0;
      float phase = map(green(pixelColor), 0, 255, 0, TWO_PI); // Map hue to phase
      freqData[index] = new PVector(magnitude, phase);
      index++;
    }
  }
  return freqData;
}

PVector[] getFrequencyDataAVG(int sliceX, int chunkHeight) {
  PVector[] freqData = new PVector[bufferSize];

  // Iterate over each row in the image
  int index = 0;
  for (int x = sliceX; x < sliceX + columns; x++) {
    for (int y = 0; y < img.height; y++) {
      float sumMagnitude = 0;
      float sumPhase = 0;
      int count = 0;

      // Iterate vertically over a chunkHeight around sliceX, y
      int startY = max(0, y - chunkHeight / 2);
      int endY = min(img.height - 1, y + chunkHeight / 2);

      for (int cy = startY; cy <= endY; cy++) {
        int pixelColor = img.get(sliceX, cy);
        float magnitude = green(pixelColor) / 255.0;
        float phase = map(brightness(pixelColor), 0, 255, 0, TWO_PI); // Map hue to phase
        sumMagnitude += magnitude;
        sumPhase += phase;
        count++;
      }

      // Calculate average magnitude and phase
      float avgMagnitude = sumMagnitude / count;
      float avgPhase = sumPhase / count;

      // Create PVector with smoothed values
      freqData[index] = new PVector(avgMagnitude, avgPhase);
      index++;
    }
  }
  return freqData;
}

int nextPowerOfTwo(int n) {
  int power = 1;
  while (power < n) {
    power *= 2;
  }
  return power;
}

void stop() {
  player.close();
  minim.stop();
  super.stop();
}
