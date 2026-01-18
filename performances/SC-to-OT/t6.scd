// set clock dynamically
t.tempo_(80/60);

// reset
(
~t6 = 5;
m.control(5, 16, 64);
m.control(5, 26, 64);
m.control(5, 26, 64);
m.control(5, 25, 64);
m.control(5, 45, 1);
m.control(5, 40, 1);
)

(

Pdef(\s6, Pbind(\type, \midi, \midiout,m,\midicmd,\noteOn,\chan, ~t6, \note, 20,
  \dur, 0.5,
  \sustain, 1,
  \amp, 100, // velocity
));
)

(
Pdef(\s6).quant_(4);
Pdef(\s6).play(t, doReset: false);
)

Pdef(\s6).stop;

m.noteOn(5, note: 80, veloc: 127);
m.noteOff(~t6, note: 64, veloc: 127);

m.control(5, 35, 120);

// pitch
(
Pdef(\pitch6, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t6,\ctlNum, [16],
  \control, Pwhite(54, 74, inf),
  \dur, 8,
  // \dur, 1
));
Pdef(\pitch6).quant_(4);
Pdef(\pitch6).fadeTime = 1.0;
Pdef(\pitch6).play(t, doReset: false);
)
Pdef(\pitch6).stop;
// panning
(
Pdef(\pan6, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t6,\ctlNum, [26],
  \control, Pxrand((0..127), inf),
  \dur, 1.5,
  // \dur, 1
));
Pdef(\pan6).quant_(4);
Pdef(\pan6).play(t, doReset: false);
)
Pdef(\pan6).stop;
m.control(5, 26, 64)

// volume
(
Pdef(\vol6, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t6,\ctlNum, [25],
  \control, Prand([20,64], inf),
  \dur, Pseq(Array.series(10, 0.125, 0.125).stutter(10), inf),
  // \dur, 1
));
Pdef(\vol6).quant_(4);
Pdef(\vol6).play(t, doReset: false);
)
Pdef(\vol6).stop;

// Delay
(
Pdef(\dlymix6, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t6,\ctlNum, [45],
  \control, Pseq((0..1), inf),
  \dur, 1,
  // \dur, 1
));
Pdef(\dlymix6).quant_(4);
Pdef(\dlymix6).fadeTime = 1.0;
Pdef(\dlymix6).play(t, doReset: false);
)
Pdef(\dlymix6).stop;

(
Pdef(\dlytime6, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t6,\ctlNum, [40],
  \control, Prand((8..64), inf),
  \dur, 2,
  // \dur, 1
));
Pdef(\dlytime6).quant_(4);
Pdef(\dlytime6).fadeTime = 1.0;
Pdef(\dlytime6).play(t, doReset: false);
)
Pdef(\dlytime6).stop;





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
