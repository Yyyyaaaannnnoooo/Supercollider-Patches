s.reboot
s.quit
~size

b = Buffer.readChannel(s, "/Users/ya/Documents/supercollider/perfs/dronecore/audio/stems2/vox/00015-vox.wav")

b.stop

~t = Bus.control(s, 1);

(
SynthDef(\kick, {
  arg buf, out=0;
  var sig, sig2, kick, env, sample, sweep, trigger,
  ampl, chain, env1, env2, env3, env4;
  sample = PlayBuf.ar(2, buf, \rate.kr(1, 0.5), 1, loop:1);
  sample = RHPF.ar(sample, 500);
  ampl = Amplitude.kr(BPF.ar(sample, \bpf.kr(80, 1)));
  // Out.kr(~t, ampl);

  trigger = Pulse.kr(\trigR.kr(1, 0.5), width: 0.1, mul:1);
  trigger = ampl>\tresh.kr(0.185);
  // trigger.poll;
  sweep = EnvGen.kr(Env.perc(0.001, 0.125, 220, -4), trigger, doneAction:0);
  env = EnvGen.kr(Env.perc(0.001, 1.25, 1, -4), trigger, doneAction:0);
  env4 = EnvGen.kr(Env.perc(0.2, 0.75, 1, 0), trigger, doneAction:0);
  // sweep.poll;
  kick = SinOsc.ar(30 + sweep);
  kick = (kick * \dist.kr(10, 0.125)).tanh;
  kick = (kick * 5.1).atan;
  chain = FFT(LocalBuf(~size), kick);
  env1 = 0.25+Env.perc(0.1, 0.5, 0.5, -2).kr(0, gate:trigger);
  env2 = Env.perc(0.25, 0.12, 1, -2).kr(0, gate:trigger);
  // chain = PV_PitchShift(chain, env2);
  env3 = 1+Env.perc(0.75, 0.5, 0.25, -4).kr(0, gate:trigger);
  // chain = PV_BinShift(chain, \bin.kr(1, \blag.kr(0)) );
  chain = PV_BinScramble(chain, 0.5, 0.25, \ext_t.tr(1));
  chain = PV_BinShift(chain,env3, env2 * 2, interp:1);
  // chain = PV_RandComb(chain, 0.5, trigger);
  chain = PV_Diffuser(chain, trigger);
  sig2 = IFFT(chain)* \amp.kr(-12.dbamp);
  sig2 = RLPF.ar(sig2, 3000);
  sig2 = RHPF.ar(sig2, 80);
  sig2 = Splay.ar(sig2, 1, center: SinOsc.kr(0.5));
  kick = RLPF.ar(kick, 800);
  kick = kick  * env * \amp.kr(-12.dbamp);

  sig = Mix.ar([sig2, kick, sample]);
  // sig = kick!2;
  Out.ar(out, sig!2);
  // Out.ar(out, sample);
}).add;
)
s.meter

(
x.free;
x = Synth(\kick, [\buf, ~br1])
)

x.set(\rate, 1.75)
x.set(\ext_t, 1)
x.set(\bpf, 200)
x.set(\tresh, 0.2)
x.set(\dist, 10)

(
~ctrl.stop;
~ctrl = Routine{
  inf.do({
    arg item, i;
    var val = ~t.get({
      arg value;
      // "get value".postln;
      value.postln;
      if(value>0.06){
        ~sk = Synth(\skibidi, [\recBuf, ~fft_bd, \sample, ~bd, \rate, 1]);
      }
    });
    // val.value.postln;
    0.001.wait;
  });
};
~ctrl.play;
)

(
SynthDef(\gabberkick, {
  var snd;
  var trigger = Impulse.kr(0.25);
  snd = SinOsc.ar(Env([1000, 69, 60], [0.015, 0.1], \exp).ar(doneAction:0, gate: trigger) * [-0.1, 0, 0.1].midiratio);
  snd = Mix(snd);
  snd = (snd * \dist.kr(1, 0.25)).tanh;
  snd = (snd * 5.1).atan;
  snd = BPeakEQ.ar(snd, XLine.kr(2000, 100, 0.3), 2.0, 8);
  snd = snd + DelayC.ar(snd, 0.01, SinOsc.ar(4).range(0.0, 0.001));
  snd = RLPF.ar(snd, 8000, 0.7);
  snd = snd * Env([0, 1, 0.7, 0.7, 0], [0.001, 0.01, 0.3, 0.02]).ar(doneAction:0, gate: trigger);
  snd = (snd * 0.6).clip(-1, 1);
  Out.ar(\out.kr(0), Pan2.ar(snd, \pan.kr(0), \amp.kr(0.1)));
}).add;
)

g = Synth(\gabberkick, [amp: 0.6, dist: 0.1])




// spectral kick

~bd = Buffer.readChannel(s, "/Users/ya/Documents/supercollider/perfs/dronecore/audio/bd/gabber-10.wav")

~bd.play

~fft_bd = {Buffer.alloc(s, ~bd.duration.calcPVRecSize(~size, ~hop))}!2;

Synth(\pvrec, [\recBuf, ~fft_bd, \soundBufnum, ~bd]);
0.25.reciprocal
(
SynthDef(\skibidi, {
  arg out=0, recBuf=1, sample=0, rate=1;
  var in, bufnum, chain, sig1, sig2, sig3, sig4, sig, trig,
  env1, env2, env3, offset=0;
  // trig = Impulse.kr(0.25);
  bufnum = LocalBuf.new(~size, 2);
  // "rate".poll;
  trig = 1;
  env1 = Env.perc(1.85, 0, 1, -2).kr(2, gate:trig);
  // rate = rate.varlag(\lag.kr(0));
  // (trig>0.125).poll;
  rate = rate - env1;
  chain = PV_PlayBuf(
    buffer:bufnum,
    playbuf:recBuf,
    rate:rate,
    offset:offset,
    loop:1,
  );
  chain = PV_Diffuser(chain, trig);
  env2 = 1 + Env.perc(0, 0.85, 0.25, -2).kr(0, gate:trig);
  // chain = PV_PitchShift(chain, env2);
  env3 = 2 - Env.perc(1.45, 0, 1, -4).kr(0, gate:trig);
  // chain = PV_BinShift(chain, \bin.kr(1, \blag.kr(0)) );
  chain = PV_BinScramble(chain, 0.5, 0.2, trig);
  chain = PV_BinShift(chain, env2);
  // chain = PV_BinShift(chain, 1, MouseX.kr(-128, 128) );
  sig1 = IFFT(chain, 1);

  sig2 = PlayBuf.ar(
    numChannels: 2,
    bufnum: sample,
    // rate:BufRateScale.kr(sample) * rate,
    rate:BufRateScale.kr(sample) * 1,
    trigger: trig,
    startPos: 0,
    loop: 1);
  // sig4 = RHPF.ar(sig2, 200);
  sig4 = Splay.ar(sig2, 1) * Env.perc(0, 0.125, 1, -2).kr(0, gate:trig);

  // sig3 = SelectX.ar(\sel.kr(0), [sig1, sig4]);
  // sig = SelectX.ar((rate.abs<1), [sig2, sig3]);

  sig = Mix.ar([sig1, sig4]);

  // sig = sig2;
  // (rate<1).poll;
  // sig = sig * Line.kr(0.0, 1.0, \atk.kr(0.2), doneAction:0);
  Out.ar(out, sig * \amp.kr(-3.dbamp, 0.125));
}).add;
)
(
~sk.free;
~sk = Synth(\skibidi, [\recBuf, ~fft_bd, \sample, ~bd, \rate, 1])
)

~sk.set(\rate, 0.95)



~br1 = Buffer.readChannel(s, "/Users/ya/Documents/supercollider/perfs/dronecore/audio/stems2/break/00029-break.wav")

~br1.play
~size = 1024;
~hop = 0.25
~fft_bd = {Buffer.alloc(s, ~br1.duration.calcPVRecSize(~size, ~hop))}!2;

~fft_bd[0].duration

~rec_fft = Synth("pvrec_alt", [\recBuf, ~fft_bd, \soundBufnum, ~br1]);

(

SynthDef("scrub2",
  {
    arg out=0, recBuf=1, buf=0;
    var chain1, chain2, bufnum,
    sig, sig1, sig12, sig2,
    sig3, sig4, env, trig,
    ampl, position, rate, mod,
    pitch, bin, wipe, width, pos;
    pitch = \pitch.kr(1, 0.5);
    wipe = \wipe.kr(0);
    width = \width.kr(0.25);
    bin = \bin.kr(1);
    pos = \pos.kr(0, \plag.kr(0));
    bufnum ={LocalBuf.new(~size)}!2;
    // position = Line.kr(0, 1, BufDur.kr(buf) * \rate.kr(1).reciprocal);
    // BufFrames.kr(buf).poll;
    trig = \ttt.tr(1);
    rate = \rate.kr(1, \lag.kr(2.5));
    position = Phasor.kr(trig, (256 / BufFrames.kr(recBuf)) * rate , 0, 1, 0);
    mod = SinOsc.kr(\lfo.kr(0.001)).range(0, \mul.kr(0));
    chain1 = PV_BufRd(
      bufnum,
      recBuf,
      pos +
      position +
      mod
    );
    chain1 = PV_PitchShift(chain1, pitch);
    chain1 = PV_BinShift(chain1, bin);
    chain1 = PV_BinScramble(chain1, wipe, width, \tt.tr(1));
    sig1 = IFFT(chain1, 1);
    sig2 = PlayBuf.ar(
      numChannels: 2,
      bufnum: buf,
      rate:BufRateScale.kr(buf) * rate,
      trigger: trig,
      startPos: 0,
      loop: 1);
    // sig4 = RHPF.ar(sig2, 200);
    sig4 = Splay.ar(sig2, 1);
    sig3 = SelectX.ar(\sel.kr(0), [sig1, sig4]);
    sig = Select.ar((rate.abs<1), [sig2, sig3]);
    // sig = [sig1, sig2];
    Out.ar(out, sig * \amp.kr(-12.dbamp, 0.125));
}).add;

)
// \pos.kr(0, \lag.kr(0)) + SinOsc.kr(\lfo.kr(0.001)).range(0, \mul.kr(0.01)));

~micBus = Bus.audio(s, 2);

(
~scr.free;
~scr = Synth(\scrub2, [\recBuf, ~fft_bd, \buf, ~br1, \sel, 0.5, \rate, 0.5, \out, ~micBus])
)

~scr.set(\pos, 0.5)
~scr.set(\plag, 10)
~scr.set(\lfo, 0.005)
~scr.set(\mul, 0.5)
~scr.set(\sel, 0)
~scr.set(\rate, 0)


(
SynthDef(\resynth,{
  arg buf, amp = 0.5, rot = 0, in=0;
  var sig, car1, car2, mod, num = 32, bpfmod, q = \q.kr(20), track, sel,
  bpfhz, bufpos, freqs;
  bpfhz = (1..num).linexp(1, num, 25, 19500);
  freqs = (1..num).linexp(1, num, 40, 660);
  // mod = PlayBuf.ar(1, buf, BufRateScale.ir(buf), loop:1);
  mod = In.ar(in, 1);
  bpfmod = BPF.ar(mod, bpfhz, 1/q, sqrt(q));
  track = Amplitude.kr(bpfmod);
  sel = SelectX.kr(\scramble.kr(0).varlag(1, -3), [track, track.scramble]);
  // car1 = SinOsc.ar(bpfhz + \freq.kr(0).varlag(0.5, -3), mul: sel);
  // car1 = SinOsc.ar(freqs + \freq.kr(0).varlag(0.5, -3), mul: sel);
  car1 = SinOsc.ar(freqs + \freq.kr(0).varlag(0.5, -3), mul: track * 8);
  sig = car1;
  sig = Splay.ar(sig.scramble, 0.1);
  // Out.ar(\out.kr(0), sig);
  ReplaceOut.ar(\out.kr(0), sig * amp)
}).add
)

(
~rs.free;
~rs = Synth.after(~src, \resynth, [\in, ~micBus])
)

~rs.set(\amp, 10.dbamp)
~rs.set(\freq, 400)
