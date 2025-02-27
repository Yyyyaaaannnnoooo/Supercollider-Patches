Platform.userExtensionDir
VSTPlugin.pluginKeys
VSTPlugin.plugins(s)


// ValhallaSupermassive  Emergence  Fracture
// Fracture.vst3 Emergence.vst3 ValhallaSupermassive.vst3

(
SynthDef(\reese, {
  arg freq = 120, lpf = 800, nof=0.25,a=1.5, s=2, r=1;
  var sig, voices = 16, detune = 10, env;
  sig = LFSaw.ar((Array.series(voices, 0.01, 0.37).rand2 + freq).varlag(1.5, -3), 0, voices.reciprocal);
  sig = RLPF.ar(sig, lpf.clip(20, 17000).varlag(0.75, -3), 1);
  sig = FreeVerb.ar(sig, 0.5, 0.5, 0.5);
  sig = sig.sum;
  sig = sig!2;
  env = EnvGen.kr(Env.new([0,1,0.75,0], [a,s,r], curve:[2, -3, -3]),gate: \gate.kr(1.0), doneAction: 2);
  sig = sig * env;
  sig = sig * -6.dbamp;
  Out.ar(0, sig);
}).add;
)


f = Synth(\fracture)

x = Synth(\reese, [\freq, 66.midicps, \a, 1.5, \s, 4, \r, 20, \lpf, 1600])
x.set(\freq, 24.midicps)
x.set(\lpf, 6400)


x.free


(
SynthDef(\vst, {
  arg bus;
    // 'GChorus' is a shortcut for VSTPlugin.plugins['GChorus']
  var sig = VSTPlugin.ar(In.ar(bus, 2), 2, id: \glitch);
    ReplaceOut.ar(bus, sig);
}).add;
)
VSTPlugin.search(s, "~/Library/Audio/Plug-Ins/VST3")
~glitch = Synth(\vst, 0)
~fx = VSTPluginController(~glitch)
// /Library/Audio/Plug-Ins/VST3/Dexed.vst3
// /Library/Audio/Plug-Ins/VST3/Elektron/Analog Four.vst3
// /Library/Audio/Plug-Ins/VST3/Elektron/Analog Heat.vst3
// /Library/Audio/Plug-Ins/VST3/Elektron/Analog Rytm.vst3
// /Library/Audio/Plug-Ins/VST3/Elektron/Digitone.vst3
// /Library/Audio/Plug-Ins/VST3/Emergence.vst3
// /Library/Audio/Plug-Ins/VST3/Fracture.vst3
// /Library/Audio/Plug-Ins/VST3/Noise Engineering/Ruina.vst3
// /Library/Audio/Plug-Ins/VST3/Noise Engineering/Sinc Vereor.vst3
// /Library/Audio/Plug-Ins/VST3/Noise Engineering/Virt Vereor.vst3
// /Library/Audio/Plug-Ins/VST3/PaulXStretch.vst3
// /Library/Audio/Plug-Ins/VST3/RAVE.vst3
// /Library/Audio/Plug-Ins/VST3/ValhallaSupermassive.vst3
// /Library/Audio/Plug-Ins/VST3/Vital.vst3
~fx.open("/Library/Audio/Plug-Ins/VST3/Fracture.vst3", verbose: true)
~fx.editor
~fx.gui

