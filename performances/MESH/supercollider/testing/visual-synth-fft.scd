s.boot



(
// Server.default.options.outDevice_("Multi-Output Device");
// Server.default.options.inDevice_("BlackHole 16ch");
Server.default.options.outDevice_("BlackHole 16ch");
s.options.numOutputBusChannels = 8;
// s.options.numInputBusChannels = 2;
s.reboot;
)
s.quit
(
s.newBusAllocators;
~size = 1024;
~hop = 0.25;
~win = 0;
~imagBus = Bus.control(s, ~size);
~ratectrl = Bus.control(s, 1);
~micBus = Bus.audio(s, 2);
~recBus = Bus.audio(s, 2);
~fxBusRev = Bus.audio(s, 2);
~fxBusGran = Bus.audio(s, 2);
~ch1 = Bus.audio(s, 2);
~ch2 = Bus.audio(s, 2);
~ch3 = Bus.audio(s, 2);
~ch4 = Bus.audio(s, 2);

~synths = Group.new;
~fxs = Group.after(~synths);
~eoc = Group.after(~fxs);
// f = (1..~size).linexp(1, ~size, 25, 8000);

f = Array.rand(~size, 0, 1);
f.do({
  arg item, i;
  ~imagBus.setAt(i, item);
});

~setBus = {
  arg list;
  list.do({
    arg item, i;
    ~imagBus.setAt(i, item);
  })
}
)



// Set up OSC receive
(
OSCdef(
  key: \image,
  func: {
    arg msg, time, addr, recvPort;
    // msg.postln;
    msg.do({
      arg item, i;
      if(i>0,
        {~imagBus.setAt(i, item)}
      );
    })
  },
  path: '/image');
)

s.quit


(



SynthDef(\spectralimage, {
  arg in=0, rbuf;
  var mask = ~size.collect ({ arg i; In.kr(~imagBus.index + i) });
  var input, chain, sig, noise, mic;
  input = WhiteNoise.ar() * -12.dbamp;
  chain = FFT(LocalBuf(~size), input);
  chain = chain.pvcalc(~size, {
    arg mags, phases;
    [mags*mask, phases*mask]
  });
  // record also into PV-Buffer
  // chain = PV_RecordBuf(chain, rbuf, run:1, loop:1, hop:~hop, wintype:~win);
  sig = IFFT(chain);
  Out.ar(\aux.kr(~recBus), sig!2 * \send.kr(0.dbamp));
  sig = sig * \amp.kr(-6.dbamp);
  Out.ar(\out.kr(0), sig!2);
}).add;



SynthDef(\recorder, {
  arg bufnum, in;
  var input = In.ar(in, 2);
  RecordBuf.ar(input, bufnum, loop: 1);
  0;
}).add;

// Playback SynthDef
SynthDef(\glibuf, {
  arg bufnum, out = 0;
  var play, pos, trig = 1, env, kick, sweep, atk, rel;
  // trig = Impulse.kr(\trigrate.kr(4, 0.5));
  // COULD USE SELECTX.KR here to choose between random triggers and consecutive ones
  trig = Dust.kr(\trigrate.kr(4));
  sweep = Latch.kr(LFNoise1.kr(0.05).range(0.25, 3), trig);
  atk = Latch.kr(LFNoise1.kr(500).range(0.001, 0.2), trig);
  rel = Latch.kr(LFNoise1.kr(500).range(0.025, 0.75), trig);
  kick = EnvGen.kr(Env.perc(0.001, 0.25, sweep, -4), trig, doneAction:0);
  play = PlayBuf.ar(
    numChannels: 2,
    bufnum: bufnum,
    rate:BufRateScale.kr(bufnum) * \rate.kr(1, 0.0625) + kick,
    trigger: trig,
    startPos: \pos.kr(0).linlin(0, 2000, 0, BufFrames.kr(bufnum)),
    loop: 1);
  env = EnvGen.kr(Env.perc(
    atk,
    rel,
    1, -4),
  trig, doneAction:0);
  // play = Pan2.ar(play, );
  play = play * env;
  play = Balance2.ar(play[0], play[1], LFNoise1.kr(\pan.kr(4, 0.5)).range(-1, 1));
  Out.ar(\aux.kr(~fxBusRev), play * \send.kr(0, 0.25));
  Out.ar(out, play * \amp.kr(0.dbamp, 0.5));
}).add;

SynthDef(\vst, {
  arg in;
  var sig = VSTPlugin.ar(In.ar(in, 2), 2, id: \glitch);
  sig = Limiter.ar(sig, -6.dbamp, 0.01);
  Out.ar(\out.ar(0), sig * \amp.kr(2.dbamp));
}).add;

/*SynthDef(\vstReverb, {
arg in;
var sig = VSTPlugin.ar(In.ar(in, 2), 2,
params: [
0, \mix.kr(50),
1, lfo,
13, "Sagittarius"
]; id: \reverb);
sig = Limiter.ar(sig, -6.dbamp, 0.01);
Out.ar(\out.ar(0), sig * \amp.kr(2.dbamp));
}).add;*/
SynthDef(\pvrec, {
  arg in=0, rbuf=0, fftsize=1024, hop=0.25, win=0;
  var sig = In.ar(in, 2);
  var localbuf = {LocalBuf.new(fftsize)}!2;
  var chain = FFT(localbuf, sig, hop, win);
  chain = PV_RecordBuf(chain, rbuf, run:1, loop:1, hop:hop, wintype:win);
  0;
}).add;

SynthDef(\pvplay, {
  arg out=0, rbuf=0, fftsize=1024, hop=0.25, win=0;
  var localbuf = {LocalBuf.new(fftsize)}!2;
  var chain = PV_PlayBuf(
    buffer:localbuf,
    playbuf:rbuf,
    rate:\rate.kr(1).varlag(3,-1),
    loop:1
  );
  var sig;
  chain = PV_BinScramble(chain, \scrWipe.kr(0.125), \scrWidth.kr(0.5), \trig.tr(0));
  chain = PV_PitchShift(chain, \pitch.kr(1).varlag(0.5, -3));
  sig = IFFT(chain, win);
  Out.ar(\aux.kr(~fxBusRev), sig * \send.kr(0, 0.25));
  Out.ar(out, sig * \amp.kr(-6.dbamp, 0.25))
}).add;

// s.sync;

SynthDef(\eoc, {
  arg in1 = 0, in2 = 2, in3 = 4, in4 = 6;
  var input1 = In.ar(in1, 2);
  var input2 = In.ar(in2, 2);
  var input3 = In.ar(in3, 2);
  var input4 = In.ar(in4, 2);
  var sig1, sig2, sig3, sig4;
  sig1= RLPF.ar(input1, \lpf.kr(8000, 0.25).clip(20, 19000));
  sig1 = RHPF.ar(sig1, \hpf.kr(40, 0.5).clip(20, 19000));

  sig2= RLPF.ar(input2, \lpf.kr(8000, 0.25).clip(20, 19000));
  sig2 = RHPF.ar(sig2, \hpf.kr(40, 0.5).clip(20, 19000));

  sig3= RLPF.ar(input3, \lpf.kr(8000, 0.25).clip(20, 19000));
  sig3 = RHPF.ar(sig3, \hpf.kr(40, 0.5).clip(20, 19000));

  sig4= RLPF.ar(input4, \lpf.kr(8000, 0.25).clip(20, 19000));
  sig4 = RHPF.ar(sig4, \hpf.kr(40, 0.5).clip(20, 19000));
  ReplaceOut.ar(0, [sig1[0], sig1[1], sig2[0], sig2[1], sig3[0], sig3[1], sig4[0], sig4[1]]);
}).add;

)
s.meter

~specimg = Synth(\spectralimage,[\out, ~ch1], target:~synths)
~specimg.set(\amp, -12.dbamp)
~specimg.set(\amp, 0)
~specimg.set(\send, 0.dbamp)
~specimg.set(\out, ~fxBusGran)


~specimg.free

(
~bufferSize = 4;
~recordbuf = Buffer.alloc(s, s.sampleRate * ~bufferSize, 2);
)
~recorder = Synth.after(~specimg, \recorder, [\in, ~recBus, \bufnum, ~recordbuf]);
~recorder.free
~glitch = Synth.after(~recorder, \glibuf, [\bufnum, ~recordbuf, \out, ~ch2])
~glitch.set(\rate, 1)
~glitch.set(\ktrig, 1)
~glitch.set(\trigrate, 0.5)
~glitch.set(\send, 0.dbamp)
~glitch.set(\amp, 0)

~glitch.free
s.meter

~recbuf = {Buffer.alloc(s, 5.calcPVRecSize(~size,~hop))}!2;


~pvrec = Synth.after(~specimg, \pvrec, [ \in, ~recBus,\rbuf, ~recbuf,\fftsize, ~size,\hop, ~hop,\win, ~win])


~pvrec.free


~pvplay = Synth.after(~pvrec, \pvplay, [\out, ~ch3, \rbuf, ~recbuf, \fftsize, ~size,\hop, ~hop,\win, ~win])

~pvplay.set(\rate, 0.1)
~pvplay.set(\trig, 1)
~pvplay.set(\scrWipe, 0)
~pvplay.set(\scrWidth, 0.7)
~pvplay.set(\pitch, 1)
~pvplay.set(\amp, -6.dbamp)

~pvplay.free

~master = Synth(\eoc, [\in1, ~ch1, \in2, ~ch2, \in3, ~ch3, \in4, ~ch4, ],target:~eoc)
~master.set(\lpf, 8000)
~master.set(\hpf, 40)

~master.free

// Granular
~granular = Synth(\vst, [\in, ~fxBusGran, \out, ~fxBusRev],target:~fxs)
~vst1 = VSTPluginController(~granular)
~vst1.open("/Library/Audio/Plug-Ins/VST3/Emergence.vst3", verbose: true)
~vst1.editor
~vst1.gui
~vst1.free
~vst1.set(0, 0.125) //dry volume
~vst1.set(2, 0.5) //wet volume
~vst1.set(59, 0.125) //random 1 freq
~vst1.set(61, 0.25) //random 1 freq
~granular.free
~granular.set(\amp, -12.dbamp)
~granular.set(\out, ~fxBusRev)

// REVERB
~reverb = Synth.after(~granular, \vst, [\in, ~fxBusRev],target:~fxs)
~vst2 = VSTPluginController(~reverb)
// /Library/Audio/Plug-Ins/VST3/Emergence.vst3
// /Library/Audio/Plug-Ins/VST3/Fracture.vst3
// /Library/Audio/Plug-Ins/VST3/Noise Engineering/Ruina.vst3
// /Library/Audio/Plug-Ins/VST3/ValhallaSupermassive.vst3
~vst2.open("/Library/Audio/Plug-Ins/VST3/ValhallaSupermassive.vst3", verbose: true)
~vst2.editor
~vst2.gui
~vst2.free
~vst2.set(\Mix, 0.5)
~vst2.set(\Delay_Ms, 0.5)
~vst2.set(\DelayWarp, 0.125)
~vst2.set(\Feedback, 0.95)
~vst2.set(13, 0.2)
~reverb.free
~reverb.set(\amp, 10.dbamp)




b = Buffer.read(s, "/Users/ya/Documents/music/breakcore-samples/octatrack/8gb-card/AUDIO/BRAKE/breaks/cw_amen03_167.wav")
(
SynthDef(\sampler, {
  arg buf, out=0;
  var sig = PlayBuf.ar(numChannels:2,bufnum:buf,rate:BufRateScale.kr(buf),loop:\loop.kr(1));
  sig = sig * \amp.kr(-6.dbamp, 0.25);
  Out.ar(out, sig)
}).add;
)

~sampler = Synth(\sampler, [\buf, b], target:~synths)
~sampler.set(\out, ~fxBusGran)
~sampler.free


(
var num_seg = rrand(6, 35);

~wt = [
  /*// sine
  Signal.sineFill(size: 1024, amplitudes:1.0/[1]).asWavetable,
  // tri
  Env([0,1,0], [1,1], [-0.2, 0.2]).asSignal(1024).asWavetable,
  // saw
  Env([0,1,0], [0.01,1], 0.2).asSignal(1024).asWavetable,
  // reverse saw
  Env([0,1,0], [1,0.01], -0.2).asSignal(1024).asWavetable,
  // shark tooth
  Env([0,1,0.5,1,0], [0,1,0,1],[0,0.2,0,0.2]).asSignal(1024).asWavetable,*/

  Signal.sineFill(size: 1024, amplitudes: ({rrand(0.01, 1.0)}!8).scramble).asWavetable,

  Signal.chebyFill(size: 1024, amplitudes: ({rrand(0.01, 1.0)}!8).scramble).asWavetable,

  Env(
    [0]++
    (({rrand(0.0, 1.0)}!(num_seg-1))* [1, -1]).scramble
    ++[0],
    {exprand(1, 20)}!num_seg,
    {rrand(-20, 20)}!num_seg
  ).asSignal(1024).asWavetable,

  Env(
    [0]++
    (({rrand(0.0, 1.0)}!(num_seg-1))* [1, -1]).scramble
    ++[0],
    {exprand(1, 20)}!num_seg,
    {rrand(-20, 20)}!num_seg
  ).asSignal(1024).asWavetable,

  Env(
    [0]++
    (({rrand(0.0, 1.0)}!(num_seg-1))* [1, -1]).scramble
    ++[0],
    {exprand(1, 20)}!num_seg,
    {rrand(-20, 20)}!num_seg
  ).asSignal(1024).asWavetable,

  Signal.sineFill(size: 1024, amplitudes: ({rrand(0.01, 1.0)}!8).scramble).asWavetable,
];


~buf = Buffer.allocConsecutive(~wt.size, s, 2048);

(
~buf.do({
  arg buf, i;
  buf.loadCollection(~wt[i]);
});
)
// ~buf.do(_.free);
)


(
SynthDef.new(\vosc, {
  arg out=0, amp=0.25118864315096, buf=0, num_bufs=2;
  var sig, bufpos, detune, mod, lpf_mod;
  detune = LFNoise1.kr(0.2!8).bipolar(0.2).midiratio;
  // bufpos = buf + LFNoise1.kr(0.05).range(0, num_bufs - 1);
  mod = SinOsc.ar(0.025).range(0.5, 0.005);
  // bufpos = buf + SinOsc.kr(mod).range(0.001, num_bufs - 1.01);
  bufpos = MouseX.kr(0, num_bufs - 1.01).clip(0, num_bufs - 1.01);
  // sig = VOsc.ar(bufpos, freq);
  // bufpos.poll;
  sig = VOsc.ar(bufpos, \freq.kr(40, 0.25) * detune);
  sig = Splay.ar(sig);
  lpf_mod = SinOsc.ar(0.025).range(600, 15000);
  sig = RLPF.ar(sig, \lpf.kr(3000, 0.5).clip(2, 20000), 1.0);
  sig = LeakDC.ar(sig) * amp;
  Out.ar(out, sig);
}).add;
)

(
~vosc = Synth.new(\vosc, [
  \buf, ~buf[0].bufnum, \num_bufs, ~wt.size, \out, ~ch4
],
target:~synths);
)
~vosc.free


~vosc.set(\freq, 40)
~vosc.set(\amp, -6.dbamp)
~vosc.set(\lpf, 600)
~vosc.set(\out, ~fxBusGran)
~vosc.set(\out, 0)
s.quit

// ??????

SynthDef(\spectral, {
  arg out=0, rbuf=0, fftsize=1024, hop=0.25, win=0;
  var localbuf = {LocalBuf.new(fftsize)}!2;
  var chain = PV_PlayBuf(
    buffer:localbuf,
    playbuf:rbuf,
    rate:\rate.kr(1).varlag(0.75, -3),
    loop:1
  );
  var sig;
  // chain = PV_BinShift(chain, MouseX.kr(0.25, 8, \exponential, 0.8), 0.8, interp: 1);
  chain = PV_BinShift(chain, \bin.kr(1.0).linexp(0, 100, 0.25, 8, \minmax).varlag(0.75, -3), 0.8, interp: 1);
  chain = PV_BinScramble(chain, \scrWipe.kr(0.125), \scrWidth.kr(0.5), \trig.tr(0));
  // chain = PV_BrickWall(chain, \filter.kr(0).linexp(0, 100, -1, 1, \minmax).varlag(0.25, 3));
  chain = PV_MagShift(chain, \mag.kr(1.0).linexp(0, 100, 0.25, 4, \minmax).varlag(0.75, -3), 0.8 );
  // chain = PV_MagSmear(chain, MouseX.kr(0, 10));
  chain = PV_MagAbove(chain, \magThr.kr(0.0));
  chain = PV_PitchShift(chain, \pitch.kr(1).varlag(0.5, -3));
  sig = IFFT(chain, win);
  // var mic = SoundIn.ar([0,1]);
  // sig = XFade2.ar(mic, sig, \mix.kr(-1).varlag(0.5, 3));
  Out.ar(out, sig)
}).add;