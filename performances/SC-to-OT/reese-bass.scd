s.boot
(
///~~~ BUSSES ~~~///
s.newBusAllocators;
~reverb_bus = Bus.audio(s, 2);
~tp_dly_bus = Bus.audio(s, 2);

SynthDef.new(\reverb,
  {
    arg in=0, mix=0.4, out=0, mod_speed=0.05;
    var sig, wet, verb_mod, mod_carrier;
    sig = In.ar(in, 2); // reads from the audio bus
    mod_carrier = SinOsc.kr(mod_speed).range(0.005, 1);
    verb_mod = SinOsc.kr(mod_carrier).range(0.2, 0.999);
    sig = FreeVerb2.ar(
      sig[0], sig[1],
      mix: mix.clip(0.0, 1.0), room: verb_mod, damp: 0.85
    );
    Out.ar(out, sig)
}).add;

SynthDef.new(\tapedly, {
  arg in=0, out=0,fb=0.6, fc=5000, dlytime=0.125, wet=0.5, pan=0.0, f_mod=1.0;
  var local, sig, delayed, phi, phR, phP, freq;
  var tdbh; // time delay between heads (seconds)
  local = LocalBuf(SampleRate.ir * 3, 1);
  local.clear; // clear the buffer

  tdbh = 0.125;
  phi = (2 * tdbh) / BufDur.ir(local);
  freq = f_mod.clip(0.125, 2.0) / BufDur.ir(local); // frequency to playback the buffer at rate 1
  freq = (freq * tdbh) / VarLag.kr(dlytime, 2, warp:\linear);
  phR = LFSaw.ar( freq, phi, 0.5, 0.5)*BufFrames.kr( local );
  phP = LFSaw.ar( freq, 0.0, 0.5, 0.5)*BufFrames.kr( local );

  sig = Mix.ar(In.ar(in,2));
  delayed = BufRd.ar(1, local, phP, loop:1);
  delayed = delayed.tanh;
  BufWr.ar( LPF.ar( (sig + delayed), fc.clip(25, 19500), mul:fb), local, phR, loop:1);
  // pan = LFNoise1.ar(5);
  Out.ar(out, Pan2.ar(delayed*wet, pan));
}).add;

s.sync;

~makeNodes = {
  ~synths = Group.new;
  ~fxs = Group.after(~synths);
  ~verb = Synth.new(\reverb, [\in, ~reverb_bus], target: ~fxs);
  ~delay = Synth.new(\tapedly, [\in, ~tp_dly_bus, \out, ~reverb_bus], target: ~fxs);
};
~makeNodes.()
)
(
SynthDef(\reese, {
  arg freq = 120, lpf = 800, nof=0.25,a=1.5, s=2, r=1, amp = -6.dbamp;
  var sig, voices = 16, detune = 10, env;
  sig = LFSaw.ar((Array.series(voices, 0.01, 0.37).rand2 + freq).varlag(1.5, -3), 0, voices.reciprocal);
  sig = RLPF.ar(sig, lpf.clip(20, 17000).varlag(0.75, -3), 1);
  sig = FreeVerb.ar(sig, 0.5, 0.5, 0.5);
  sig = sig.sum;
  sig = sig!2;
  env = EnvGen.kr(Env.new([0,1,0.75,0], [a,s,r], curve:[2, -3, -3]),gate: \gate.kr(1.0), doneAction: 2);
  sig = sig * env;
  sig = sig * amp;
  Out.ar(0, sig);
}).add;
)

x = Synth(\reese, [\freq, 66.midicps, \a, 1.5, \s, 4, \r, 3, \lpf, 600])
x.set(\freq, 54.midicps)
x.set(\lpf, 1400)


x.free

(
~r0 = Pdef(\pad, Pbind(
  \instrument, \reese,
  // \group, ~synths,
  \dur, 0.25,
  // \dur, Pxrand([1, 2, 4, 6, 8] / 8, inf),
  // \a, Pwhite(1.5 / 8, 3 / 8, inf),
  \a, 0.001,
  \s, Pfunc({arg e; var r; var d = e[\dur]; var a = e[\a]; r = d + a}),
  \freq, Pseq([66, 64, 55, 66, 77, 66, 66, 66].scramble.midicps, inf)),
  \amp, 5.dbamp,
  \out, 0
)
)

~r0.play

~r0.stop

~verb.set(\mix, 0.6)
~delay.set(\dlytime, 2)