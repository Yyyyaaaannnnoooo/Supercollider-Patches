// set clock dynamically
t.tempo_(60/60);
(
// reset
~t3 = 2;
m.control(2, 20, 0);
m.control(2, 26, 64);
m.control(2, 35, 64);
)

(
Pdef(\slice3, Pbind(\type,\midi,\midiout,m,\midicmd,\control,\chan, ~t3,\ctlNum, [17], // slice
  // \control, Prand((0..15) * 2, inf),
  // \dur, Prand(Array.interpolation(10, 0.5, 5), inf),
  // \control, Pxrand((0..16)* 2, inf),
  \control, Pseq(
    Pseq(((0..7) * 2))!4 ++ [Pxrand(((0..7) * 2))]++
    [Pseq(((0..2) * 2))]
    ,inf),
  \dur, 0.5,
));
Pdef(\slice3).quant_(4);
Pdef(\slice3).play(t);
)

(
Pdef(\s3, Pbind(\type, \midi, \midiout,m,\midicmd,\noteOn,\chan,  ~t3,
  \midinote, Pseq((86!16)++(92!4)++(80!8), inf),
  \dur, 0.5,
  \sustain, Pkey(\dur, inf),
  \amp, 100, // velocity
));
Pdef(\s3).quant_(1);
Pdef(\s3).play(t, doReset: false);
)



Pdef(\s3).stop;
Pdef(\s3).play;

m.control(2, 35, 127);


Pdef(\slice3).stop;

(
Pdef(\rel3,Pbind(\type,\midi,\midiout,m,\midicmd,\control,\chan, ~t3,\ctlNum, 24,
  \dur, 0.5,
  \control, Pseq((80!24) ++ (50!8), inf)
));
Pdef(\rel3).quant_(1);
Pdef(\rel3).play(t);
)
Pdef(\rel3).stop;

(
Pdef(\rep3, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t3,\ctlNum, 20,
  // \control, Pseq((79..127), inf), //55 = 1/8, 67 = 1/4, 79 = 1/2, 91 = 1, 103 = 2 127 = 8
  \control, Pseq([0,64,0,64].lace(64).scramble, inf),
  // \control, Pbind(\value, Pdef(\cc0, \control)),
  // \dur, Pseq(Array.series(8, 0, 0.25).replace(0, Rest(0.5)).stutter(3), inf),
  \dur, 1
));
Pdef(\rep3).quant_(1);
Pdef(\rep3).play(t, doReset: false);
)

Pdef(\rep3).stop;

// repeat time
(
Pdef(\rtime3, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t3,\ctlNum, 21,
  \control, Pxrand([67, 79, 91], inf), //55 = 1/8, 67 = 1/4, 79 = 1/2, 91 = 1, 103 = 2 127 = 8
  // \control, Pwrand([0, 64], [0.75, 0.25], inf),
  // \control, Pbind(\value, Pdef(\cc0, \control)),
  // \dur, Pseq(Array.series(8, 0, 0.25).replace(0, Rest(0.5)).stutter(3), inf),
  \dur, 1
));
Pdef(\rtime3).quant_(1);
Pdef(\rtime3).play(t, doReset: false);
)
Pdef(\rtime3).stop;

(
Pdef(\rate3, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t3,\ctlNum, 19,
  \control, Pseq((127!20) ++ (0!5), inf),
  \dur, 0.5
));
Pdef(\rate3).quant_(1);
Pdef(\rate3).play(t, doReset: false);
)

Pdef(\rate3).stop;

(
Pdef(\pan3, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t3,\ctlNum, 26,
  \control, Pwhite(20, 107, inf),
  \dur, 0.5
));
Pdef(\pan3).quant_(1);
Pdef(\pan3).play(t, doReset: false);
)
Pdef(\pan3).stop;



m.control(2, 35, 70);


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
