(
// Server.default.options.outDevice_("Multi-Output Device");
// Server.default.options.inDevice_("BlackHole 16ch");

// Replace this with your virtual audio card

Server.default.options.outDevice_("BlackHole 16ch");
// s.options.numOutputBusChannels = 8;
// s.options.numInputBusChannels = 2;
s.reboot

)


b = Buffer.read(s, "/Users/ya/Documents/supercollider/flucoma/break/00021-break.wav")

(

// To add every tot the mose xshould be offset by random value

SynthDef(\pulsaretNNresynth, {
  arg out = 0, sample;
  // variables
  var snd, freq, formantCount,
  formantFreq, sineCycles, pulsaretPhase,
  window, randomLFO, randomLFOs, lfoRate,
  mouseX, mouseY, baseOffset, randomOffset,
  fx, fx2, wet1=1, wet2;
  var sig;
  var modulation = LFNoise1.kr(0.3);
  var pit = 0;
  var pos = 0;
  var size = 0;
  var dens = 0;
  var tex = 0;
  var rvb = 0;
  var fb = 0;
  var amp = 0.5;
  var numBands = 12;
  var bfhzs = (1..numBands).linexp(1, numBands, 25, 16000);
  var q = \bw.kr(20);
  var rq = 1 / q;
  var val = FluidBufToKr.kr(~paramsbuf);
  var sampler;

  lfoRate = LFDNoise1.kr(0.3).linexp(-1, 1, 0.1, 16);
  tex = 0.25;
  formantCount = 3;

  // Get mouse positions
  // mouseX = MouseX.kr(-1, 1);
  // mouseY = MouseY.kr(0, 1);


  // modulations:

  // val[0].poll;

  mouseX = val[0].linlin(0,1,-1,1);
  mouseY = val[1];

  pit = val[2].linlin(0, 1, -24, 12);
  pos = val[3].linlin(0, 1, 0, 0.2);
  size = val[4].linlin(0, 1, 0, 0.25);
  dens = val[5].linlin(0, 1, 0, 0.4);
  rvb = val[6];
  fb = val[7];
  q = val[8].linexp(0, 1, 2, 50);
  amp = val[9].linlin(0, 1, 0, -6.dbamp);
  rq = 1 / q;


  sampler = PlayBuf.ar(2, sample, BufRateScale.kr(sample)*(modulation*val[0]).range(-2, 2), loop:1);
  // sampler = PlayBuf.ar(2, sample, BufRateScale.kr(sample)*1, loop:1);

  // Modified randomLFO function that returns MouseX values with offset
  randomLFO = { |offsetIndex = 0|
    var offsetRange, offset, wrappedMouseX;
    var trigger, yoffset, randoffset;
    trigger = Dust.kr(lfoRate);
    // randoffset = Latch.kr(LFNoise2.kr(lfoRate), trigger);
    offset = offsetIndex.linlin(0, formantCount - 1, -1, 1);
    yoffset = Select.kr(ToggleFF.kr(trigger), [
      LFNoise2.kr(lfoRate) * mouseY,
      TRand.kr(-1, 1, trigger) * mouseY
    ]);
    // offset = offset + LFNoise2.kr(lfoRate).range(0, mouseY);
    wrappedMouseX = ((mouseX + offset)+yoffset).wrap(-1, 1);
    wrappedMouseX;
  };

  // Create array of LFO values with offsets
  randomLFOs = { { |i| randomLFO.(i) } ! formantCount };

  freq = randomLFO.().linexp(-1, 1, 20, 1000);
  formantFreq = randomLFOs.().linexp(-1, 1, 2, 8000);
  sineCycles = randomLFOs.().linlin(-1, 1, 1, 4);
  pulsaretPhase = LFSaw.ar(freq, iphase: 1).linlin(-1, 1, 0, 1) * formantFreq / freq;
  // pulsaretPhase = SinOsc.ar(freq, iphase: 1).linlin(-1, 1, 0, 1) * formantFreq / freq;
  window = pulsaretPhase.lincurve(0, 1, 1, 0, -4);
  snd = sin(pulsaretPhase * 2pi * sineCycles.floor) * window * (pulsaretPhase < 1);
  snd = snd * randomLFOs.().linlin(-1, 1, 0, 1);
  snd = Pan2.ar(snd, randomLFOs.() * 0.4);
  snd = snd.flop.sum;
  [0.2, 0.1, 0.05].do { |windowSize|
    snd = PitchShift.ar(snd, windowSize, randomLFO.().linexp(-1, 1, 0.25, 6)) * 6.dbamp;
    snd = FreqShift.ar(snd, randomLFO.() * 100);
  };

  snd = Limiter.ar(snd);
  snd = snd * -6.dbamp;
  //
  //
  /* analysis = Amplitude.kr(
  BPF.ar(input , bfhzs, rq:rq, mul: sqrt(20.reciprocal))
  );*/

  snd = SelectX.ar(val[2].linlin(0, 1, 0, 0.95), [snd, sampler]);

  sig = BPF.ar(snd, bfhzs, rq:rq, mul: sqrt(q));

  sig = Splay.ar(sig.scramble);

  // FX section

  fx = MiClouds.ar(
    sig,
    pit,
    pos,
    size,
    dens,
    tex,
    drywet: wet1,
    in_gain: 1, spread: 1,
    rvb:rvb, fb: fb,
    freeze: 0, lofi: 0, mode: 0
  );


  fx = MiClouds.ar(
    fx,
    pit.neg,
    pos,
    size.linlin(0, 0.25, 0.3, 0.85),
    dens.linlin(0, 0.4, 0.51, 1),
    tex,
    drywet: wet1,
    in_gain: 1, spread: 1,
    rvb:0, fb: 0.8,
    freeze: 0, lofi: 0, mode: 0
  );

  fx = fx * -6.dbamp;
  sig = sig + fx;
  sig = Limiter.ar(sig);
  sig = FluidAudioTransport.ar(
    sig,
    sampler,
    \interp.kr(0).varlag(1),
    windowSize:512
  );
  Out.ar(out, sig);
}).add;


)

Buffer.freeAll

b = Buffer.read(s, "/Users/ya/Documents/supercollider/flucoma/break/00021-break.wav")
b.play

x = Synth(\pulsaretNNresynth, [\sample, b])

x.set(\interp, 0)
x.free

(

// To add every tot the mose xshould be offset by random value

SynthDef(\pulsaretXYresynth, {
  arg out = 0, sample;
  // variables
  var snd, freq, formantCount,
  formantFreq, sineCycles, pulsaretPhase,
  window, randomLFO, randomLFOs, lfoRate,
  mouseX, mouseY, baseOffset, randomOffset,
  fx, fx2, wet1=1, wet2;
  var sig;
  var modulation = LFNoise1.kr(0.3);
  var pit = modulation.range(-24, 24);
  var pos = modulation.range(0, 0.1);
  var size = modulation.range(0,0.25);
  var dens = modulation.range(0.52, 1);
  var tex = modulation.range(0, 1);
  var numBands = 12;
  var bfhzs = (1..numBands).linexp(1, numBands, 25, 16000);
  var q = \bw.kr(20);
  var rq = 1 / q;
  var val = FluidBufToKr.kr(~paramsbuf);

  lfoRate = LFDNoise1.kr(0.3).linexp(-1, 1, 0.1, 16);
  tex = 0.25;
  formantCount = 3;

  // Get mouse positions
  mouseX = MouseX.kr(-1, 1);
  mouseY = MouseY.kr(0, 1); // MouseY controls offset randomization

  // Modified randomLFO function that returns MouseX values with offset
  randomLFO = { |offsetIndex = 0|
    var offsetRange, offset, wrappedMouseX;
    var trigger, yoffset, randoffset;
    trigger = Dust.kr(lfoRate);
    // randoffset = Latch.kr(LFNoise2.kr(lfoRate), trigger);
    offset = offsetIndex.linlin(0, formantCount - 1, -1, 1);
    yoffset = Select.kr(ToggleFF.kr(trigger), [
      LFNoise2.kr(lfoRate) * mouseY,
      TRand.kr(-1, 1, trigger) * mouseY
    ]);
    // offset = offset + LFNoise2.kr(lfoRate).range(0, mouseY);
    wrappedMouseX = ((mouseX + offset)+yoffset).wrap(-1, 1);
    wrappedMouseX;
  };

  // Create array of LFO values with offsets
  randomLFOs = { { |i| randomLFO.(i) } ! formantCount };

  freq = randomLFO.().linexp(-1, 1, 20, 1000);
  formantFreq = randomLFOs.().linexp(-1, 1, 2, 8000);
  sineCycles = randomLFOs.().linlin(-1, 1, 1, 4);
  pulsaretPhase = LFSaw.ar(freq, iphase: 1).linlin(-1, 1, 0, 1) * formantFreq / freq;
  // pulsaretPhase = SinOsc.ar(freq, iphase: 1).linlin(-1, 1, 0, 1) * formantFreq / freq;
  window = pulsaretPhase.lincurve(0, 1, 1, 0, -4);
  snd = sin(pulsaretPhase * 2pi * sineCycles.floor) * window * (pulsaretPhase < 1);
  snd = snd * randomLFOs.().linlin(-1, 1, 0, 1);
  snd = Pan2.ar(snd, randomLFOs.() * 0.4);
  snd = snd.flop.sum;
  [0.2, 0.1, 0.05].do { |windowSize|
    snd = PitchShift.ar(snd, windowSize, randomLFO.().linexp(-1, 1, 0.25, 6)) * 6.dbamp;
    snd = FreqShift.ar(snd, randomLFO.() * 100);
  };

  snd = Limiter.ar(snd);
  snd = snd * -6.dbamp;
  //
  //
  /* analysis = Amplitude.kr(
  BPF.ar(input , bfhzs, rq:rq, mul: sqrt(20.reciprocal))
  );*/

  sig = BPF.ar(snd, bfhzs, rq:rq, mul: sqrt(q));

  sig = Splay.ar(sig.scramble);

  // FX section

  fx = MiClouds.ar(
    sig,
    pit,
    pos,
    size,
    dens,
    tex,
    drywet: wet1,
    in_gain: 1, spread: 1,
    rvb:0, fb: 1,
    freeze: 0, lofi: 0, mode: 0
  );


  fx2 = MiClouds.ar(
    fx,
    pit.neg,
    pos,
    size.linlin(0,0.25, 0.1, 0.5),
    dens.linlin(0.52, 1, 0.1, 0.49),
    tex,
    drywet: wet1,
    in_gain: 1, spread: 1,
    rvb:0, fb: 0.8,
    freeze: 0, lofi: 0, mode: 0
  );

  // fx = Limiter.ar(fx);
  fx = fx * -6.dbamp;
  fx2 = fx2 * -6.dbamp;
  //
  sig = sig + fx;
  // snd = snd + fx;
  // snd = fx + fx2;

  sig = Limiter.ar(sig);

  Out.ar(out, sig);
}).add;


)


x = Synth(\pulsaretXYresynth)
x.set(\bw, 5000)


x.free


(

// To add every tot the mose xshould be offset by random value

SynthDef(\pulsaretXYgrain, {
  arg out = 0;
  // variables
  var snd, freq, formantCount,
  formantFreq, sineCycles, pulsaretPhase,
  window, randomLFO, randomLFOs, lfoRate,
  mouseX, mouseY, baseOffset, randomOffset,
  fx, fx2, wet1=1, wet2;
  var modulation = LFNoise1.kr(0.3);
  var pit = modulation.range(-24, 24);
  var pos = modulation.range(0, 0.1);
  var size = modulation.range(0,0.25);
  var dens = modulation.range(0.52, 1);
  var tex = modulation.range(0, 1);
  lfoRate = LFDNoise1.kr(0.3).linexp(-1, 1, 0.1, 16);
  tex = 0.25;

  formantCount = 3;


  // Get mouse positions
  mouseX = MouseX.kr(-1, 1);
  mouseY = MouseY.kr(0.001, 0.734); // MouseY controls offset randomization

  // Modified randomLFO function that returns MouseX values with offset
  randomLFO = { |offsetIndex = 0|
    var offsetRange, offset, wrappedMouseX;
    var trigger, yoffset, randoffset;
    trigger = Dust.kr(lfoRate);
    randoffset = Latch.kr(LFNoise2.kr(lfoRate), trigger);
    offset = offsetIndex.linlin(0, formantCount - 1, -1, 1);
    yoffset = Select.kr(ToggleFF.kr(trigger), [
      LFNoise2.kr(lfoRate) * mouseY,
      TRand.kr(-1, 1, trigger) * mouseY
    ]);
    offset = offset + LFNoise2.kr(lfoRate).range(0, mouseY);
    wrappedMouseX = ((mouseX + offset)+yoffset).wrap(-1, 1);
    wrappedMouseX;
  };

  // Create array of LFO values with offsets
  randomLFOs = { { |i| randomLFO.(i) } ! formantCount };

  freq = randomLFO.().linexp(-1, 1, 20, 1000);
  formantFreq = randomLFOs.().linexp(-1, 1, 2, 8000);
  sineCycles = randomLFOs.().linlin(-1, 1, 1, 4);
  pulsaretPhase = LFSaw.ar(freq, iphase: 1).linlin(-1, 1, 0, 1) * formantFreq / freq;
  // pulsaretPhase = SinOsc.ar(freq, iphase: 1).linlin(-1, 1, 0, 1) * formantFreq / freq;
  window = pulsaretPhase.lincurve(0, 1, 1, 0, -4);
  snd = sin(pulsaretPhase * 2pi * sineCycles.floor) * window * (pulsaretPhase < 1);
  snd = snd * randomLFOs.().linlin(-1, 1, 0, 1);
  snd = Pan2.ar(snd, randomLFOs.() * 0.4);
  snd = snd.flop.sum;
  [0.2, 0.1, 0.05].do { |windowSize|
    snd = PitchShift.ar(snd, windowSize, randomLFO.().linexp(-1, 1, 0.25, 6)) * 6.dbamp;
    snd = FreqShift.ar(snd, randomLFO.() * 100);
  };
  snd = Limiter.ar(snd);
  snd = snd * -6.dbamp;

  var val = FluidBufToKr.kr(~paramsbuf);

  // FX section

  fx = MiClouds.ar(
    snd,
    pit,
    pos,
    size,
    dens,
    tex,
    drywet: wet1,
    in_gain: 1, spread: 1,
    rvb:0, fb: 1,
    freeze: 0, lofi: 0, mode: 0
  );


  fx2 = MiClouds.ar(
    fx,
    pit.neg,
    pos,
    size.linlin(0,0.25, 0.1, 0.5),
    dens.linlin(0.52, 1, 0.1, 0.49),
    tex,
    drywet: wet1,
    in_gain: 1, spread: 1,
    rvb:0, fb: 0.8,
    freeze: 0, lofi: 0, mode: 0
  );

  // fx = Limiter.ar(fx);
  fx = fx * -6.dbamp;
  fx2 = fx2 * -6.dbamp;
  //
  snd = snd + fx + fx2;
  // snd = snd + fx;
  // snd = fx + fx2;

  // snd = Limiter.ar(snd);

  Out.ar(out, snd);
}).add;


)

x = Synth(\pulsaretXYgrain)


x.free









// PLAYGROUND / OLD STUFF

// Original from here: https://nathan.ho.name/posts/pulsar-synthesis/
s.boot

(
{
  var snd, freq, formantCount, formantFreq, sineCycles, pulsaretPhase, window, randomLFO, randomLFOs, lfoRate;
  formantCount = 3;
  lfoRate = LFDNoise1.kr(0.3).linexp(-1, 1, 0.1, 16);
  randomLFO = {
    var trigger;
    trigger = Dust.kr(lfoRate);
    Select.kr(ToggleFF.kr(trigger), [
      LFNoise2.kr(lfoRate),
      TRand.kr(-1, 1, trigger)
    ]);
  };
  randomLFOs = { { randomLFO.() } ! formantCount };
  freq = randomLFO.().linexp(-1, 1, 1, 1000);
  formantFreq = randomLFOs.().linexp(-1, 1, 2, 8000);
  sineCycles = randomLFOs.().linlin(-1, 1, 1, 4);
  pulsaretPhase = LFSaw.ar(freq, iphase: 1).linlin(-1, 1, 0, 1) * formantFreq / freq;
  window = pulsaretPhase.lincurve(0, 1, 1, 0, -4);
  snd = sin(pulsaretPhase * 2pi * sineCycles.floor) * window * (pulsaretPhase < 1);
  snd = snd * randomLFOs.().linlin(-1, 1, 0, 1);
  snd = Pan2.ar(snd, randomLFOs.() * 0.4);
  snd = snd.flop.sum;
  [0.2, 0.1, 0.05].do { |windowSize|
    snd = PitchShift.ar(snd, windowSize, randomLFO.().linexp(-1, 1, 0.5, 2)) * 6.dbamp;
    snd = FreqShift.ar(snd, randomLFO.() * 100);
  };
  snd = Limiter.ar(snd);
  snd = snd * -2.dbamp;
  snd;
}.play(fadeTime: 0);
)


(

SynthDef(\pulsaretXold, {
  arg out = 0;
  // variables
  var snd, freq, formantCount,
  formantFreq, sineCycles, pulsaretPhase,
  window, randomLFO, randomLFOs, lfoRate, mouseX;
  formantCount = 3;
  lfoRate = LFDNoise1.kr(0.3).linexp(-1, 1, 0.1, 16);
  /* randomLFO = {
  var trigger;
  trigger = Dust.kr(lfoRate);
  Select.kr(ToggleFF.kr(trigger), [
  LFNoise2.kr(lfoRate),
  TRand.kr(-1, 1, trigger)
  ]);
  };



  randomLFOs = { { randomLFO.() } ! formantCount };

  */
  // Get mouse X position (normalized to -1 to 1)
  mouseX = MouseX.kr(-1, 1);

  // Modified randomLFO function that returns MouseX values with offsets
  randomLFO = { |offsetIndex = 0|
    var offset = offsetIndex.linlin(0, formantCount - 1, -1, 1);
    var wrappedMouseX = (mouseX + offset).wrap(-1, 1);
    wrappedMouseX;
  };

  // Create array of LFO values with offsets
  randomLFOs = { { |i| randomLFO.(i) } ! formantCount };Ï

  freq = randomLFO.().linexp(-1, 1, 1, 1000);
  formantFreq = randomLFOs.().linexp(-1, 1, 2, 8000);
  sineCycles = randomLFOs.().linlin(-1, 1, 1, 4);
  pulsaretPhase = LFSaw.ar(freq, iphase: 1).linlin(-1, 1, 0, 1) * formantFreq / freq;
  window = pulsaretPhase.lincurve(0, 1, 1, 0, -4);
  snd = sin(pulsaretPhase * 2pi * sineCycles.floor) * window * (pulsaretPhase < 1);
  snd = snd * randomLFOs.().linlin(-1, 1, 0, 1);
  snd = Pan2.ar(snd, randomLFOs.() * 0.4);
  snd = snd.flop.sum;
  [0.2, 0.1, 0.05].do { |windowSize|
    snd = PitchShift.ar(snd, windowSize, randomLFO.().linexp(-1, 1, 0.5, 2)) * 6.dbamp;
    snd = FreqShift.ar(snd, randomLFO.() * 100);
  };
  snd = Limiter.ar(snd);
  snd = snd * -2.dbamp;
  Out.ar(out, snd);
}).add;
)

x = Synth(\pulsaret)

x.free


(
SynthDef(\pulsaretXY, {
  arg out = 0;
  // variables
  var snd, freq, formantCount,
  formantFreq, sineCycles, pulsaretPhase,
  window, randomLFO, randomLFOs, lfoRate,
  mouseX, mouseY, baseOffset, randomOffset;

  formantCount = 3;

  // Get mouse positions
  mouseX = MouseX.kr(-1, 1);
  mouseY = MouseY.kr(0.001, 0.734); // MouseY controls offset randomization

  // Modified randomLFO function that returns MouseX values with offset
  randomLFO = { |offsetIndex = 0|
    var offsetRange, offset, wrappedMouseX;

    // Base offset based on index (evenly spaced from -1 to 1)
    offset = offsetIndex.linlin(0, formantCount - 1, -1, 1);

    // Add randomized offset controlled by MouseY
    // MouseY=0.001: tiny randomization (almost no offset)
    // MouseY=0.734: larger randomization
    // offset = offset + LFNoise2.kr(0.3).range(0, mouseY * 2);
    offset = offset + LFNoise2.kr(0.1).range(0, mouseY);

    // Wrap the mouse position with offset
    wrappedMouseX = (mouseX + offset).wrap(-1, 1);
    wrappedMouseX;
  };

  // Create array of LFO values with offsets
  randomLFOs = { { |i| randomLFO.(i) } ! formantCount };

  freq = randomLFO.().linexp(-1, 1, 20, 1000);
  formantFreq = randomLFOs.().linexp(-1, 1, 2, 8000);
  sineCycles = randomLFOs.().linlin(-1, 1, 1, 4);
  pulsaretPhase = LFSaw.ar(freq, iphase: 1).linlin(-1, 1, 0, 1) * formantFreq / freq;
  // pulsaretPhase = SinOsc.ar(freq, iphase: 1).linlin(-1, 1, 0, 1) * formantFreq / freq;
  window = pulsaretPhase.lincurve(0, 1, 1, 0, -4);
  snd = sin(pulsaretPhase * 2pi * sineCycles.floor) * window * (pulsaretPhase < 1);
  snd = snd * randomLFOs.().linlin(-1, 1, 0, 1);
  snd = Pan2.ar(snd, randomLFOs.() * 0.4);
  snd = snd.flop.sum;
  [0.2, 0.1, 0.05].do { |windowSize|
    snd = PitchShift.ar(snd, windowSize, randomLFO.().linexp(-1, 1, 0.5, 6)) * 6.dbamp;
    snd = FreqShift.ar(snd, randomLFO.() * 100);
  };
  snd = Limiter.ar(snd);
  snd = snd * -2.dbamp;
  Out.ar(out, snd);
}).add;


)

x = Synth(\pulsaretXY)

x.free


Buffer.freeAll
b = Buffer.readChannel(s, "/Users/ya/Documents/supercollider/sc-patches/00021-break.wav", channels:[0])

b.play

(
SynthDef(\pulsaretXYsample, {
  arg out = 0, sample=0;
  // variables
  var snd, freq, formantCount,
  formantFreq, sineCycles, pulsaretPhase,
  window, randomLFO, randomLFOs, lfoRate,
  mouseX, mouseY, baseOffset,
  randomOffset, rate;



  formantCount = 3;

  // Get mouse positions
  mouseX = MouseX.kr(-1, 1);
  mouseY = MouseY.kr(0.001, 0.734); // MouseY controls offset randomization

  // Modified randomLFO function that returns MouseX values with offset
  randomLFO = { |offsetIndex = 0|
    var offsetRange, offset, wrappedMouseX;

    // Base offset based on index (evenly spaced from -1 to 1)
    offset = offsetIndex.linlin(0, formantCount - 1, -1, 1);

    // Add randomized offset controlled by MouseY
    // MouseY=0.001: tiny randomization (almost no offset)
    // MouseY=0.734: larger randomization
    // offset = offset + LFNoise2.kr(0.3).range(0, mouseY * 2);
    offset = offset + LFNoise2.kr(0.1).range(0, mouseY);

    // Wrap the mouse position with offset
    wrappedMouseX = (mouseX + offset).wrap(-1, 1);
    wrappedMouseX;
  };

  // Create array of LFO values with offsets
  randomLFOs = { { |i| randomLFO.(i) } ! formantCount };

  freq = randomLFO.().linexp(-1, 1, 20, 1000);
  rate = randomLFO.().linlin(-1, 1, -2, 4);
  formantFreq = randomLFOs.().linexp(-1, 1, 2, 8000);
  sineCycles = randomLFOs.().linlin(-1, 1, 1, 4);
  // pulsaretPhase = LFSaw.ar(freq, iphase: 1).linlin(-1, 1, 0, 1) * formantFreq / freq;
  // pulsaretPhase = SinOsc.ar(freq, iphase: 1).linlin(-1, 1, 0, 1) * formantFreq / freq;
  // pulsaretPhase = PlayBuf.ar(1, sample, BufRateScale.kr(sample) * rate, 1, loop:1 ).linlin(-1, 1, 0, 1) * formantFreq / freq;
  pulsaretPhase = PlayBuf.ar(1, sample, BufRateScale.kr(sample) * rate, trigger: 1, loop:1 ).linlin(-1, 1, 0, 1) * formantFreq / freq;

  window = pulsaretPhase.lincurve(0, 1, 1, 0, -4);
  snd = sin(pulsaretPhase * 2pi * sineCycles.floor) * window * (pulsaretPhase < 1);
  // snd = sin(pulsaretPhase * pi * sineCycles.floor) * window * (pulsaretPhase < 1);
  snd = snd * randomLFOs.().linlin(-1, 1, 0, 1);
  snd = Pan2.ar(snd, randomLFOs.() * 0.4);
  snd = snd.flop.sum;
  [0.2, 0.1, 0.05].do { |windowSize|
    snd = PitchShift.ar(snd, windowSize, randomLFO.().linexp(-1, 1, 0.5, 6)) * 6.dbamp;
    snd = FreqShift.ar(snd, randomLFO.() * 100);
  };
  snd = Limiter.ar(snd);
  // snd = pulsaretPhase;
  snd = snd * -2.dbamp;
  Out.ar(out, snd);
}).add;


)

x = Synth(\pulsaretXYsample, [\sample, b])

x.free


s.boot

