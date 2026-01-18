
(
~size = 1024 * 2;
~waves = 16;
~hop = 0.25;
~win = 0;
~bc1 = Bus.control(s, 1);//wipe
~bc2 = Bus.control(s, 1);//pos
~bc3 = Bus.control(s, 1);//rate
~bc4 = Bus.control(s, 1);//lfo speed
~bc5 = Bus.control(s, 1);//lfo depth
~bc6 = Bus.control(s, 1);//fade
~bc1.set(0);
~bc2.set(0);
~bc3.set(1);
~bc4.set(0.0001);
~bc5.set(0);
~bc6.set(0);
// ~lfo1 = Bus.control(s, 1);
//
//
// SynthDef(\lfo, {
//   arg f = 0.5;
//   var sine = SinOsc.kr(f);
//   var saw = Saw.kr(f);
//   var blend = SelectX.kr(\blend.kr(0), [sine, saw]);
//   Out.kr(\out.kr(0), blend);
// }).add;
//
//
// /*~w = Synth(\lfo, [\out, ~lfo])
// ~w.set(\blend, 1)
// ~w.free*/
//
//
// SynthDef(\testlfo, {
//   arg in = 0;
//   var lfo = In.kr(in, 1);
//   lfo.poll;
//   0;
// })
//


SynthDef(\fftscrubLR,
  {
    arg out=0, recBufL=0, recBufR=1, sample=0, start=0, dura = 1;
    var chainL, chainR, bufnumL, bufnumR, close=0,
    sig, sig1, sig12, sig2,
    sig3, sig4, env, trig,
    ampl, position, rate, mod,
    pitch, bin, wipe, width, pos, end=1;
    pitch = \pitch.kr(1, 0.5);
    wipe = \wipe.kr(0);
    width = \width.kr(0.25);
    bin = \bin.kr(1);
    pos = \pos.kr(0, \plag.kr(0));
    bufnumL = LocalBuf.new(~size);
    bufnumR = LocalBuf.new(~size);
    trig = \ttt.tr(1);
    rate = \rate.kr(1, \lag.kr(2.5));
    end = start + dura;
    end.clip(0, 1);
    position = Phasor.kr(trig, (256 / BufFrames.kr(recBufL)) * rate , 0, 1, 0);
    // position = Phasor.kr(trig, (rate / SampleRate.ir), start, end, start);
    // \mul.kr(0)
    mod = SinOsc.kr(\lfo.kr(0.001)).range(0, \mul.kr(0));
    chainL = PV_BufRd(
      bufnumL,
      recBufL,
      pos +
      position +
      mod
    );
    chainL = PV_PitchShift(chainL, pitch);
    chainL = PV_BinShift(chainL, bin);
    chainL = PV_BinScramble(chainL, wipe, width, \tt.tr(1));

    chainR = PV_BufRd(
      bufnumR,
      recBufR,
      pos +
      position +
      mod
    );
    chainR = PV_PitchShift(chainR, pitch);
    chainR = PV_BinShift(chainR, bin);
    chainR = PV_BinScramble(chainR, wipe, width, \tt.tr(1));
    sig1 = [IFFT(chainL, 1), IFFT(chainR, 1)];
    // use BufRd here!
    sig2 = PlayBuf.ar(
      numChannels: 2,
      bufnum: sample,
      rate:BufRateScale.kr(sample) * rate,
      trigger: trig,
      startPos: 0,
      loop: 1,
      doneAction:close
    );
    sig4 = Splay.ar(sig2, 1);
    sig3 = SelectX.ar(\sel.kr(0), [sig1, sig4]);
    sig = Select.ar((rate.abs<1), [sig2, sig3]);
    Out.ar(out, sig * \amp.kr(0.dbamp, 0.5));
}).add;

SynthDef(\padLR,
  {
    arg out=0, recBufL=0, recBufR=1, sample=0, start=0, dura = 1;
    var chainL, chainR, bufnumL, bufnumR,
    sig, sig1, sig12, sig2,
    sig3, sig4, env, trig,
    ampl, position, rate, mod,
    pitch, bin, wipe, width, pos, end=1;

    /*    wipe = ~bc1.kr;
    width = \width.kr(0.25);
    bin = \bin.kr(1);
    // pos = \pos.kr(0, \plag.kr(0));
    pos = ~bc2.kr;
    bufnum ={LocalBuf.new(~size)}!2;
    trig = \ttt.tr(1);
    // rate = \rate.kr(1, \lag.kr(2.5));
    rate = ~bc3.kr;*/

    pitch = \pitch.kr(1, 0.5);
    wipe = ~bc1.kr;
    width = \width.kr(0.25);
    bin = \bin.kr(1);
    pos = ~bc2.kr;
    bufnumL = LocalBuf.new(~size);
    bufnumR = LocalBuf.new(~size);
    trig = \ttt.tr(1);
    rate = ~bc3.kr;
    end = start + dura;
    end.clip(0, 1);
    position = Phasor.kr(trig, (256 / BufFrames.kr(recBufL)) * rate , 0, 1, 0);
    // position = Phasor.kr(trig, (rate / SampleRate.ir), start, end, start);
    // mod = SinOsc.kr(\lfo.kr(0.001)).range(0, \mul.kr(0));
    mod = SinOsc.kr(~bc4.kr).range(0, ~bc5.kr);
    chainL = PV_BufRd(
      bufnumL,
      recBufL,
      pos +
      position +
      mod
    );
    chainL = PV_PitchShift(chainL, pitch);
    chainL = PV_BinShift(chainL, bin);
    chainL = PV_BinScramble(chainL, wipe, width, \tt.tr(1));

    chainR = PV_BufRd(
      bufnumR,
      recBufR,
      pos +
      position +
      mod
    );
    chainR = PV_PitchShift(chainR, pitch);
    chainR = PV_BinShift(chainR, bin);
    chainR = PV_BinScramble(chainR, wipe, width, \tt.tr(1));
    sig1 = [IFFT(chainL, 1), IFFT(chainR, 1)];
    // use BufRd here!
    sig2 = PlayBuf.ar(
      numChannels: 2,
      bufnum: sample,
      rate:BufRateScale.kr(sample) * rate,
      trigger: trig,
      startPos: 0,
      loop: 1);
    sig4 = Splay.ar(sig2, 1);
    // sig3 = SelectX.ar(\sel.kr(0), [sig1, sig4]);
    sig3 = SelectX.ar(~bc6.kr, [sig1, sig4]);
    sig = Select.ar((rate.abs<1), [sig2, sig3]);
    env = EnvGen.kr(
      Env.new(
        [0,1,0.7,0],
        [\atk.kr(0.1),\sus.kr(0.5), \rel.kr(0.5)],
        [-4,-4,-4]
    ), 1, doneAction:2);
    sig = sig * env;
    Out.ar(out, sig * \amp.kr(-12.dbamp, 0.5));
}).add;

SynthDef(\pvrecLR, {
  arg recBufL=1, recBufR=0, soundBufnum=2;
  var bufnumL, bufnumR, in, chainL, chainR;
  Line.kr(1, 1, BufDur.kr(soundBufnum), doneAction: 2);
  in = PlayBuf.ar(2, soundBufnum, BufRateScale.kr(soundBufnum), loop: 0);
  bufnumL = LocalBuf.new(~size); // uses frame size from above
  bufnumR = LocalBuf.new(~size); // uses frame size from above
  // note the window type and overlaps... this is important for resynth parameters
  chainL = FFT(bufnumL, in[0], 0.25, 1);
  chainL = PV_RecordBuf(chainL, recBufL, 0, 1, 0, 0.25, 1);
  chainR = FFT(bufnumR, in[1], 0.25, 1);
  chainR = PV_RecordBuf(chainR, recBufR, 0, 1, 0, 0.25, 1);
}).add;

SynthDef(\fftscrub,
  {
    arg out=0, recBuf=1, sample=0, start=0, dura = 1;
    var chain1, chain2, bufnum,
    sig, sig1, sig12, sig2,
    sig3, sig4, env, trig,
    ampl, position, rate, mod,
    pitch, bin, wipe, width, pos, end=1;
    pitch = \pitch.kr(1, 0.5);



    wipe = \wipe.kr(0);
    width = \width.kr(0.25);
    bin = \bin.kr(1);
    pos = \pos.kr(0, \plag.kr(0));
    bufnum ={LocalBuf.new(~size)}!2;
    trig = \ttt.tr(1);
    rate = \rate.kr(1).varlag(\lag.kr(5), warp: \sin);
    end = start + dura;
    end.clip(0, 1);
    position = Phasor.kr(trig, (256 / BufFrames.kr(recBuf)) * rate , 0, 1, 0);
    // position = Phasor.kr(trig, (rate / SampleRate.ir), start, end, start);
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
    // use BufRd here!
    sig2 = PlayBuf.ar(
      numChannels: 2,
      bufnum: sample,
      rate:BufRateScale.kr(sample) * rate,
      trigger: trig,
      startPos: 0,
      loop: 1);
    sig4 = Splay.ar(sig2, 1);
    sig3 = SelectX.ar(\sel.kr(0), [sig1, sig4]);
    sig = Select.ar((rate.abs<1), [sig2, sig3]);
    Out.ar(out, sig * \amp.kr(-12.dbamp, 0.5));
}).add;

SynthDef(\scrubPad,
  {
    arg out=0, recBuf=1, sample=0, start = 0, dur = 1;
    var chain1, chain2, bufnum,
    sig, sig1, sig12, sig2,
    sig3, sig4, env, trig,
    ampl, position, rate, mod,
    pitch, bin, wipe, width, pos, end = 1;
    pitch = \pitch.kr(1, 0.5);
    // wipe = \wipe.kr(0);
    wipe = ~bc1.kr;
    width = \width.kr(0.25);
    bin = \bin.kr(1);
    // pos = \pos.kr(0, \plag.kr(0));
    pos = ~bc2.kr;
    bufnum ={LocalBuf.new(~size)}!2;
    trig = \ttt.tr(1);
    // rate = \rate.kr(1, \lag.kr(2.5));
    rate = ~bc3.kr;
    end = start + dur;
    end.clip(0, 1);
    position = Phasor.kr(trig, (256 / BufFrames.kr(recBuf)) * rate ,0, 1, 0);
    mod = SinOsc.kr(~bc4.kr).range(0, ~bc5.kr);
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
      bufnum: sample,
      rate:BufRateScale.kr(sample) * rate,
      trigger: trig,
      startPos: BufFrames.kr(sample) * pos,
      loop: 1);
    sig4 = Splay.ar(sig2, 1);
    sig3 = SelectX.ar(~bc6.kr, [sig1, sig4]);
    sig = Select.ar((rate.abs<1), [sig2, sig3]);
    env = EnvGen.kr(
      Env.new(
        [0,1,0.7,0],
        [\atk.kr(0.1),\sus.kr(0.5), \rel.kr(0.5)],
        [-4,-4,-4]
    ), 1, doneAction:2);
    sig = sig * env;
    Out.ar(out, sig * \amp.kr(-12.dbamp, 0.125));
}).add;
// Env.new([0,1,0.7,0], [0.1,0.5, 0.5],[-2,-2,-2]).plot

SynthDef("pvrec", {
  arg bufnum=0, recBuf=1, soundBufnum=2;
  var in, chain;
  Line.kr(1, 1, BufDur.kr(soundBufnum), doneAction: 2);
  in = PlayBuf.ar(2, soundBufnum, BufRateScale.kr(soundBufnum), loop: 0);
  bufnum = {LocalBuf.new(numFrames:~size)}!2;
  chain = FFT(bufnum, in, 0.25, 1);
  chain = PV_RecordBuf(chain, recBuf,0,1,0, 0.25, 1);
}).add;




SynthDef("frate", {
  arg out=0, recBuf=1, sample=0, rate;
  var in, bufnum, chain, sig1, sig2, sig3, sig4, sig, trig, mod;
  trig = Impulse.kr(1);
  bufnum = LocalBuf.new(~size, 2);
  // "rate".poll;
  mod = SinOsc.kr(\lfo_f.kr(0.5), mul: \lfo_mul.kr(0)).range(-1, 1);
  rate = rate.varlag(\lag.kr(0), -8);
  rate = (rate + mod).range(-1, 1);
  chain = PV_PlayBuf(
    buffer:bufnum,
    playbuf:recBuf,
    rate:rate,
    loop:1
  );
  chain = PV_Diffuser(chain, trig);
  chain = PV_PitchShift(chain, \pitch.kr(1, 0.5));
  chain = PV_BinShift(chain, \bin.kr(1, \blag.kr(0)) );
  chain = PV_BinScramble(chain, \wipe.kr(0), \width.kr(0.25), \tt.tr(1));
  sig1 = IFFT(chain, 1);

  sig2 = PlayBuf.ar(
    numChannels: 2,
    bufnum: sample,
    rate:BufRateScale.kr(sample) * rate,
    trigger: 1,
    startPos: 0,
    loop: 1);
  // sig4 = RHPF.ar(sig2, 200);
  sig4 = Splay.ar(sig2, 1);
  sig3 = SelectX.ar(\sel.kr(0), [sig1, sig4]);
  sig = Select.ar((rate.abs<1), [sig2, sig3]);
  // sig = sig2;
  // (rate<1).poll;
  sig = sig * Line.kr(0.0, 1.0, \atk.kr(0.2), doneAction:0);
  // Out.ar(~recBus, sig * \amp.kr(-12.dbamp, 0.125));
  Out.ar(out, sig * \amp.kr(-12.dbamp, 0.125));
}).add;

SynthDef("scrub",
  {
    arg out=0, recBuf=1, in = 0;
    var chain, bufnum, sig, env, trig, ampl;
    trig = Impulse.kr(2);
    // trig.poll;
    bufnum = LocalBuf.new(~size, 2);
    env = Env.perc(0.01, 1.5, level:1, curve:-4).kr(0, trig);
    chain = PV_BufRd(
      bufnum,
      recBuf,
      \pos.kr(0, \lag.kr(0)) + SinOsc.kr(\lfo.kr(0.001)).range(0, \mul.kr(0.01)));
    chain = PV_PitchShift(chain, \pitch.kr(1, 0.5));
    chain = PV_BinShift(chain, \bin.kr(1, \blag.kr(0)));
    chain = PV_BinScramble(chain, \wipe.kr(0), \width.kr(0.25), \tt.tr(1) + trig);
    sig = IFFT(chain, 1).dup;
    Out.ar(out, sig * \amp.kr(-12.dbamp, 0.125));
}).add;

SynthDef(\sampler, {
  arg bufnum;
  var sig = PlayBuf.ar(
    numChannels: 2,
    bufnum: bufnum,
    rate:BufRateScale.kr(bufnum),
    trigger: 1,
    startPos: 0,
    loop: 1);
  Out.ar(\out.kr(0), sig * \amp.kr(-12.dbamp, 0.125));
}).add;

SynthDef(\eoc, {
  arg in1 = 0, in2 = 2, in3 = 4, in4 = 6, in5=8;
  var input1 = In.ar(in1, 2);
  var input2 = In.ar(in2, 2);
  var input3 = In.ar(in3, 2);
  var input4 = In.ar(in4, 2);
  var input5 = In.ar(in5, 2);
  var sig1, sig2, sig3, sig4, sig5;
  sig1= RLPF.ar(input1, \lpf.kr(19000, 0.25).clip(20, 19000));
  sig1 = RHPF.ar(sig1, \hpf.kr(20, 0.5).clip(20, 19000));
  sig1 = LeakDC.ar(sig1);

  sig2= RLPF.ar(input2, \lpf.kr(19000, 0.25).clip(20, 19000));
  sig2 = RHPF.ar(sig2, \hpf.kr(20, 0.5).clip(20, 19000));
  sig2 = LeakDC.ar(sig2);

  sig3= RLPF.ar(input3, \lpf.kr(19000, 0.25).clip(20, 19000));
  sig3 = RHPF.ar(sig3, \hpf.kr(20, 0.5).clip(20, 19000));
  sig3 = LeakDC.ar(sig3);

  sig4= RLPF.ar(input4, \lpf.kr(19000, 0.25).clip(20, 19000));
  sig4 = RHPF.ar(sig4, \hpf.kr(20, 0.5).clip(20, 19000));
  sig4 = LeakDC.ar(sig4);

  sig5= RLPF.ar(input5, \lpf.kr(19000, 0.25).clip(20, 19000));
  sig5 = RHPF.ar(sig5, \hpf.kr(20, 0.5).clip(20, 19000));
  sig5 = LeakDC.ar(sig5);

  ReplaceOut.ar(0,
    [
      sig1[0], sig1[1],
      sig2[0], sig2[1],
      sig3[0], sig3[1],
      sig4[0], sig4[1],
      sig5[0], sig5[1],
  ]);
}).add;

"Synths Loaded".postln;

)