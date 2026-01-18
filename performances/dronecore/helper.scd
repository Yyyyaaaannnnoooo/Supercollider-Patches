~buffer = ~break[10];
~buffer.play
~fft_buf = {Buffer.alloc(s, ~buffer.duration.calcPVRecSize(~size, ~hop), 1)}!2
~fft_buf

(
SynthDef("pvrec_alt", {
  arg bufnum=0, recBufL=1, recBufR=1, soundBufnum=2;
  var in, chainL, chainR;
  Line.kr(1, 1, BufDur.kr(soundBufnum), doneAction: 2);
  in = PlayBuf.ar(2, soundBufnum, BufRateScale.kr(soundBufnum), loop: 0);
  bufnum = {LocalBuf.new(~size)}!2; // uses frame size from above
  // note the window type and overlaps... this is important for resynth parameters
  chainL = FFT(bufnum[0], in[0], 0.25, 1);
  chainL = PV_RecordBuf(chainL, recBufL, 0, 1, 0, 0.25, 1);
  chainR = FFT(bufnum[1], in[1], 0.25, 1);
  chainR = PV_RecordBuf(chainR, recBufR, 0, 1, 0, 0.25, 1);
}).add;
)

(
SynthDef(\fftscrubLR,
  {
    arg out=0, recBufL=1, recBufR=0, sample=0, start=0, dura = 1;
    var chainL, chainR, bufnum,
    sig, sig1, sig12, sig2,
    sig3, sig4, env, trig,
    ampl, position, rate, mod,
    pitch, bin, wipe, width, pos, end=1;
    pitch = \pitch.kr(1, 0.5);
    wipe = \wipe.kr(0);
    width = \width.kr(0.25);
    bin = \bin.kr(1);
    pos = \pos.kr(0, \plag.kr(0));
    bufnum ={LocalBuf.new(~size)}!2;
    trig = \ttt.tr(1);
    rate = \rate.kr(1, \lag.kr(2.5));
    end = start + dura;
    end.clip(0, 1);
    position = Phasor.kr(trig, (256 / BufFrames.kr(recBufL)) * rate , 0, 1, 0);
    // position = Phasor.kr(trig, (rate / SampleRate.ir), start, end, start);
    mod = SinOsc.kr(\lfo.kr(0.001)).range(0, \mul.kr(0));
    chainL = PV_BufRd(
      bufnum[0],
      recBufL,
      pos +
      position +
      mod
    );
    chainL = PV_PitchShift(chainL, pitch);
    chainL = PV_BinShift(chainL, bin);
    chainL = PV_BinScramble(chainL, wipe, width, \tt.tr(1));
    chainR = PV_BufRd(
      bufnum[1],
      recBufR,
      pos +
      position +
      mod
    );
    chainR = PV_PitchShift(chainR, pitch);
    chainR = PV_BinShift(chainR, bin);
    chainR = PV_BinScramble(chainR, wipe, width, \tt.tr(1));
    sig1 = [IFFT(chainL, 1), IFFT(chainR, 1)];
    // use BufRd here!
    sig2 = PlayBuf.ar(
      numChannels: 2,
      bufnum: sample,
      rate:BufRateScale.kr(sample) * rate,
      trigger: trig,
      startPos: 0,
      loop: 1);
    sig4 = Splay.ar(sig2, 1);
    sig3 = SelectX.ar(\sel.kr(0), [sig1, sig4]);
    sig = Select.ar((rate.abs<1), [sig2, sig3]);
    Out.ar(out, sig * \amp.kr(-12.dbamp, 0.5));
}).add;
)
Synth("pvrec_alt",[\recBufL, ~fft_buf[0], \recBufR, ~fft_buf[1], \soundBufnum, ~buffer], target:~synths);
(
~mPlayer = {
  arg val;
  ~p3 = Synth(\fftscrubLR,[
    \out, ~ch3, \recBufL, ~fft_buf[0], \recBufR, ~fft_buf[1],
    \pos, ~scrub_pos3,
    \lag, ~lag, \bin, ~bin,
    \wipe, ~wipe, \width, ~width,
    \sample, ~buffer, \sel, ~fade,
    \rate, ~audio_rate3, \pitch, ~pitch3,
    \lfo, ~lfo_rate3, \mul, ~lfo_amp3
  ], target:~synths);
};

)

~mPlayer.()

~p3.set(\rate, 0.75)
~p3.set(\pos, 0.9)

~free_all.();

