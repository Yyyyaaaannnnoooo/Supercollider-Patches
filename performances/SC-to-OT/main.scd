s.boot;
(
s.waitForBoot({
  MIDIClient.init;
  m = MIDIOut(2);
})
)



t = TempoClock.new(50/60).permanent_(true);
~mclock = MIDIClockOut.new("AudioBox USB 96", "AudioBox USB 96", t);

~mclock.play;

(
~task.stop;
~task = Task({
  loop{
    [180, 160, 140, 100, 80, 60, 30].do({
      arg tempo, i, w;
      t.tempo_(tempo / 60);
      tempo.postln;
      t.beatDur.postln;
      w = [10, 30, 20, 5].choose;
      'wait time'.postln;
      w.postln;
      w.wait;
  });}
});
)
~task.play(t);
~task.stop(t);




// ~mclock = MIDIClockOut.new("IAC Driver", "Bus 1", t);

~mclock.stop;

(
Pdef.removeAll;
)
m = MIDIOut.newByName("AudioBox USB 96", "AudioBox USB 96")

// set clock dynamically
t.tempo_(80/60);

(
// reset
m.control(0, 17, 8);
m.control(0, 26, 64);
m.control(0, 20, 0);
m.control(0, 19, 127);
m.control(0, 45, 0);
m.control(0, 34, 0);
)

(
~t1 = 0;


Pdef(\s1, Pbind(\type, \midi, \midiout,m,\midicmd,\noteOn,\chan, ~t1,
  // \midinote, Pseq([86, 82, 96].lace(12).scramble,inf),
  \midinote, 86,
  \dur, Prand(
    [
      Pseq(Array.series(8, 0, 0.25).replace(0, Rest(0.5)).stutter(3)),
      Prand(Array.series(4, 0, 0.5).replace(0, Rest(0.5)).stutter(10)),
      Pseq(Array.interpolation(10, 0, 2).replace(0, Rest(0.5)).stutter(10)),
  ], inf),
  /*\dur, Pseq([
  Pseq(Array.interpolation(40, 0.125 / 4, 0.25).stutter(5)),
  Pseq(Array.interpolation(40, 0.125 / 4, 0.25).stutter(2)),
  Pseq(Array.interpolation(40, 0.125 / 4, 0.25).stutter(8)),
  ]
  , inf),*/
  /*\dur, Pseq([
    Pseq([0.25, 0, 0.25, 0].sputter(0.25, 64).lace(64 * 2).replace(0, Rest(0.25))),
    Pseq([0.25, 0, 0.25, 0].sputter(0.25, 64).lace(64).replace(0, Rest(0.25))),
    Pseq([0.25, 0, 0, 0].sputter(0.25, 64).lace(64 * 2).replace(0, Rest(0.25))),
    Pseq([0.25, 0.25, 0.25, 0].sputter(0.25, 64).lace(64).replace(0, Rest(0.25))),
  ], inf),*/
  // \dur, 0.5,
  // \dur, Pseq([0.25, 0, 0].lace(64).replace(0, Rest(0.5)).scramble, inf),
  // \dur, Prand(Array.interpolation(7, 4, 6), inf),
  \sustain, Pkey(\dur, inf),
  \amp, 100, // velocity
));
Pdef(\s1).quant_(1);
Pdef(\s1).play(t, doReset: false);
)

Pdef(\s1).stop;
// CC

(
Pdef(\slice1, Pbind(\type,\midi,\midiout,m,\midicmd,\control,\chan,~t1,\ctlNum, 17, // slice
  // \control, Prand((0..15) * 2, inf),

  // \dur, Prand(Array.interpolation(10, 0.5, 5), inf),
  // \dur, Pseq([0.5, 1, 0.5, 2].sputter(0.333, 64).lace(64)),
  \dur, 0.5,
  \control, Pseq(((4..12)*2).dupEach(2), inf),
  // \control, Pseq([8, 10, 12, 14, 16, 18, 20, 22, 24, 26].dupEach(2).scramble.dupEach(7), inf),

));
Pdef(\slice1).quant_(2);
Pdef(\slice1).play(t);
)

Pdef(\slice1).stop;


(
Pdef(\rep1, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t1,\ctlNum, 20,
  // \control, Pseq((79..127), inf), //55 = 1/8, 67 = 1/4, 79 = 1/2, 91 = 1, 103 = 2 127 = 8
  \control, Pseq([0,0,0,64].lace(64).scramble, inf),
  // \control, Pbind(\value, Pdef(\cc0, \control)),
  // \dur, Pseq(Array.series(8, 0, 0.25).replace(0, Rest(0.5)).stutter(3), inf),
  \dur, 1
));
Pdef(\rep1).quant_(4);
Pdef(\rep1).play(t, doReset: false);
)

Pdef(\rep1).stop;

// repeat time
(
Pdef(\rtime1, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t1,\ctlNum, 21,
  \control, Pxrand([55, 67, 79, 91], inf), //55 = 1/8, 67 = 1/4, 79 = 1/2, 91 = 1, 103 = 2 127 = 8
  // \control, Pwrand([0, 64], [0.75, 0.25], inf),
  // \control, Pbind(\value, Pdef(\cc0, \control)),
  // \dur, Pseq(Array.series(8, 0, 0.25).replace(0, Rest(0.5)).stutter(3), inf),
  \dur, 1
));
Pdef(\rtime1).quant_(4);
Pdef(\rtime1).play(t, doReset: false);
)

Pdef(\rtime1).stop;

// retrig!!!
m.control(~t1, 21, 0)

// PAnning
(
Pdef(\pan1, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t1,\ctlNum, [26], // panning
  \control, Pxrand((0..127), inf),
  \dur, 0.5,
));
Pdef(\pan1).quant_(4);
Pdef(\pan1).play(t, doReset: false);
)
Pdef(\pan1).stop;


// RATE
(
Pdef(\rate1, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t1,\ctlNum, [19], // rate
  \control, Pseq([70, 80, 127, 127].lace(32).scramble, inf),
  \dur, 0.5,
));
Pdef(\rate1).quant_(4);Pdef(\rate1).fadeTime = 1.0;Pdef(\rate1).play(t, doReset: false);
)

Pdef(\rate1).stop;


// Reverb
(
Pdef(\fx2mix1, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t1,\ctlNum, [45],
  \control, Prand([0, 127], inf),
  \dur, 4,
  // \dur, 1
));
Pdef(\fx2mix1).quant_(1);
Pdef(\fx2mix1).play(t, doReset: false);
)
Pdef(\fx2mix1).stop;
m.control(0, 45, 0)

(
Pdef(\fx2time1, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t1,\ctlNum, [40],
  \control, Prand((30..127), inf),
  \dur, 0.5,
  // \dur, 1
));
Pdef(\fx2time1).quant_(1);
Pdef(\fx2time1).play(t, doReset: false);
)

Pdef(\fx2time1).stop;

(
Pdef(\fx1hpf1, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t1,\ctlNum, [34],
  \control, Pxrand((0..80).mirror, inf),
  // \control, 35,
  \dur, 2,
  // \dur, 1
));
Pdef(\fx1hpf1).quant_(4);
Pdef(\fx1hpf1).fadeTime = 1.0;
Pdef(\fx1hpf1).play(t, doReset: false);
)
Pdef(\fx1hpf1).stop;

m.control(0, 34, 0)
m.control(0, 35, )

(
Pdef(\s1).stop;
Pdef(\slice1).stop;
Pdef(\rep1).stop;
Pdef(\rtime1).stop;
Pdef(\pan1).stop;
Pdef(\rate1).stop;
Pdef(\fx2mix1).stop;
Pdef(\fx2time1).stop;
Pdef(\fx1hpf1).stop;
)



CC Values
16 Pitch
17 Slice / start
18 N slices
19 Rate
20 Retrig count
21 Retrig Rate
AMP
22 (Attack) X X
23 (Hold) X X
24 (Release) X X
25 (Volume) X X
26 (Balance) X X
27 (N/A) X X
LFO
28 (Speed 1) X X
29 (Speed 2) X X
30 (Speed 3) X X
31 (Depth 1) X X
32 (Depth 2) X X
33 (Depth 3) X X
FX1
34 FX1 param #1 HPF
35 FX1 param #2 LPF
36 FX1 param #3
37 FX1 param #4
38 FX1 param #5
39 FX1 param #6
FX2
40 FX2 param #1 X X
41 FX2 param #2 X X
42 FX2 param #3 X X
43 FX2 param #4 X X
44 FX2 param #5 X X
45 FX2 param #6 X X




