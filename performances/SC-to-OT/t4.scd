// set clock dynamically
t.tempo_(145/60);

// reset
(

~t4 = 3;
m.control(3, 16, 64);
m.control(3, 26, 64);
m.control(3, 26, 64);
m.control(3, 25, 64);
m.control(3, 45, 1);
m.control(3, 40, 16);
)

(

Pdef(\s4, Pbind(\type, \midi, \midiout,m,\midicmd,\noteOn,\chan, ~t4, \note, 20,
  \dur, 0.5,
  \sustain, 1,
  \amp, 100, // velocity
));
)

(
Pdef(\s4).quant_(4);
Pdef(\s4).play(t, doReset: false);
)

Pdef(\s4).stop;

m.control(3, 35, 70); // lpf
m.noteOn(3, note: 84, veloc: 127);

m.noteOff(3, note: 64, veloc: 127);


// LFO

m.control(3, 31, 127); //depth
m.control(3, 28, 10); //speeed

// panning
(
Pdef(\pan4, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t4,\ctlNum, [26],
  \control, Pwhite(20, 107, inf),
  \dur, 1.5,
  // \dur, 1
));
Pdef(\pan4).quant_(4);
Pdef(\pan4).play(t, doReset: false);
)
Pdef(\pan4).stop;
m.control(3, 26, 64)

// volume
(
Pdef(\vol4, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t4,\ctlNum, [25],
  \control, Prand([20,64], inf),
  \dur, Pseq(Array.series(10, 0.125, 0.125).stutter(10), inf),
  // \dur, 1
));
Pdef(\vol4).quant_(4);
Pdef(\vol4).play(t, doReset: false);
)
Pdef(\vol4).stop;

// Delay
(
Pdef(\dlymix4, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t4,\ctlNum, [45],
  \control, Pseq((0..1), inf),
  \dur, Prand([2, 4], inf),
  // \dur, 1
));
Pdef(\dlymix4).quant_(4);
Pdef(\dlymix4).fadeTime = 1.0;
Pdef(\dlymix4).play(t, doReset: false);
)
Pdef(\dlymix4).stop;

(
Pdef(\dlytime4, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~t4,\ctlNum, [40],
  \control, Pxrand([2, 4, 8, 16, 32, 64] - 1, inf),
  \dur, 0.5,
  // \dur, 1
));
Pdef(\dlytime4).quant_(4);
Pdef(\dlytime4).fadeTime = 1.0;
Pdef(\dlytime4).play(t, doReset: false);
)
Pdef(\dlytime4).stop;





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
