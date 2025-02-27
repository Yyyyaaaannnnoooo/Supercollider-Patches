

s.boot
(
SynthDef(\supersaw, {|out=0, rate=1, decay=0, sustain=1, pan, accelerate, freq,
  voice=0.5, semitone=12, resonance=0.2, lfo=1, pitch1=1, speed=1, cutoff=8000, cutoffD=0|
  var env = EnvGen.ar(Env.pairs([[0,0],[0.05,1],[0.2,1-decay],[0.95,1-decay],[1,0]], -3), timeScale:sustain, doneAction:2);
  var basefreq = freq * DirtFreqScale.kr(speed, accelerate, sustain);
  var basefreq2 = basefreq * (2**(semitone/12));
  var lfof1 = min(basefreq*10*pitch1, 22000);
  var lfof2 = min(lfof1 * (lfo + 1), 22000);
  var sig = (0.5 * Mix.arFill(5, {|i|SawDPW.ar(basefreq * ((i)*voice/50+1), 0)})) + (0.5 * LFTri.ar(basefreq2, voice));
  var lpfmod = LFTri.ar(basefreq/64*rate, 0.5).range(lfof1,lfof2).clip(20, 19500);
  var sound = MoogFF.ar(sig, lpfmod, resonance*4);
  sound = RLPF.ar(sound, cutoff);
  sound = sound.tanh*2;
  Out.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add
)


x.free;

x = Synth(\supersaw, [\cutoff, 1800, \voice, 0.125 / 2, \sustain, 3, \freq, 50.midicps]);

(
SynthDef(\hoover, {
  var snd, freq, bw, delay, decay;
  freq = \freq.kr(440);
  freq = freq * Env([-5, 6, 0], [0.1, 1.7], [\lin, -4]).kr.midiratio;
  bw = 1.035;
  snd = {DelayN.ar(Saw.ar(freq * ExpRand(bw, 1 / bw)) + Saw.ar(freq * 0.5 * ExpRand(bw, 1 / bw)), 0.01, Rand(0, 0.01)) }.dup(20);
  snd = (Splay.ar(snd) * 3).atan;
  snd = snd * Env.perc(0.01, \rel.kr(4), 1.0).kr(0, \gate.kr(1));
  snd = FreeVerb2.ar(snd[0], snd[1], 0.3, 0.9);
  snd = snd * Env.perc(0, \rel.kr(4), 1, 6).kr(2, \gate.kr(1));
  snd = Pan2.ar(snd, \pan.kr(0));
  Out.ar(\out.kr(0), snd * \amp.kr(0.1));
}).add;
)

Env.perc(0, 4, 1, 6).plot

y.free;

y = Synth(\hoover, [\freq, 80.midicps, \rel, 1])
y.set(\gate, 0)


t = TempoClock.new(185/60).permanent_(true);

(
Pdef(\hoova, Pbind(
  \instrument, \hoover,
  \dur, Pseq((0.25 ! 12) ++ (Rest(0.5)!1), inf),
  \freq, Pseq(([60, 68, 64]).midicps,inf),
  \rel, 1
))
)

(
Pdef(\hoova).quant_(4);
Pdef(\hoova).fadeTime = 1.0;
Pdef(\hoova).play(t, doReset: false);
)
