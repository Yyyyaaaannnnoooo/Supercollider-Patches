
// HELPER FUNCTIONS
(
~fade = 0;
~scrub_pos1 = 0;
~scrub_pos2 = 0;
~scrub_pos3 = 0;
~audio_rate = 1;
~audio_rate1 = 1;
~audio_rate2 = 1;
~audio_rate3 = 1;
~pitch1 = 1;
~pitch2 = 1;
~pitch3 = 1;
~lfo_rate1 = 0;
~lfo_rate2 = 0;
~lfo_rate3 = 0;
~lfo_amp1 = 0;
~lfo_amp2 = 0;
~lfo_amp3 = 0;
~lag = 5;
~bin = 1;
~wipe = 0;
~wipe1 = 0;
~wipe2 = 0;
~wipe3 = 0;
~width = 0.25;


~rates = [];
~scrubs = [];

~free_all = {
  ~synths.freeAll
};

~names = {
  arg list;
  list.do({
    arg buffer, i;
    var file_name = PathName( buffer.path).fileName;
    (i+file_name).postln;

  })
};


~mP1 = {
  arg val;
  ~p1 = Synth(\fftscrub,[
    \out, ~ch1, \recBuf, ~recbufs_b[val],
    \pos, ~scrub_pos1,
    \lag, ~lag, \bin, ~bin,
    \wipe, ~wipe1, \width, ~width,
    \sample, ~break[val], \sel, ~fade,
    \rate, ~audio_rate1, \pitch, ~pitch1,
    \lfo, ~lfo_rate1, \mul, ~lfo_amp1
  ], target:~synths);
};

~mP2 = {
  arg val;
  ~p2 = Synth(\fftscrub,[
    \out, ~ch2, \recBuf, ~recbufs_k[val],
    \pos, ~scrub_pos2,
    \lag, ~lag, \bin, ~bin,
    \wipe, ~wipe2, \width, ~width,
    \sample, ~kick[val], \sel, ~fade,
    \rate, ~audio_rate2, \pitch, ~pitch2,
    \lfo, ~lfo_rate2, \mul, ~lfo_amp2
  ], target:~synths);
};

~mP3 = {
  arg val;
  ~p3 = Synth(\fftscrub,[
    \out, ~ch3, \recBuf, ~recbufs_v[val],
    \pos, ~scrub_pos3,
    \lag, ~lag, \bin, ~bin,
    \wipe, ~wipe3, \width, ~width,
    \sample, ~vox[val], \sel, ~fade,
    \rate, ~audio_rate3, \pitch, ~pitch3,
    \lfo, ~lfo_rate3, \mul, ~lfo_amp3
  ], target:~synths);
};

~mPlayer1 = {
  arg val, close=0;
  ~p1 = Synth(\fftscrubLR,[ \close, close,
    \out, ~ch1, \recBufL, ~recbufs_b[val][0],\recBufR, ~recbufs_b[val][1],
    \pos, ~scrub_pos1,
    \lag, ~lag, \bin, ~bin,
    \wipe, ~wipe1, \width, ~width,
    \sample, ~break[val], \sel, ~fade,
    \rate, ~audio_rate1, \pitch, ~pitch1,
    \lfo, ~lfo_rate1, \mul, ~lfo_amp1
  ], target:~synths);
};

~mPlayer2 = {
  arg val, close=0;
  ~p2 = Synth(\fftscrubLR,[ \close, close,
    \out, ~ch2, \recBufL, ~recbufs_k[val][0],\recBufR, ~recbufs_k[val][1],
    \pos, ~scrub_pos2,
    \lag, ~lag, \bin, ~bin,
    \wipe, ~wipe2, \width, ~width,
    \sample, ~kick[val], \sel, ~fade,
    \rate, ~audio_rate2, \pitch, ~pitch2,
    \lfo, ~lfo_rate2, \mul, ~lfo_amp2
  ], target:~synths);
};

~mPlayer3 = {
  arg val, close=0;
  ~p3 = Synth(\fftscrubLR,[ \close, close,
    \out, ~ch3, \recBufL, ~recbufs_v[val][0], \recBufR, ~recbufs_v[val][1],
    \pos, ~scrub_pos3,
    \lag, ~lag, \bin, ~bin,
    \wipe, ~wipe3, \width, ~width,
    \sample, ~vox[val], \sel, ~fade,
    \rate, ~audio_rate3, \pitch, ~pitch3,
    \lfo, ~lfo_rate3, \mul, ~lfo_amp3
  ], target:~synths);
};



~mPad = {
  arg val, atk, sus, rel, pitch;
  ~pitch3 = pitch;
  ~p4 = Synth(\scrubPad,[
    \out, ~ch4, \recBuf, ~recbufs_v[val],
    \pos, ~scrub_pos3,
    \lag, ~lag, \bin, ~bin,
    \wipe, ~wipe, \width, ~width,
    \sample, ~vox[val], \sel, ~fade,
    \rate, ~audio_rate3, \pitch, ~pitch3,
    \lfo, ~lfo_rate3, \mul, ~lfo_amp3,
    \atk, atk, \sus, sus, \rel, rel
  ], target:~synths);
};

// ~vox[0]
~currSample = 0;


~set_all_sample = {
  arg val;
  ~amp1 = -12.dbamp;
  ~amp2 = 0;
  ~amp3 = 0;
  ~r_amp1 = 0;
  ~r_amp2 = -2.dbamp;
  ~r_amp3 = -12.dbamp;
  ("select sample " + val).postln;
  // ("fade: " + ~fade).postln;
  // if(val < 6, {~r_amp1 = ~r_amp3}, {~r_amp1 = ~r_amp2});
  ~currSample = val;
  ~mPlayer1.(val);
  ~mPlayer2.(val);
  ~mPlayer3.(val);
  ~rates = [~p1, ~p2, ~p3];
};

~change_drums = {
  arg val;
  ~amp1 = -12.dbamp;
  ~amp2 = 0;
  ~amp3 = 0;
  ~r_amp1 = 0;
  ~r_amp2 = -2.dbamp;
  ~r_amp3 = -12.dbamp;
  if(val < 6, {~r_amp1 = ~r_amp3}, {~r_amp1 = ~r_amp2});
  // ~currSample = val;
  ~p1.onFree({
    "p1 is free".postln;
    ~mPlayer1.(val);
    ~rates = [~p1, ~p2, ~p3];
  });

  ~p2.onFree({
    "p2 is free".postln;
    ~mPlayer2.(val);
    ~rates = [~p1, ~p2, ~p3];
  });

  // ~free_all.();
  ~p1.free;
  ~p2.free;
};

~change_vox = {
  arg val;
  ~amp1 = -12.dbamp;
  ~amp2 = 0;
  ~amp3 = 0;
  ~r_amp1 = 0;
  ~r_amp2 = -2.dbamp;
  ~r_amp3 = -12.dbamp;
  if(val < 6, {~r_amp1 = ~r_amp3}, {~r_amp1 = ~r_amp2});
  ~currSample = val;

  ~p3.onFree({
    "p3 is free".postln;
    ~mPlayer3.(val);
    ~rates = [~p1, ~p2, ~p3];
  });

  ~p3.free;
};

~changeP1 = {
  arg val, close=0;
  ~currSample = val;
  ~p1.onFree({
    "p1 is free".postln;
    ~mPlayer1.(val,close);
    ~rates = [~p1, ~p2, ~p3];
  });
  ~p1.free;
};

~changeP2 = {
  arg val, close=0;
  ~currSample = val;
  ~p2.onFree({
    "p2 is free".postln;
    ~mPlayer2.(val,close);
    ~rates = [~p1, ~p2, ~p3];
  });
  ~p2.free;
};

~changeP3 = {
  arg val, close=0;
  ~currSample = val;
  ~p3.onFree({
    "p3 is free".postln;
    ~mPlayer3.(val,close);
    ~rates = [~p1, ~p2, ~p3];
  });
  ~p3.free;
};

~change_sample = {
  arg val,close=0;
  ~changeP1.(val,close);
  ~changeP2.(val,close);
  ~changeP3.(val,close);
};

~init_decks = {
  arg v1=0,v2=0,v3=0;
  ~get_samples_names.(v1,v2,v3);
  ~synths.freeAll;
  // ~amp1 = -12.dbamp;
  ~amp2 = 0;
  ~amp3 = 0;
  ~r_amp1 = 0;
  ~r_amp2 = -2.dbamp;
  ~r_amp3 = -12.dbamp;
  // ("fade: " + ~fade).postln;
  // if(val < 6, {~r_amp1 = ~r_amp3}, {~r_amp1 = ~r_amp2});
  // ~currSample = val;
  ~mPlayer1.(v1);
  ~mPlayer2.(v2);
  ~mPlayer3.(v3);
  ~rates = [~p1, ~p2, ~p3];
};

~make_decks = {
  arg v1=0, v2=0, v3=0, c1=0, c2=0, c3=0;
  ~get_samples_names.(v1,v2,v3);
  ~changeP1.(v1,c1);
  ~changeP2.(v2,c2);
  ~changeP3.(v3,c3);
};

~get_samples_names = {
  arg v1=0,v2=0,v3=0;
  var b1 = ~break[v1];
  var b2 = ~kick[v2];
  var b3 = ~vox[v3];
  var f1 = PathName( b1.path).fileName;
  var f2 = PathName( b2.path).fileName;
  var f3 = PathName( b3.path).fileName;
  ("select sample " + f1).postln;
  ("select sample " + f2).postln;
  ("select sample " + f3).postln;
};

~gnames = {
  "~~~~~~~~~~~~~".postln;
  ~names.(~break);
  "~~~~~~~~~~~~~".postln;
  ~names.(~kick);
  "~~~~~~~~~~~~~".postln;
  ~names.(~vox);
  "~~~~~~~~~~~~~".postln;
};


//
// ~set_random_sample = {
//   var val = 0;
//   ~r_amp1 = 0;
//   ~r_amp2 = -2.dbamp;
//   ~r_amp3 = -12.dbamp;
//   ("random sample").postln;
//   // ("fade: " + ~fade).postln;
//   if(val < 6, {~r_amp1 = ~r_amp3}, {~r_amp1 = ~r_amp2});
//   ~amp1.postln;
//   val = 16.rand.floor;
//   ~p2 = Synth("frate",[
//     \out, ~ch1, \recBuf, ~recbufs_b[val],\lag, ~lag,\bin, ~bin,
//     \sample, ~break[val], \sel, ~fade, \amp, ~r_amp1,
//   \rate, ~audio_rate1], target:~synths);
//   val = 16.rand.floor;
//   ~p4 = Synth("frate",[
//     \out, ~ch2, \recBuf, ~recbufs_k[val],\lag, ~lag,\bin, ~bin,
//     \sample, ~kick[val], \sel, ~fade, \amp, ~r_amp1,
//   \rate, ~audio_rate2], target:~synths);
//   val = 16.rand.floor;
//   ~p6 = Synth("frate",[
//     \out, ~ch3, \recBuf, ~recbufs_v[val],\lag, ~lag,\bin, ~bin,
//     \sample, ~vox[val], \sel, ~fade, \amp, ~r_amp1,
//   \rate, ~audio_rate3], target:~synths);
//   val = 16.rand.floor;
//   ~p1 = Synth("scrub",
//     [\out, ~ch4,
//       \recBuf, ~recbufs_b[val],\lag, ~lag,\bin, ~bin,
//       \pos, ~scrub_pos,
//       \lfo, ~lfo_rate,
//       \mul, ~lfo_amp, \amp, ~amp1
//   ], target:~synths);
//   val = 16.rand.floor;
//   ~p3 = Synth("scrub",
//     [\out, ~ch4,
//       \recBuf, ~recbufs_k[val],\lag, ~lag,\bin, ~bin,
//       \pos, ~scrub_pos,
//       \lfo, ~lfo_rate,
//       \mul, ~lfo_amp, \amp, ~amp2
//   ], target:~synths);
//   val = 16.rand.floor;
//   ~p5 = Synth("scrub",
//     [\out, ~ch4,
//       \recBuf, ~recbufs_v[val],\lag, ~lag,\bin, ~bin,
//       \pos, ~scrub_pos,
//       \lfo, ~lfo_rate,
//       \mul, ~lfo_amp, \amp, ~amp3
//   ], target:~synths);
//
//   ~rates = [~p2, ~p4, ~p6];
//   ~scrubs = [~p1, ~p3, ~p5];
// };
//

//
// ~set_all_var = {
//   ~p1.set(\pos, ~scrub_pos);
//   ~p2.set(\rate, ~audio_rate1);
//   ~p3.set(\pos, ~scrub_pos);
//   ~p4.set(\rate, ~audio_rate2);
//   ~p5.set(\pos, ~scrub_pos);
//   ~p6.set(\rate, ~audio_rate3);
//   /*  ~p8.set(\rate, ~audio_rate);
//   ~p7.set(\pos, ~scrub_pos);*/
// };


//
// ~rand_all = {
//   var rates = {1.5.rand2}!3;
//   var bins = {0.5 + 3.5.rand}!3;
//   rates.postln;
//   ~audio_rate1 = rates[0];
//   ~audio_rate2 = rates[1];
//   ~audio_rate3 = rates[2];
//   ~rates.do({arg item, i;item.set(\rate, rates[i])});
//   ~rates.do({arg item, i;item.set(\bin, rates[i])});
//   {bins.do({
//     arg item, i;
//     ("bin_"+(i+1)+" is set to: "+item).postln;
//     0.125.wait;
//   })}.fork;
//   {rates.do({
//     arg item, i;
//     ("rate_"+(i+1)+" is set to: "+item).postln;
//     0.125.wait;
//   })}.fork;
// };



~reset_all = {
  var rates = 1!3;
  var bins = 1!3;
  ~audio_rate1 = rates[0];
  ~audio_rate2 = rates[1];
  ~audio_rate3 = rates[2];
  ~bc3.set(1);
  ~rates.do({arg item, i;item.set(\rate, rates[i])});
  ~rates.do({arg item, i;item.set(\bin, rates[i])});
  {rates.do({
    arg item, i;
    ("rate_"+(i+1)+" is set to: "+item).postln;
    0.125.wait;
  })}.fork;

};


~zero_all = {
  var rates = 0.0001!3;
  ~audio_rate1 = rates[0];
  ~audio_rate2 = rates[1];
  ~audio_rate3 = rates[2];
  ~bc3.set(0);
  ~rates.do({arg item, i;item.set(\rate, rates[i])});
  {rates.do({
    arg item, i;
    ("rate_"+(i+1)+" is set to: "+item).postln;
    0.125.wait;
  })}.fork;

};



~random_sample = {
  var len = ~break.size;
  var index = len.rand;
  var path = PathName.new(~break[index].path);
  path.fileName.postln;
  ~changeP1.(index);
  len = ~kick.size;
  index = len.rand;
  path = PathName.new(~kick[index].path);
  path.fileName.postln;
  ~changeP2.(index);
  len = ~vox.size;
  index = len.rand;
  path = PathName.new(~vox[index].path);
  path.fileName.postln;
  ~changeP3.(index);
};

~semi_random_sample = {
  arg list1, list2;
  var len = ~break.size;
  var index = len.rand;
  var path = PathName.new(~break[index].path);
  path.fileName.postln;
  ~changeP1.(index);
  index = ~get_random_list_val.(list1);
  index.postln;
  path = PathName.new(~kick[index].path);
  path.fileName.postln;
  ~changeP2.(index);
  len = ~vox.size;
  index = ~get_random_list_val.(list2);
  path = PathName.new(~vox[index].path);
  path.fileName.postln;
  ~changeP3.(index);
};







~set_pos_all = {
  ~scrub_pos1 = 1.0.rand;
  ~scrub_pos2 = 1.0.rand;
  ~scrub_pos3 = 1.0.rand;
  ~p1.set(\pos, ~scrub_pos1);
  ~p2.set(\pos, ~scrub_pos2);
  ~p3.set(\pos, ~scrub_pos3);
};

~set_rate_all = {
  ~audio_rate1 = 0;
  ~audio_rate2 = 1.0.rand2;
  ~audio_rate3 = 1.0.rand2;
  ~p1.set(\rate, ~audio_rate1);
  ~p2.set(\rate, ~audio_rate2);
  ~p3.set(\rate, ~audio_rate3);
};

~get_random_list_val = {
  arg list;
  list[list.size.rand]
};

// [0,1].size.rand

/*
00000-choir.wav 0
00001-choir.wav 1
00002-choir.wav 2
00003-choir.wav 3
dies-irae.wav 4
estate-al-mare.wav 5
evangelion.wav 6
maiale-01.wav 7
requiem.wav 8
summertime.wav 9
summertime.wav 10

dtol-01.wav 0
dtol-02.wav 1
dtol-03.wav 2
dtol-04.wav 3
fini.wav 4
g8-bella-ciao.wav 5
g8-pestaggio.wav 6
letten-1995.wav 7
platzspitz-1992.wav 8
srf-doku-00.wav 9
srf-doku-01.wav 10
*/

// ~semi_random_sample.([8, 4, 4.rand], [7, 8, 9])
// ~semi_random_sample.([5, 5, 4.rand], [5, 6, 4.rand] );
// ~semi_random_sample.([7, 4.rand], [4, 10, 4.rand]);
// ~semi_random_sample.([10, 4.rand, 11], [4.rand, 4.rand, 4.rand]);

~travelling1 = false;
~time_travel1 = {
  if(
    ~travelling1 == false,
    {
      ~travelling1 = true;
      {[0].do({
        arg item, i;
        ~zero_all.();
        ~set_pos_all.();
        (~lag+2).wait;
        // ~random_sample.();
        // ~semi_random_sample.([9, 4, 4.rand], [7, 8, 9]);
        ~semi_random_sample.([8, 4, 4.rand], [7, 8]);
        2.wait;
        ~set_rate_all.();
        ~travelling1 = false;
      })}.fork
    },
    {"doing a time travel!"}
  );
};

~travelling2 = false;
~time_travel2 = {
  if(
    ~travelling2 == false,
    {
      ~travelling2 = true;
      {[0].do({
        arg item, i;
        ~zero_all.();
        ~set_pos_all.();
        (~lag+2).wait;
        // ~random_sample.();
        // ~semi_random_sample.([7, 8, 5, 5, 4.rand], [4, 5, 6, 4.rand] );
        ~semi_random_sample.([5,5, 5], [5, 6, 6]);
        2.wait;
        ~set_rate_all.();
        ~travelling2 = false;
      })}.fork
    },
    {"doing a time travel!"}
  );
};

~travelling3 = false;
~time_travel3 = {
  if(
    ~travelling3 == false,
    {
      ~travelling3 = true;
      {[0].do({
        arg item, i;
        ~zero_all.();
        ~set_pos_all.();
        (~lag+2).wait;
        // ~semi_random_sample.( [6, 4.rand], [10, 4.rand] );
        // ~semi_random_sample.([7, 6, 4.rand], [4, 10, 4.rand]);
        // ~semi_random_sample.([10, 4.rand, 11], [4.rand, 4.rand, 4.rand]);
        // ~semi_random_sample.([7, 6, 4.rand], [4, 10, 4.rand]);
        ~semi_random_sample.([8], [4, 4.rand]);
        // ~random_sample.();
        2.wait;
        ~set_rate_all.();
        ~travelling3 = false;
      })}.fork
    },
    {"doing a time travel!"}
  );
};

~travelling4 = false;
~time_travel4 = {
  if(
    ~travelling4 == false,
    {
      ~travelling4 = true;
      {[0].do({
        arg item, i;
        ~zero_all.();
        ~set_pos_all.();
        (~lag+2).wait;
        // ~semi_random_sample.([10, 4.rand], [4.rand]);
        ~semi_random_sample.([10, 4.rand, 11], [4.rand, 4.rand, 4.rand]);
        2.wait;
        ~set_rate_all.();
        ~travelling4 = false;
      })}.fork
    },
    {"doing a time travel!"}
  );
};

"Helper Functions Loaded".postln;

)







