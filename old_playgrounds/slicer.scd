/*
* some source can be found here
* https://schollz.com/blog/sampler/
*/

s.boot;
s.quit;
(
// load all audio files in Path to keyed collection

var path, subfolders;
b = ();
path = PathName(thisProcess.nowExecutingPath).parentPath;
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


SynthDef.new(\slicer, {
  arg t_trig=1, buf=0, amp=0.5, slice=0, rate=1, out=0;
  var sig, env, clip, fold, frames, start, duration, sustain;
  rate = BufRateScale.ir(buf) * rate;
  frames = BufFrames.kr(buf);
  duration = frames / 32;
  start = slice * duration;
  sig = PlayBuf.ar(2, buf, rate, startPos: start, loop: 0);
  sustain = duration/rate.abs/BufSampleRate.ir(buf);
  env=EnvGen.ar(
    Env.new(
      levels: [0,1,1,0],
      times: [0,sustain-0.01,0.01],
      curve:\sine,
    ),
    gate: t_trig,
    doneAction: 2;
  );
  fold = Fold.ar(sig, 0.0, 0.15);
  clip = Clip.ar(sig, 0.0, 0.15);
  sig = Mix.ar([sig, clip, fold]);
  sig = sig * amp * env;
  Out.ar(out, sig);
}).add;

)

x = Synth.new(\slicer, [\buf, ~breaks[6], \slice, 0, \rate, 1, \t_trig, 1])

// create a clock in sc
// sc tempo is in seconds, therefore divide by 60
t = TempoClock.new(185/60);
// make a clock that survives `cmd + .`
t = TempoClock.new(185/60).permanent_(true);
t.beats;
// set clock dynamically
t.tempo_(185/60);
// basic sequencer
(
~seq.stop;
p = Pbind(
  \instrument, \slicer,
  \dur, Pseq([Pshuf([0.5,0.5,0.5,0.5,0.5,0.25, Rest(0.25)], 1)], inf),
  \buf, ~breaks[4],
  \slice,Pseq([Pshuf([0, 2, 3, 4, 0, 3, 16, 5, 31], 1)], inf)
);
~seq = p.play(t);
)

~seq.stop;



