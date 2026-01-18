s.boot
(
s.newBusAllocators;
~size = 64;
~imagBus = Bus.control(s, ~size);
~recBus = Bus.audio(s, 2);
~playBus = Bus.audio(s, 2);
f = (1..~size).linexp(1, ~size, 25, 8000);
f.do({
  arg item, i;
  ~imagBus.setAt(i, item);
})
)

(
~setBus = {
  arg list;
  list.do({
  arg item, i;
  ~imagBus.setAt(i, item);
})
}
)

(
OSCdef(
  key: \image,
  func: {
    arg msg, time, addr, recvPort;
    msg.postln;
    msg.do({
      arg item, i;
      if(i>0,
        {~imagBus.setAt(i, item)}
      );
    })
  },
  path: '/image');
)
// use pprocessing-to-spectral code for with OSC in supercollider
// and take osc code from oscP5sendreceive


b = Buffer.read(s, "/Users/ya/Documents/music/breakcore-samples/octatrack/8gb-card/AUDIO/BRAKE/breaks/cw_amen03_167.wav")
b.play

Buffer.cueSoundFile()




// setup audio to be processed
(
SynthDef(\player, {
  arg buf, out=0;
  var sig = PlayBuf.ar(numChannels:2,bufnum:buf,rate:BufRateScale.kr(buf),loop:1);
  Out.ar(out, sig)
}).add
)

~player.free

~player = Synth(\player, [\buf, b, \out, ~recBus])


(
SynthDef(\notches, {
  arg in=0, rbuf=0, fftsize=1024, hop=0.25, win=0;
  var sig = In.ar(in, 2);
  var num = 64;
  // var freqs = (1..num).linexp(1, num, 25, 8000);
  var freqs = ~size.collect ({ |i| In.kr(~imagBus.index + i) });
  var control = Control.names(\array).kr((1..num).linexp(1, num, 25, 16000));
  var notchedSignal = sig;

  freqs.do{
    arg freq, i;
    var f = freqs[i];
    // notchedSignal = Notch.ar(notchedSignal, freq.varlag(0.75, -3), 0.05);
    notchedSignal = BPF.ar(
      in: notchedSignal,
      freq: freq.varlag(0.25, 3),
      rq: 0.125
    ).neg + notchedSignal;
  };
  // notchedSignal = RLPF.ar(notchedSignal, 8000, 1.0);
  Out.ar(0, notchedSignal);
}).add
)


~notches.free

~notches.setn(\array, Array.rand(64, 25, 8000));
~setBus.(Array.exprand(64, 25, 8000))

(
~notches = Synth.after(~player, \notches, [
  \in, ~recBus,
])
)
s.meter
s.tree

(
SynthDef(\resynth,{
  arg buf, amp = 0.5, rot = 0;
  var sig, car1, car2, mod, num = 32, bpfmod, q = \q.kr(20), track, sel,
  bpfhz, bufpos;
  bpfhz = (1..num).linexp(1, num, 25, 16000);
  mod = PlayBuf.ar(1, buf, BufRateScale.kr(buf), loop:1);
  bpfmod = BPF.ar(mod, bpfhz, 1/q, sqrt(q));
  track = Amplitude.kr(bpfmod);
  sel = SelectX.kr(\scramble.kr(0).varlag(1, -3), [track, track.scramble]);
  car1 = SinOsc.ar(bpfhz + \freq.kr(0).varlag(0.5, -3), mul: sel * amp);
  sig = car1;
  sig = Splay.ar(sig.scramble, 0.1);
  Out.ar(0, sig);
}).add
)



