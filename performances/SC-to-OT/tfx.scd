
// set clock dynamically
t.tempo_(87/60);

// CLOCK PULSES!
(
~tfx = 15;
Pdef(\sfx, Pbind(\type, \midi, \midiout,m,\midicmd,\noteOn,\chan, ~tfx, \midinote, [ 69, 70, 71, 72, 73, 74, 75, 76 ],
  \dur, 2,
  \sustain, 0.125 / 2,\amp, 100, // velocity
));

Pdef(\sfx).quant_(4);Pdef(\sfx).fadeTime = 1.0;Pdef(\sfx).play(t, doReset: false);
)

Pdef(\sfx).play(t)

// Endles processor trigger Deprecated
(
~tfx = 15;
Pdef(\sfxproc, Pbind(\type, \midi, \midiout,m,\midicmd,\noteOn,\chan, ~tfx, \midinote, 63,
  \dur, Pseq( 3 * [2, 4, 8].lace(16).scramble.stutter(5), inf),
  \sustain, 0.125 / 2,\amp, 100, // velocity
));

Pdef(\sfxproc).quant_(4);Pdef(\sfxproc).fadeTime = 1.0;Pdef(\sfxproc).play(t, doReset: false);
)


//////////////
// CONTROL: data bender repeats//
(
Pdef(\ctl0, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~tfx,\ctlNum, 69, // lpf
  \control, Pbrown(0,31, 2, inf),
  \dur, 0.125,
));
Pdef(\ctl0).quant_(4);Pdef(\ctl0).fadeTime = 1.0;Pdef(\ctl0).play(t, doReset: false);
)

Pdef(\ctl0).stop;

//////////////
// CONTROL: data bender bend//
(
Pdef(\ctl1, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~tfx,\ctlNum, 70, // lpf
  \control, Pbrown(15, 80, 5, inf),
  \dur, 0.5,
));
Pdef(\ctl1).quant_(4);Pdef(\ctl1).fadeTime = 1.0;Pdef(\ctl1).play(t, doReset: false);
)

//////////////
// CONTROL: mimeophon zone//
(
Pdef(\ctl2, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~tfx,\ctlNum, 71, // lpf
  \control, Pseq((0..31).mirror, inf),
  \dur, 0.5,
));
Pdef(\ctl2).quant_(4);Pdef(\ctl2).play(t, doReset: false);
)

//////////////
// CONTROL: reverb drive//
(
Pdef(\ctl3, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~tfx,\ctlNum, 72, // lpf
  \control, Pwhite(0.0, 5.0, inf),
  \dur, 0.5,
));
Pdef(\ctl3).quant_(4);Pdef(\ctl3).play(t, doReset: false);
)

Pdef(\ctl3).stop

//////////////
// CONTROL: mimeophon time//
(

Pdef(\ctl4, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~tfx,\ctlNum, 73, // lpf
  \control, Pxrand([12.0, 31.0], inf),
  \dur, 0.2,
));
Pdef(\ctl4).quant_(4);Pdef(\ctl4).fadeTime = 1.0;Pdef(\ctl4).play(t, doReset: false);
)


//////////////
// CONTROL: mimeophon rate//
(
Pdef(\ctl5, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~tfx,\ctlNum, 74, // lpf
  \control, Pwhite(0, 127, inf),
  \dur, 0.125 / 4,
));
Pdef(\ctl5).quant_(4);Pdef(\ctl5).fadeTime = 1.0;Pdef(\ctl5).play(t, doReset: false);
)

//////////////
// CONTROL: //
(
Pdef(\ctl6, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~tfx,\ctlNum, 75, // lpf
  \control, Pwhite(0, 127, inf),
  \dur, 0.5,
));
Pdef(\ctl6).quant_(4);Pdef(\ctl6).fadeTime = 1.0;Pdef(\ctl6).play(t, doReset: false);
)

//////////////
// CONTROL: //
(
Pdef(\ctl7, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan, ~tfx,\ctlNum, 76, // lpf
  \control, Pwhite(0, 127, inf),
  \dur, 0.5,
));
Pdef(\ctl7).quant_(4);Pdef(\ctl7).fadeTime = 1.0;Pdef(\ctl7).play(t, doReset: false);
)


Pdef(\s7).stop;
Pdef(\ctl0).stop;



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
