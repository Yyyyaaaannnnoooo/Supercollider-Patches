s.boot



s.quit


(
SynthDef(\test,{
  var sig = VarSaw.ar(\freq.kr(80, 0.5) + {rrand(0.01, 0.2)}!16, mul: 16.reciprocal);
  sig = sig!2;
  sig = Splay.ar(sig, 1);
  sig = sig * \amp.kr(0.dbamp, 0.5);
  Out.ar(0, sig);
}).add
)

(
x.free;

x = Synth(\test)
)

x.set(\amp, 0.dbamp)
x.set(\freq, 80)

s.meter


(
// ~r.stop
~r = Routine({
  loop{
    [40, 50, 60, 80].do({
      arg val, i;
      x.set(\freq, val);
      val.postln;
      0.5.wait;
    })
  }
})
)

~r.play
~r.stop
(
~buildR = {
  arg list, synth, attr;
  Routine({
  loop{
    list.do({
      arg val, i;
      synth.set(attr, val);
      val.postln;
      0.5.wait;
    })
  }
})
}
)
~r1 = ~buildR.([20, 30, 50, 440], x, \freq)
~r1.play
~r1.stop

~r2 = ~buildR.([0.dbamp, 0, -12.dbamp], x, \amp)
~r2.play
~r2.stop