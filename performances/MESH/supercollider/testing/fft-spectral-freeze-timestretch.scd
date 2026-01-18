s.boot

b = Buffer.read(s, "/Users/ya/Documents/music/breakcore-samples/octatrack/8gb-card/AUDIO/BRAKE/breaks/cw_amen03_167.wav")
b.play

s.meter

(
Server.default.options.outDevice_("MacBook Pro Speakers");
Server.default.options.inDevice_("BlackHole 16ch");
s.options.numOutputBusChannels = 2;
s.options.numInputBusChannels = 2;
s.reboot;
)
(

)

(
~makeNodes = {
  ~fftsize = 256;
  ~hop = 0.25;
  ~win = 0;
  s.newBusAllocators;

  ~ch1 = Bus.audio(s, 2);
  ~ch2 = Bus.audio(s, 2);
  ~ch3 = Bus.audio(s, 2);
  ~ch4 = Bus.audio(s, 2);

  ~pvrec = Bus.audio(s, 2);

  ~glitchBus = Bus.audio(s, 2);
  ~fftfx = Bus.audio(s, 2);
  ~notchesfx = Bus.audio(s, 2);

  ~synths = Group.new;
  ~mix = Group.after(~synths);
  ~recs = Group.after(~mix);
  ~fxs = Group.after(~recs);
  // Allocate buffers
  ~bufferSize = 4;  // 10 seconds buffer size
  ~recordBuf = Buffer.alloc(s, s.sampleRate * ~bufferSize, 2);
  ~playbackBuf = Buffer.alloc(s, s.sampleRate * ~bufferSize, 2);
};
~makeNodes.()
)


(

SynthDef(\mic,{
  arg in=0, out=0;
  var sig = SoundIn.ar([0,1]);
  Out.ar(out, sig)
}).add;

SynthDef(\player, {
  arg buf, out=0;
  var sig = PlayBuf.ar(numChannels:2,bufnum:buf,rate:BufRateScale.kr(buf),loop:1);
  sig = sig * \amp.kr(-6.dbamp, 0.25);
  Out.ar(out, sig)
}).add;

SynthDef(\noise, {
  arg out = 0;
  var sig = WhiteNoise.ar()!2;
  sig = sig * \amp.kr(-18.dbamp, 0.25);
  Out.ar(out, sig)
}).add;

SynthDef(\additive, {
  arg out=0;
  var sines, sig, sigL, sigR, penv, control, numsines, size = 1024, mod;
  numsines = 20;
  control = Control.names(\array).kr(Array.rand(numsines, 40.0, 1100.0));
  sines = Mix(SinOsc.ar(control.varlag(1.5, -3), 0, numsines.reciprocal));
  sig = sines * \amp.kr(-6.dbamp, 0.25);
  Out.ar(out, sig);
}).add;


SynthDef(\submixer, {
  arg in1, in2, in3, in4, out=0, aux1, aux2, glitch;
  var input1 = In.ar(in1, 2) * \amp1.kr(-12.dbamp, 0.125);
  var input2 = In.ar(in2, 2) * \amp2.kr(-12.dbamp, 0.125);
  var input3 = In.ar(in3, 2) * \amp3.kr(-12.dbamp, 0.125);
  var input4 = In.ar(in4, 2) * \amp4.kr(-12.dbamp, 0.125);
  var sig = input1 + input2 + input3 + input4;
  Out.ar(aux1, sig * \auxS1.kr(0, 0.125));
  Out.ar(aux2, sig * \auxS2.kr(0, 0.125));
  Out.ar(glitch, sig * \reclevel.kr(0, 0.125));
  Out.ar(out, sig * \masterLevel.kr(-6.dbamp, 0.25));
}).add;



SynthDef(\recorder, {
  arg bufnum, in;
  var input = In.ar(in, 2);
  RecordBuf.ar(input, bufnum, loop: 1);
  0;
}).add;

// Playback SynthDef
SynthDef(\playback, {
  arg bufnum, out = 0;
  var play, pos, trig;
  trig = Impulse.kr(\trigrate.kr(4, 0.5));
  play = PlayBuf.ar(
    numChannels: 2,
    bufnum: bufnum,
    rate:BufRateScale.kr(bufnum) * \rate.kr(1, 0.0625),
    trigger: trig,
    startPos: \pos.kr(0).linlin(0, 2000, 0, BufFrames.kr(bufnum)),
    loop: 1);
  Out.ar(out, play);
}).add;

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

SynthDef(\spectral, {
  arg in, out=0;
  var sig, chain, size=512;
  in = In.ar(in, 2);
  chain = FFT(Array.fill(2, { LocalBuf(size, 1) }), in);
  chain = PV_BinShift(chain, \bin.kr(1.0).linexp(0, 100, 0.25, 8, \minmax).varlag(0.75, -3), 0.8, interp: 1);
  chain = PV_BinScramble(chain, \scrWipe.kr(0.0).varlag(0.5, -2), \scrWidth.kr(0.5), \trig.tr(0));
  chain = PV_MagShift(chain, \mag.kr(1.0).linexp(0, 100, 0.25, 4, \minmax).varlag(0.75, -3), 0.8 );
  chain = PV_MagAbove(chain, \magAThr.kr(0.0));
  chain = PV_MagBelow(chain, \magBThr.kr(10.0));
  chain = PV_PitchShift(chain, \pitch.kr(1).varlag(0.5, -3));

  // CHECK THOSE BELOW OUT!!!!!!!!
  // chain = PV_RandComb(chain, 0.95, Impulse.kr(0.4));
  // chain = PV_RectComb(chain, 8, LFTri.kr(0.097,0,0.4,0.5), LFTri.kr(0.24,0,-0.5,0.5));
  ///////////////////////////////////////

  sig = IFFT(chain);
  sig = sig * \amp.kr(-6.dbamp, 0.25);
  Out.ar(out, sig!2);
}).add

)

~makeNodes.()

s.reboot
~additive = Synth(\additive,[\out, ~ch1], target:~synths)
~additive.setn(\array, {rrand(40, 1200.rand)}!20);
~additive.set(\out, ~pvrec)
~additive.free
~spectral.free
~pvplay.free
~pvrec.free
~player.free

~noise = Synth(\noise, [\out, ~ch2], target:~synths)
~noise.set(\amp, -24.dbamp)
~noise.free

~player = Synth(\player,[\out, ~ch3, \buf, b], target:~synths)
s.meter
// MIXER
(
~mixer = Synth(\submixer, [
  \in1, ~ch1, \in2, ~ch2,
  \in3, ~ch3, \in4, ~ch4,
  \aux1, ~fftfx,
  \aux1, ~notchesfx,
  \glitch, ~glitchBus
], target:~mix)
)

~mixer.set(\masterLevel, 0.5)
~mixer.set(\reclevel, 0.65)
~mixer.set(\auxS1, 1)

// set up recorders
~recorder = Synth(\recorder, [\bufnum, ~recordBuf, \in, ~glitchBus], target: ~recs)
~recorder.free
~playback.free
~playback = Synth(\playback, [\bufnum, ~recordBuf, \rate, 0.5], target: ~fxs)
~playback.set(\rate, 1.25)
~playback.set(\trigrate, 4)


~spectral.free
~spectral = Synth(\spectral, [\out, 0, \in, ~fftfx],target: ~fxs)
~spectral.set(\trig, 1)
~spectral.set(\scrWipe, 0.74)
~spectral.set(\scrWidth, 1)
~spectral.set(\mag, 4)
~spectral.set(\bin, 7)
~spectral.set(\magThr, 2.5)
~spectral.set(\pitch, 1)

~pvplay.set(\rate, 1)
~pvplay.set(\trig, 1)
~pvplay.set(\scrWipe, 1)
~pvplay.set(\scrWidth, 1)
~pvplay.set(\mag, 40)
~pvplay.set(\bin, 40)
~pvplay.set(\magThr, 3)
~pvplay.set(\pitch, 1)


~player = Synth(\player, [\buf, b, \out, ~PVrec], target: ~synths)

~recbuf = {Buffer.alloc(s, b.duration.calcPVRecSize(~fftsize,~hop))}!2;

(
~pvrec = Synth(\pvrec, [
  \in, ~pvrec,
  \rbuf, ~recbuf,
  \fftsize, ~fftsize,
  \hop, ~hop,
  \win, ~win
],
target: ~recs)
)

(

~pvplay = Synth(\pvplay, [
  \out, 0,
  \rbuf, ~recbuf,
  \fftsize, ~fftsize,
  \hop, ~hop,
  \win, ~win
],
target: ~fxs
)


)

