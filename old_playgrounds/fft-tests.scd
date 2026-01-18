s.boot

b = Buffer.read(s, "/Users/ya/Documents/supercollider/sc-patches/00021-break.wav")
c = Buffer.read(s, "/Users/ya/Documents/supercollider/sc-patches/00003-kick.wav")

(
s.newBusAllocators;
~bus = Bus.audio(s, 2);
~size = 1024;
~hop = 0.5;

~init = {
  ~synth = Group.new();
  ~fx = Group.after(~synth);
}
)


(
SynthDef(\sampler, {
  arg buf1=0, buf2=1, rate1=1, rate2=1, amp = 0.5, out=0, kernel;
  var in1, in2, sig, chain, chain1, chain2, lb1, lb2;
  lb1 = {LocalBuf(~size)}!2;
  lb2 = {LocalBuf(~size)}!2;
  in1 = PlayBuf.ar(2,buf1,rate1, loop:1);
  in2 = PlayBuf.ar(2,buf2,rate2, loop:1);
  chain1 = FFT(lb1, in1);
  chain2 = FFT(lb2, in2);
  // chain1 = PV_SpectralMap(chain1, chain2, \floor.kr(0), \freeze.kr(0), \mode.kr(0));
  // chain = PV_Morph(chain1, chain2, \fade.kr(0, 2));
  // chain = PV_SoftWipe(chain1, chain2, \fade.kr(0, 2));
  // chain = PV_Invert(chain1);
  // sig = IFFT(chain);
  sig = Convolution2L.ar(in1, kernel, \trig.tr(0), ~size, 1);
  Out.ar(out, sig);
}).add;
)


(
d = Buffer.alloc(s, ~size);
e = Buffer.alloc(s, ~size);
f = Buffer.alloc(s, ~size);

d.zero;
// e.zero;
f.zero;
)

(
50.do { |it| d.set(20 * it + 10, 1.0.rand) };
3.do { |it| e.set(400 * it + 100, 1) };
20.do { |it| f.set(40 * it + 40, 1) };
)
d.plot

x.free
x = Synth(\sampler, [\buf1, b, \buf2, c, \kernel, d])
(
x.set(\kernel, d);
x.set(\trig, 1)
)
x.set(\fade, 0)
x.set(\floor, 0)
x.set(\freeze, 1)
x.set(\mode, 1)
x.set(\rate2, 1)



