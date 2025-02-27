


// https://youtu.be/MnD8stNB5tE?t=536
s.boot;
(
~buf = 9999;
~buf_copy = 9998;
~buffer = Buffer.alloc(server: s, numFrames: s.sampleRate * 5,numChannels: 2, bufnum: ~buf);
~buffer_copy = Buffer.alloc(server: s, numFrames: s.sampleRate * 5,numChannels: 2, bufnum: ~buf);


~rec = Bus.audio(s, 2);
~mic = Bus.audio(s, 2);
~pointer = Bus.audio(s, 2);
~freeze_dly = Bus.audio(s, 2);

~micGrp = Group.new;
~ptrGrp = Group.after(~micGrp);
~recGrp = Group.after(~ptrGrp);
~delayGrp = Group.after(~recGrp);

SynthDef.new(\mic, {
  arg in=0, out=0, amp=0.25;
  var sig;
  sig = In.ar(in, 2) * amp;
  Out.ar(out, sig);
}).add;

SynthDef.new(\ptr, {
  arg out=0, buf=0;
  var sig;
  sig = Phasor.ar(0, BufRateScale.kr(buf), 0, BufFrames.kr(buf));
  Out.ar(out, sig);
}).add;

SynthDef.new(\rec, {
  arg ptrIn=0, micIn=0, buf=0;
  var ptr, sig;
  ptr = In.ar(ptrIn, 2);
  sig = In.ar(micIn, 2);
  BufWr.ar(sig, buf, ptr);
}).add;

SynthDef.new(\freeze_dly, {
  arg in=0, out=0, buf=0, mix=0, rate=1, gate=1,
  start=0, loop=1;
  var sig, freeze, frames, pos, pos_rate,
  dry, start_pos, end_pos, leftover;
  frames = BufFrames.kr(buf);
  dry = In.ar(in, 2);
  start_pos = In.ar(ptrIn, 2).reciprocal;
  // needs sustained envelope
  // so that it is called
  // and it frees up itself
  // when gate is 0
  leftover = frames - start_pos;
  end_pos = leftover / loop;
  pos_rate = rate * BufRateScale.ir(buf);
  pos = Phasor.ar(gate,pos_rate,start_pos,end_pos,start_pos);
  freeze = BufRd.ar(numChannels: 2, bufnum: buf, phase: pos, loop: 1, interpolation: 4);
  sig = XFade2.ar(dry, freeze, mix, 1);
  Out.ar(out, sig);
}).add;

)

(
Synth(\mic, [\in, ~rec, \out, ~mic], ~micGrp);
Synth(\ptr, [\buf, ~buffer, \out, ~pointer], ~ptrGrp);
Synth(\rec, [\ptrIn, ~pointer, \micIn, ~mic], ~recGrp);

)



(
SynthDef.new(\supasaw, {
  arg freq=440, out=0, rec=0, gate=1, offset=2, amp=0.5, lpf=3000, atk=2.5, rel=1;
  var sig, env;
  // build the envelope
  env = EnvGen.ar(
    Env.new(
      [0, 1, 0.75, 0],
      [atk, 0.5, rel],
      -2,
    ),
    gate,
    doneAction: 2,
  );

  sig = VarSaw.ar(
    freq: [ freq-11, freq-3, freq, freq+3, freq+5, freq+7, freq+9, freq+11],
    iphase: {Rand(0.0, 1.0)}!8,
    width: {ExpRand(0.001, 0.02)}!8
  );

  sig = Splay.ar(sig) * 0.5;
  sig = RLPF.ar(sig, lpf.clip(20, 20000), 1);
  sig = Balance2.ar(sig[0], sig[1], 0, amp)  * env;
  Out.ar(rec, sig);
  // Out.ar(out, sig);
}).add;


)

(
x = Synth.new(\supasaw, [\freq, exprand(100, 660), \out, 0, \rec, ~rec, \rel, 10])

)

(
z.free;
z = Synth.new(\freeze_dly, [\in, 0, \buf, ~buffer, \ptrIn, ~pointer, \loop, 16, \mix, 1, \rate, 1.5], ~delayGrp);

)

x.free

~buffer.plot

// ATTEMPT #2

s.boot;
(
s.freeAll;
~bufNum = 9999;
~buf = Buffer.alloc(server: s, numFrames: s.sampleRate * 5,numChannels: 2, bufnum: ~bufNum);
)

(

/*~rec = Bus.audio(s, 2);
~mic = Bus.audio(s, 2);
~pointer = Bus.audio(s, 2);*/
~freeze_dly = Bus.audio(s, 2);


~delayGrp = Group.new;

SynthDef.new(\freeze, {
  arg in=0, out=0, buf=0, rate=1, trig=0, amp=0.25;
  var rec, sig, recptr, rdptr, wet;
  recptr = Phasor.ar(trig, BufRateScale.kr(buf), 0, BufFrames.kr(buf), 0);
  rdptr = Phasor.ar(trig, BufRateScale.kr(buf)*rate, 0, BufFrames.kr(buf), 0);
  rec = In.ar(in, 2);
  // set trig to one to record into buffer
  Demand.ar(trig, 0, Dbufwr(rec, buf, recptr, 1));
  wet = BufRd.ar(2, buf, rdptr, 1);
  sig = XFade2.ar(rec,wet, 0, amp);
}).add;




SynthDef.new(\supasaw, {
  arg freq=440, out=0, rec=0, gate=1, offset=2, amp=0.5, lpf=3000, atk=2.5, rel=1;
  var sig, env;
  // build the envelope
  env = EnvGen.ar(
    Env.new(
      [0, 1, 0.75, 0],
      [atk, 0.5, rel],
      -2,
    ),
    gate,
    doneAction: 2,
  );

  sig = VarSaw.ar(
    freq: [ freq-11, freq-3, freq, freq+3, freq+5, freq+7, freq+9, freq+11],
    iphase: {Rand(0.0, 1.0)}!8,
    width: {ExpRand(0.001, 0.02)}!8
  );

  sig = Splay.ar(sig) * 0.5;
  sig = RLPF.ar(sig, lpf.clip(20, 20000), 1);
  sig = Balance2.ar(sig[0], sig[1], 0, amp)  * env;
  // Out.ar(rec, sig);
  Out.ar(out, sig);
}).add;

~freeze = Synth.new(\freeze, [\amp, 0.15, \in, ~freeze_dly], ~delayGrp);

x = Synth.new(\supasaw, [\freq, exprand(100, 660), \out, ~freeze_dly, \rel, 10])




/*(
{
var val = MouseY.kr(1000, 200, 1); // cursor y pos controls frequency
var pos = MouseX.kr(0, BufFrames.kr(b) - 1); // cursor x position controls buffer pos
var write = MouseButton.kr; // button controls write action
Demand.kr(write, 0, Dbufwr(val, b, pos, 1));
SinOsc.ar(
Duty.kr(Dseq([0.5, 0.75, 0.5, 1.0], inf) * 0.2, 0, Dbufrd(b, Dseries(0, 1, inf)))
) * 0.1
}.play;*/
)

