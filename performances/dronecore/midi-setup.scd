
// MIDI SETUP!!!

MIDIClient.init;
MIDIIn.connectAll;
// MIDIIn.connect(inport: 0, device: MIDIClient.sources.at(2));
// m = MIDIOut.connect(inport:0, device: MIDIClient.sources.at(0));
// m = MIDIOut.newByName("IAC Driver", "Bus 1");
// MIDIClient.sources
// MIDIIn.controlList
MIDIFunc.trace(true);

MIDIFunc.trace(false);

MIDIdef.freeAll;


// USE PRESET 1 on FADERFOX!!!!!!

(
~arr_size = 30;
~mod_pos1 = 0!~arr_size;
~mod_pos2 = 0!~arr_size;
~mod_pos3 = 0!~arr_size;
~mod_pos4 = 0!~arr_size;
~record = false;
~index1 = 0;
~index2 = 0;
~index3 = 0;
~index4 = 0;
~indexes = [~index1, ~index2, ~index3, ~index4];


~bend_val = 16383;
~max_speed = 0.25;
// ENCODERS
// lfo speed
~enc1 = MIDIdef.bend(key: \enc1,
  func: {
    arg val, num, chan;
    var lfo = val.linlin(0, ~bend_val, 0.0001,~max_speed);
    var depth = val.linlin(0, ~bend_val, 0, 0.25);
    ~lfo_rate1 = lfo;
    ~p1.set(\lfo, lfo);
    ~lfo_amp1 = depth;
    ~p1.set(\mul, depth);
}, chan: 0);
~enc2 = MIDIdef.bend(key: \enc2,
  func: {
    arg val, num, chan;
    var lfo = val.linlin(0, ~bend_val, 0.0001,~max_speed);
    var depth = val.linlin(0, ~bend_val, 0, 0.25);
    // lfo.postln;
    ~lfo_rate2 = lfo;
    ~p2.set(\lfo, lfo);
    ~lfo_amp2 = depth;
    ~p2.set(\mul, depth);
}, chan: 1);
~enc3 = MIDIdef.bend(key: \enc3,
  func: {
    arg val, num, chan;
    var lfo = val.linlin(0, ~bend_val, 0.0001,~max_speed);
    var depth = val.linlin(0, ~bend_val, 0, 0.25);
    // lfo.postln;
    ~lfo_rate3 = lfo;
    ~p3.set(\lfo, lfo);
    ~lfo_amp3 = depth;
    ~p3.set(\mul, depth);
    ~bc4.set(depth);
}, chan: 2);

// change sample
~old_sample_drums = nil;
// ~enc4 = MIDIdef.bend(key: \enc4,
//   func: {
//     arg val, num, chan;
//     var sample = val.linlin(0, ~bend_val, 0, 10).floor;
//     // sample.postln;
//     if(~old_sample_drums != sample, {
//       ~old_sample_drums = sample;
//       ("old sample "+~old_sample_drums).postln;
//       // ~free_all.();
//       // ~set_all_sample.(sample.floor);
//       ~change_drums.(sample.floor)
//     });
//     sample.postln;
// }, chan: 3);

// lfo mult aka depth
~enc5 = MIDIdef.bend(key: \enc5,
  func: {
    arg val, num, chan;
    var pos = val.linlin(0, ~bend_val, 0, 1);
    ~scrub_pos1 = pos;
    ~p1.set(\pos, pos);
    // var depth = val.linlin(0, ~bend_val, 0, 1);
    // ~this_pos = [~scrub_pos1, ~scrub_pos2, ~scrub_pos3];
    // ~rates.do({arg item, i; item.set(\pos,~this_pos[i])})
    /*    ~this_depth = [~lfo_amp1, ~lfo_amp2, ~lfo_amp3];
    ~rates.do({arg item, i; item.set(\mul,~this_depth[i])})*/
}, chan: 4);
~enc6 = MIDIdef.bend(key: \enc6,
  func: {
    arg val, num, chan;
    var pos = val.linlin(0, ~bend_val, 0, 1);
    ~scrub_pos2 = pos;
    ~p2.set(\pos, pos);
/*    var depth = val.linlin(0, ~bend_val, 0, 1);
    ~lfo_amp2 = depth;
    ~p2.set(\mul, depth);*/
    /*    ~this_depth = [~lfo_amp1, ~lfo_amp2, ~lfo_amp3];
    ~rates.do({arg item, i; item.set(\mul,~this_depth[i])})*/
}, chan: 5);
~enc7 = MIDIdef.bend(key: \enc7,
  func: {
    arg val, num, chan;
    var pos = val.linlin(0, ~bend_val, 0, 1);
    ~scrub_pos3 = pos;
    ~p3.set(\pos, pos);
    ~bc2.set(pos);
    // var depth = val.linlin(0, ~bend_val, 0, 1);
    // ~lfo_amp3 = depth;
    // ~p3.set(\mul, depth);
    /*
    ~this_depth = [~lfo_amp1, ~lfo_amp2, ~lfo_amp3];
    ~rates.do({arg item, i; item.set(\mul,~this_depth[i])})*/
}, chan: 6);
// some global fx
~old_sample_vox = nil;
/*~enc8 = MIDIdef.bend(key: \enc8,
  func: {
    arg val, num, chan;
    var sample = val.linlin(0, ~bend_val, 0, 10).floor;
    // sample.postln;
    if(~old_sample_vox != sample, {
      ~old_sample_vox = sample;
      ("old sample "+~old_sample_vox).postln;
      // ~free_all.();
      // ~set_all_sample.(sample.floor);
      ~change_vox.(sample.floor)
    });
    sample.postln;
}, chan: 7);*/

// Sliders
// rate
~sl1 = MIDIdef.cc(\sl1,{
  arg val, num, chan;
  ~audio_rate = val.linlin(0, 127, -1,1.35);
  ~audio_rate1 = ~audio_rate;
  ~this_rates = [~audio_rate1, ~audio_rate2, ~audio_rate3];
  ~rates.do({arg item, i; item.set(\rate,~this_rates[i])})
},70, 8);
~sl2 = MIDIdef.cc(\sl2,{
  arg val, num, chan;~audio_rate = val.linlin(0, 127, -1,1.35);
  ~audio_rate2 = ~audio_rate;
  ~this_rates = [~audio_rate1, ~audio_rate2, ~audio_rate3];
  ~rates.do({arg item, i; item.set(\rate,~this_rates[i])})
},71, 8);
~sl3 = MIDIdef.cc(\sl3,{
  arg val, num, chan;
  ~audio_rate = val.linlin(0, 127, -1,1.35);
  ~audio_rate3 = ~audio_rate;
  ~this_rates = [~audio_rate1, ~audio_rate2, ~audio_rate3];
  ~rates.do({arg item, i; item.set(\rate,~this_rates[i])});
  ~bc3.set(~audio_rate3);
},72, 8);

// pos
~sl4 = MIDIdef.cc(\sl4,{
  arg val, num, chan;
  var pos = val.linlin(0, 127, 0, 1);
/*  ~scrub_pos1 = pos;
  ~this_pos = [~scrub_pos1, ~scrub_pos2, ~scrub_pos3];
  ~rates.do({arg item, i; item.set(\pos,~this_pos[i])})*/
},73, 8);
~sl5 = MIDIdef.cc(\sl5,{
  arg val, num, chan;
  // var pos = val.linlin(0, 127, 0, 1);
  ~wipe1 = val.linlin(0, 127, 0, 1);
  ~p1.set(\tt, 1);
  ~p1.set(\wipe, ~wipe1);
/*  ~scrub_pos2 = pos;
  ~this_pos = [~scrub_pos1, ~scrub_pos2, ~scrub_pos3];
  ~rates.do({arg item, i; item.set(\pos,~this_pos[i])})*/
},74, 8);
~sl6 = MIDIdef.cc(\sl6,{
  arg val, num, chan;
  // var angle = val.linlin(0, 127, 0, 2*pi);
  ~wipe2 = val.linlin(0, 127, 0, 1);
  ~p2.set(\tt, 1);
  ~p2.set(\wipe, ~wipe2);
  // angle.postln;
  /*
  var x = angle.cos.linlin(-1, 1, 0,127);
  var y = angle.sin.linlin(-1, 1, 0,127);
  // x.postln;
  m.control(15, 90, x);
  m.control(15, 91, y);*/
/*  ~scrub_pos3 = pos;
  ~this_pos = [~scrub_pos1, ~scrub_pos2, ~scrub_pos3];
  ~rates.do({arg item, i; item.set(\pos,~this_pos[i])});
  ~bc2.set(~scrub_pos3);*/
},75, 8);

// bin Scramble
~sl7 = MIDIdef.cc(\sl7,{
  arg val, num, chan;
  ~wipe3 = val.linlin(0, 127, 0, 1);
  ~p3.set(\tt, 1);
  ~p3.set(\wipe, ~wipe3);
  // ~bc5.set(~wipe);
},76, 8);
~sl8 = MIDIdef.cc(\sl8,{
  arg val, num, chan;

  ~wipe = val.linlin(0, 127, 0, 1);
  ~wipe1 = ~wipe;
  ~wipe2 = ~wipe;
  ~wipe3 = ~wipe;
  // ~wipe.postln;
  ~rates.do({
    arg i;
    i.set(\wipe, ~wipe);
    i.set(\tt, 1);
  });
  ~p1.set(\tt, 1);
  ~p1.set(\wipe, ~wipe1);
  ~p2.set(\tt, 1);
  ~p2.set(\wipe, ~wipe2);
  ~p3.set(\tt, 1);
  ~p3.set(\wipe, ~wipe3);
  ~bc5.set(~wipe);
},77, 8);

// blend fft playbuf
~sl9 = MIDIdef.cc(\sl9,{
  arg val, num, chan;
  ~fade = val.linlin(0, 127, 0,1);
  ~bc6.set(~fade);
  // ~fade.postln;
  ~rates.do({
    arg synth, i;
    synth.set(\sel, ~fade);
  })
},78, 8);

~b1 = MIDIdef.cc(\b1,{
  arg val, num, chan;
  ~reset_all.();
},74,0);



~reset_scramble = MIDIdef.cc(\reset_scramble,{
  arg val, num, chan;
  // var sample = val.linlin(0, 31, 0, 1);
  "reset random values".postln;
  // ~free_all.();
  // ~set_random_sample.();
  // ~rand_all.();
  ~rates.do({
    arg i;
    ~wipe = 0;
    ~wipe.postln;
    i.set(\wipe, ~wipe);
    // i.set(\width, ~width);
    i.set(\tt, 1);
  });
},96, 12);

~bin_reset = MIDIdef.cc(\bin_reset,{
  arg val, num, chan;
  // var sample = val.linlin(0, 31, 0, 1);
  ~bin = 1;
  ~rates.do({arg item; item.set(\bin, ~bin)});
},97, 12);

~btn2 = MIDIdef.cc(\btn2, {
  ~zero_all.();
  ~rates.do({
    arg item;
    ~audio_rate = 0;
    ~audio_rate1 = ~audio_rate;
    ~audio_rate2 = ~audio_rate;
    ~audio_rate3 = ~audio_rate;
    ~rates.do({arg item; ~lag = 10; item.set(\lag, ~lag)});
    ~this_rates = [~audio_rate1, ~audio_rate2, ~audio_rate3];
    ~rates.do({arg item, i; item.set(\rate,~this_rates[i])});
    ~rates.do({arg item; ~lag = 2; item.set(\lag, ~lag)});
  });
},92, 12);



//
//
//
// ~enc1 = MIDIdef.bend(key: \enc1,
//   func: {
//     arg val, num, chan;
//     ~audio_rate = val.linlin(0, ~bend_val, -1,1.35);
//     // ~scrub_pos = val.linlin(0, ~bend_val, 0,1);
//     ~audio_rate1 = ~audio_rate;
//     ~audio_rate2 = ~audio_rate;
//     ~audio_rate3 = ~audio_rate;
//     // [val, num, chan].postln;
//     // ~set_all_var.();
//     ~this_rates = [~audio_rate1, ~audio_rate2, ~audio_rate3];
//     ~rates.do({arg item, i; item.set(\rate,~this_rates[i])})
//
//     // ~record_mod.(~mod_pos1, 0, ~audio_rate);
//
//   },
// chan: 7);
//
// // slider 2
// ~f12 = MIDIdef.bend(key: \f12,
//   func: {
//     arg val, num, chan;
//     ~audio_rate = val.linlin(0, ~bend_val, -1,1.35);
//     // ~scrub_pos = val.linlin(0, ~bend_val, 0,1);
//     ~audio_rate1 = ~audio_rate;
//     // [val, num, chan].postln;
//     // ~set_all_var.();
//     ~this_rates = [~audio_rate1, ~audio_rate2, ~audio_rate3];
//     ~rates.do({arg item, i; item.set(\rate,~this_rates[i])})
//     // [val, num, chan].postln;
//     // ~set_all_var.();
//     // ~record_mod.(~mod_pos1, 0, ~audio_rate1);
//   },
// chan: 8);
// // slider 3
// ~f13 = MIDIdef.bend(key: \f13,
//   func: {
//     arg val, num, chan;
//     ~audio_rate = val.linlin(0, ~bend_val, -1,1.35);
//     ~audio_rate2 = ~audio_rate;
//     // ~rates[1].set(\rate, ~audio_rate2);
//     ~this_rates = [~audio_rate1, ~audio_rate2, ~audio_rate3];
//     ~rates.do({arg item, i; item.set(\rate,~this_rates[i])})
//     // ~set_all_var.();
//   },
// chan: 9);
// // slider 4
// ~f14 = MIDIdef.bend(key: \f14,
//   func: {
//     arg val, num, chan;
//     ~audio_rate = val.linlin(0, ~bend_val, -1,1.35);
//     ~audio_rate3 = ~audio_rate;
//
//     // ~rates[2].set(\rate, ~audio_rate2);
//     ~this_rates = [~audio_rate1, ~audio_rate2, ~audio_rate3];
//     ~rates.do({arg item, i; item.set(\rate,~this_rates[i])})
//     // ~set_all_var.();
//   },
// chan: 10);
//
//
// // encoder 7
// ~f15 = MIDIdef.bend(key: \f15,
//   func: {
//     arg val, num, chan;
//     // ~audio_rate = val.linlin(0, ~bend_val, -1,1);
//     ~scrub_pos = val.linlin(0, ~bend_val, 0,1);
//     ~scrub_pos.postln;
//     // ~audio_rate3 = ~audio_rate;
//     // [val, num, chan].postln;
//     // ~set_all_var.();
//     // ~scrubs.do({arg item; item.set(\pos, ~scrub_pos)})
//     ~p1.set(\pos, ~scrub_pos);
//
//   },
// chan: 11);
//
// ~x_fade = MIDIdef.cc(\x_fade,{
//   arg val, num, chan;
//   /*var sample = val.linlin(0, 31, 0, 1);
//   // sample.postln;
//   sample.trunc.postln;
//   // ~p1.free;
//   // ~p2.free;
//   ~free_all.();
//   ~set_all_sample.(sample.floor);*/
//
//
//
// },19, 0);

// ~rand_sample = MIDIdef.cc(\random,{
//   arg val, num, chan;
//   // var sample = val.linlin(0, 31, 0, 1);
//   "random sample".postln;
//   ~free_all.();
//   ~set_random_sample.();
// },95, 12);





//
// //
// //
// ~sample_sel = MIDIdef.cc(\sample_sel,{
//   arg val, num, chan;
//
//
// },4, 0);



//
// ~f2 = MIDIdef.cc(\f2,{
//   arg val, num, chan;
//   ~lfo_rate = val.linlin(0, 127, 0.0001,0.25);
//   "rate".postln;
//   ~lfo_rate.postln;
//   ~p1.set(\lfo, ~lfo_rate);
//   // ~p3.set(\lfo, ~lfo_rate);
//   // ~p5.set(\lfo, ~lfo_rate);
//   // ~p7.set(\lfo, ~lfo_rate);
// },14, 0);
//
// ~f3 = MIDIdef.cc(\f3,{
//   arg val, num, chan;
//   ~lfo_amp = val.linlin(0, 127, 0.0001,1);
//   "amp".postln;
//   ~lfo_amp.postln;
//   ~p1.set(\mul, ~lfo_amp);
//   // ~p3.set(\mul, ~lfo_amp);
//   // ~p5.set(\mul, ~lfo_amp);
//   // ~p7.set(\mul, ~lfo_amp);
// },6,0);

// no need for this
//
// ~f4= MIDIdef.cc(\f4,{
//   arg val, num, chan;
//   var sel = val.linlin(0, 127, 1, 3).floor;
//   // sel.postln;
//   switch(sel,
//     1,{
//       ~amp1 = -12.dbamp;
//       ~amp2 = 0;
//       ~amp3 = 0;
//       ~p1.set(\amp, ~amp1);
//       ~p3.set(\amp, ~amp2);
//       ~p5.set(\amp, ~amp3);
//     },
//     2.0,{
//       ~amp1 = 0;
//       ~amp2 = -12.dbamp;
//       ~amp3 = 0;
//       ~p1.set(\amp, ~amp1);
//       ~p3.set(\amp, ~amp2);
//       ~p5.set(\amp, ~amp3);
//     },
//     3,{
//       ~amp1 = 0;
//       ~amp2 = 0;
//       ~amp3 = -12.dbamp;
//       ~p1.set(\amp, ~amp1);
//       ~p3.set(\amp, ~amp2);
//       ~p5.set(\amp, ~amp3);
//     },
//   );
// },8,0);


//
// // do not need this anymore
// ~enc2 = MIDIdef.cc(\enc2,{
//   arg val, num, chan;
//   ~bin = val.linexp(0, 127, 0.25, 4);
//   ~bin.postln;
//   ~rates.do({arg item; item.set(\bin, ~bin)});
// },1,8);
//
// ~enc3 = MIDIdef.cc(\enc3,{
//   arg val, num, chan;
// },2,9);
"MIDI Functions loaded".postln;

)