
// set clock dynamically
t.tempo_(255/60);

(
// reset
m.control(4, 35, 70);
m.control(4, 17, 0);
m.control(4, 16, 64);
m.control(4, 26, 64);
m.control(4, 20, 0);
)

(
~t5 = 4;
Pdef(\s5, Pbind(\type, \midi, \midiout,m,\midicmd,\noteOn,\chan, ~t5, \midinote, 86,
  \dur, Pseq(Array.series(4, 0.25, 0.25).replace(0, Rest(0.5)).scramble.stutter(10), inf),
));
Pdef(\s5).quant_(4);
Pdef(\s5).fadeTime = 1.0;
Pdef(\s5).play(t, doReset: false);
)

Pdef(\s5).stop;

(
Pdef(\lpf4, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t5,\ctlNum, 35, // lpf
  \control, Pxrand((70..110).mirror, inf),
  // \dur, Pseq (Array.series(8, 0.25, 0.25).replace(0, Rest(0.5)).stutter(3), inf),
  \dur, 0.125
));
Pdef(\lpf4).quant_(4);
Pdef(\lpf4).play(t, doReset: false);
)
Pdef(\lpf4).stop;
m.control(4, 35, 90);

(
Pdef(\slice4, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t5,\ctlNum, 17,
  \control, Pxrand((0..15) * 2, inf),
  // \dur, Pseq(Array.series(8, 0.25, 0.25).replace(0, Rest(0.5)).stutter(3), inf),
  \dur, 1
));
Pdef(\slice4).quant_(4);Pdef(\slice4).play(t, doReset: false);
)

(
Pdef(\pitch4, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t5,\ctlNum, 16, // pitch
  \control, Prand((0..127), inf),
  // \dur, Pseq(Array.series(8, 0.25, 0.25).replace(0, Rest(0.5)).stutter(3), inf),
  \dur, 1.5
));
Pdef(\pitch4).quant_(4);
Pdef(\pitch4).fadeTime = 1.0;
Pdef(\pitch4).play(t, doReset: false);

)
(
Pdef(\pan4, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t5,\ctlNum, 26, // pitch
  \control, Pwhite(0.0, 127.0, inf),
  // \dur, Pseq(Array.series(8, 0.25, 0.25).replace(0, Rest(0.5)).stutter(3), inf),
  \dur, 0.5
));
Pdef(\pan4).quant_(4);
Pdef(\pan4).play(t, doReset: false);
)

(
Pdef(\rep4, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t5,\ctlNum, 20,
  \control, Pseq([64, 0, 0, 0].lace(16).scramble.stutter(4), inf),
  // \dur, Pseq(Array.series(8, 0.25, 0.25).replace(0, Rest(0.5)).stutter(3), inf),
  \dur, 0.125,
));
Pdef(\rep4).quant_(4);
Pdef(\rep4).fadeTime = 1.0;
Pdef(\rep4).play(t, doReset: false);
)


Pdef(\lpf4).stop;
Pdef(\pan4).stop;
Pdef(\rep4).stop;
Pdef(\pitch4).stop;
Pdef(\s5).stop;
m.control(4, 35, 80)


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
