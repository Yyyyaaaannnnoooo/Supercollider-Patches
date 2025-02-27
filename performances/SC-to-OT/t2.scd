// set clock dynamically
t.tempo_(60/60);

//reset
(
m.control(1, 45,1);
m.control(1, 24, 60);
m.control(1, 19, 127);
m.control(1, 20, 0);
m.control(1, 26, 64);
)

(
~t2 = 1;
Pdef(\s2, Pbind(\type, \midi, \midiout,m,\midicmd,\noteOn,\chan, ~t2,
  \midinote, Pseq((80!5)++(84!16)++(88!8),inf),
  \dur, Pseq([0.25,0.25,0,0,0.25,0,0.25,0].replace(0, Rest(0.25)).lace(64).scramble.stutter(4), inf),
  \sustain, Pkey(\dur, inf),
  \amp, 100, // velocity
));
Pdef(\s2).quant_(1);
Pdef(\s2).play(t, doReset: false);
)

Pdef(\s2).stop;

(
Pdef(\slice2, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t2,\ctlNum, 17, // slice
  \control, Pseq([0, 6].dupEach(7), inf),
  // \control, 0,
  \dur, 0.25,
));
Pdef(\slice2).quant_(1);
Pdef(\slice2).play(t, doReset: false);
)

Pdef(\slice2).stop;


(
Pdef(\rel2, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t2,\ctlNum, 24,
  \control, Pxrand((40..80), inf),
  // \control, 0,
  \dur, 1,
));
Pdef(\rel2).quant_(1);
Pdef(\rel2).play(t, doReset: false);
)

Pdef(\rel2).stop;

(
Pdef(\rate2, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t2,\ctlNum, 19,
  \control, Pxrand((0!2) ++ (127!8) , inf),
  // \control, 0,
  \dur, 1,
));
Pdef(\rate2).quant_(1);
Pdef(\rate2).play(t, doReset: false);
)

Pdef(\rate2).stop;

(
Pdef(\pan2, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t2,\ctlNum, 26, // slice
  \control, Pwhite(20, 107, inf),
  // \control, 0,
  \dur, 1,
));
Pdef(\pan2).quant_(1);
Pdef(\pan2).play(t, doReset: false);
)

Pdef(\pan2).stop;

(
Pdef(\rep2, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t2,\ctlNum, 20,
  \control, Prand  ([0, 63], inf) ,
  // \control, 79,
  \dur, 1,
));
Pdef(\rep2).quant_(1);
Pdef(\rep2).play(t, doReset: false);

Pdef(\rtime2, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t2,\ctlNum, 21,
  // \control, Pseq((79..127), inf), //55 = 1/8, 67 = 1/4, 79 = 1/2, 91 = 1, 103 = 2 127 = 8
  \control, Prand([67, 79, 91], inf),
  // \control, 79,
  \dur, 2,
));
Pdef(\rtime2).quant_(1);
Pdef(\rtime2).play(t, doReset: false);
)

Pdef(\s1).stop;
Pdef(\s2).stop;
Pdef(\slice2).stop;
Pdef(\rep2).stop;
Pdef(\rtime2).stop;


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
