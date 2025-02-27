s.boot;
s.quit;
(
SynthDef.new(\saw, {
  arg freq= 220, out=0, amp=0.5, lpf=20000, t_trig=1;
  var sig, env;

  sig = Saw.ar([freq, freq + 2]!8);
  sig = RLPF.ar(sig, freq: lpf);
  env = EnvGen.ar(
    Env.adsr(
      attackTime: 0.2, decayTime: 0.3, sustainLevel: 0.5, releaseTime: 0.5, curve: -4
    ),
    doneAction: 2
  );
  /*sig = PitchShift.ar(
    in: sig,
    windowSize: 0.025,
    pitchRatio: 0.25,
    pitchDispersion: 0.001,
    timeDispersion: 0.0001
  );*/
  sig = Splay.ar(sig);
  sig = sig * amp * env;
  Out.ar(out, sig)
}).add;
)

(
SynthDef.new(\supasaw, {
  arg freq=440, out=0, gate=1, offset=2, amp=0.5, lpf=3000, wrap=1.0;
  var sig, env;
  // build the envelope
  env = EnvGen.ar(
    Env.new(
      [0, 1, 0.75, 0],
      [0.05, 0.75, 1],
      -2,
      2
    ),
    doneAction: 2
  );

  sig = VarSaw.ar(
    freq: [ freq-7, freq-3, freq, freq+3, freq+5, freq+7, freq+9, freq+11],
    iphase: {Rand(0.0, 1.0)}!8,
    width: {ExpRand(0.001, 0.02)}!8
  );


  if(
    wrap != 0,
    {sig = Wrap.ar(sig, 0 - wrap, wrap) * 1/(wrap*4);}
  );
  sig = Splay.ar(sig) * 0.5;
  sig = RLPF.ar(sig, lpf.clip(20, 20000), 1);
  sig = Balance2.ar(sig[0], sig[1], 0, amp)  * env;
  Out.ar(out, sig);
}).add
)


(
x.free;
x = Synth.new(\supasaw, [\freq, 300]);
)

x.set(\amp, 0.5)
x.set(\wrap, 0.75)

(1 / 0.125) / 2

x.free;

s.freeAll;

Line.kr(0.1,4,20).scope;