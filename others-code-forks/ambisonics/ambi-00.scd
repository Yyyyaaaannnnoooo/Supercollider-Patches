s.boot;


(
Ndef(\ambienceMaker).addSpec(\rWet, [-1, 1, \lin]);
Ndef(\ambienceMaker).addSpec(\rateRedux, [0, 1]);
Ndef(\ambienceMaker).addSpec(\bits, [1, 32, \lin]);

Ndef(\ambienceMaker).addSpec(\bpWet, [0, 1, \lin]);
Ndef(\ambienceMaker).addSpec(\bpFreq, \freq);
Ndef(\ambienceMaker).addSpec(\bpRq, [0, 2, \lin]);

Ndef(\ambienceMaker).addSpec(\hpnoise, [-48, 0, \db]);
Ndef(\ambienceMaker).addSpec(\white, [-48, 0, \db]);
Ndef(\ambienceMaker).addSpec(\pink, [-48, 0, \db]);
Ndef(\ambienceMaker).addSpec(\brown, [-48, 0, \db]);
Ndef(\ambienceMaker).addSpec(\gray, [-48, 0, \db]);
Ndef(\ambienceMaker).addSpec(\dust, [-48, 0, \db]);
Ndef(\ambienceMaker).addSpec(\dustDensity, [1, s.sampleRate/2, \exp]);

Ndef(\ambienceMaker).addSpec(\drops, [-48, 0, \db]);
Ndef(\ambienceMaker).addSpec(\dropDensity, [1, s.sampleRate/2, \exp]);
Ndef(\ambienceMaker).addSpec(\dropDecay, [0.001, 1, \exp]);
Ndef(\ambienceMaker).addSpec(\dropFFreq, \freq);
Ndef(\ambienceMaker).addSpec(\dropFRq, [0, 2, \lin]);



Ndef(\ambienceMaker, {
  var noise, src;
  var zeroAmp = 0.0039811;
  var hpnoise = \hpnoise.kr(1).dbamp - zeroAmp;
  var hpNFreq = \hpNFreq.kr(1000, 0.1);
  var white = \white.kr(1).dbamp - zeroAmp;
  var pink = \pink.kr(1).dbamp - zeroAmp;
  var brown = \brown.kr(1).dbamp - zeroAmp;
  var gray = \gray.kr(1).dbamp - zeroAmp;
  var dust = \dust.kr(1).dbamp - zeroAmp;
  var dustDensity = \dustDensity.kr(1);

  var drops = \drops.kr(1).dbamp - zeroAmp;
  var dropDensity = \dropDensity.kr(1);
  var dropDecay = \dropDecay.kr(1);
  var dropFFreq = \dropFFreq.kr(1);
  var dropFRq = \dropFRq.kr(1);


  var bpF;
  var bpWet = \bpWet.kr(0);
  var bpFreq = \bpFreq.kr(20000, 0.01);
  var bpRq = \bpRq.kr(1, 0.01);


  var redux;
  var rWet = \rWet.kr(0);
  var rateRedux = \rateRedux.kr(1, 0.01);
  var bits = \bits.kr(32);


  hpnoise = {HPF.ar(PinkNoise.ar(hpnoise), hpNFreq)}!2;
  white   = {WhiteNoise.ar(white)}!2;
  pink    = {PinkNoise.ar(pink)}!2;
  brown   = {BrownNoise.ar(brown)}!2;
  gray    = {GrayNoise.ar(gray)}!2;
  dust    = {Dust2.ar(dustDensity, dust)}!2;



  src = Mix([white, pink, brown, gray, dust, hpnoise]);

  drops = {Decay.ar(Dust.ar(dropDensity, drops), dropDecay) * PinkNoise.ar}!2;

  src = Mix([src, drops]);

  bpF = BPF.ar(src, bpFreq, bpRq);
  src = SelectX.ar(bpWet, [src, bpF]);

  redux = Latch.ar(src, Impulse.ar(SampleRate.ir * (rateRedux/2)));
  redux = redux.round(0.5 ** bits);
  SelectX.ar(1 + rWet, [src - redux, src, redux]);

})
)

Ndef(\ambienceMaker).gui
13280 * 2

(
Ndef('noiseBurst').set('white', -48.0, 'pink', -40.494860819681, 'bpWet', 0.76190476190476, 'bpRq', 1.2910052910053, 'dust', -17.0397263296, 'dropDecay', 0.0066895487869141, 'dustDensity', 4.89136346687, 'bits', 3.952380952381, 'noiseType', 1.1746031746032, 'dropFFreq', 119.89685006379, 'bpFreq', 928.31776672256, 'brown', -36.400703367795, 'dropDensity', 6.7191745397468, 'dropFRq', 0.074074074074074, 'gray', -48.0, 'rateRedux', 0.47619047619048, 'drops', -9.8101205277825, 'rWet', 0.37037037037037);

)

BinauralDecoderCIPIC
HoaEncodeDirection


// Setup decoder
(
~order = ~order ? 3;
BinauralDecoderCIPIC.new(
  hoaOrder: ~order,
  id: 21
);
)
Atk.downloadKernels
Atk.downloadMatrices
// Inspect the node tree to see that it is in fact in action:
s.plotTree
s.reboot
// Play some high order ambisonics sound
(
// White Noise going round
n = Ndef(\hoa_testorientation, {|amp=0.125, freq=100, rotFreq=0.125, ele=10|
  // var sig = LFTri.ar(freq)*amp;
  var sig = WhiteNoise.ar(amp);
  var azi = LFSaw.kr(rotFreq, mul: pi);

  sig = HoaEncodeDirection.ar(
    sig,
    azi,
    ele,
    AtkHoa.refRadius,
    ~order
  );

})
)

n.play

n.set(\rotFreq, 0.73)
n.set(\ele, 90)


(
r.stop;
r = Routine({
  inf.do({
    arg item, i;
    0.125.wait;
    Array.series(100, 0.0, 0.01).mirror.do({
      arg item, i;
      item.postln;
      n.set(\ele, item * 10);
      0.125.wait;
    });
  })

})
)

r.play