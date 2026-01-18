s.boot;
Server.default.options.outDevice_("AudioBox USB 96");
Server.default.options.outDevice_("BlackHole 16ch");
// Paulstretch for SuperCollider
  // Based on the Paul's Extreme Sound Stretch algorithm by Nasca Octavian PAUL
  // https://github.com/paulnasca/paulstretch_python/blob/master/paulstretch_steps.png
  //
  // By Jean-Philippe Drecourt
  // http://drecourt.com
  // April 2020
  //
  // Arguments:
  // out: output bus (stereo output)
  // bufnum: the sound buffer. Must be Mono. (Use 2 instances with Buffer.readChannel for stereo)
  // envBufnum: The grain envelope buffer created as follows:
  //// envBuf = Buffer.alloc(s, s.sampleRate, 1);
  //// envSignal = Signal.newClear(s.sampleRate).waveFill({|x| (1 - x.pow(2)).pow(1.25)}, -1.0, 1.0);
  //// envBuf.loadCollection(envSignal);
  // pan: Equal power panning, useful for stereo use.
  // stretch: stretch factor (modulatable)
  // window: the suggested grain size, will be resized to closest fft window size
  // amp: amplification
(
SynthDef(\paulstretchMono, { |out = 0, bufnum, envBufnum, pan = 0, stretch = 50, window = 0.25, amp = 1|
  var trigPeriod, sig, chain, trig, pos, fftSize;
  // Calculating fft buffer size according to suggested window size
  fftSize = 2**floor(log2(window*SampleRate.ir));
  // Grain parameters
  // The grain is the exact length of the FFT window
  trigPeriod = fftSize/SampleRate.ir;
  trig = Impulse.ar(1/trigPeriod);
  pos = Demand.ar(trig, 0, demandUGens: Dseries(0, trigPeriod/stretch));
  // Extraction of 2 consecutive grains
  // Both grains need to be treated together for superposition afterwards
  sig = [
    GrainBuf.ar(1, trig, trigPeriod, bufnum, 1, pos, envbufnum: envBufnum),
    GrainBuf.ar(1, trig, trigPeriod, bufnum, 1, pos + (trigPeriod/(2*stretch)), envbufnum: envBufnum)]*amp;
  // FFT magic
  sig = sig.collect({ |item, i|
    chain = FFT(LocalBuf(fftSize), item, hop: 1.0, wintype: -1);
    // PV_Diffuser is only active if its trigger is 1
    // And it needs to be reset for each grain to get the smooth envelope
    chain = PV_Diffuser(chain, 1 - trig);
    item = IFFT(chain, wintype: -1);
  });
  // Reapply the grain envelope because the FFT phase randomization removes it
  sig = sig*PlayBuf.ar(1, envBufnum, 1/(trigPeriod), loop:1);
  // Delay second grain by half a grain length for superposition
  sig[1] = DelayC.ar(sig[1], trigPeriod/2, trigPeriod/2);
  // Panned output
  Out.ar(out, Pan2.ar(Mix.new(sig), pan));
}).add;
)

~reverb_bus = Bus.audio(s, 2);






s.boot

"/Users/ya/Documents/supercollider/paulstretch-mono/boys.wav"
"/Users/ya/Documents/supercollider/paulstretch-mono/khole.wav"
"/Users/ya/Documents/supercollider/paulstretch-mono/the-Sea.wav"
"/Users/ya/Documents/supercollider/paulstretch-mono/kill0he-poor.wav"
"/Users/ya/switchdrive2/Private/music/breakcore-samples/pico-drums/gabba-kickis/gabber-kick-00001_mono.wav"
// Example
/*({
var envBuf, envSignal, buffer;
buffer = Buffer.read(s, "/Users/ya/Documents/supercollider/paulstretch-mono/khole.wav");
// The grain envelope
envBuf = Buffer.alloc(s, s.sampleRate, 1);
envSignal = Signal.newClear(s.sampleRate).waveFill({|x| (1 - x.pow(2)).pow(1.25)}, -1.0, 1.0);
envBuf.loadCollection(envSignal);
s.sync();
// Runs indefinitely
buffer.bufnum.postln;
envBuf.bufnum.postln;
~s = Synth(\paulstretchMono, [\out, ~reverb_bus,\bufnum, buffer.bufnum, \envBufnum, envBuf.bufnum, \stretch, 1000]);
}.fork;
)*/

(
~buffer = Buffer.read(s, "/Users/ya/Documents/supercollider/paulstretch-mono/boys.wav");
~envBuf = Buffer.alloc(s, s.sampleRate, 1);
~envSignal = Signal.newClear(s.sampleRate).waveFill({|x| (1 - x.pow(2)).pow(1.25)}, -1.0, 1.0);
~envBuf.loadCollection(~envSignal);
~buffer.bufnum.postln;
~envBuf.bufnum.postln;
~s = Synth(\paulstretchMono, [\out, ~reverb_bus,\bufnum, ~buffer.bufnum, \envBufnum, ~envBuf.bufnum, \stretch, 1000]);
)


s.killAll;

~s.set(\stretch, 1000)
~s.set(\out, ~reverb_bus)
~s.free;




(
SynthDef.new(\reverb,
  {
    arg in=0, mix=0.4, out=0, mod_speed=0.05, lpf=3000;
    var sig, wet, verb_mod, mod_carrier, lpf_mod;
    sig = In.ar(in, 2); // reads from the audio bus
    mod_carrier = SinOsc.kr(mod_speed).range(0.005, 1);
    verb_mod = SinOsc.kr(mod_carrier).range(0.2, 0.999);
    lpf_mod = SinOsc.kr(mod_speed).range(0, 500) + lpf;

    sig = RLPF.ar(sig, lpf_mod.clip(25, 19500), 0.5);
    sig = FreeVerb2.ar(
      sig[0], sig[1],
      mix: mix.clip(0.0, 1.0), room: verb_mod, damp: 0.85
    );
    Out.ar(out, sig)
}).add;
)

~verb = Synth(\reverb, [\in, ~reverb_bus]);
~verb.set(\mix, 0.5);
~verb.set(\lpf, 15000);
~verb.set(\mod_speed, 0.75);