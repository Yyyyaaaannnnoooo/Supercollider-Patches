s.boot



(
// Server.default.options.outDevice_("Multi-Output Device");
// Server.default.options.inDevice_("BlackHole 16ch");
Server.default.options.outDevice_("BlackHole 16ch");
s.options.numOutputBusChannels = 8;
// s.options.numInputBusChannels = 2;
s.reboot;
)
s.quit
(
s.newBusAllocators;
~size = 1024;
~waves = 16;
~hop = 0.25;
~win = 0;
~imagBus = Bus.control(s, ~size);
~imagBus2 = Bus.control(s, ~waves);
~ratectrl = Bus.control(s, 1);
~micBus = Bus.audio(s, 2);
~recBus = Bus.audio(s, 2);
~recBus1 = Bus.audio(s, 2);
~recBus2 = Bus.audio(s, 2);
~ch1 = Bus.audio(s, 2);
~ch2 = Bus.audio(s, 2);
~ch3 = Bus.audio(s, 2);
~ch4 = Bus.audio(s, 2);

~synths = Group.new;
~fxs = Group.after(~synths);
~eoc = Group.after(~fxs);

t = TempoClock.new(185/60).permanent_(true);
// f = (1..~size).linexp(1, ~size, 25, 8000);

f = Array.rand(~size, 0, 1);
f.do({
  arg item, i;
  ~imagBus.setAt(i, item);
});

~setBus = {
  arg list;
  list.do({
    arg item, i;
    ~imagBus.setAt(i, item);
  })
};

// Set up OSC receive

OSCdef(
  key: \image,
  func: {
    arg msg, time, addr, recvPort;
    // msg.postln;
    msg.do({
      arg item, i;
      if(i>0,
        {~imagBus.setAt(i, item)}
      );
    })
  },
  path: '/image');


~mod_vals = (0..15);
OSCdef(
  key: \image2,
  func: {
    arg msg, time, addr, recvPort;
    // msg.postln;
    msg.do({
      arg item, i;
      if(i>0,
        {
          ~imagBus2.setAt(i, item);
          ~mod_vals.put(i-1, item)
        }
      );
    })
  },
  path: '/image2');

~path = PathName(thisProcess.nowExecutingPath).parentPath;
~load_samples = {
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
  ~vox = b[\vox];
  ~amen = b[\amen];
  ~think = b[\think];

};
~load_samples.();


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

~rand_wave = {
  arg min=(-1), max=1, num_seg = rrand(6, 35);
  var time = 10;
  Env(
    [0]++
    (({rrand(min, max)}!(num_seg-1))).scramble
    ++[0],
    {exprand(1, time)}!num_seg,
    \sine
    // {rrand(-20, 20)}!num_seg
  );
}

)

(

SynthDef(\spectralimage, {
  arg in=0, buf;
  var mask = ~size.collect ({ arg i; In.kr(~imagBus.index + i) });
  var input, input1, input2, chain, sig, noise, mic;
  input = WhiteNoise.ar() * -12.dbamp;
  chain = FFT(LocalBuf(~size), input);
  chain = chain.pvcalc(~size, {
    arg mags, phases;
    [mags*mask, phases*mask]
  });
  sig = IFFT(chain);
  Out.ar(\aux.kr(~recBus), sig!2 * \send.kr(0.dbamp));
  sig = sig * \amp.kr(2.dbamp);
  sig = Splay.ar(sig!2, 1);
  Out.ar(\out.kr(0), sig);
}).add;



SynthDef(\recorder, {
  arg bufnum, in;
  var input = In.ar(in, 2);
  RecordBuf.ar(input, bufnum, loop: 1);
  0;
}).add;

SynthDef(\player, {
  arg buf;
  var sig = PlayBuf.ar(2, buf, \rate.kr(1, 3), 1, loop:1);
  sig = sig * \amp.kr(-24.dbamp, 0.25);
  Out.ar(\out.kr(~recBus1), sig!2);
}).add;

// Playback SynthDef
SynthDef(\glibuf, {
  arg bufnum, out = 0;
  var play, pos, trig = 1, tI=0, tD=0, env, kick, sweep, atk, rel;
  tI = Impulse.kr(\trI.kr(4, 0.5), mul:\tmI.kr(0, 0.25));
  tD = Dust.kr(\trD.kr(4, 0.25), mul:\tmD.kr(1, 0.25));
  trig = tI+tD;
  sweep = Latch.kr(LFNoise1.kr(0.05).range(0.0, 3), trig);
  atk = Latch.kr(LFNoise1.kr(500).range(0.001, 0.2), trig);
  rel = Latch.kr(LFNoise1.kr(500).range(0.025, 0.75), trig);
  kick = EnvGen.kr(Env.perc(0.001, 0.25, sweep, -4), trig, doneAction:0);
  play = PlayBuf.ar(
    numChannels: 2,
    bufnum: bufnum,
    rate:BufRateScale.kr(bufnum) * \rate.kr(1, 0.0625) + kick,
    trigger: trig,
    startPos: \pos.kr(0).linlin(0, 2000, 0, BufFrames.kr(bufnum)),
    loop: 1);
  env = EnvGen.kr(Env.perc(
    atk,
    rel,
    1, -4),
  trig, doneAction:0);
  // play = Pan2.ar(play, );
  play = play * env;
  play = Balance2.ar(play[0], play[1], LFNoise1.kr(\pan.kr(4, 0.5)).range(-1, 1));
  Out.ar(out, play * \amp.kr(0.dbamp, 0.5));
}).add;

// Playback SynthDef
SynthDef(\glibuf2, {
  arg bufnum, out = 0, sweep=1.5, atk=0.001, rel=0.025, trig=1;
  var play, env, kick, tr;
  tr = Dust.kr(\trigrate.kr(10));
  kick = EnvGen.kr(Env.perc(0.001, 0.25, sweep, -4), tr, doneAction:0);
  play = PlayBuf.ar(
    numChannels: 2,
    bufnum: bufnum,
    rate:BufRateScale.kr(bufnum) * \rate.kr(1, 0.0625) + kick,
    trigger: trig,
    startPos: \pos.kr(0).linlin(0, 2000, 0, BufFrames.kr(bufnum)),
    loop: 1);
  env = EnvGen.kr(Env.perc(
    atk,
    rel,
    1, -4),
  trig, doneAction:2);
  // play = Pan2.ar(play, );
  play = play * env;
  play = Balance2.ar(play[0], play[1], \pan.kr(0));
  // play = Balance2.ar(play[0], play[1], -1);
  Out.ar(\aux.kr(~recBus1), play * \send.kr(0.dbamp, 0.25));
  Out.ar(out, play * \amp.kr(0.dbamp, 0.5));
}).add;

// Playback SynthDef
SynthDef(\padbuf, {
  arg bufnum, out = 0, sweep=1.5, atk=1, rel=2, trig=1;
  var play, env, kick, tr;
  tr = Pulse.kr(10);
  play = PlayBuf.ar(
    numChannels: 2,
    bufnum: bufnum,
    rate:(BufRateScale.kr(bufnum) * \rate.kr(1, 0.0625)) + Array.series(8, 0.0005, 0.0087).rand2,
    trigger: trig,
    // startPos: SinOsc.kr(10).range(0, 1) * BufFrames.kr(bufnum),
    loop: 1);
  env = EnvGen.kr(Env.perc(
    atk,
    rel,
    1, -4),
  trig, doneAction:2);
  play = play * env;
  play = Balance2.ar(play[0], play[1], \pan.kr(0));
  Out.ar(\aux.kr(~recBus1), play * \send.kr(0.dbamp, 0.25));
  Out.ar(out, play * \amp.kr(0.dbamp, 0.5));
}).add;

SynthDef(\pvrec, {
  arg in=0, rbuf=0, fftsize=1024, hop=0.25, win=0;
  var sig = In.ar(in, 2);
  var localbuf = {LocalBuf.new(fftsize)}!2;
  var chain = FFT(localbuf, sig, hop, win);
  chain = PV_RecordBuf(chain, rbuf, run:1, loop:1, hop:hop, wintype:win);
  0;
}).add;

SynthDef(\fftstretch, {
  arg out=0, rbuf=0, fftsize=1024, hop=0.25, win=0;
  var localbuf = {LocalBuf.new(fftsize)}!2;
  var chain = PV_PlayBuf(
    buffer:localbuf,
    playbuf:rbuf,
    rate:\rate.kr(1),
    loop:1
  );
  var sig;
  chain = PV_BinScramble(chain, \scrWipe.kr(0.125), \scrWidth.kr(0.5), \trig.tr(0));
  chain = PV_PitchShift(chain, \pitch.kr(1).varlag(0.5, -3));
  sig = IFFT(chain, win);
  sig = RLPF.ar(sig, \lpf.kr(12000, 0.125).clip(20, 19000));
  // Out.ar(\aux.kr(~fxBusRev), sig * \send.kr(0, 0.25));
  Out.ar(out, sig * \amp.kr(-6.dbamp, 0.25))
}).add;

// s.sync;

SynthDef(\additive, {
  arg out=~ch4;
  var offsets = ~waves.collect ({ arg i; In.kr(~imagBus2.index + i) });
  var freqs = (1..~waves).linexp(1, ~waves, 30, 220);
  var sines, sig, control, numsines = ~waves;
  control = freqs + (offsets * 100);
  sines = Mix(SinOsc.ar(control.varlag(0.125,-3), 0, numsines.reciprocal * SinOsc.kr(\lfo.kr(0.1, 0.25)).range(0, 1)));
  sig = sines * \amp.kr(-24.dbamp, 0.25);
  // sig = Splay.ar(sig, 1);
  Out.ar(out, sig!2);
}).add;

SynthDef(\eoc, {
  arg in1 = 0, in2 = 2, in3 = 4, in4 = 6;
  var input1 = In.ar(in1, 2);
  var input2 = In.ar(in2, 2);
  var input3 = In.ar(in3, 2);
  var input4 = In.ar(in4, 2);
  var sig1, sig2, sig3, sig4;
  sig1= RLPF.ar(input1, \lpf.kr(8000, 0.25).clip(20, 19000));
  sig1 = RHPF.ar(sig1, \hpf.kr(40, 0.5).clip(20, 19000));

  sig2= RLPF.ar(input2, \lpf.kr(8000, 0.25).clip(20, 19000));
  sig2 = RHPF.ar(sig2, \hpf.kr(40, 0.5).clip(20, 19000));

  sig3= RLPF.ar(input3, \lpf.kr(8000, 0.25).clip(20, 19000));
  sig3 = RHPF.ar(sig3, \hpf.kr(40, 0.5).clip(20, 19000));

  sig4= RLPF.ar(input4, \lpf.kr(8000, 0.25).clip(20, 19000));
  sig4 = RHPF.ar(sig4, \hpf.kr(40, 0.5).clip(20, 19000));
  ReplaceOut.ar(0, [sig1[0], sig1[1], sig2[0], sig2[1], sig3[0], sig3[1], sig4[0], sig4[1]]);
}).add;

)

~master.free;
~specimg.free ;
~addi.free;
~recorder.free;

(
// turn on visual synth and buffer recorder
~master = Synth(\eoc, [\in1, ~ch1, \in2, ~ch2, \in3, ~ch3, \in4, ~ch4, ],target:~eoc);
~specimg = Synth(\spectralimage,[\out, ~ch1], target:~synths);
~addi = Synth(\additive,[\out, ~ch1, \amp, -18.dbamp], target: ~synths);
~bufferSize = 4;
~recordbuf = Buffer.alloc(s, s.sampleRate * ~bufferSize, 2);
~recorder = Synth.after(~specimg, \recorder, [\in, ~recBus, \bufnum, ~recordbuf]);
)

~addi.set(\amp, -24.dbamp)
~specimg.set(\amp, 2.dbamp)

(
// Spectral buffers
~recbuf1 = {Buffer.alloc(s, 5.calcPVRecSize(~size,~hop))}!2;
~recbuf2 = {Buffer.alloc(s, 5.calcPVRecSize(~size,~hop))}!2;
)

(
// spectral recorders
~pvrec1 = Synth(\pvrec, [ \in, ~recBus,\rbuf, ~recbuf1,\fftsize, ~size,\hop, ~hop,\win, ~win], target: ~fxs);
~pvrec2 = Synth(\pvrec, [ \in, ~recBus1,\rbuf, ~recbuf2,\fftsize, ~size,\hop, ~hop,\win, ~win], target: ~fxs);
)
//
// ~vox = b[\vox];
// ~amen = b[\amen];
// ~think = b[\think];

(
~player.free;
~player = Synth.after(~specimg, \player, [\buf, ~vox[1], \out, ~recBus1])
)
~player.set(\out, ~ch4)
~player.set(\out, ~recBus)
~player.set(\out, ~recBus1)
~player.set(\rate, 1)
~player.set(\buf, ~think[1])
~player.set(\amp, -24.dbamp)



~player.free
~master.free
~specimg.free
~addi.free
~recorder.free




~fftstretch1 = Synth.after(~pvrec1, \fftstretch, [\out, ~ch3, \rate, 0.2, \rbuf, ~recbuf1, \fftsize, ~size,\hop, ~hop,\win, ~win]);

~fftstretch2 = Synth.after(~pvrec2, \fftstretch, [\out, ~ch3,\amp, 2.dbamp, \rate, 0.25, \rbuf, ~recbuf2, \fftsize, ~size,\hop, ~hop,\win, ~win]);


~pvrec1.free
~pvrec2.free

(
~fftstretch1.set(\rate, -1);
~fftstretch1.set(\trig, 1);
~fftstretch1.set(\scrWipe, 0);
~fftstretch1.set(\scrWidth, 0);
~fftstretch1.set(\pitch, 1);
~fftstretch1.set(\lpf, 8000);
)
(
~fftstretch2.set(\rate, (-0.5));
~fftstretch2.set(\trig, 1);
~fftstretch2.set(\scrWipe, 0);
~fftstretch2.set(\scrWidth, 0);

~fftstretch2.set(\pitch, 1);
~fftstretch2.set(\amp, 2.dbamp);

~fftstretch2.set(\lpf, 8000);
)
~fftstretch1.free
~fftstretch2.free

// USE FFT1 only with spectral image synth
// to do spectral stretch

(
~r1.stop;
~r1 = Routine({
  loop{
    /*~interp.(40, -1, 1).do({
    arg val, i;
    // ~fftstretch1.set(\rate, val);
    // ~fftstretch1.set(\scrWipe, val );
    0.125.wait;
    });*/
    // ~series.(start, size)
    // ~interp.(steps, start, end)
    ~interp.(30, -1.0, 1.0).mirror.do({
      arg val, i;
      var avg = ~mod_vals.sum / 8;
      var one = (val + 1) /2;
      // one.postln;
      // ~fftstretch2.set(\scrWipe, 1 / val);
      // ~mod_vals[4];
      // ~fftstretch1.set(\rate, (~mod_vals[4] - 1));
      // ~fftstretch1.set(\lpf, val.postln);
      // ~fftstretch1.set(\rate, (~mod_vals[4]));
      // ~fftstretch2.set(\rate, val);
      // ~fftstretch1.set(\rate, ~mod_vals[0].linlin(0, 1, -1, 1));
      // ~fftstretch1.set(\lpf, val);
      // ~fftstretch2.set(\rate, ~mod_vals[2].linlin(0, 1, -1, 1));
      ~fftstretch2.set(\rate, avg);

      // ~fftstretch2.set(\rate, avg.linlin(0, 1, -1, 1));
      // ~fftstretch2.set(\lpf,);

      ~player.set(\rate, ~mod_vals[0].linlin(0, 1, -1, 1));
      // ~fftstretch2.set(\trig, 1);
      // ~fftstretch2.set(\scrWipe, avg.postln);
      // ~fftstretch2.set(\pitch, one.linlin(0, 1, 1, 4));
      // ~fftstretch1.set(\rate, (1 / val).postln);
      // ~fftstretch1.set(\rate, 0.1);
      // 1.0.rand.postln.wait;
      // (avg).postln;
      0.5.wait;
    });

  };
});
~r1.play
)

~r1.play
~r1.stop
~player.set(\rate, 1)
~player.free
~fftstretch1.set(\lpf, 8000)
~fftstretch2.set(\lpf, 8000)
~fftstretch1.set(\rate, 1)

~fftstretch1.free
~addi.set(\lfo, 0.05)
~addi.set(\amp, -20.dbamp)



/*
~step = {arg val; Pseq([val], inf);};
~mpseq = {arg list;  Pseq(list, inf)};
~mpw = {arg lo, hi; Pwhite(lo, hi, inf) };
~mpb = {arg lo, hi, s; Pbrown(lo, hi, s, inf)};
~mprand = {arg list; Prand(list,inf)  };
~mpxrand = {arg list; Pxrand(list, inf) };
*/

~player.free

(
~r = Rest(0.25);
~h = 0.5;
~q = 0.25;
// ~rand_wave.().asPseg;
~gliseq = Pdef(\gliibuf,
  Pbind(
    \instrument, \glibuf2,
    \group, ~synths,
    \addAction, 1,
    \bufnum, ~recordbuf,
    \out, ~ch2,
    \dur, Prand([
      // Pseq([0.25, 0.25, 0.25, ~r, ~r].lace(8)),
      Pseq([0.125, 0.125, 0.125, ~r, 0.25, ~r].lace(32)),
      Pseq([0.25, ~r, 1].lace(32)),
    ], inf),
    // \dur, ~mprand.([0.5, 1, 0.25, 0.125, ~r, ~r]),
    // \dur, ~mprand.([2, 1, 4, ~r, ~r]),
    \dur, ~mpw.(3.5, 2.25),
    // \dur, Pwhite(0.001, 1, inf),
    // \rate, ~pexp.(12, 0.1, 4),
    // \dur, ~mprand.([2, 1]),
    // \rate, ~mpw.(0.13, 1),
    // \rate, ~mpsq.([0.5, 1, 0.25]),
    // \atk, Pexprand(0.1, 0.5, inf),
    \atk, 0.001,
    \rel, Pwhite(0.3, 1.75, inf),
    // \rel, Pfunc(0.3, 0.75, inf),
    // \rate, 1,
    // \rel, 2,
    \sweep, Prand([2, 3, 1], inf),
    \trigrate, Prand([10, 30, 50] * 100, inf),
    \pan, Pseq([-1, 1, -0.5, 0.5, -0.25, 0.25], inf),
    \pan, Pseq([-1, 1], inf)

  )
)
)

Pdef.removeAll;

~gliseq.play
~gliseq.stop
~mod_vals.sum / 8