s.newBusAllocators;
~tp_dly_bus = Bus.audio(s, 2);

(
SynthDef.new(\rythm, {
  arg speed = 0.1, out = 0;
  var voices = 8;
  // sound gen
  var sig = LFSaw.ar(
    (Array.series(voices, 0.01, 0.37).rand2 + \freq.kr(110)).varlag(1.5, -3),
    0,
    voices.reciprocal);
  sig = sig!2;
  sig = BPF.ar(sig,
    [
      SinOsc.kr(speed).linexp(-1, 1, 50, 8000).clip(50, 19000),
      SinOsc.kr(speed + rand(0.01, 0.123)).linexp(-1, 1, 8000, 50).clip(50, 19000)
  ], 1.0);
  sig  = sig * -12.dbamp;
  Out.ar(out, sig);
}).add;
)

Phasor
(
SynthDef.new(\tapedly, {
  arg in=0, out=0,fb=0.6, fc=5000, dlytime=0.125, wet=0.5, pan=0.0, f_mod=1.0;
  var local, sig, delayed, phi, phR, phP, freq;
  var tdbh; // time delay between heads (seconds)
  local = LocalBuf(SampleRate.ir * 3, 2);
  local.clear; // clear the buffer

  tdbh = 0.125;
  phi = (2 * tdbh) / BufDur.ir(local);
  freq = f_mod.clip(0.125, 2.0) / BufDur.ir(local); // frequency to playback the buffer at rate 1
  freq = (freq * tdbh) / VarLag.kr(dlytime, 2, warp:\linear);
  phR = LFSaw.ar( freq, phi, 0.5, 0.5)*BufFrames.kr( local );
  phP = LFSaw.ar( freq, 0.0, 0.5, 0.5)*BufFrames.kr( local );

  sig = Mix.ar(In.ar(in,2));
  delayed = BufRd.ar(2, local, phP, loop:1);
  delayed = delayed.tanh;
  BufWr.ar(
    LPF.ar( (sig + delayed) ! 2, fc.clip(25, 19500), mul:fb),
    local, phR, loop:1);
  // pan = LFNoise1.ar(5);
  Out.ar(out, Pan2.ar(delayed*wet, pan));
}).add;
)

(
~synths = Group.new;
~fxs = Group.after(~synths);
~tp_dly = Synth.new(\tapedly, [\in, ~tp_dly_bus], target: ~fxs);
)

x.free;
~tp_dly.free

x = Synth(\rythm, [\speed, 0.01, \out, ~tp_dly_bus], target: ~synths)
x.set(\speed, 0.1, \freq, 60)

~tp_dly.set([\dlytime, 1, \fb, 0.7, \wet, 0.75, \f_mod, 2])


