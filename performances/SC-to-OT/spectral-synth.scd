s.boot;

Server.default.options.outDevice_("AudioBox USB 96");



(
SynthDef(\additive, {
  arg out=0, amp = 0.5, trig = 0, dist = 3.43, rate=0.25, ratio = 2;
  var sines, sig, sigL, sigR, penv, control, numsines, chain, size = 1024, mod;
  numsines = 20;
  control = Control.names(\array).kr(Array.rand(numsines, 40.0, 1100.0));
  trig = Trig.kr(SinOsc.kr(rate));
  penv = EnvGen.ar(Env.adsr(0.75,0,1,rate-0.75, curve: -4, bias: 1), trig);
  // sines = Mix(SinOsc.ar(control.varlag(1.5, -3), 0, numsines.reciprocal));
  sines = Mix(SinOsc.ar(control.varlag(1.5, -3), 0, numsines.reciprocal));
  sines = sines + PinkNoise.ar(0.125);
  mod = LFBrownNoise2.ar(rate, 1,1);
  chain = FFT(LocalBuf(size), sines);
  chain = PV_BinShift(chain, MouseX.kr(0.25, 8, \exponential, 0.8), 0.8, interp: 1);
  chain = PV_BinScramble(chain, 0.125, 0.125, trig);
  // chain = PV_Freeze(chain, trig);
  // chain = PV_Diffuser(chain, trig);
  // chain = PV_PartialSynthF

  // chain = PV_MagFreeze(chain, SinOsc.kr(rate) );
  // chain = PV_SpectralEnhance(chain, 16, 2, 0.75);
  // chain = PV_PhaseShift(chain, 8, phasemod * pi);
  // chain = PV_NoiseSynthP(chain, MouseY.kr(0, pi/4));
  // chain = PV_MagAbove(chain, SinOsc.kr(SinOsc.kr(rate).range(rate, rate*3.34)).abs * 10);
  chain = PV_PitchShift(chain, ratio.varlag(0.5, -3));
  // chain = PV_BrickWall(chain, SinOsc.kr(0.125).range(-1, -0.00001).poll);
  sigL = IFFT(chain);
  sigL = FreeVerb.ar(sigL, 0.5, 1, 0.5);
  // sigR = PitchShiftPA.ar(sigL, Pitch.kr(sigL)[0], 2.1, 2);
  // sigR = FreeVerb.ar(sigR, 0.5, 1, 0.5);
  // sig = Disintegrator.ar(sig, 0.5, 0.25);
  // sig = CrossoverDistortion.ar(sig, 0.25, 0.95);
  // sig = (sig * dist).tanh * 2;
  // sig = (sig * (dist / 2)).atan;
  // sig = sig * amp;
  // sig = Splay.ar(sig, 1)* amp;
  sigL = sigL * amp * penv;
  // sigR = sigR * amp;
  // sig = Limiter.ar(sig, 0.25, 0.02);
  // sigL = Compander.ar(sigL, sigL, 0.05, 1, 0.1, 0.01, 0.01);
  // sigR = Compander.ar(sigR, sigR, 0.05, 1, 0.1, 0.01, 0.01);
  // Out.ar(out, [sigL, sigR]);
  Out.ar(out, sigL!2);
}).add;
)

(
b.free;
b = Synth(\additive);
)

b.setn(\rate, 10)
b.setn(\ratio, 0.2)

b.setn(\array, [50, 2000])

b.setn(\array, Array.rand(20, 200, 160));
b.setn(\dist, 2);
b.setn(\array, {rrand(400, 1200.rand)}!20);
(
b.set(\trig, 0);
// b.setn(\array, {rrand(20, 600)}.dup(20));
b.set(\trig, 1);
)



