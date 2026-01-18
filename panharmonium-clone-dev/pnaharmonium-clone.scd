s.boot;
s.quit;
(
// Server.default.options.inDevice_("BlackHole 16ch");
Server.default.options.outDevice_("Multi-Output Device");
s.options.numInputBusChannels = 2;
s.reboot;
)
l = Buffer.read(s, "/Users/ya/Documents/supercollider/sc-patches/panharmonium-clone/waves.wav")

l.plot
~waves;
~wt_size;
~wt;

Env([0,1,0], [0.01,1], 0.2).plot
Env([0,1,1,0,0], [0, 0.5, 0,0.5], 0.2).plot
(


~wavetable_from_signals = {
  var waves, size = 2048;
  Buffer.freeAll;
  waves = [
    Signal.sineFill(size: size, amplitudes:1.0/[1]).asWavetable,
    // tri
    Env([0,1,0], [1,1], [-0.2, 0.2]).asSignal(size).asWavetable,
    // saw
    Env([0,1,0], [0.01,1], 0.2).asSignal(size).asWavetable,
    // square
    Env([0,1,1,0,0], [0, 0.5, 0,0.5], 0.2).asSignal(size).asWavetable;
  ];
  waves.size.postln;
  ~wt = Buffer.allocConsecutive(waves.size, s, size*2);
  ~wt.do({
    arg buf, i;
    buf.loadCollection(waves[i]);
  });
};

~wavetable_from_file = {
  arg path;
  var load_waves, make_wavetable, buffer;
  load_waves = {
    arg path;
    var buffer_array;
    var directory = PathName(path).entries;
    Buffer.freeAll;
    buffer_array = directory.collect({
      arg filename;
      var buf;
      buf = Buffer.read(s, filename.fullPath);
    });
  };

  make_wavetable = {
    arg waves;
    var frames, size;
    frames = waves[0].numFrames;
    ~wt_size = waves.size;
    ~wt = Buffer.allocConsecutive(~wt_size, s, frames*2);
    ~wt.do({
      arg buf, i;
      buf = waves[i];
    })
  };
  {
    buffer = load_waves.(path);
    0.5.wait;
    "waves loaded".postln;
    make_wavetable.(buffer);
    "Wavetbles compiled".postln;
  }.fork
};

// ~wavetable_from_file.("/Users/ya/Documents/supercollider/sc-patches/panharmonium-clone/wave-single/")
)


~wavetable_from_signals.()

(
~init = {
  s.newBusAllocators;
  ~mic = Bus.audio(s, 1);
  ~bus1 = Bus.audio(s, 2);
  ~synths = Group.new();
  ~fx = Group.after(~synths);
};
~init.();
s.meter;
s.scope;
s.plotTree;
)



(
SynthDef.new(\vosc, {
  arg out=0, amp=0.5, buf=0, num_bufs=9, freq=80, lpf=20000;
  var sig, bufpos, detune, mod, lpf_mod;
  detune = LFNoise1.kr(0.2!5).bipolar(0.2).midiratio;
  detune =  Select.kr(\detune.kr(0), [1, detune]);
  sig = VOsc.ar(\wt.kr(0, 2), freq*detune);
  sig = RLPF.ar(sig, 12000, 1.0);
  sig = sig!2 * amp;
  Out.ar(out, sig);
}).add;

SynthDef(\mic, {
  arg in=0, amp = 0.5, rot = 0, out = 0;
  var sig;
  sig = SoundIn.ar(in, 1);
  Out.ar(out, sig);
}).add;

// SynthDef(\additive, {
//   arg out=~ch4;
//   var offsets = ~waves.collect ({ arg i; In.kr(~imagBus2.index + i) });
//   var freqs = (1..~waves).linexp(1, ~waves, 30, 220);
//   var sines, sig, control, numsines = ~waves;
//   control = freqs + (offsets * 100);
//   sines = Mix(
//     SinOsc.ar(
//       control.varlag(0.125,-3),
//       0,
//       numsines.reciprocal * SinOsc.kr(\lfo.kr(1, 0.25)).range(-1, 1)
//   ));
//   sig = sines * \amp.kr(-24.dbamp, 0.25);
//   // sig = Splay.ar(sig, 1);
//   Out.ar(out, sig!2);
// }).add;



// From Nick Collins: https://composerprogrammer.com/teaching/supercollider/sctutorial/12.2%20Singing%20Voice%20Synthesis.html
SynthDef(\vocoder,{
  arg freq=200, voiced=1, amp=4;

  var centrefreqs, amps, bandwidths, rq; //data for formants

  var analysissignal,
  synthesissignal,
  periodicsource,
  aperiodicsource;

  var analysisfilters, synthesisfilters;

  //choose centre frequencies
  centrefreqs= (1..33)*(440*0.25);

  amps= (0.dup(10)).dbamp;
  //(1..10)*200;  //bandwidths
  bandwidths= 300.dup(10);
  //reciprocal of q; bandwidth/centrefreq
  rq= bandwidths/centrefreqs;
  analysissignal= SoundIn.ar; //analyze audio input on machine

  periodicsource=Saw.ar(freq);


  //pink noise drops off as frequency increases at -dB per octave,

  aperiodicsource= PinkNoise.ar(0.7);


  //take now as mixture of periodic and aperiodic

  synthesissignal= (voiced*periodicsource)+((1.0-voiced)*aperiodicsource);
  //do the analysis in the specified bands, finding the amplitude in each band
  analysisfilters = Amplitude.kr(BPF.ar(analysissignal, centrefreqs, rq));
  //modulate bandwise the resynthesis
  synthesisfilters = analysisfilters*BPF.ar(synthesissignal, centrefreqs, rq);


  //amp compensates for energy lost by filters

  Out.ar(0,(amp*Mix(synthesisfilters)).dup)

}).add;




SynthDef(\resynth,{
  arg in=0, amp = 3, rot = 0,
  out = 0, num_bufs=9, numBands = 33;
  var sig, car1, car2, mod,
  num = 33, bpfmod, q = \q.kr(20), rq,
  track, sel, bpfhz, glidingFreqs, bufpos,
  detune, resample_t, input,
  fMin=20, fMax=11500, centerFreq = (fMax-fMin)*0.5,
  centerBand = 16, halfRange, startBand, endBand, selectedIndices,
  bandPositions = (0..num-1), mask, maskedSig,
  activeBands, outBands, centerIndex = (num-1)/2;
  numBands.clip(1, 33);
  resample_t = Impulse.ar(\trig.kr(10));
  // bpfhz = (1..num).linexp(1, num, 20, 11500);
  // bpfhz = (1..num).linexp(1, num, 1, num)*\center.kr(440);
  bpfhz = (1..num).linexp(1, num,
    \center.kr(440) * (1/(centerIndex+1)),
    \center.kr(440) * (centerIndex+1)
  );
  input = SoundIn.ar(in, 1);
  bpfmod = BPF.ar(input, bpfhz, 1/q, sqrt(q));
  track = Latch.ar(
    Amplitude.ar(bpfmod),
    resample_t + \freeze.kr(0);
  ).lag(0.01);
/*  detune = LFNoise1.kr(0.2!8).bipolar(0.2).midiratio;
  detune =  Select.kr(\detune.kr(0), [1, detune]);
  sig = VOsc.ar(
    \wt.kr(0).varlag(0.5),
    (bpfhz +  \freq.kr(0)) * detune,
    mul: track;
  );*/
  sig = VOsc.ar(
    (\wt.kr(0) - 0.01).varlag(0.5),
    (bpfhz +  \freq.kr(0)),
    mul: track;
  );
  // >>DeepSeek help from here
  // Select bands symmetrically around center band (16)
  halfRange = (numBands - 1) / 2;
  startBand = (centerBand - halfRange).round.asInteger;
  endBand = (centerBand + halfRange).round.asInteger;
  // Clamp to valid range (0-32)
  startBand = startBand.max(0);
  endBand = endBand.min(num - 1);
  // Create mask: 1 for bands in range, 0 for bands outside range
  mask = bandPositions.collect { arg pos;
    var inRange = (pos >= startBand) * (pos <= endBand);
    inRange;
  };
  // >>Until here
  // Apply mask and remove zero channels
  sig = sig * mask;
  sig = Splay.ar(sig.scramble, 0);
  sig = sig * amp;
  Out.ar(out, sig);
}).add;


SynthDef(\cloudcloud, {
  arg inbus=0, dens1=0, dens2=0, dw=0.5, size1=0, size2=0;
  var sig, t, in, mod;
  t = Pulse.kr(\rate.kr(100));
  in = In.ar(inbus,2);
  mod = SinOsc.kr(\c1mod.kr(0.1, 0.5), (0..6).linlin(0,6,0, 2pi));
  sig = MiClouds.ar(in,
    pit: mod[0].range(0,0.25),
    pos: mod[1].range(0,1),
    size: mod[2].range(0,0.5),
    dens: mod[3].range(0,1),
    tex: 0.5,
    drywet: dw,
    in_gain: 1,
    spread: mod[4].range(0,1),
    rvb: mod[5].range(0,1),
    fb: mod[6].range(0,0.25),
    trig:t
  );
  sig = MiClouds.ar(sig, pit: 0,
    pos: LFNoise0.kr(300).range(0,1),
    size: size2,
    dens: dens2,tex: 0.5,drywet: dw,in_gain: 1,spread: 0.5, trig:t
  );
  Out.ar(0, sig);
}).add;


~synths.freeAll;
~fx.freeAll;
)

~init.()
x.free


x = Synth(\resynth, [\out, 0], target:~fx)
x.set(\trig, 10)
x.set(\freq, 50)
x.set(\detune, 1)
x.set(\wt, 2)
x.set(\amp, 2)
x.set(\numBands, 13)
x.set(\center, 200)
x.set(\freeze, 0)



y = Synth.after(x, \cloudcloud,[\inbus, ~bus1] )

y.set(\c1mod, 0.025)
y.set(\size2, 1)
y.set(\dens2, 1.0)
y.set(\dw, 1)
y.set(\rate, 1)
y.free

33.dbamp

MiClouds