// Resynthesis


s.boot;

b = Buffer.read(s,"/Users/ya/Documents/music/breakcore-samples/octatrack/ambients-samples/vox/move-the-truck.wav");

b.play;


(
SynthDef(\resynth,{
  arg buf, amp = 0.5, rot = 0;
  var sig, car1, car2, mod, num = 32, bpfmod, q = \q.kr(20), track, sel,
  bpfhz, bufpos;
  bpfhz = (1..num).linexp(1, num, 25, 16000);
  mod = PlayBuf.ar(1, buf, BufRateScale.ir(buf), loop:1);
  bpfmod = BPF.ar(mod, bpfhz, 1/q, sqrt(q));
  track = Amplitude.kr(bpfmod);
  sel = SelectX.kr(\scramble.kr(0).varlag(1, -3), [track, track.scramble]);
  car1 = SinOsc.ar(bpfhz + \freq.kr(0).varlag(0.5, -3), mul: sel * amp);
  sig = car1;
  sig = Splay.ar(sig.scramble, 0.1);
  Out.ar(0, sig);
}).add
)


x = Synth(\resynth, [\buf, b])
x.set(\scramble, 0)
x.set(\freq, 220)
x.set(\q, 50)
Notch