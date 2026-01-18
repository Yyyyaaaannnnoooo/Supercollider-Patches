PV_BinShift

GrainBuf

s.boot

(
{
  var sig, chain;
  sig = WhiteNoise.ar(0.2);
  chain = FFT(LocalBuf(2048), sig);
  chain = PV_RectComb(chain,  MouseX.kr(0, 32), MouseY.kr, 0.2);
  IFFT(chain).dup
}.play;
)




(
SynthDef("help-magAbove2", { arg out=0;
  var in, chain;
  in = WhiteNoise.ar(0.2);
  chain = FFT(LocalBuf(2048), in);
  // chain = PV_MagAbove(chain, MouseX.kr(0, 10));
  Out.ar(out, 0.1 * IFFT(chain).dup);
}).play(s);
)

(
x = SynthDef("help-magAbove3", { arg out=0, soundBufnum=2, ratio=2;
  var in, chain, size = 2048*2;
  in = PlayBuf.ar(1, soundBufnum, BufRateScale.kr(soundBufnum), loop: 1);
  chain = FFT(LocalBuf(size), in);
  chain = PV_MagAbove(chain, MouseX.kr(0, 100));
  // chain = PV_MagSmear(chain, MouseX.kr(0, 100));
  chain = PV_SpectralEnhance(chain, 8, ratio, MouseY.kr(0, 1.99));
  chain = PV_BrickWall(chain, \wipe1.kr(0).clip(-1, 0));
  chain = PV_BrickWall(chain, \wipe2.kr(0).clip(0,1));
  Out.ar(out, 0.1 * IFFT(chain).dup);
}).play(s, [\soundBufnum, q]);
)

x.set(\ratio, 8)
x.set(\wipe1, -0.6)
x.set(\wipe2, 0.1)


q = q ? ();
Buffer.freeAll
// load buffers
// e.g. mono sound (see below)
q.audioBuffer = Buffer.readChannel(s, "/Users/ya/Documents/supercollider/audio/breaks/606-amen.wav", channels: [0]);

(
Ndef(\freezePlayer).addSpec(
  \lpFreq, \freq,
  \hpFreq, \freq,
  \shift, [0.125, 4, \exp],
  \freezeRate, [10, 100, \exp], // how fast to go back and forth
  \rateDir, [-1, 1, \lin], // direction of movement in the buffer, if 1 or -1, use normal playback
  \rate, [0.125, 16, \exp], // how fast the buffer should play back/forth in normal mode
  \modSource, [0, 2, \lin, 0], // [SinOsc, LFPulse, LFTri]
);

// make sure to check number of channels of the buffer(s) to be used
Ndef(\freezePlayer, {|bufnum = 0|
  var numChannels = 1;
  var chain, efx;
  var rateDir = \rateDir.kr(0);
  // var wet = \wet.kr(0) > 0;
  var wet = rateDir.abs < 1;
  var rateScale = BufRateScale.kr(bufnum);

  // possible modulation sources are e.g. LFPulse, LFTri, SinOsc..
  // for the system to work properly, the integrated signal should be 0, (i.e. going equal parts backwards and forwards).
  var modSource = LinSelectX.kr(\modSource.kr(0), [
    SinOsc.kr(\freezeRate.kr(20), phase: 0).range(-1, 1),
    LFPulse.kr(\freezeRate.kr(20), iphase: 0).range(-1, 1),
    LFTri.kr(\freezeRate.kr(20), iphase: 0).range(-1, 1)
  ]);


  var rateFX = (
    ((1-wet) * rateDir.sign) // normal playback
    + (wet * (modSource + rateDir)) // "freeze"
  ) * \rate.kr(1) * rateScale;

  var snd = PlayBuf.ar(
    numChannels: numChannels,
    bufnum: bufnum,
    rate: rateFX,
    trigger: \trig.tr(1),
    loop: 1
  );

  snd = LPF.ar(HPF.ar(snd, \hpFreq.kr(10)), \lpFreq.kr(10000));
});
);

Ndef(\freezePlayer).set(\bufnum, q.audioBuffer.bufnum);
Ndef(\freezePlayer).edit;


// q.audioBuffer.play

//////////////// frequency-domain

(
Ndef(\freezePlayerFFT).addSpec(
  \lpFreq, \freq,
  \hpFreq, \freq,
  \wet, [0, 1, \lin, 1],
  \frShift, [0.25, 4, \exp],
  \frDiff, [0, 1, \lin, 1]
);
Ndef(\freezePlayerFFT, {|bufnum = 0|
  var numChannels = 1;
  var chain, efx;
  var wet = \wet.kr(0) > 0;
  var buffer = q.audioBuffer;
  var snd = PlayBuf.ar(
    numChannels: numChannels,
    bufnum: bufnum,
    rate: \rate.kr(1) * BufRateScale.kr(bufnum) * (1-wet),
    trigger: \trig.tr(1),
    loop: 1
  );

  // FFT processing
  chain = FFT(LocalBuf(4096), snd); // encode to frequency domain
  chain = PV_Diffuser(chain, \frDiff.kr(0) * wet);
  chain = PV_Freeze(chain, wet);
  chain = PV_BinShift(chain, \frShift.kr(1));

  efx = IFFT(chain); // decode to time domain

  snd = Select.ar(wet, [snd, efx]);
  // snd = efx;

  snd = LPF.ar(HPF.ar(snd, \hpFreq.kr(10)), \lpFreq.kr(10000));
});
)

Ndef(\freezePlayerFFT).set(\bufnum, q.audioBuffer.bufnum);


Ndef(\freezePlayerFFT).play
Ndef(\freezePlayerFFT).edit
// By Nathaniel Virgo
// https://listarc.cal.bham.ac.uk/lists/sc-users-2009/msg55766.html

// This comes from the mailing list as an attempt to simulate the vst Shapee

(
s.boot.doWhenBooted {
  c = Buffer.read(s,"/Users/ya/Documents/supercollider/audio/breaks/606-amen.wav");
}
)

(
x = {
  // parameters to play with - width should be an integer - I think 4 is the theoretical optimum
  var fftsize = 512, width=4;

  var in, chain, in2, chain2, out;

  // timbre source - vocal sample
  in = PlayBuf.ar(1, c, BufRateScale.kr(c), loop: 1);

  // pitch source - random polyphonic line
  in2 = Saw.ar(LFNoise0.ar(1!3).exprange(100,5000)).mean;

  chain = FFT(LocalBuf(fftsize), in, wintype:1);
  chain2 = FFT(LocalBuf(fftsize), in2, wintype:1);

  chain = chain.pvcalc2(chain2, fftsize, {|e_mags, e_phases, f_mags, f_phases|

    var fbins = e_mags.clump(width).collect(_.sum) / f_mags.clump(width).collect(_.sum);

    [f_mags*fbins.stutter(width), f_phases];
    //[e_mags, f_phases];
  });


  out = IFFT(chain);
  Out.ar(0, 0.5 * out.dup);
}.play(s);
)

x.set(\width, 1)