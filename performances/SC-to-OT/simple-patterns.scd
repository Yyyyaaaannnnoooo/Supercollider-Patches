
(
/*
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
*/
  // Server.default.options.outDevice_("AudioBox USB 96");
  Server.default.options.outDevice_("BlackHole 16ch");
s.waitForBoot({
  Server.default.options.memSize = 65536;
  MIDIClient.init;
  t = TempoClock.new(180/60).permanent_(true);
  // ~mclock = MIDIClockOut.new("AudioBox USB 96", "AudioBox USB 96", t);
  // m = MIDIOut(2);
  ~mclock = MIDIClockOut.new("IAC Driver", "Bus 1", t);
  m = MIDIOut(0);

  ~mclock.play;

  SynthDef(\spectral, {
    arg out=0, amp = 0.5, trig = 1, dist = 3.43, rate=0.25, ratio = 2;
    var sines, sig, sigL, sigR, penv, control, numsines, chain, chain2, size = 256, mod;
    numsines = 20;
    control = Control.names(\array).kr(Array.rand(numsines, 40.0, 1100.0));
    trig = Trig.kr(SinOsc.kr(rate));
    penv = EnvGen.ar(Env.adsr(0.75,0.5,0.5,0.5, curve: -4, bias: 1), trig);
    sines = Mix(SinOsc.ar(control.varlag(3.5, -3), 0, numsines.reciprocal));
    mod = LFBrownNoise2.ar(rate, 1,1);
    chain = FFT(LocalBuf(size), sines);
    chain = PV_BinShift(chain, MouseX.kr(0.25, 8, \exponential, 0.8) + mod, 0.8, interp: 1);
    chain2 = PV_BinShift(chain, (0.125/2) + MouseX.kr(0.25, 8, \exponential, 0.8) + mod, 0.8, interp: 1);
    // chain = PV_SpectralEnhance(chain, 16, 2, 0.75);
    // chain = PV_MagAbove(chain, SinOsc.kr(SinOsc.kr(rate).range(rate, rate*3.34)).abs * 10);
    sigL = IFFT(chain);
    // sigR = PitchShiftPA.ar(sigL, Pitch.kr(sigL)[0], 1.1, 1.147);
    sigR = IFFT(chain2);
    sigL = FreeVerb.ar(sigL, 0.5, 1, 0.5);
    sigR = FreeVerb.ar(sigR, 0.5, 1, 0.5);
    sigL = sigL * amp;
    sigR = sigR * amp;
    sigL = Compander.ar(sigL, sigL, 0.05, 1, 0.1, 0.01, 0.01);
    sigR = Compander.ar(sigR, sigR, 0.05, 1, 0.1, 0.01, 0.01);
    sig = Splay.ar([sigL, sigR], \spread.kr(0));
    Out.ar(out, sig);
  }).add;


  SynthDef(\reese, {
    arg freq = 120, lpf = 800, nof=0.25,a=1.5, s=2, r=0.5;
    var sig, voices = 8, detune = 10, env;
    sig = LFSaw.ar(
      (Array.series(voices, 0.01, 0.37).rand2 + freq).varlag(1.5, -3),
      0,
      voices.reciprocal
    );
    sig = RLPF.ar(sig, lpf.clip(20, 17000).varlag(0.75, -3), 1);
    env = EnvGen.kr(
      Env.new([0,1,0.75,0],
        [a,s,r],
        curve:[2, -3, -3]),
      gate: \gate.kr(1.0),
      doneAction: 2
    );
    sig = sig * env;
    sig = FreeVerb.ar(sig, 0.5, 0.5, 0.5);
    sig = sig!2;
    sig = sig * -6.dbamp;
    Out.ar(0, sig);
  }).add;


  r = Rest(0.25); // rest
  q = 0.25; // quarter note
  h = 0.5; // half note
  f = 1; // full note
  // basic patterns
  // kicks
  ~kicks = [
    [q]++(r!9)++[q]++(r!5),
    [q]++(r!9)++[q]++(r!3)++[q,r],
    [q]++(r!7)++[q,r,q]++(r!5),
    [q]++(r!7)++[q,r,q]++(r!3)++[q,r],
    [q]++(r!5)++[q,r,r,r,q]++(r!5),
    [q]++(r!5)++[q,r,r,r,q]++(r!2)++[q,r,r],
    [q]++(r!6)++[q,r,r,q,r,r]++[q,r,r],
    [q]++(r!2)++[q,r,r,r,q,r,r,q,r,r,q,r,r],
    [q]++(r!5)++[q,r,r,q]++(r!6),
    [q,r,r,r].lace(12)++[q,r,q,r]
  ];

  ~kicks.do({arg i, index; "~~~~~~".postln; "pattern".postln; index.postln; i.postln; i.size.postln;});

  ~snares = [
    (r!4)++[q]++(r!7)++[q]++(r!3),
    (r!4)++[q]++(r!7)++[q,r,q,r],
    (r!4)++[q,r,r,q]++(r!4)++[q,r,r,r],
    (r!4)++[q,r,r,q,r,q]++(r!2)++[q,r,r,r],
    (r!4)++[q,r,r,q,r,q]++(r!2)++[q,r,q,r],
    (r!4)++[q,r,r,r,r,q]++(r!2)++[q,r,r,r],
    (r!4)++[q,r,r,r,r,q]++(r!2)++[q,r,q,r],
    (r!4)++[q,r,r,q]++(r!4)++[q,r,q,r],
    (r!2)++[q,r,r,r,q]++(r!9),
    (r!2)++[q,r,r,r,q,r,q]++(r!7),
  ];

  ~snares.do({arg i, index;
    i.replace(r, 0).replace(q, 1).postln;
  });

  ~arps = [
    [12,13,19,20],
    [12,14,19,17],
    [12,15,14,15],
    [12,15,19,20],
    [12,15,20,17],
    [12,14,21,19],
    [12,19,24,19],
    [36,20,15,12],
    [17,17,12,15],
    [19,17,14,12]
  ];

  ~arps.do({ arg i, index;
    (i + 60).midicps.postln;
  });



  // OT cc values
  ~pitch  = 16;
  ~slice  = 17;
  ~nslice = 18;
  ~rate   = 19; // Rate
  ~rtrign = 20; // Retrig count
  ~rtrigr = 21; // Retrig Rate
  // AMP
  ~atk    = 22; // (Attack) X X
  ~hold   = 23; // (Hold) X X
  ~rel    = 24; // (Release) X X
  ~vol    = 25; // (Volume) X X
  ~pan    = 26; // (Balance) X X
  // LFO
  ~lfos1 = 28; // (Speed 1) X X
  ~lfos2 = 29; // (Speed 2) X X
  ~lfos3 = 30; // (Speed 3) X X
  ~lfod1 = 31; // (Depth 1) X X
  ~lfod2 = 32; // (Depth 2) X X
  ~lfod3 = 33; // (Depth 3) X X
  // FX1
  ~fx1p1 = 34; // FX1 param #1 HPF
  ~fx1p2 = 35; // FX1 param #2 LPF
  ~fx1p3 = 36; // FX1 param #3
  ~fx1p4 = 37; // FX1 param #4
  ~fx1p5 = 38; // FX1 param #5
  ~fx1p6 = 39; // FX1 param #6
  // FX2
  ~fx2p1 = 40; // FX2 param #1 X X
  ~fx2p2 = 41; // FX2 param #2 X X
  ~fx2p3 = 42; // FX2 param #3 X X
  ~fx2p4 = 43; // FX2 param #4 X X
  ~fx2p5 = 44; // FX2 param #5 X X
  ~fx2p6 = 45; // FX2 param #6 X X

  ~cc69 = 69;
  ~cc70 = 70;
  ~cc71 = 71;
  ~cc72 = 72;
  ~cc73 = 73;
  ~cc74 = 74;
  ~cc75 = 75;
  ~cc76 = 76;

  ~t1 = 0;
  ~t2 = 1;
  ~t3 = 2;
  ~t4 = 3;
  ~t5 = 4;
  ~t6 = 5;
  ~t7 = 6;
  ~t8 = 7;
  ~tfx = 15;

  ~step = {arg val; Pseq([val], inf);};

  ~mpseq = {arg list;  Pseq(list, inf)};

  ~mpw = {arg lo, hi; Pwhite(lo, hi, inf) };

  ~mpb = {arg lo, hi, s; Pbrown(lo, hi, s, inf)};

  ~mprand = {arg list; Prand(list,inf)  };

  ~mpxrand = {arg list; Pxrand(list, inf) };

  ~coll = {
    arg list, equal, a, b;
    list.collect({|v,i|if(v==equal,{a},{b})})
  };

  ~pcoll = {
    arg list, equal, a, b;
    var r = list.collect({|v,i|if(v==equal,{a},{b})});
    Pseq(r, inf)
  };

  ~series = {
    arg size, start;
    Array.series(size, start, 1)
  };
  ~pseries = {
    arg size, start;
    var r = Array.series(size, start, 1).postln;
    Pseq(r, inf)
  };

  ~interp = {
    arg steps, start, end;
    Array.interpolation(steps, start, end);
  };

  ~pinterp = {
    arg steps, start, end;
    var r = Array.interpolation(steps, start, end).dupEach(8);
    Pseq(r, inf);
  };

  ~exp = {
    arg size, start, stop;
    Array.interpolation(size, start, stop).linexp(start,stop,start,stop)
  };

  ~pexp = {
    arg size, start, stop;
    var r = Array.interpolation(size, start, stop).linexp(start,stop,start,stop);
    Pseq(r, inf)
  };

  ~slices = {
    arg seq, offset, length, repeats, steps;
    ((seq + offset) * (2)).lace(length) ++ ((steps[0]*2)!repeats[0]) ++
    ((seq.scramble + offset) * (2)).lace(length) ++ ((steps[1]*2)!repeats[1]) ++
    ((seq + offset) * (2)).lace(length) ++ ((steps[2]*2)!repeats[2]);
  };

  ~rpsl = {
    arg repeats, length;
    (0!length) ++ (127!repeats[0]) ++
    (0!length) ++ (127!repeats[1]) ++
    (0!length) ++ (127!repeats[2])
  };

  ~rpt = {
    // 55 = 1/8, 67 = 1/4, 79 = 1/2, 91 = 1, 103 = 2 127 = 8
    arg repeats, length;
    (103!length) ++ ([79,91,84].choose!repeats[0]) ++
    (103!length) ++ ([79,91,84].choose!repeats[1]) ++
    (103!length) ++ ([79,91,84].choose!repeats[2])
  };

  ~prate = {
    arg repeats, length;
    (127!length) ++ (((0!1)++(127!2)).choose!repeats[0]) ++
    (127!length) ++ (((0!2)++(127!1)).choose!repeats[1]) ++
    (127!length) ++ (((0!3)++(127!1)).choose!repeats[2])
  };

  ~ptch = {
    arg note, repeats, length;
    (note!length) ++ (~series.(repeats[0] / 2, note)).mirror1 ++
    (note!length) ++ (~series.(repeats[1] / 2, note)).mirror1 ++
    (note!length) ++ (~series.(repeats[2] / 2, note)).mirror1
  };

  ~ptch2 = {
    arg note, repeats, length;
    (note!length) ++ ([note-2,note+4, note+8].choose!repeats[0]) ++
    (note!length) ++ ([note-2,note+4, note+8].choose!repeats[1]) ++
    (note!length) ++ ([note-2,note+4, note+8].choose!repeats[2])
  };

  ~mmn = {
    arg channel, name, patN, patD;
    Pdef(name, Pbind(\type,\midi,\midiout,m,\midicmd,\noteOn,\chan,channel,
      \midinote, patN,
      \dur, patD,
      \sustain, 5,
      \amp, 100, // velocity
    ));
    Pdef(name).quant_(1);
    Pdef(name).fadeTime = 1.0;
  };

  ~mmcc = {
    arg channel, name, cc, patCC, patD;
    Pdef(name, Pbind(\type, \midi, \midiout,m,\midicmd,\control,\chan,channel,\ctlNum,cc,
      \control, patCC,
      \dur, patD,
    ));
    Pdef(name).quant_(1);
    Pdef(name).fadeTime = 1.0;
  }
})
)

(
~init_midi_modular = {
  ~sfx.stop;
  // FX seq
  ~sfx = Pdef(\sfx, Pbind(\type,\midi,\midiout,m,\midicmd,\noteOn,\chan,~tfx,\midinote, (60..67),
    \dur, f,\sustain, 0.125 / 2,\amp, 100,));
  ~sfx.quant_(1);
  ~sfx.play(t);
  // ~sfx1.stop;
  // FX seq
  // ~sfx1 = Pdef(\sfx, Pbind(\type,\midi,\midiout,m,\midicmd,\noteOn,\chan,~tfx,\midinote, [61, 62, 63],
  // \dur, f,\sustain, 0.125 / 2,\amp, 100,));
  // ~sfx1.quant_(1);
  // ~sfx1.play(t);
  ~scc0 = ~mmcc.(~tfx, \cc69, 69, ~mpw.(0, 31), ~step.(q));
  ~scc0.play(t);
  ~scc1 = ~mmcc.(~tfx, \cc70, 70, ~mpb.(0, 31, 2), ~step.(q));
  ~scc1.play(t);
  ~scc2 = ~mmcc.(~tfx, \cc71, 71, ~mpb.(0, 31, 2), ~step.(q));
  ~scc2.play(t);
  ~scc3 = ~mmcc.(~tfx, \cc72, 72, ~mpb.(0, 31, 2), ~step.(q));
  ~scc3.play(t);
  ~scc4 = ~mmcc.(~tfx, \cc73, 73, ~mpb.(0, 31, 2), ~step.(q));
  ~scc4.play(t);
  ~scc5 = ~mmcc.(~tfx, \cc74, 74, ~mpseq.(~series.(64, 0).mirror), ~step.(q));
  ~scc5.play(t);
  ~scc6 = ~mmcc.(~tfx, \cc75, 75, ~mpb.(0, 31, 2), ~step.(q));
  ~scc6.play(t);
  ~scc7 = ~mmcc.(~tfx, \cc76, 76, ~mpb.(0, 127, 1), ~step.(q));
  ~scc7.play(t);
}
)

(~scc0.stop;)




MIDIClient.disposeClient


t.tempo_((180/60).varlag(0.5, -3));
Pdef.removeAll;
~mclock.play;
~mclock.stop;

t.tempo
(
~bd = {
  arg pitch = (82..92).scramble.dupEach(8),
  dur = ~interp.(40, 0.125, 1).dupEach(8).mirror2,
  seq = ~mpb.(0, 16, 2),
  rate = ((127!32)++(0!8)),
  retrig = ((0!16) ++ (127!4)),
  pan = 0;
  ~p0 = pitch;
  // ~pD0 = Pseq(~p0.collect({|val, i| if(val < 86, {f + [(q/16).neg, q/16, (q/9).neg, q /16].choose}, {[q, q/2, q/4].choose})}), inf);
  ~pD0 = ~mpseq.(dur);
  ~s1 = ~mmn.(~t1, \s1, Pseq(~p0, inf), ~pD0);
  ~s1sl = ~mmcc.(~t1, \slice1, ~slice, seq, ~pD0);
  ~s1Rep = ~mmcc.(~t1, \rtrig1, ~rtrign, ~mpseq.(retrig), ~pD0);
  ~s1Rate = ~mmcc.(~t1, \rate1, ~rate, ~mpseq.(rate), ~pD0);
  ~s1pan = ~mmcc.(~t1, \pan1, ~pan, ~mprand.((64 + ((-64..64) * pan))), ~pD0);
  ~s1.play(t);
  ~s1sl.play(t);
  ~s1pan.play(t);
  ~s1Rep.play(t);
  ~s1Rate.play(t);
}
)

(
~stop_bd = {
  ~s1.stop;
  ~s1sl.stop;
  ~s1pan.stop;
  ~s1Rate.stop;
  ~s1Rep.stop;
}
)

(
~bd.(
  [86,82].dupEach(7),
  // ((h!32)++(r!4)),
  ~exp.(32, 0.5, 2).dupEach(8).mirror,
  ~mpb.(4, 12, 1),
  ((127!16)++(0!4)),
  [0, 0, 0, 127],
  1
)
)

~stop_bd.()

m.control(~t1, ~rate, 64.varlag(0.5, -3))

(
~lynn = {
  arg seq=(0..8).scramble, steps=16, offset = [0, 2, 5, 7].choose,
  repeats = [12, 4, 8], repsteps = [0, 2, 3] + offset,
  pitch=[84, 88].dupEach(16), rate = [127],pan = 0, dur = ~step.(h);
  var step = 0, rot = 0;
  seq.postln;
  repsteps = repsteps + offset;
  ~p2 = ~slices.(seq, offset, steps, repeats, repsteps);
  ~pD2 = dur;
  ~s2rate = ~mmcc.(~t2, \rate2, ~rate, ~mpseq.(rate), ~pD2);
  ~s2 = ~mmn.(~t2, \s2, ~mpseq.(pitch), ~pD2);
  ~s2sl = ~mmcc.(~t2, \slice2, ~slice, ~mpseq.(~p2), ~pD2);
  ~s2Rep = ~mmcc.(~t2, \rtrig2, ~rtrign, ~mpseq.(~rpsl.(repeats, steps)), ~pD2);
  ~s2pan = ~mmcc.(~t2, \pan2, ~pan, ~mprand.((64 + ((-64..64) * pan))), ~pD2);
  ~s2.play(t);
  ~s2Rep.play(t);
  ~s2sl.play(t);
  ~s2pan.play(t);
  ~s2rate.play(t);
}
)




(
~stop_lynn = {
  ~s2pan.stop;
  ~s2Rep.stop;
  ~s2Rep.stop;
  ~s2rt.stop;
  ~s2sl.stop;
  ~s2.stop;
  "lynn stopped".postln;
}
)


(
~amen = {
  arg seq=(0..8).scramble,
  steps=16, offset = 0, repeats = [12, 4, 8],
  repsteps = [0, 2, 3], pitch = [84, 88].dupEach(32), rate=[127], pan=0, dur = ~step.(h);
  var step = 0,  rot = 0;
  seq.postln;
  repsteps = repsteps + offset;
  ~p3 = ~slices.(seq, offset, steps, repeats, repsteps);
  ~pD3 = dur;
  ~s3rate = ~mmcc.(~t3, \rate3, ~rate, ~mpseq.(rate), ~pD3);
  ~s3 = ~mmn.(~t3, \s3, ~mpseq.(pitch), ~pD3);
  // ~s3 = ~mmn.(~t3, \s3, ~mpseq.(~ptch2.(86, repeats, steps)), ~pD3);
  ~s3sl = ~mmcc.(~t3, \slice3, ~slice, ~mpseq.(~p3), ~pD3);
  ~s3Rep3 = ~mmcc.(~t3, \rtrig3, ~rtrign, ~mpseq.(~rpsl.(repeats, steps)), ~pD3);
  ~s3pan = ~mmcc.(~t3, \rtime3, ~pan, ~mprand.((64 + ((-64..64) * pan))), ~pD3);
  ~s3.play(t);
  ~s3Rep3.play(t);
  ~s3sl.play(t);
  ~s3pan.play(t);
  ~s3rate.play(t);
}
)
(
~stop_amen = {
  ~s3.stop(t);
  ~s3Rep3.stop(t);
  ~s3sl.stop(t);
  ~s3pan.stop(t);
  ~s3rate.stop(t);
}
)

~stop_amen.()

(

)

(
~amen.(
  (0..8).scramble,          // seq
  16,          // steps
  0,          // offset
  [4, 16, 8], // n of repeats
  [0, 1, 2], // repeated steps
  // (82..94).dupEach(1).mirror,
  [86],
  ((127!16)++(0!8)),
  1,
  ~mpseq.(((h!16) ++ (r!8)))
);
)

~stop_lynn.()

(
~lynn.(
  (0..2),
  16,
  0,
  [12, 4, 6],
  [0, 1, 2],
  [84, 88].dupEach(16),
  ((127!16) ++ (0!8)), // rate
  // [127], // rate
  1, // pan
);
)
s.boot

(
~pad = {
  arg dur=2, f=80, lpf=600, a=0.5, r=0.5;
  ~r0 = Pdef(\pad, Pbind(
    \instrument, \reese,\dur, dur,\freq, f,\lpf, lpf,\a, a, \r, r,
    \s, Pfunc({arg e; var r; var d = e[\dur]; var a = e[\a]; r = d}),
  ),
  );
  ~r0.quant_(4);
  ~r0.fadeTime = 1.0;
  ~r0.play(t)
};
~stop_pad = {~r0.stop(t)}
)

(
~pad.(
  ~mpw.(0.5, 2), // dur Pwhite(0.5, 2, inf)
  Pseq((~arps[(0..9).choose] + [45, 48, 45, 40]).midicps, inf), ///freq
  ~mpw.(100, 1000), //lpf
  ~mpw.(0.125, 0.75), // attack
  0.5, //r
)
)

~stop_pad.()

(
~arp = {
  arg dur=0.25, f=80, lpf=600, r=0.25;
  ~r1 = Pdef(\arp, Pbind(
    \instrument, \reese, \dur, dur, \freq, f, \lpf, lpf, \a, 0.01, \r, r,
    \s, Pfunc({arg e; var r; var d = e[\dur]; var a = e[\a]; r = d / 2}),
  ),
  );
  ~r1.quant_(4);
  ~r1.fadeTime = 1.0;
  ~r1.play(t)
};
~stop_arp = {~r1.stop(t)}
)

t.tempo_((200/60).varlag(0.25))

(
~arp.(
  ~mpw.(0.5, 0.55 ), // dur Pwhite(0.5, 2, inf)
  // ~pinterp.(32, 0.125, 0.5),
  // 0.5,
  ~mprand.([
    Pseq((~arps[(0..9).choose] + 48).midicps),
    Pseq((~arps[(0..9).choose] + 40).midicps),
    Pseq((~arps[(0..9).choose] + 50).midicps),
    Pseq((~arps[(0..9).choose] + 60).midicps)
  ]
  ), ///freq
  ~mpw.(200, 1600), //lpf
  ~mpseq.([0.125 / 2, 0.25]), //r
)
)

~stop_arp.()

(
b.free;
b = Synth(\spectral);
)
b.setn(\rate, 0.5)
b.setn(\amp, 2.dbamp)
b.setn(\spread, 1)
b.setn(\array, {rrand(140, 1700.rand)}!20);
