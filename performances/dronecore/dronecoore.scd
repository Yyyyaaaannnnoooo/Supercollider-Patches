(
// Server.default.options.outDevice_("Multi-Output Device");
Server.default.options.outDevice_("BlackHole 16ch");
// Server.default.options.inDevice_("BlackHole 16ch");
Server.default.options.inDevice_("VB-Cable");
s.options.numOutputBusChannels = 16;
s.options.numInputBusChannels = 2;
s.reboot;
~size = 1024 * 2;
~waves = 16;
~hop = 0.25;
~win = 0;
)




(
// 1. OPEN FILE SYNTHS
"/Users/ya/Documents/supercollider/sc-patches/performances/dronecore/synths.scd".openDocument;
// 2. OPEN FILE init-funcs
"/Users/ya/Documents/supercollider/sc-patches/performances/dronecore/init-funcs.scd".openDocument;
// 3. open and load help-funcs
"/Users/ya/Documents/supercollider/sc-patches/performances/dronecore/help-funcs.scd".openDocument;
// 4. open and load midi-setup
"/Users/ya/Documents/supercollider/sc-patches/performances/dronecore/midi-setup.scd".openDocument;
)

// LOAD FILES
"/Users/ya/Documents/supercollider/sc-patches/performances/dronecore/synths.scd".load;
"/Users/ya/Documents/supercollider/sc-patches/performances/dronecore/init-funcs.scd".load;
"/Users/ya/Documents/supercollider/sc-patches/performances/dronecore/help-funcs.scd".load;

MIDIClient.init;

MIDIIn.connect(inport: 0, device: MIDIClient.sources.at(3));
// do this manuallY
"/Users/ya/Documents/supercollider/sc-patches/performances/dronecore/midi-setup.scd".load;



//
// VERY MEGA IMPORTANT!
// THE SAMPLES IN THE BREAK FOLDER ARE ONLY 15
// SO at THE MOMENT  THIS PATCH WORKS WITH 15
// SAMPLES.
// TO CHANGE THIS UPDATE BREAK FOLDER TO HAVE 16
// SAMPLES THEN CHANGE THE MIDI FUNCTION BELOW
//
s.quit


// REMEMBER SCREEN SETTINGS SO THAT IT DOES NOT BECOME DARK

~init.();
~load_samples.();

// VERY MEGA SUPER IMPORTANT DO NOT SKIP
// SPECIALLY FOR UNSORTED!
~vox = ~kick

~names.(~kick)
~names.(~vox)
~names.(~break)
// WAIT to execute this
~init_fft_bufs.();

// LOAD FFT BUFFERS
(
~r2 = Routine{
  ~recbufs_b.do({
    arg item, i;
    var rec = Synth("pvrecLR",
      [
        \recBufL, ~recbufs_b[i][0],
        \recBufR, ~recbufs_b[i][1],
        \soundBufnum, ~break[i]
      ],
      target:~synths);
    var dur = ~break[i].duration + 1;
    var name = PathName( ~break[i].path).fileName;
    ("processing break samples %: "+((i / ~break.size)* 100)).postln;
    ("sample name: "+name).postln;
    ("for "+dur+" seconds").postln;
    dur.wait;
  });
  "BREAKS done".postln;
};
~r2.play;
)
~r2.stop
(
~r3 = Routine{
  ~recbufs_k.do({
    arg item, i;
    var rec = Synth(\pvrecLR,
      [
        \recBufL, ~recbufs_k[i][0],
        \recBufR, ~recbufs_k[i][1],
        \soundBufnum, ~kick[i]],
      target:~synths);
    var dur = ~kick[i].duration + 1;
    var name = PathName( ~kick[i].path).fileName;
    ("processing kick samples %: "+((i / ~kick.size)* 100)).postln;
    ("sample name: "+name).postln;
    ("for "+dur+" seconds").postln;
    dur.wait;
    // 22.wait;
  });
  "KICK done".postln;
  ~recbufs_v = ~recbufs_k;
  "VOX done".postln;
};
~r3.play;
)
~r3.stop

(
~r4 = Routine{
  ~recbufs_v.do({
    arg item, i;
    var rec = Synth("pvrecLR",
      [
        \recBufL, ~recbufs_v[i][0],
        \recBufR, ~recbufs_v[i][1],
        \soundBufnum, ~vox[i]],
      target:~synths);
    var dur = ~vox[i].duration + 1;
    var name = PathName( ~vox[i].path).fileName;
    ("processing vox samples %: "+((i/~vox.size)*100)).postln;
    ("sample name: "+name).postln;
    ("for "+dur+" seconds").postln;
    dur.wait;
  });
  "VOX done".postln;
};
~r4.play;
)

~r4.stop
(
var tot = 0;
~vox.do({
  arg item, i;
  var dur = item.duration;
  dur.postln;
  tot = tot + dur;
  tot.postln;
})
)

// ~load_fft_samples.()

s.meter
~init.()
// do not forget midi!!!

// actual synths!
(
~main = Synth(\eoc, [
  \in1, ~ch1, \in2, ~ch2,
  \in3, ~ch3, \in4, ~ch4,
  \in5, ~ch5,
],target:~eoc);
)





~free_all.();

// UNSORTED

~gnames.()


/*
0 delrey-sumertime-1.wav
1 delrey-summertime-2.wav

2 g8-bella-ciao.wav
3 g8-cowell-pestaggio-short.wav
4 g8-pestaggio.wav
5 g8-spaccatura.wav

6 giuni-estate-2.wav

7 nature-birds-frogs-grasshoppers.wav
8 nature-whales.wav

9 pad-ambience.wav
10 pad-liminal-ambient.wav

11 pal-rossa-palestina.wav
12 pal-sidun.wav

13 vox-maiale.wav
14 vox-summer-dialogue.wav
*/

~gnames.()

~init_decks.(0,9,7);
~make_decks.(4,3,8);

// max 11
~changeP1.(7)

~changeP2.(14)

~changeP3.(1)


~synths.freeAll
~eoc.freeAll
s.meter
~mPlayer1.(0)
~p1.set(\rate, 1)

// 0 00002-kick.wav
// 1 00003-kick.wav
// 2 00004-kick.wav
// 3 00005-kick.wav
// 4 00006-kick.wav
// 5 00007-kick.wav
// 6 00021-break.wav
// 7 00022-break.wav
// 8 00023-break.wav
// 9 00024-break.wav
// 10 00025-break.wav
// 11 00026-break.wav
//


~set_all_sample.(0);
~change_sample.(3)



















~time_travel1.()
~time_travel2.()
~time_travel3.()
~time_travel4.()


s.meter

~reset_all.()



(
~vox.do({
  arg item;
  var path = PathName.new(item.path);
  path.fileName.postln;
})
)
(
~kick.do({
  arg item;
  var path = PathName.new(item.path);
  path.fileName.postln;
})
)









// ~change_sample.(8)





~mPad.(0, 5, 1.5, 1.5, 100.linlin(0, 127, 0, 5));
~p4.free

// ~mP3.(0);
~p3.set(\rate, 0.5)
~p3.set(\dur, 0.6)
~p3.set(\start, 0.28)
~p3.setn(\rate, 0.99, \ttt, 1, \end, 1)

// Random pads gen
//
// Synth(\scrubPad,[
//   \out, ~ch4, \recBuf, ~recbufs_v[val],
//   \pos, ~scrub_pos3,
//   \lag, ~lag, \bin, ~bin,
//   \wipe, ~wipe, \width, ~width,
//   \sample, ~vox[val], \sel, ~fade,
//   \rate, ~audio_rate3, \pitch, ~pitch3,
//   \lfo, ~lfo_rate3, \mul, ~lfo_amp3,
//   \atk, atk, \sus, sus, \rel, rel
// ], target:~synths);
(
~bc1 = Bus.control(s, 1);//wipe
~bc2 = Bus.control(s, 1);//pos
~bc3 = Bus.control(s, 1);//rate
~bc4 = Bus.control(s, 1);//lfo speed
~bc5 = Bus.control(s, 1);//lfo depth
~bc6 = Bus.control(s, 1);//fade
~bc1.set(0);
~bc2.set(0);
~bc3.set(1);
~bc4.set(0.0001);
~bc5.set(0);
~bc6.set(0);
)
(
~currSample = 7;
~randPads = Pdef(\randPads,
  Pbind(
    \instrument, \padLR, \group, ~synths,
    \recBufL, ~recbufs_v[~currSample][0], \recBufR, ~recbufs_v[~currSample][1],
    \pos, ~scrub_pos3, \wipe, ~wipe, \width, ~width,
    \sample, ~vox[~currSample], \sel, ~fade,
    \rate, ~audio_rate3, \lfo, ~lfo_rate3, \mul, ~lfo_amp3,
    \out, ~ch3,
    \pitch, Pxrand([10, 2, 8, 15, 6].linlin(0,127, 0.1, 5), inf),
    \atk, 0.33,
    \sus, 0.2,
    \rel, 0.25,
    \dur, Pxrand([0.5, 0.25, 0.125], inf)
));
// ~randPads.play;
)
~randPads.play;

~randPads.stop;

Pdef.freeAll




















// TEST STUFF!!!!

(
~p1.free;
~p1 = Synth("scrub",
  [\out, ~ch4, \in, ~ch1,
    \recBuf, ~recbufs_v[0],\lag, ~lag,\bin, ~bin,
    \wipe, ~wipe, \width, ~width,
    \pos, ~scrub_pos,
    \lfo, ~lfo_rate,
    \mul, ~lfo_amp, \amp, ~amp1
], target:~synths);

)

~p1.set(\pos, 0)
~p1.set(\mul, 1)
~p1.set(\lfo, 0.05)
~p1.set(\amp, -12.dbamp)
~p1.set(\lag, 10)
~p1.set(\tresh, 0.02)

(
~p1.set(\tt, 1);
~p1.set(\wipe, 0.5);
)
~p1.free
~rates
~rates.do({arg item; item.set(\lfo_mul, 0, \lfo_f, 0.05)})

~p6.free

(
~free_all.();
~set_random_sample.();
)
(
var val = 2;
~p2.set([\recBuf,~recbufs_b[val],\sample, ~break[val]])
)
~rand_all.()

~reset_all.()

(
~rates.do({
  arg i;
  ~wipe = 0.125;
  ~width = 0.5;
  i.set(\wipe, ~wipe);
  i.set(\width, ~width);
  i.set(\tt, 1);
})
)

~rates.do({arg i;~lag = 5; i.set(\lag, ~lag)})
~rates.do({arg i; i.set(\blag, 5)})
~rates.do({arg i; i.set(\sel, 0)})
~scrubs.do({arg i;~lag = 0; i.set(\lag, ~lag)})

(
~audio_rate1 = 0.5;
~p2.set(\rate, ~audio_rate1);
~audio_rate2 = -0.4;
~p4.set(\rate, ~audio_rate2);
~audio_rate3 = 0.075;
~p6.set(\rate, ~audio_rate3)
)

(
~lfo_amp = 0.05;
~lfo_rate = 0.23;
~scrubs.do({arg i; i.set(\lfo, ~lfo_rate)});
~scrubs.do({arg i; i.set(\mul, ~lfo_amp)});
)


(
~scrubs.do({
  arg item, i;
  ~scrub_pos = 0.3;
  item.set(\pos, ~scrub_pos);
  // item.set(\amp, -12.dbamp);
})
)


(
~rates.do({
  arg item, i;
  ~audio_rate = 1;
  ~audio_rate1 = ~audio_rate;
  ~audio_rate2 = ~audio_rate;
  ~audio_rate3 = ~audio_rate;
  item.set(\rate, ~audio_rate);
})
)

(
~rs.stop;
~list = Array.series(10, 0.0, 0.125);
~rs = {~list.do({arg v,i; ~p2.set(\rate, v); i.postln;3.wait})}.fork

)
~rs.stop

~p4.set(\amp, -12.dbamp)
~p4.set(\rate, -12.dbamp)

(
~audio_rate = 0.25;
~scrub_pos = 0.89;
~set_all_var.();

)
s.meter
(
~lfo_amp = 0.5;
~lfo_rate = 0.23;
~p1.set(\mul, ~lfo_amp);
~p1.set(\lfo, ~lfo_rate);
)
~break[0].plot

// DEBUG!!

// p2, p4, p5
(
// l = Array.interpolation(1000, 0.0, 0.99);
~rr1.stop;
~rr1 = ~routine_rate.(~mod_pos1, ~p2, ~audio_rate1,0.125);
~rr1.play;
)

(
~routine_rate = {
  arg list, synth, curr, w;
  Routine{
    loop{
      list.do({
        arg val, i;
        var mult = 0;
        if(~record, {
          mult = 1;
          synth.set(\rate, val);
          // mult.postln;
          val.postln;
        }, {
          mult = 0;
          synth.set(\rate, curr);
          curr.postln;
        });


        // ~record.postln;
        w.wait;
      })
    }
  };
}
)



(
{
  e = Env.sine.asStream;
  50.do({
    e.next.postln;
    0.125.wait;
})}.fork
)

e.stop


(
~rand_wave = {
  arg min=0, max=1, time=5;
  var num_seg = rrand(6, 35);
  Env(
    [min]++
    (({rrand(min, max)}!(num_seg-1))).scramble
    ++[min],
    {exprand(1, time)}!num_seg,
    \sine
    // {rrand(-20, 20)}!num_seg
  );
}
)
(
~rr.stop;
x = ~rand_wave.();
x = x.asPseg;
x = x.asStream;

~rr = {
  inf.do({
    x.next.postln;
    0.0125.wait;
  })
}.fork;
// ~rr.play
)
