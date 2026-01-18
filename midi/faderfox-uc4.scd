
// MIDI SETUP!!!

MIDIClient.init;
MIDIIn.connectAll;
MIDIIn.connect(inport: 0, device: MIDIClient.sources.at(2));
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
    var depth = val.linlin(0, ~bend_val, 0, 0.25);
}, chan: 0);
~enc2 = MIDIdef.bend(key: \enc2,
  func: {
    arg val, num, chan;
    var depth = val.linlin(0, ~bend_val, 0, 0.25);
}, chan: 1);
~enc3 = MIDIdef.bend(key: \enc3,
  func: {
    arg val, num, chan;
    var depth = val.linlin(0, ~bend_val, 0, 0.25);
}, chan: 2);
~enc5 = MIDIdef.bend(key: \enc5,
  func: {
    arg val, num, chan;
    var pos = val.linlin(0, ~bend_val, 0, 1);
}, chan: 4);
~enc6 = MIDIdef.bend(key: \enc6,
  func: {
    arg val, num, chan;
    var pos = val.linlin(0, ~bend_val, 0, 1);
}, chan: 5);
~enc7 = MIDIdef.bend(key: \enc7,
  func: {
    arg val, num, chan;
    var pos = val.linlin(0, ~bend_val, 0, 1);
}, chan: 6);

~enc8 = MIDIdef.bend(key: \enc8,
  func: {
    arg val, num, chan;
    var pos = val.linlin(0, ~bend_val, 0, 1);
}, chan: 7);

~sl1 = MIDIdef.cc(\sl1,{
  arg val, num, chan;
  var input = val.linlin(0, 127, -1,1.35);
},70, 8);
~sl2 = MIDIdef.cc(\sl2,{
  arg val, num, chan;
  var input = val.linlin(0, 127, -1,1.35);
},71, 8);
~sl3 = MIDIdef.cc(\sl3,{
  arg val, num, chan;
  var input = val.linlin(0, 127, -1,1.35);
},72, 8);

// pos
~sl4 = MIDIdef.cc(\sl4,{
  arg val, num, chan;
  var input = val.linlin(0, 127, -1,1.35);
},73, 8);
~sl5 = MIDIdef.cc(\sl5,{
  arg val, num, chan;
},74, 8);
~sl6 = MIDIdef.cc(\sl6,{
  arg val, num, chan;
  var input = val.linlin(0, 127, -1,1.35);
},75, 8);

// bin Scramble
~sl7 = MIDIdef.cc(\sl7,{
  arg val, num, chan;
  var input = val.linlin(0, 127, -1,1.35);
},76, 8);
~sl8 = MIDIdef.cc(\sl8,{
  arg val, num, chan;
  var input = val.linlin(0, 127, -1,1.35);
},77, 8);

// blend fft playbuf
~sl9 = MIDIdef.cc(\sl9,{
  arg val, num, chan;
  var input = val.linlin(0, 127, -1,1.35);
},78, 8);

~b1 = MIDIdef.cc(\b1,{
  arg val, num, chan;
},74,0);

"MIDI Functions loaded".postln;

)