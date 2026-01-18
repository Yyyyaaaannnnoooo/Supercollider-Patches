s.boot

(
SynthDef(\sine_double, { |outbus = 0, amp = 0.5, freqx = 440, freqy = 440, pan = 0|
  var data, sine;
  freqx = Lag.kr(freqx, 0.1);
  freqy = Lag.kr(freqy, 0.1);

  data = SinOsc.ar(freqx) * SinOsc.ar(freqy) * amp;
  data = Pan2.ar(data, pan);

  Out.ar(outbus, data);
}).store;
)
(
SynthDef(\fx_comb, { |inbus = 0, outbus = 0, wet = 0.5, delaytime = 0.1, decaytime = 1.0, fade = 0.5|
  var in, out;

  wet = Lag.kr(wet, fade);
  delaytime = Lag.kr(delaytime, fade);

  in = In.ar(inbus, 2);
  out = CombN.ar(in, 2.0, delaytime, decaytime);

  out = (wet * out) + ((1 - wet) * in);
  Out.ar(outbus, out);
}).store;

)

(
SynthDef(\sine_harmonic, { |outbus = 0, freq = 200, amp = 0.1, gate = 1, pan = 0|
  var data, env;

  amp = Lag.kr(amp, 0.4);

  // generate, degrade, filter, echo
  data = SinOsc.ar(freq, 0, amp);
  data = Latch.ar(data, Impulse.ar(Rand(1000, 35000)));
  data = LPF.ar(data, 1000);
  data = Pan2.ar(data, pan);
  data = data + CombN.ar(data, 0.5, 0.3, 15.0, 0.3);

  // envelope
  env = EnvGen.kr(Env.asr(0.5, 1.0, 1.0), gate: gate, doneAction: 2);
  data = data * env;

  data = [ data[0], data[1] * Select.kr(IRand(0, 3), [ 1, 1, -1 ]) ];

  Out.ar(outbus, data);
}).store;
)

(
SynthDef(\moogsaw, { |freq = 500, amp = 1.0, outbus = 0, pan = 0, cutoff = 120, resonance = 0.7|
	var data;

	freq = Lag.kr(freq, 0.1);

	data = Saw.ar(freq, amp);
	data = MoogVCF.ar(data, cutoff, resonance);
	data = data + CombN.ar(data, 0.05, 0.05, 0.5, 0.1);
	data = Pan2.ar(data, pan);

	Out.ar(outbus, data);
}).store;

)



(
SynthDef(\pulser, { |freq = 50, amp = 0.1, pan = 0, outbus = 0|
	var data;

	data = Impulse.ar(freq, 0, amp);
	data = Pan2.ar(data, pan);
	data = Decay.ar(data, 0.005);
	data = data * SinOsc.ar(freq);

	Out.ar(outbus, data);
}).store;
)

(
// reverb
SynthDef(\fx_rev_gverb, { |inbus = 0, outbus = 0, wet = 0.5, fade = 1.0, roomsize = 50, reverbtime = 1.0, damp = 0.995, amp = 1.0|
	var in, out;

	wet = Lag.kr(wet, fade);
	wet = wet * 0.5;

	reverbtime = Lag.kr(reverbtime, fade) * 0.5;
	in = In.ar(inbus, 2) * amp;
	out = GVerb.ar(in, roomsize, reverbtime, damp);
	out = (wet * out) + ((1.0 - wet) * in);

	Out.ar(outbus, out);
}).store;
)

Notch