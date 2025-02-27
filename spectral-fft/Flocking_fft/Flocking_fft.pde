/**
 * Flocking
 * by Daniel Shiffman.
 *
 * An implementation of Craig Reynold's Boids program to simulate
 * the flocking behavior of birds. Each boid steers itself based on
 * rules of avoidance, alignment, and coherence.
 *
 * Click the mouse to add a new boid.
 */

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress remote_location;

Flock flock;
int num = 512;
int[] mags = new int[num];
int[] phases = new int[num];
void setup() {
  size(640, 360);
  flock = new Flock();
  // Add an initial set of boids into the system
  for (int i = 0; i < num; i++) {
    flock.addBoid(new Boid(width / 2, height / 2));
  }
  for (int i = 0; i < num; i++) {
    mags[i] = floor(random(num));
    phases[i] = i;
  }

  //println(mags);
  oscP5 = new OscP5(this, 57120);
  remote_location = new NetAddress("127.0.0.1", 57120);
  //send_osc();
}

void draw() {
  background(50);
  flock.run();
  //println(mags);
  //get xy values of boids
  //ArrayList<Boid> boids = flock.boids;
  //int i = 0;
  //for (Boid b : boids) {
  //  float x = b.position.x;
  //  float y = b.position.y;
  //  int mag = parseInt((x / parseFloat(width)) * 256);
  //  int phase = parseInt((x / parseFloat(width)) * 256);
  //  mags[i] = mag;
  //  phases[i] = phase;
  //  i++;
  //}
}

void mouseClicked(){
  send_osc();
}

void send_osc() {
  /* in the following different ways of creating osc messages are shown by example */
  OscMessage mag = new OscMessage("/mag");
  for (int i = 0; i < mags.length; i++) {
    int mag_result = mags[i];
    mag.add(mag_result); /* add an int to the osc message */
  }
  //println(mag);
  oscP5.send(mag, remote_location);

  OscMessage phase = new OscMessage("/phase");
  for (int i = 0; i < phases.length; i++) {
    int phase_result = phases[i];
    phase.add(phase_result); /* add an int to the osc message */
  }
  oscP5.send(phase, remote_location);
}


/* incoming osc message are forwarded to the oscEvent method. */
//void oscEvent(OscMessage theOscMessage) {
//  /* print the address pattern and the typetag of the received OscMessage */
//  print("### received an osc message.");
//  print(" addrpattern: "+theOscMessage.addrPattern());
//  println(" typetag: "+theOscMessage.typetag());
//}
