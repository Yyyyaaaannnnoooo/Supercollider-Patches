(
s.boot;
)
(
s.meter;
)
(
s.plotTree;
)
(
s.reboot;
)

(
s.quit;
)
// kick drum
(
	~f1 = 750;
	~f2 = 250;
	~f3 = 15;

	~a = 0.01;
	~d = 1.2;

	~ca = -2;
	~cb = -12;
Env([~f1, ~f2, ~f3], [~a, ~d], [~ca, ~cb]).plot;

)
(x = Synth.new(\kick, [
	\freq_1, ~f1,
	\freq_2, ~f2,
	\freq_3, ~f3,
	\freq_dur_1, ~a,
	\freq_dur_2, ~b,
	\freq_curve_1, ~ca,
	\freq_curve_2, ~cb,
]);)
x = Synth.new(\kick);
(
SynthDef.new(\kick,{
	arg freq_1=1750,
	freq_2=80,
	freq_3=10,
	freq_dur_1=0.01,
	freq_dur_2=1.2,
	freq_curve_1=(-2),
	freq_curve_2=(-12),
	env_atk=0.001,
	env_rel=0.75,
	env_curve_1=1,
	env_curve_2=(-5),
	amp=0.25,
	pan=0,
	out=0;
	var sig, env, freq_sweep, dist;
	freq_sweep = Env(
		[freq_1, freq_2, freq_3],
		[freq_dur_1, freq_dur_2],
		[freq_curve_1, freq_curve_2]
	).ar;
	env = Env(
		[0,1,0],
		[env_atk, env_rel],
		[env_curve_1, env_curve_2]
	).kr(2);
	sig = SinOsc.ar(freq_sweep, pi/2);
	dist = (sig * 100).tanh + ((sig.sign - sig) * -8.dbamp); // dist
	sig = sig * env;
	dist = dist * env;
	sig = sig + dist;
	sig = Pan2.ar(sig, pan, amp);
	Out.ar(out, sig);
}).add;
)


(s.freeAll)
