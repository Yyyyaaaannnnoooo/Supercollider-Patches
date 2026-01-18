s.boot

b = Buffer.read(s, "/Users/ya/Documents/music/breakcore-samples/octatrack/8gb-card/AUDIO/BRAKE/breaks/cw_amen03_167.wav")
b.play


s.meter

(
Server.default.options.outDevice_("AudioBox USB 96");
// Server.default.options.inDevice_("BlackHole 16ch");
s.options.numOutputBusChannels = 2;
s.options.numInputBusChannels = 2;
s.reboot;
)
(

)

(
~fftsize = 1024;
~hop = 0.25;
~win = 0;
s.newBusAllocators;
~recBus = Bus.audio(s, 2);
~fftfx = Bus.audio(s, 2);
~playBus = Bus.audio(s, 2);
~synths = Group.new;
~fxs = Group.after(~synths);
)

~mic.free

~mic = Synth(\mic, [\out, ~recBus])

// setup audio to be processed
(



SynthDef(\mic,{
  arg in=0, out=0;
  var sig = SoundIn.ar([0,1]);
  Out.ar(out, sig)
}).add;

SynthDef(\player, {
  arg buf, out=0;
  var sig = PlayBuf.ar(numChannels:2,bufnum:buf,rate:BufRateScale.kr(buf),loop:1);
  Out.ar(out, sig)
}).add;

SynthDef(\noise, {
  arg out = 0;
  var sig = WhiteNoise.ar()!2;
  Out.ar(out, sig * \amp.kr(-6.dbamp))
}).add;

SynthDef(\additive, {
  arg out=0, amp = 0.5, trig = 0, dist = 3.43, rate=0.25, ratio = 2;
  var sines, sig, sigL, sigR, penv, control, numsines, size = 1024, mod;
  numsines = 20;
  control = Control.names(\array).kr(Array.rand(numsines, 40.0, 1100.0));
  sines = Mix(SinOsc.ar(control.varlag(1.5, -3), 0, numsines.reciprocal));
  Out.ar(out, sines!2);
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
  // chain = PV_BinShift(chain, \bin.kr(1.0).linexp(0, 100, 0.25, 8, \minmax).varlag(0.75, -3), 0.8, interp: 1);
  chain = PV_BinScramble(chain, \scrWipe.kr(0.125), \scrWidth.kr(0.5), \trig.tr(0));
  // chain = PV_BrickWall(chain, \filter.kr(0).linexp(0, 100, -1, 1, \minmax).varlag(0.25, 3));
  // chain = PV_MagShift(chain, \mag.kr(1.0).linexp(0, 100, 0.25, 4, \minmax).varlag(0.75, -3), 0.8 );
  // chain = PV_MagSmear(chain, MouseX.kr(0, 10));
  // chain = PV_MagAbove(chain, \magThr.kr(0.0));
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
  sig = IFFT(chain);
  Out.ar(out, sig!2);
}).add

)
s.quit
s.reboot
~additive = Synth(\additive,[\out, 0], target:~synths)
~additive.setn(\array, {rrand(40, 2200.rand)}!20);
~additive.set(\out, ~recBus)
~additive.free

~pvplay.set(\rate, 1)
~pvplay.set(\trig, 1)
~pvplay.set(\scrWipe, 0.125)
~pvplay.set(\scrWidth, 0.25)
~pvplay.set(\pitch, 1)
~pvplay.set(\mag, 40)
~pvplay.set(\bin, 40)
~pvplay.set(\magThr, 3)
~pvplay.set(\pitch, 1)


~player = Synth(\player, [\buf, b, \out, ~recBus], target: ~synths)

~recbuf = {Buffer.alloc(s, b.calcPVRecSize(~fftsize,~hop))}!2;

(
~pvrec = Synth(\pvrec, [
  \in, ~recBus,
  \rbuf, ~recbuf,
  \fftsize, ~fftsize,
  \hop, ~hop,
  \win, ~win
],
target: ~fxs)
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

