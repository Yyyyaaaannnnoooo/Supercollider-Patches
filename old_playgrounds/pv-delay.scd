
(
// use as multislider - del time vals on top, feedback on the bottom
// max delay time is 1 second, delaytime and fb are initialized to 0.0
// and are controlled by the GUI. The multi-slider on the top controls
// each bins delay time, the bottom controls FB.

~init = {
  var size, fftSize, hop, awin, delaySilder, fbSlider, maxdel, synth, sampler, cond, playbuf, recbuf, pvrec;
  var setup, onReadyFunc, fftBuffer, delTimeBuffer, fbAmtBuffer, createGUI, liveInputMix, inBus;


  size = 128;
  fftSize = size * 2;
  hop = 0.5;
  recbuf = Buffer.alloc(s, 1.calcPVRecSize(fftSize, hop).postln);
  maxdel = 0.5;
  cond = Condition.new;
  liveInputMix = 1.0; // change to 1 to hear sound from live input, otherwise, an Impulse

  SynthDef(\pvrec, {
    arg recbuf, in=0, fftSize, hop;
    var chain, bufnum, input;
    bufnum = LocalBuf.new(fftSize, 1);
    input = In.ar(in, 1);
    chain = FFT(bufnum, input, 0.25, 1);
    chain = PV_RecordBuf(chain, recbuf, 0, 1, 1, hop, 1);
  }).add;

  s.sync;

  SynthDef(\pvplay, {
    arg recbuf, fftSize, hop, out = 0, rate=1;
    var chain, bufnum;
    bufnum = LocalBuf.new(fftSize, 1);
    chain = PV_PlayBuf(bufnum, recbuf, rate, 0, 1);
    Out.ar(out, IFFT(chain, 1).dup);
  }).add;

  SynthDef(\helpBinDelay, {
    arg inbus=0, inMix = 0.0, out=0, fftBuf=0, delayBuf=0, fbBuf=0;
    var in, chain;
    in = (Impulse.ar(0.33) * (1.0 - inMix)) + (In.ar(inbus, 1) * inMix);
    chain = FFT(fftBuf, in, 0.25);
    chain = PV_BinDelay(chain, maxdel, delayBuf, fbBuf, 0.25);
    Out.ar(out,
      (in + IFFT(chain))!2 * -18.dbamp// inverse FFT
    );
  }).add;

  SynthDef(\sampler, {
    arg buf, amp=1, out = 0, rate = 1;
    var sig = PlayBuf.ar(2, buf, rate:rate, loop:1);
    sig = sig * amp;
    Out.ar(out, sig);
  }).add;

  /* Functions that allocate buffers and call onReadyFunc when done */
  setup = {
    Routine.run({
      "Allocating FFT buffer".postln;
      fftBuffer = Buffer.alloc(s, fftSize, 1);
      "Allocating DelTime buffer".postln;
      delTimeBuffer = Buffer.alloc(s, size, 1);
      "Allocating FB buffer".postln;
      fbAmtBuffer = Buffer.alloc(s, size, 1);
      s.sync(cond);
      onReadyFunc.value()
    });
  };

  createGUI = {

    awin = Window("test", Rect(200 , 450, 10 + (size * 1), 10 + (size *1* 2)));
    awin.view.decorator = FlowLayout(awin.view.bounds);

    delaySilder = MultiSliderView(awin, Rect(0, 0, size * 1, size * 1));
    delaySilder.action = {

      arg xb;
      ("Deltime index: " ++ xb.index ++" value: " ++ (xb.currentvalue * maxdel)).postln;
      delTimeBuffer.set(xb.index, xb.currentvalue * maxdel)
    };

    fbSlider = MultiSliderView(awin, Rect(0, 0, size * 1, size * 1));
    fbSlider.action = {
      arg xb;
      ("FB index: " ++ xb.index ++" value: " ++ xb.currentvalue).postln;
      fbAmtBuffer.set(xb.index, xb.currentvalue)
    };

    [delaySilder, fbSlider].do({
      arg thisSliderView;
      var initDataArray;
      initDataArray = Array.fill(size, {0.0});
      thisSliderView.value_(initDataArray);
      thisSliderView.xOffset_(5);
      thisSliderView.thumbSize_(12.0);

      // value axis size of each blip in pixels
      thisSliderView.valueThumbSize_(15.0);
      // index axis size of each blip in pixels
      thisSliderView.indexThumbSize_( thisSliderView.bounds.width / initDataArray.size );
      thisSliderView.gap = 0;
    });

    awin.front;

    awin.onClose_({
      synth.free;
      fftBuffer.free;
      fbAmtBuffer.free;
      delTimeBuffer.free;
    })
  };

  onReadyFunc = {
    // createGUI.defer();

/*    synth = Synth(\helpBinDelay, [
      \inbus, ~bus1,
      \inMix, liveInputMix,
      \out, 0,
      \fftBuf, fftBuffer.bufnum,
      \delayBuf, delTimeBuffer.bufnum,
      \fbBuf, fbAmtBuffer.bufnum,
    ], target:~fx);*/

    pvrec = Synth(\pvrec, [
      \recbuf, recbuf,
      \in, ~bus1,
      \fftSize, fftSize,
      \hop, hop
    ], target:~rec);

    ~pvplay = Synth(\pvplay,[
      \recbuf, recbuf,
      \fftSixe, fftSize,
      \hop, hop,
      \rate, 1;
    ], target:~fx );

    ~sampler = Synth(\sampler, [
      \buf, ~buf,
      \out, ~bus1
    ], target: ~synths);
  };

  // setup.value();
  onReadyFunc.value()
}
)



s.boot;

~buf = Buffer.read(s,"/Users/ya/Documents/supercollider/sc-patches/00021-break.wav");

~buf.play

(
s.newBusAllocators;
~bus1 = Bus.audio(s, 2);
~synths = Group.new();
~rec = Group.after(~synths);
~fx = Group.after(~rec);
// Buffer.freeAll;


~sampler = nil;

~pvplay = nil;
)

(

~init = {
  var size, fftSize, hop, awin, delaySilder, fbSlider, maxdel, synth, sampler, cond, playbuf, recbuf, pvrec;
  var setup, onReadyFunc, fftBuffer, delTimeBuffer, fbAmtBuffer, createGUI, liveInputMix, inBus;


  size = 128;
  fftSize = size * 2;
  hop = 0.5;
  recbuf = Buffer.alloc(s, 1.calcPVRecSize(fftSize, hop).postln);
  maxdel = 0.5;
  // cond = Condition.new;
  liveInputMix = 1.0; // change to 1 to hear sound from live input, otherwise, an Impulse

  SynthDef(\pvrec, {
    arg recbuf, in=0, fftSize, hop;
    var chain, bufnum, input;
    bufnum = LocalBuf.new(fftSize, 1);
    input = In.ar(in, 2);
    chain = FFT(bufnum, input[0], 0.25, 1);
    chain = PV_RecordBuf(chain, recbuf, 0, 1, 1, hop, 1);
  }).add;

  // s.sync;

  SynthDef(\pvplay, {
    arg recbuf, fftSize, hop, out = 0, rate=1;
    var chain, bufnum;
    bufnum = LocalBuf.new(fftSize, 1);
    chain = PV_PlayBuf(bufnum, recbuf, rate, 0, 1);
    Out.ar(out, IFFT(chain, 1).dup);
  }).add;

/*  SynthDef(\helpBinDelay, {
    arg inbus=0, inMix = 0.0, out=0, fftBuf=0, delayBuf=0, fbBuf=0;
    var in, chain;
    in = (Impulse.ar(0.33) * (1.0 - inMix)) + (In.ar(inbus, 1) * inMix);
    chain = FFT(fftBuf, in, 0.25);
    chain = PV_BinDelay(chain, maxdel, delayBuf, fbBuf, 0.25);
    Out.ar(out,
      (in + IFFT(chain))!2 * -18.dbamp// inverse FFT
    );
  }).add;*/

  SynthDef(\sampler, {
    arg buf, amp=1, out = 0, rate = 1;
    var sig = PlayBuf.ar(2, buf, rate:rate, loop:1);
    Out.ar(out, sig * amp);
    Out.ar(~bus1, sig);
  }).add;



  onReadyFunc = {
    "add synths".postln;

/*    synth = Synth(\helpBinDelay, [
      \inbus, ~bus1,
      \inMix, liveInputMix,
      \out, 0,
      \fftBuf, fftBuffer.bufnum,
      \delayBuf, delTimeBuffer.bufnum,
      \fbBuf, fbAmtBuffer.bufnum,
    ], target:~fx);*/

    pvrec = Synth(\pvrec, [
      \recbuf, recbuf,
      \in, ~bus1,
      \fftSize, fftSize,
      \hop, hop
    ], target:~rec);

    ~pvplay = Synth(\pvplay,[
      \recbuf, recbuf,
      \fftSize, fftSize,
      \hop, hop,
      \rate, 1;
    ], target:~fx );

    ~sampler = Synth(\sampler, [
      \buf, ~buf,
      \out, 0
    ], target: ~synths);
  };

  // setup.value();
  onReadyFunc.value()
}
)
~init.()

~sampler.free;
~sampler.set(\rate, 0.5);
~pvplay.set(\rate, 0)
s.meter