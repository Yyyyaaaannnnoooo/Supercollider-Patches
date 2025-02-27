s.boot
NetAddr.langPort;
~self = NetAddr("127.0.0.1", 57120);


(
OSCdef(
  key: \phase,
  func: {
    arg msg, time, addr, recvPort;
    msg.postln;
    msg.do({
      arg item, i;
      if(i>0,
        {~phaseBus.setAt(i, item.linlin(0, 512, 0, pi / 2))}
      );
    })
  },
  path: '/phase');

OSCdef(
  key: \mag,
  func: {
    arg msg, time, addr, recvPort;
    msg.postln;
    msg.do({
      arg item, i;
      var val=0;
      if(i > 0,
        {
          val = item.linlin(0, 512, 0.1, 4.8);
          ~magBus.setAt(i, val)
        }
      );
    })
  },
  path: '/mag')
)

(
OSCdef(\phase).free;
OSCdef(\mag).free
)

(
~fftsize = 512;
~magBus = Bus.control(s, ~fftsize);
~phaseBus = Bus.control(s, ~fftsize);
)
(
SynthDef(\spectral, {
  var mags = ~fftsize.collect ({ |i| In.kr(~magBus.index + i) });
  var phases = ~fftsize.collect ({ |i| In.kr(~phaseBus.index + i) });
  var chain = FFT(LocalBuf(~fftsize*2), Silent.ar);
  chain = PackFFT(chain, ~fftsize, [mags, phases].flop.flatten);
  Out.ar(0, IFFT(chain).dup);
}).add
)


(
Array.series(~fftsize).scramble.do({ arg i;
  ~magBus.setAt(i, -6.dbamp.rand);
  ~phaseBus.setAt(i, (2*pi).rand)
});
)

x = Synth(\spectral)