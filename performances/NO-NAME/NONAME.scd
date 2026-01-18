ServerOptions.outDevices;
(

///~~~ SERVER CLEANUP ~~~///
s.freeAll;
~cleanup = {
  Pdef.removeAll;
  ServerBoot.removeAll;
  ServerQuit.removeAll;
  ServerTree.removeAll;
  CmdPeriod.removeAll;
};

ServerQuit.add(~cleanup);
~cleanup.();

///~~~ Load path to samples here ~~~///
~path = PathName(thisProcess.nowExecutingPath).parentPath;

///~~~ BUSSES ~~~///
s.newBusAllocators;
~reverb_bus = Bus.audio(s, 2);
~delay_bus = Bus.audio(s, 2);
~tp_dly_bus = Bus.audio(s, 2);

///~~~ MIDI ~~~///
// MIDIIn.connectAll();
// MIDIIn.disconnectAll();

/*MIDIIn.noteOn({
// function for your midi notes
// like playing a synth
}).permanent_(true);*/ /// <= this makes it cmd + . agnostic
/*ServerOptions.outDevices;
Server.default.options.outDevice_("AudioBox USB 96");
Server.default.options.inDevice_("AudioBox USB 96");*/

// Server.default.options.outDevice_("BlackHole 16ch");
// Server.default.options.inDevice_("BlackHole 16ch");

Buffer.freeAll;
s.waitForBoot({
  ///~~~ LOAD SAMPLES IN BUFFERS ~~~///
  ///~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~///
  var subfolders;
  b = ();
  ~path.postln;
  subfolders = PathName(~path ++ "audio/").entries;
  subfolders.do({
    arg dir;
    var buf_array;
    buf_array = dir.entries.collect({
      arg file;
      Buffer.readChannel(s, file.fullPath, channels: [0, 1]);
    });
    b[dir.folderName.asSymbol] = buf_array;
  });


  // ~breaks = b[\breaks];
  ~b2bar = b[\twobars];
  ~b4bar = b[\fourbars];
  ~modular = b[\modular];
  // ~gabber = b[\gabber];
  // ~synth = b[\synth_loops];
  ~bd = b[\bd];
  ~sd = b[\sd];
  ~o = b[\o];
  ~ultra = b[\ultrcr];
  ~pad = b[\pad];
  ~rytm = b[\rytm];
  ~vox = b[\vox];
  // ~zeke = b[\zeke];
  ~noise = b[\noises];
  ~fx = b[\fx];
  ~uk = b[\ultrakicks];
  ~gltch = b[\gltch];

  ///~~~ LOAD SYNTH DEFS ~~~///
  ///~~~~~~~~~~~~~~~~~~~~~~~///


  SynthDef.new(\slicer, {
    arg t_trig=1,buf=0,amp=0.5, lpf=17000, fold_amt=0.15,clip_amt=0.15, out=0,
    slice=0, slices=32,
    rel=0,atk=0, sus=1,loops=1,rate=1,pitch=1,bars=4,beat=1,do_stretch=1,grain=5;
    var sig, env, pos_env, micro_pos_env, pos, clip, fold, frames, start, end, start_pos, end_pos, duration,
    sustain, pos_rate, micro_pos, micro_dur,tot_duration, sample_duration, stretch=1, llist, index = 0, phase, loop=0;
    tot_duration = beat * 4 * bars;
    sample_duration = BufDur.kr(buf);
    stretch = 1 / (tot_duration / sample_duration);
    llist = [stretch, 1];
    stretch = (((do_stretch>=1) * stretch) + ((do_stretch<1)*1));
    pos_rate = (BufRateScale.kr(buf) * rate) * stretch;
    frames = BufFrames.ir(buf);
    // just corrected this
    // duration = (frames / slices) * num_slices;
    duration = (frames / slices);
    start = slice * duration;
    end = start + duration;
    sustain = (duration / (rate.abs * stretch) / BufSampleRate.ir(buf)) * loops;
    // NEEDS BETTER ENVELOPE
    env = EnvGen.ar(
      Env.new([0,1,1,0],[atk, sustain * sus, rel],\lin),
      gate: t_trig,
      doneAction: 2,
    );
    pos_env = EnvGen.ar(
      Env.new([0,1,1,0],[0, sustain, 0],\lin),
      gate: t_trig,
      doneAction: 0,
    );
    start_pos = (((rate>0)*start)+((rate<0)*end));
    end_pos = (((rate>0)*end)+((rate<0)*start));
    pos = Phasor.ar(t_trig,pos_rate,start_pos,end_pos,start);
    // timestretch withouth Pitch shift
    micro_dur = duration / grain;
    micro_dur = (((rate>0) * micro_dur)-((rate<0)* micro_dur));
    micro_pos = Phasor.ar(t_trig, pitch.abs, pos, pos + micro_dur, start);
    micro_pos_env = EnvGen.ar(
      Env.new([0,1,1,0],[0, micro_dur*0.25, 0],\sine),
      gate: t_trig,
      doneAction: 0,
    );
    micro_pos = micro_pos * pos_env;

    loop = (loops>1);
    sig = BufRd.ar(numChannels: 2, bufnum: buf, phase: micro_pos, loop: 0, interpolation: 4);
    sig = RLPF.ar(sig, lpf.clip(25, 19500), 0.5);
    fold_amt = 1-fold_amt;
    fold_amt = fold_amt.clip(0.001, 1);
    clip_amt = 1-clip_amt;
    clip_amt = clip_amt.clip(0.001, 1);
    fold = Fold.ar(sig, 0-fold_amt, fold_amt) * 1/fold_amt;
    clip = Clip.ar(sig, 0-clip_amt, clip_amt) * 1/clip_amt;
    sig = Mix.ar([sig, fold, clip]);
    // sig = Compander.ar(sig, sig, 0.1, 1, 1/8, 0.002, 0.01);
    sig = sig * amp * env;
    Out.ar(out, sig);
  }).add;

  SynthDef.new(\simpler, {
    arg t_trig=1,buf=0,amp=0.5, lpf=17000, fold_amt=0.15,clip_amt=0.15, out=0,
    slice=0, num_slices=1, slices=32,
    rel=0,atk=0, sus=1,loops=1,rate=1,pitch=1,bars=4,beat=1,do_stretch=1,grain=5;
    var sig, env, pos_env, pos, clip, fold, frames, start, end, start_pos, end_pos, duration,
    sustain, pos_rate, micro_pos, micro_dur,tot_duration, sample_duration, stretch=1, llist, index = 0, phase, r_amp, r_time;
    tot_duration = beat * 4 * bars;
    sample_duration = BufDur.kr(buf);
    stretch = 1 / (tot_duration / sample_duration);
    stretch = (((do_stretch>=1) * stretch) + ((do_stretch<1)*1));
    pos_rate = (BufRateScale.ir(buf) * rate) * stretch;

    frames = BufFrames.ir(buf);
    // just corrected this
    // duration = (frames / slices) * num_slices;
    duration = (frames / slices)/loops;
    start = slice * duration;
    end = start + duration;

    sustain = (duration / (rate.abs * stretch) / BufSampleRate.ir(buf));

    // NEEDS BETTER ENVELOPE

    env = EnvGen.ar(
      Env.new([0,1,1,0],[atk, sustain * sus, rel],\lin),
      gate: t_trig,
      doneAction: 2,
    );
    start_pos = (((rate>0)*start)+((rate<0)*end));
    end_pos = (((rate>0)*end)+((rate<0)*start));
    pos = Phasor.ar(t_trig,pos_rate,start_pos,end_pos,start_pos);
    /*    r_time=duration / loops;
    r_amp=1/loops;
    pos = EnvGen.ar(
    Env.new(
    [0,r_amp].lace(loops) ++ [0],
    [r_time, 0].lace(loops),
    \lin
    );
    );*/

    sig = BufRd.ar(numChannels: 2, bufnum: buf, phase: pos, loop: 1, interpolation: 4);
    sig = RLPF.ar(sig, lpf.clip(25, 19500), 0.5);
    fold_amt = 1-fold_amt;
    fold_amt = fold_amt.clip(0.001, 1);
    clip_amt = 1-clip_amt;
    clip_amt = clip_amt.clip(0.001, 1);
    fold = Fold.ar(sig, 0-fold_amt, fold_amt) * 1/fold_amt;
    clip = Clip.ar(sig, 0-clip_amt, clip_amt) * 1/clip_amt;
    sig = Mix.ar([sig, fold, clip]);
    // sig = Compander.ar(sig, sig, 0.1, 1, 1/8, 0.002, 0.01);
    sig = sig * amp * env;
    Out.ar(out, sig);
  }).add;


  ///~~~ LOAD FX SYNTH DEFS ~~~///
  ///~~~~~~~~~~~~~~~~~~~~~~~~~~///
  SynthDef.new(\reverb,
    {
      arg in=0, mix=0.4, out=0, mod_speed=0.05;
      var sig, wet, verb_mod, mod_carrier;
      sig = In.ar(in, 2); // reads from the audio bus
      mod_carrier = SinOsc.kr(mod_speed).range(0.005, 1);
      verb_mod = SinOsc.kr(mod_carrier).range(0.2, 0.999);
      sig = FreeVerb2.ar(
        sig[0], sig[1],
        mix: mix.clip(0.0, 1.0), room: verb_mod, damp: 0.85
      );
      Out.ar(out, sig)
  }).add;

  SynthDef.new(\delay, {
    arg in=0, mix=1.0, out=0, delay_time=0.5, fb=10, mod_speed=0.5;
    var dry, wet, sig, dry_mix, dly_mod;
    dry = In.ar(in, 2);
    dly_mod = LFDNoise0.ar(mod_speed).range(0.002, delay_time);
    wet = AllpassN.ar(dry, 10.0, dly_mod, fb);
    sig = XFade2.ar(dry, wet, mix.clip(-1.0, 1.0));
    Out.ar(out, sig);
  }).add;

  // Delay grabbed from this guy here: https://scsynth.org/t/tape-delay-implementation/2290
  SynthDef.new(\tapedly, {
    arg in=0, out=0,fb=0.6, fc=5000, dlytime=0.125, wet=0.5, pan=0.0, f_mod=1.0;
    var local, sig, delayed, phi, phR, phP, freq;
    var tdbh; // time delay between heads (seconds)
    local = LocalBuf(SampleRate.ir * 3, 1);
    local.clear; // clear the buffer

    tdbh = 0.125;
    phi = (2 * tdbh) / BufDur.ir(local);
    freq = f_mod.clip(0.125, 2.0) / BufDur.ir(local); // frequency to playback the buffer at rate 1
    freq = (freq * tdbh) / VarLag.kr(dlytime, 2, warp:\linear);
    phR = LFSaw.ar( freq, phi, 0.5, 0.5)*BufFrames.kr( local );
    phP = LFSaw.ar( freq, 0.0, 0.5, 0.5)*BufFrames.kr( local );

    sig = Mix.ar(In.ar(in,2));
    delayed = BufRd.ar(1, local, phP, loop:1);
    delayed = delayed.tanh;
    BufWr.ar( LPF.ar( (sig + delayed), fc.clip(25, 19500), mul:fb), local, phR, loop:1);
    // pan = LFNoise1.ar(5);
    Out.ar(out, Pan2.ar(delayed*wet, pan));
  }).add;


  SynthDef.new(\compressor,
    {
      arg in=0, out=0;
      var compressed;
      in = In.ar(in,2);
      compressed = Compander.ar(in, in, 0.1, 1, 1/8, 0.002, 0.01);
      Out.ar(out, compressed);
  }).add;

  ///~~~ VERY IMPORTANT ~~~///
  s.sync;

  ~makeNodes = {
    ~synths = Group.new;
    ~fxs = Group.after(~synths);
    ~comp = Synth.new(\compressor, [\in, 0], target: ~fxs);
    ~verb = Synth.new(\reverb, [\in, ~reverb_bus], target: ~fxs);
    ~tp_dly = Synth.new(\tapedly, [\in, ~tp_dly_bus], target: ~fxs);
    ~delay = Synth.new(\delay, [\in, ~delay_bus, \out, ~reverb_bus], target: ~fxs);

    Pdef.removeAll;
  };
  ServerTree.add(~makeNodes);
  ServerTree.run;

  t = TempoClock.new(185/60).permanent_(true);
  ~r = {arg stop; [Rest(0.5)].lace(stop)};

  (
    ~rand_wave = {
      arg min=100, max=19500, time=50;
      var num_seg = rrand(6, 35);
      Env(
        [min]++
        (({rrand(min, max)}!(num_seg-1))).scramble
        ++[min],
        {exprand(1, time)}!num_seg,
        \sine
        // {rrand(-20, 20)}!num_seg
      ).asPseg;
    }
  )



});

)

Server.killAll

r = ~rand_wave
r.plot
// Set TEMPO

(
t.tempo_(197/60);
Pdef(\t1).set([\beat, t.beatDur]);
Pdef(\t2).set([\beat, t.beatDur]);
Pdef(\t3).set([\beat, t.beatDur]);
Pdef(\t4).set([\beat, t.beatDur]);
Pdef(\t5).set([\beat, t.beatDur]);

Pdef(\t6).set([\beat, t.beatDur]);
Pdef(\t7).set([\beat, t.beatDur]);
)


// BRRRRRRREEEEEEEAAAAAAAKKKKKSSSSS
(

Pdef(\t1, Pbind(
  \instrument, \slicer,
  \group, ~synths,
  \slices, 32,
  \bars, 4,
  \beat, t.beatDur,
  \dur, Prand([
    Pseq([0.5].lace(32)),
    Pseq([0.5, Rest(0.5), 1].lace(8)),
    Pseq([0.5, 0.5, Rest(0.5), 1, 3, 4, 0.5]),
    Pseq([2, Rest(0.5)].lace(8)),
    Pseq([0.5].lace(7))
  ], inf),

  // \dur, Prand([0.5].lace(50)++[1, 2], inf),
  \dur, 0.5,
  // \rate, 1,
  \rate, Pfunc({arg ev;var r;
    if(ev[\dur] < 1,
      {r = 1},
      {r = (-1/(2 * ev[\dur].abs))});}),
  // \rate, 0.25,
  // \clip_amt, Pseq([Env([1, 0.5, 1, 0.01, 0.25, 1], [10,0, 30, 10, 0], \sine).asPseg], inf),
  // \clip_amt, 0.76,
  // \pitch, Pseq([Env([1, 0.5, 1, 1, 2, 1], [10,0, 30, 10, 0], \sine).asPseg], inf),
  // \pitch, Prand([0.5, 0.25, 1.25, 1, 1.5], inf),
  \pitch, 1,
  // \grain, Prand((5..10), inf),
  \grain, 2,
  // \buf, Pseq([~b2bar[0], ~b2bar[0], ~b2bar[0], ~b2bar[0], ~b2bar[0], ~b2bar[4], ~b2bar[4]], inf),
  // \buf, Prand([~b2bar[0], ~b2bar[5], ~b2bar[2]], inf),
  \buf, ~b4bar[4],
  // \lpf, Pseq([Env([3000, 17000, 8000], [50,10], \sine).asPseg], inf),

  // \slice, Pseq((0..7) + [Pwhite.new(0,2)] + 0 , inf),
  \slice,Prand([
    Pseq((16..31)),
    Pseq((24..31)),
    Pseq((0..7)),
    Pseq((8..23)),
    Pseq((8..23)),
    Pseq((1..3).lace(9)),
    Pseq((1..3).lace(9)),
    Pseq((5..8).lace(9)),
    Pseq((12..15).lace(9)),
    Pseq((7..12).lace(9)),
    Pseq((12..15).lace(9)),
    Pseq((12..15).lace(9)),
    Pseq((9..12).lace(9)),
  ], inf),
  // \slice, Pseq((0..7) + 2 , inf),
  // \slice, 2,
  \amp, -12.dbamp,
  \atk, 0.0,
  // \sus, Pfunc({arg ev;var ret;if(ev[\dur] < 1,{ret = ev[\dur] * 2},{ret = 1})}),
  \sus, 1,
  \rel, 0,
  // \out, ~delay_bus,
  \out, Pfunc({
    arg ev;
    var r;
    if(ev[\dur] < 1,
      {r = 0},
      {r = ~delay_bus}
    )
  }
  ),
  \out, 0,
  // \out, ~tp_dly_bus,
)
)
)

~tp_dly.set(\dlytime, 0.125 / 16, \fb, 0.125,\wet, 0.5,\fc, 19000, \f_mod, 0.25, \out, 0);


(
Pdef(\t1).quant_(4);
Pdef(\t1).fadeTime = 1.0;
Pdef(\t1).play(t, doReset: false);
)

Pdef(\t1).stop;

Pdef(\t1).stop;
Pdef(\t2).stop;
Pdef(\t3).stop;
Pdef(\t4).stop;
Pdef(\t5).stop;
Env([1, 0.5, 1, 1, 2, 1] , [10,0, 30, 10, 0], \sine).plot

// pads: 0 = "ethereal", 1 = "doom-00",
// 2 = "doom-01"[8 slices], 3 = "reese"
(
Pdef(\t2, Pbind(
  \instrument, \slicer,
  \group, ~synths,
  \dur, 4,
  // \rate, Prand([0.125, 0.25, 0.5, 0.75, 1, 1.5, 2], inf),
  \rate, 1,
  \grain, 10,
  \fold, 0.75,
  \buf, Prand([~pad[0], ~pad[1], ~pad[3]], inf),
  // \buf, ~pad[1],
  \lpf, Pxrand([
    ~rand_wave.value(500, 12000, 30),
    ~rand_wave.value(500, 12000, 30),
    ~rand_wave.value(500, 12000, 30),
    ~rand_wave.value(500, 12000, 30),
  ], inf),
  \lpf, 17000,
  \pitch, Pseq([Env([1, 0.5, 1, 1, 2, 1] , [10,0, 30, 10, 0], \sine).asPseg], inf),
  // \pitch, 2,
  \slices, 4,
  \slice, Prand((0..3), inf),
  \atk, 0.05,
  \rel, 0.5,
  \sus, 0.5,
  \amp, -30.dbamp,
  \out, ~delay_bus,
)
)
)



(
Pdef(\t2).quant_(4);
Pdef(\t2).fadeTime = 1.0;
Pdef(\t2).play(t);
)
Pdef(\t2).stop;


Pdef(\t1).stop;
Pdef(\t2).stop;
Pdef(\t3).stop;
Pdef(\t4).stop;
Pdef(\t5).stop;


// ~~~~~~~~~ FX SETTINGS ~~~~~~~~~~~~~~~~

~delay.set(\delay_time, 1);
~delay.set(\mod_speed, 1);
~delay.set(\fb, 5);
~delay.set(\mix, 0.5);
~verb.set(\mix, 0.5);
~verb.set(\mod_speed, 0.5);




// gabber kicks slices
(
Pdef(\t3, Pbind(
  \instrument, \slicer,
  \group, ~synths,
  \dur, Prand([
    Pseq([1].lace(32)),
    Pseq([0.25].lace(32)),
    Pseq([0.25].lace(32)),
    Pseq([0.25].lace(32)),
    Pseq([0.5].lace(32)),
    Pseq([0.5, Rest(0.5), Rest(0.5)].lace(32)),
    Pseq([1].lace(32)),
    Pseq([2].lace(16)),
    Pseq([0.5, 0.5, Rest(0.5), 1, 3, 4, 0.5]),
    Pseq([2, Rest(0.5)].lace(8)),
    Pseq([0.5].lace(7))
  ], inf),
  // \dur, 0.5,
  \beat, t.beatDur,
  \do_stretch, 0,
  // \rate, 1,
  \rate, Pfunc({arg ev;var return;if(ev[\dur] < 2 ,{return = 1},{return = (-1/(2 * ev[\dur].abs))});}),
  \grain, 32,
  \fold_amt, 0,
  \clip_amt, 0,
  \slices, 8,
  \buf, ~gabber[2],
  \lpf, 17000,
  // \lpf, Pseq([~rand_wave.value(100, 17000, 5),~rand_wave.value(100, 17000, 10), ~rand_wave.value(500, 17000, 3),~rand_wave.value(500, 17000, 30)], inf),
  // \lpf, Pseq([~rand_wave.value(100, 17000, 50)], inf),
  \lpf, Pseq([Env([300, 17000, 300], [100,50], \sine).asPseg], inf),
  // \slice, 7,
  \slice, Prand([7, 7, 7, 7, 4, 4, 5, 5, 5, 5, 7, 7, 7, 7, 7, 7], inf),
  \rel, 0.05,
  \sus, 0.5,
  \atk, Prand([0.0001, 0.001, 0.01], inf),
  \amp, -25.dbamp,
  \out, Pfunc({
    arg ev;
    var return;
    if(
      ev[\dur] <= 1,
      {return = 0},
      {return = ~delay_bus}
    )
  }),
  // \out, ~delay_bus,

))

)

(
// Pdef(\t5).stop;
Pdef(\t3).quant_(4);
Pdef(\t3).fadeTime = 1.0;
Pdef(\t3).play(t, doReset: false);
)
Pdef(\t3).stop;

Pdef(\t1).stop;
Pdef(\t2).stop;
Pdef(\t3).stop;
Pdef(\t4).stop;
Pdef(\t5).stop;



// Manis MOdular
(
Pdef(\t4, Pbind(
  \instrument, \simpler,
  \group, ~synths,
  \dur, Prand([0.5, 1, 2, 3, 4, 5], inf),
  \rate, 1,
  \pitch, 1,
  \grain, 32,
  \fold_amt, 0,
  \clip_amt, 0,
  \buf, ~modular[0], // change this to noise
  \lpf, Pxrand([
    ~rand_wave.value(500, 12000, 30),
    ~rand_wave.value(500, 12000, 30),
    ~rand_wave.value(500, 12000, 30),
    ~rand_wave.value(500, 12000, 30),
  ], inf),
  // \lpf, 2000,
  \loops, 1,
  \slices, 64,
  \slice, Prand((0..63), inf),
  \atk, 0.01,
  \rel, 1,
  \amp, -25.dbamp,
  \out, ~delay_bus,
)
)
)

(
Pdef(\t4).quant_(4);
Pdef(\t4).fadeTime = 1.0;
Pdef(\t4).play(t);
)
Pdef(\t4).stop;

Pdef(\t1).stop;
Pdef(\t2).stop;
Pdef(\t3).stop;
Pdef(\t4).stop;
Pdef(\t5).stop;
Pdef(\t6).stop;
Pdef(\t7).stop;


// rytm drum loop
(
Pdef(\t5, Pbind(
  \instrument, \simpler,
  \group, ~synths,
  \dur, Prand([
    Pseq([1].lace(32)),
    Pseq([0.25].lace(32)),
    Pseq([0.5].lace(32)),
    Pseq([0.5, Rest(0.5), Rest(0.5)].lace(32)),
    Pseq([1].lace(32)),
    Pseq([2].lace(16)),
    Pseq([0.5, 0.5, Rest(0.5), 1, 3, 4, 0.5]),
    Pseq([2, Rest(0.5)].lace(8)),
    Pseq([0.5].lace(7))
  ], inf),
  // \dur, 1,
  \rate, 1,
  \beat, t.beatDur,
  \bars, 4,
  \buf, ~rytm[1],
  \loops, 1,
  \slices, 32,
  \slice, Pseq((0..31), inf),
  \slice,Prand(
    [
      Pseq((0..7).lace(9)),
      Pseq((8..16).lace(9)),
      Pseq((5..23).lace(9)),
      Pseq((0..3).lace(9)),
      Pseq([0,0,0,1,1,1,1,1]),
      Pseq([3,3,3,3,3,3]),
  ], inf),
  \atk, 0.05,
  \sus, 1,
  \rel, 0.25,
  \amp, -12.dbamp,
  // \out, ~delay_bus,
  \out, Pfunc({
    arg ev;
    var return;
    if(
      ev[\dur] <= 1,
      {return = 0},
      {return = ~delay_bus}
    )
  })
)
)
)

(
Pdef(\t1).stop;
Pdef(\t5).quant_(4);
Pdef(\t5).fadeTime = 1.0;
Pdef(\t5).play(t);
)
Pdef(\t5).stop;

// Drum Kits
(
Pdef(\t6, Pbind(
  \instrument, \simpler,
  \group, ~synths,\slices,1, \do_stretch, 0, \bars, 0.35,
  \dur, Pseq([
    Pseq([1].lace(32)),
    Pseq([0.25].lace(32)),
    Pseq([0.5].lace(32)),
    Pseq([0.75].lace(32)),
    Pseq([0.5, Rest(0.5), Rest(0.5)].lace(32)),
    Pseq([1].lace(32)),
    Pseq([2].lace(16)),
    Pseq([0.5, 0.5, Rest(0.5), 1, 3, 4, 0.5]),
    Pseq([2, Rest(0.5)].lace(8)),
    Pseq([0.5].lace(7))
  ], inf),
  // \dur, Pseq([1, Rest(0.5), 0.5, 0.25].lace(16) ++ ~r.value(2) ++ [1, 0.25].lace(4), inf),
  // \dur, 4,
  \rate, 1,
  \buf, Prand([~uk[7], ~uk[8], ~uk[1], ~uk[10]], inf),
  \atk, 0,
  \sus, 0.5,
  \rel, 0.15,
  \amp, -10.dbamp,
  // \out, ~delay_bus,
  \out, Pfunc({arg ev;var return;if(ev[\dur] <= 1,{return = 0},{return = ~delay_bus})}),
  \out, 0,
)
)
)


(
Pdef(\t6).quant_(4);
Pdef(\t6).fadeTime = 1.0;
Pdef(\t6).play(t, doReset: false);
)
Pdef(\t6).stop;


// Hey Babe!
(
Pdef(\t7, Pbind(
  \instrument, \simpler,
  \group, ~synths,
  \dur, Pseq([
    Pseq([1].lace(32)),
    Pseq([0.25].lace(32)),
    Pseq([0.5].lace(32)),
    Pseq([0.5, Rest(0.5), Rest(0.5)].lace(32)),
    Pseq([1].lace(32)),
    Pseq([2].lace(16)),
    Pseq([0.5, 0.5, Rest(0.5), 1, 3, 4, 0.5]),
    Pseq([2, Rest(0.5)].lace(8)),
    Pseq([0.5].lace(7))
  ], inf),
  \dur, 2,
  \buf, ~vox[0],
  \rate, 1,
  \slices, 32,
  \sus, 1,
  \rel, 0,
  \bars, 32,
  // \pitch, 1,
  \rate, Pseq([Env([1, 0.5, -0.5, 1, 2, 1], [50,0, 80, 90, 10], \sine).asPseg], inf),
  \beat, t.beatDur,
  \slice, Pseq((0..31), inf),
  \amp, -12.dbamp,
  \out, ~delay_bus,
)
)
)



(
Pdef(\t7).quant_(4);
Pdef(\t7).fadeTime = 1.0;
Pdef(\t7).play(t, doReset: false);
)
Pdef(\t7).stop;



// ~~~~ SINGLE SHOTS SAMPLES ~~~~

(
x.free;
Pdef(\t1).stop;
Pdef(\t2).stop;
Pdef(\t3).stop;
Pdef(\t4).stop;
Pdef(\t5).stop;
Pdef(\t6).stop;
Pdef(\t7).stop;

x = Synth(\simpler, [
  \buf, ~vox[2],
  \loops, 1,
  \rate, 1,
  \slices,1,
  \sus, 1,
  \rel, 0,
  \bars, 2,
  \beat, t.beatDur,
  \do_stretch, 0,
  \amp, -9.dbamp,
  \out, ~delay_bus,
])

)

x.free;
x.set([\amp, -10.dbamp]);


Pdef(\t1).play(t);
Pdef(\t2).play(t);
Pdef(\t3).play(t);
Pdef(\t4).play(t);
Pdef(\t5).play(t);
Pdef(\t6).play(t);





