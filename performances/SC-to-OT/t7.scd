
// set clock dynamically
t.tempo_(124/60);

(
m.control(6, 35, 70); //LPF
m.control(6, 24, 85); //release
)
m.control(6, 24, 90); //release

(
~t7 = 6;
Pdef(\s7, Pbind(\type, \midi, \midiout,m,\midicmd,\noteOn,\chan, ~t7,
  \midinote, Pseq([72, 86, 94].dupEach(3), inf),
  \dur, 0.5,
  // \dur, Pseq(Array.series(32, 0.125 / 2, 0.125 / 2).replace(0, Rest(0.5)).stutter(8).mirror, inf),
  \dur, Pseq([
    Pseq(Array.interpolation(16, 0.125 / 2, 0.5).stutter(4).mirror),
    Pseq(Array.interpolation(16, 0.125 / 4, 0.25).stutter(8).mirror),
    Pseq(Array.interpolation(16, 0.125 / 2, 1).stutter(16).mirror),
  ], inf),
  \sustain, Pkey(\dur, inf),
  \amp, 100, // velocity
));

Pdef(\s7).quant_(1);
Pdef(\s7).play(t, doReset: false);
)

Pdef(\s7).stop;

(
Pdef(\lpf7, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t7,\ctlNum, 35, // lpf
  \control, Pseq((60..120).mirror, inf),
  // \dur, Pseq(Array.series(8, 0, 0.5).replace(0, Rest(0.5)).stutter(3), inf),
  \dur, 0.125,
));

Pdef(\lpf7).quant_(1);
Pdef(\lpf7).play(t, doReset: false);

)

(
Pdef(\revtime7, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t7,\ctlNum, 40, // lpf
  \control, Pxrand((40..80).mirror, inf),
  \dur, 0.5,
));

Pdef(\revtime7).quant_(1);
Pdef(\revtime7).play(t, doReset: false);

)

m.control(6, 35, 60)


Pdef(\pitch7).stop;
Pdef(\lpf7).stop;
Pdef(\revtime7).stop;
Pdef(\s7).stop;



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
