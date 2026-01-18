/**
 * oscP5sendreceive by andreas schlegel
 * example shows how to send and receive osc messages.
 * oscP5 website at http://www.sojamo.de/oscP5
 */

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;
int num = 512;
int[] mags = new int[num];
int[] phases = new int[num];

//String [] list_to_String (int[] list) {
//  String [] s = new String[num];
//  for (int i = 0; i < num; i++) {
//    s[i] = str(list[i]);
//  }
//  return s.join(",");
//}

void setup() {
  size(400, 400);
  frameRate(25);
  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this, 57120);
  for (int i = 0; i < num; i++) {
    mags[i] = floor(random(num));
    phases[i] = i;
  }

  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device,
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the same, hence you will
   * send messages back to this sketch.
   */
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);

  background(0);
  noStroke();
  fill(255);
  for (int i = 0; i < num; i++) {
    float w = width / float(num);
    int h = mags[i];
    float x = w * i;
    float y = height - h;
    rect(x, y, w, h);
  }
}


void draw() {
  background(0);
  for (int i = 0; i < num; i++) {
    float w = width / float(num);
    int h = mags[i];
    float x = w * i;
    float y = height - h;
    rect(x, y, w, h);
  }
}

void mouseMoved() {
}

void mousePressed() {

  int posY = floor(map(mouseY, height, 0, 0, num));
  int posX = parseInt(map(mouseX, 0, width, 0, num));
  for (int i = 0; i < posX; i++) {
    int interp = round(lerp(0, posY, float(i) / posX));
    mags[i] = interp;
  }
  for (int i = posX; i < num; i++) {
    int interp = round(lerp(0.0, parseFloat(posY), (num - i) / parseFloat(num - posX) ));
    //int interp = 100;
    mags[i] = interp;
  }



  /* in the following different ways of creating osc messages are shown by example */
  OscMessage mag = new OscMessage("/image");
  //String mag_result = "[" + join(nf(mags, 0), ", ") + "]";
  //println(mag_result);
  for (int i = 0; i < mags.length; i++) {
    int mag_result = mags[i];
    mag.add(mag_result); /* add an int to the osc message */
  }
  //mag.add(mag_result); /* add an int to the osc message */
  println(mag);
  oscP5.send(mag, myRemoteLocation);

  OscMessage phase = new OscMessage("/phase");
  //String phase_result = "[" + join(nf(phases, 0), ", ") + "]";
  //phase.add(phase_result);
  for (int i = 0; i < phases.length; i++) {
    int phase_result = phases[i];
    phase.add(phase_result); /* add an int to the osc message */
  }
  oscP5.send(phase, myRemoteLocation);
  /* send the message */
}


/* incoming osc message are forwarded to the oscEvent method. */
//void oscEvent(OscMessage theOscMessage) {
//  /* print the address pattern and the typetag of the received OscMessage */
//  print("### received an osc message.");
//  print(" addrpattern: "+theOscMessage.addrPattern());
//  println(" typetag: "+theOscMessage.typetag());
//}
