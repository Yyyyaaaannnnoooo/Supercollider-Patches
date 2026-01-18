/*
* some source can be found here
* https://schollz.com/blog/sampler/
*/

s.boot;
s.quit;
(
// load all audio files in Path to keyed collection
// from Eli Fieldsteel

var path, subfolders;
b = ();
path = PathName(thisProcess.nowExecutingPath).parentPath;
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
)

(
SynthDef.new(\slicer, {
  arg t_trig=1, buf=0, amp=0.5,
  slice=0, num_slices=1, slices=32, rel=0.05, loops=1,
  rate=1, out=0, fold_amt=0.15, clip_amt=0.15;

  var sig, env, pos, clip, fold, frames, start, end, duration, sustain, pos_rate;

  pos_rate = BufRateScale.ir(buf) * rate;
  frames = BufFrames.kr(buf);
  duration = (frames / slices) * num_slices;
  start = slice * duration;
  end = start + duration;

  sustain = (duration / rate.abs / BufSampleRate.ir(buf)) * loops;
  env = EnvGen.ar(
    Env.new(
      levels: [0,1,1,0],
      times: [0, sustain - rel, rel],
      curve: \lin
    ),
    gate: t_trig,
    doneAction: 2,
  );
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
  sig = Mix.ar([sig * amp, fold]);
  sig = sig * amp * env;
  Out.ar(out, sig);
}).add;

)


// create a clock in sc
// sc tempo is in seconds, therefore divide by 60
t = TempoClock.new(185/60);
// make a clock that survives `cmd + .`
t = TempoClock.new(185/60).permanent_(true);
t.beats;
// set clock dynamically
t.tempo_(189/60);
// basic sequencer
(
Pdef(\p, Pbind(
  \instrument, \slicer,
  // \dur, Pseq([Pshuf([0.5,0.5,0.5,0.5,0.5,0.25, Rest(0.25)], 1)], inf),
  \dur, 0.5,
  \clip_amt, 0.125,
  \fold_amt, 0.02,
  \rate , 1,
  // \rate, Prand([1, 1, 1, 2, -1, -1, -2, 0.5, -0.25, 4, 6, 8], inf),
 /* \rate, Pseq(
    [Pxrand([1, 2, 4, 1.5, 1, 2, 1, 1, 1, 0.5, 2, 0.1, -1, -2, -0.5], 1)],
    inf),*/
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
  \buf, Pseq([Pshuf([~breaks[4]], 1)] , inf),
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
);
)
)


Pdef(\p).quant_(4);
Pdef(\p).fadeTime = 2.0
Pdef(\p).play(t);
Pdef(\p).stop;

s.freeAll;





