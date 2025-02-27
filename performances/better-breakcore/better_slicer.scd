s.boot;
s.quit;

(
~audio_sources = Group.new();
~fx_group = Group.new(~audio_sources, \addAfter);

// assign busses for FX
~reverb = Bus.audio(s, 2);
~delay = Bus.audio(s, 2);
)
(
var path, subfolders;
path = PathName(thisProcess.nowExecutingPath).parentPath;
b = ();
path.postln;
subfolders = PathName(path ++ "audio/").entries;
subfolders.do({
  arg dir;
  var buf_array;
  buf_array = dir.entries.collect({
    arg file;
    Buffer.readChannel(s, file.fullPath, channels: [0, 1]);
  });
  b[dir.folderName.asSymbol] = buf_array;
});


~breaks = b[\breaks];
~modular = b[\modular];
~gabber = b[\gabber];
~synth = b[\synth_loops];
)


///~~~ FFFFFXXXXXX ~~~///

///~~~ REVERB ~~~///
(
SynthDef.new(\reverb, {
  arg in=0, mix=0.0, out=0;
  var sig, wet;
  sig = In.ar(in, 2); // reads from the audio bus
  sig = FreeVerb2.ar(
    sig[0], sig[1],
    mix: mix.clip(0.0, 1.0), room: 0.999, damp: 0.85
  );
  Out.ar(out, sig)
}).add;

)


///~~~ DELAY ~~~///

(
SynthDef.new(\delay, {
  arg in=0, mix=1.0, out=0, delay_time=0.5, fb=10, mod_speed=0.5;
  var dry, wet, sig, dry_mix, dly_mod;
  dry = In.ar(in, 2);
  dly_mod = LFDNoise0.ar(mod_speed).range(0.02, delay_time);
  wet = AllpassN.ar(dry, 10.0, dly_mod, fb);
  sig = XFade2.ar(dry, wet, mix.clip(-1.0, 1.0));
  Out.ar(out, sig);
}).add;
)
(
~fx_verb = Synth.new(\reverb, [\in, ~reverb], target: ~fx_group);
~fx_delay = Synth.new(\delay, [\in, ~delay, \out, ~reverb],target: ~fx_group);
)

(
~fx_delay.set(\delay_time, 0.53);
~fx_delay.set(\mod_speed, 5);
~fx_delay.set(\fb, -5.5);
~fx_delay.set(\mix, 0.25);

)

~fx_verb.set(\mix, 0.5);

// remove all the stuff from FX BUS
~fx_group.freeAll;

///~~~ SUPA SAW ~~~///

(
SynthDef.new(\supasaw, {
	arg freq=440, out=0, gate=1, offset=2, amp=0.5, lpf=3000, atk=2.5, rel=1, hold=0.5;
	var sig, env, detune;
  detune = LFNoise1.kr(0.2!8).bipolar(0.2).midiratio;
	// build the envelope
	env = EnvGen.ar(Env.new([0, 1, 0.75, 0],[atk, hold, rel],-2,),gate,doneAction: 2,);
  sig = VarSaw.ar(freq:freq*detune,iphase:{Rand(0.0, 1.0)}!8,width:{ExpRand(0.001,0.02)}!8);
	sig = Splay.ar(sig) * 0.5;
  sig = RLPF.ar(sig, lpf.clip(20, 20000), 1);
	sig = Balance2.ar(sig[0], sig[1], 0, amp)  * env;
	Out.ar(out, sig);
}).add;
)



///~~~ SAMPLER ~~~///
(
SynthDef.new(\slicer, {
  arg t_trig=1, buf=0, amp=0.5, lpf=5000, r=0.3,
  slice=0, num_slices=1, slices=32, rel=0.05, loops=1,
  rate=1, out=0, fold_amt=0.15, clip_amt=0.15;
  var sig, env, pos, clip, fold, frames, start, end, duration, sustain, pos_rate;
  pos_rate = BufRateScale.ir(buf) * rate;
  frames = BufFrames.kr(buf);
  duration = (frames / slices) * num_slices;
  start = slice * duration;
  end = start + duration;

  sustain = (duration / rate.abs / BufSampleRate.ir(buf)) * loops;
  env = EnvGen.ar(Env.new(levels:[0,1,1,0],times:[0,sustain-rel,rel],curve: \lin),gate:t_trig,doneAction:2);
  // phasor
  pos = Phasor.ar(
    trig: t_trig,
    rate: pos_rate,
    start:   (((rate>0)*start)+((rate<0)*end)),
    end:     (((rate>0)*end)+((rate<0)*start)),
    resetPos:(((rate>0)*start)+((rate<0)*end))
  );

  sig = BufRd.ar(
    numChannels: 2, bufnum: buf, phase: pos, loop: 0, interpolation: 4
  );
  fold = CrossoverDistortion.ar(sig, fold_amt, smooth: clip_amt);
  sig = Mix.ar([sig, fold]);
  sig = RLPF.ar(sig, lpf.clip(20, 20000), r);
  sig = sig * amp * env;
  Out.ar(out, sig);
}).add;
)


///~~~ TEMPO ~~~///
t = TempoClock.new(185/60).permanent_(true);
// set clock dynamically
t.tempo_(186/60);

(
Pdef(\p, Pbind(
  \instrument, \slicer,
  \group, ~audio_sources,
  \amp, 0.25,
  \num_slices, 1,
  // \rel, 1.5,
  // \dur, Pseq([Pshuf([0.5,0.5,0.5,0.5,0.5,0.25, Rest(0.25)], 1)], inf),
  \dur, 0.5,
  \clip_amt, 0.5,
  \fold_amt, 0.1,
  \rate, 0.8,
  // \rate, Pseq([1, 2, 3, 2, 1, 0.5, 0.25, 0.125, -0.25, -0.5, 1], inf),
  // \rate, Prand([1, 1, 1, 1, 1, 2, -1, -1, -2, 0.5, -0.25, 4, 6, 8], inf),
  // \rate, Pseq([Pxrand([1, 2, 4, 1.5, 1, 2, 1, 1, 1, 0.5, 2, 0.1, -1, -2, -0.5], 1)],inf),
  \loops, 1,

  \loops, Pfunc({
    arg ev;
    var return;
    if(
      ev[\rate] < 1 ,
      {return = 1},
      {return = ev[\rate].abs}
    );
  }
  ),
  \out, Pfunc({
    arg ev;
    var return;
    if(
      ev[\rate] < 0.5,
      {return = ~delay},
      {return = 0},
    );
  }),
  // \lpf, 20000,
  \lpf, Pseq([Env([2000, 17000, 12000, 3500, 2000], [5, 10, 15, 7.5], \sine).asPseg], inf),
  \buf, Prand([~breaks[3]], inf),
  \slices, 32,
  \slice,Pxrand(
    [
      Pwrand((0..31), (0..7).lace(32).reverse.normalizeSum, 1),
      Pseq((16..31)),
      Pseq((24..31)),
      Pseq((0..7)),
      Pseq((8..23)),
      Pseq((8..23)),
      Pseq((8..23)),
      Pseq((8..23)),
      Pseq((24..31)),
      Pseq((24..31)),
      Pseq((1..3).lace(9)),
    ]
    , inf)
)
)
)
Env([85, 17000, 750], [50, 10], \sine).plot

Pdef(\p).quant_(4);
Pdef(\p).fadeTime = 1.0;
Pdef(\p).play(t);
Pdef(\p).stop;


(
Pdef(\sup, Pbind(
  \instrument, \supasaw,
  \group, ~audio_sources,
  \out, ~delay,
  \dur, 4,
  // \dur, Pxrand([1, 1, 0.5, Rest(0.5)], inf),
  \freq, Pxrand(
    [
      Pseq([36, 56, 66].midicps, 2),
      Pseq([40, 80 , 120].midicps, 2),
      Pseq([44, 55, 57, 57, 57].midicps, 5),
    ]
    , inf),
  \lpf, Pseq([Env([1250, 12000, 1250], [10, 20], \sine)], inf),
  \rel, 1.5,
  \atk, 2.5,
  \hold, 0.1,
  \amp, 0.5,
))

)



Pdef(\sup).quant_(4);
Pdef(\sup).fadeTime = 4.0;
Pdef(\sup).play(t);
Pdef(\sup).stop;


s.freeAll;

