(

s = Server.local;
s.options.memSize_(32768 * 4).numOutputBusChannels_(26).numInputBusChannels_(8);

s.boot;

s.waitForBoot({
	var routeBus, celloBus, celloBuf, bfBus, outBus, decoder;
	var celloAna, celloAnaAmp, celloAnaFreq;
	var notes, procs, events, celloNote;
	var cleanup, bufTime, isPlaying, celloIn, filterBus, mainEffectBus;
	var playbackPoint, playbackChase, filtCurChord, warpHarm, inHarm, inHarmBank,
	barkDel, perc, spotBP, cascadingFilts, processInput, noiseProcessInput, stretchPlayBack;
	var limit, init, kill, pevents, rBufTime, writeBufs, cond, grainBuf;
	var setupInitialOUIButtons, localTest;
	var useIPad;
	var usePracticeBuffer, practicePath, practiceBuffer;
	var recPath;
	usePracticeBuffer = false;
	practicePath = "~/Desktop/Passacaglia/CelloPart.aif".standardizePath;
	useIPad = true;
	isPlaying = false;
	writeBufs = true;
	cond = Condition.new;
	bufTime = 180.0; // three minutes
	rBufTime = 1/bufTime;
	"Server booted".postln;
	filterBus = CtkAudio.play(1, server: s);
	mainEffectBus = CtkAudio.play(1, server: s);
	routeBus = CtkAudio.play(1, server: s);
	usePracticeBuffer.if({
		celloIn = CtkAudio.play(1, s.options.numOutputBusChannels + 2, server: s);
	}, {
		celloIn = CtkAudio.play(1, s.options.numOutputBusChannels + 0, server: s);
	});
	celloBus = CtkAudio.play(1, server: s);
	bfBus = CtkAudio.play(4, server: s);
	outBus = CtkAudio.play(s.options.numOutputBusChannels, 0, server:s);

	grainBuf = CtkBuffer.buffer(1024, server: s)
	.fillWithEnv(0.1, Env([0, 1, 0], [0.5, 0.5], \sin)).load;
	celloBuf = CtkBuffer.buffer(bufTime * s.sampleRate, server: s).load;
	usePracticeBuffer.if({
		practiceBuffer = CtkBuffer.playbuf(practicePath, server: s).load(sync: true,
			onComplete:{
				celloBuf.copyFromBuffer(practiceBuffer);
		});
	});

	celloAna = InputAnalyzer(mainEffectBus.bus, server: s);
	celloAna.gui;
	celloAna.start;
	decoder = AmbDecoderGUI(server: s)
	.addInput(bfBus.bus, bfBus.bus+1, bfBus.bus+2, bfBus.bus+3)
	.addOutput(0, -0.166, 0)
	.addOutput(1, 0.166, 0)
	.addOutput(2, 0.5, 0)
	.addOutput(3, 0.833, 0)
	.addOutput(4, -0.833, 0)
	.addOutput(5, -0.5, 0);

	useIPad.if({
		/****** IPAD SETUP *******/
		~getIP = { arg action;
			var before = NetAddr.broadcastFlag;
			NetAddr.broadcastFlag = true;
			OSCresponder(nil, '/getMyIP', { arg t,r,msg,addr;
				action.(addr);
				NetAddr.broadcastFlag = before;
				r.remove;
			}).add;

			NetAddr("255.255.255.255", NetAddr.langPort).sendMsg('/getMyIP');
			nil;
		};

		"Run get IP!".postln;

		~getIP.value({arg addr; ("Set the IP in OUI to: " ++ addr.ip ++ " and port: "++NetAddr.langPort).postln});

		//~setupResponders.value;
		//~removeResponders = {
		//	~resps.flat.do({arg me; me.remove});
		//	};
		//
		//~curEvs = [];

		setupInitialOUIButtons = {
			// add global slider
			"Setting up OUI widgets".postln;
			~oui.createHSlider(\globalAmp, 40, 40, 688, 40, -90, 12.0, 0, \db, {arg time, resp, msg, addr;

				(msg[1] == "/sliderValue".asSymbol).if({

					var newAmp = msg[2].dbamp;
					{pevents.amp_(newAmp);}.defer;
				});
			});

			~lastTouchUp = 0;
			~oui.createHButton(\curEvent, 180, 90, 120, 44, "Current Ev: ", 12, {arg time, resp, msg, addr;
				(msg[1] == "/touchUp".asSymbol).if({
					"Redraw!".postln;
					~setupIPad.value(true);
				})
			});

			~oui.createHButton(\next, 40, 90, 120, 44, "GO 0", 12, {arg time, resp, msg, addr;
				(msg[1] == "/touchUp".asSymbol).if({
					((Main.elapsedTime - ~lastTouchUp) > 0.5).if({
						{
							pevents.next;
							~updateNextButton.value(p.index+1);
							~lastTouchUp = Main.elapsedTime;
						}.defer;
					});
				});
			});

			~firstKill = 0;
			~oui.createHButton(\kill, 608, 90, 120, 44, "Kill", 12, {arg time, resp, msg, addr;
				(msg[1] == "/touchUp".asSymbol).if({
					((Main.elapsedTime - ~firstKill) < 1.0).if({
						{pevents.window.close}.defer;
					});
					~firstKill = Main.elapsedTime;

				});
			});


			~backAnIndexButton = ~oui.createHButton(\back, 360, 90, 90, 44, "Back", 12, {arg time, resp, msg, addr;
				(msg[1] == "/touchUp".asSymbol).if({
					{
						var curNext;
						curNext = p.nextIndexNumberBox.value.asInteger;
						curNext = curNext - 1;
						p.nextIndexNumberBox.value_(curNext);
						~updateNextButton.(curNext);
					}.defer;
				});
			});

			~forwardAnIndexButton = ~oui.createHButton(\forward, 470, 90, 90, 44, "Forward", 12, {arg time, resp, msg, addr;
				(msg[1] == "/touchUp".asSymbol).if({
					{
						var curNext;
						curNext = p.nextIndexNumberBox.value.asInteger;
						curNext = curNext + 1;
						p.nextIndexNumberBox.value_(curNext);
						~updateNextButton.(curNext);
					}.defer;
				});
			});

			~updateNextButton = {arg index;
				p.index.postln;
				"Hey!".postln;
				~oui.createHButton(\curEvent, 180, 90, 120, 44, "Current Ev: " ++ p.index, 12, {arg time, resp, msg, addr;
					(msg[1] == "/touchUp".asSymbol).if({
						"Redraw!".postln;
						~setupIPad.value;
					})
				});
				~oui.createHButton(\next, 40, 90, 120, 44, "GO "++index, 12, {arg time, resp, msg, addr;
					(msg[1] == "/touchUp".asSymbol).if({
						((Main.elapsedTime - ~lastTouchUp) > 0.5).if({
							{
								p.next;
								~updateNextButton.value(p.index+1);
								~lastTouchUp = Main.elapsedTime;
							}.defer;
						});
					});
				});
			};

		};

		(~oui.isNil or:{~oui.ip.isNil}).if({
			~oui = OUI(nil, 5701);

			~oui.listen({
				"Heard OUI!".postln;
				~oui.clearPage;
				setupInitialOUIButtons.value;
			})
		}, {
			setupInitialOUIButtons.value;
		});

		~curEvs = [];
		~newEvs = [];
		~evsToRemove = [];
		~ouiDict = IdentityDictionary.new;
		~setupIPad = {arg redraw = false;
			redraw.if({
				~oui.clearPage;
				setupInitialOUIButtons.value;
			});

			~newEvs = p.eventArray.flat.select({arg thisEv;
				p.eventDict[thisEv].notNil and: {
					p.eventDict[thisEv].isRunning || p.eventDict[thisEv].isReleasing};
			});
			~evsToRemove = [];
			~newEvs.postln;


			~newEvs.do({arg thisEv;
				~curEvs.indexOf(thisEv).isNil.if({~evsToRemove = ~evsToRemove.add(thisEv)});
				~curEvs = ~newEvs;
				~evsToRemove.do({arg thisEv;
					var ouiControls;
					ouiControls = ~ouiDict[thisEv];
					ouiControls.do({arg thisControl;
						thisControl.remove;
					});
					~ouiDict.removeAt(thisEv);
				});
				~curEvs.do({arg thisEv, i;
					var slider, label, thisAmp;
					thisAmp = pevents.eventDict[thisEv].amp.ampdb;
					slider = ~oui.createHSlider(thisEv, 40.0 + ((i % 2) * 390), 145.0 + ((i / 2).floor * 80), 300.0, 40.0, -90.0, 12.0, thisAmp, \db, {arg t, r, m, a;
						var ev;
						ev = m[0].asString;
						ev = ev.replace("/OUI/", "").asSymbol;
						(m[1] == "/sliderValue".asSymbol).if({
							pevents.eventDict[ev].amp_(m[2].dbamp);
						});
					});
					label = ~oui.createHLabel((thisEv++"Label").asSymbol, 40.0 + ((i % 2) * 390), 190.0 + ((i / 2).floor * 80), 300.0, 20.0, thisEv);
					~ouiDict.put(thisEv, [slider, label]);
				});
			});
		};

	});
	/* end iPad */
	notes = CtkProtoNotes(
		SynthDef(\PfilterSend, {arg inBus, outBus, gate = 1;
			var in, env, out;
			// we just need 'w'
			in = In.ar(inBus, 1);
			env = EnvGen.kr(
				Control.names(\env).kr(Env.newClear(8)),
				gate,
				doneAction: 2);
			Out.ar(outBus, in * env);
		}),
		SynthDef(\PpracticePlayback, {arg outBus, buffer;
			var pb;
			pb = PlayBuf.ar(1, buffer);
			Out.ar(outBus, pb);
			Out.ar(0, pb.dup);
		}),
		// startPos in seconds
		SynthDef(\PstretchPlayback, {arg outBus, buffer, startPos, stretch, loc;
			var pb, pointer;
			pointer = (Sweep.kr(0, stretch) + startPos) /  BufDur.kr(buffer);
			pb = WarpZ.ar(1, buffer, pointer, 1, 0.11, -1, 6, 0.1, 1, 0.01, 0.1);
			Out.ar(outBus, BFEncode1.ar(pb, loc));
		}),
		SynthDef(\PinputPlayback, {arg filterOutBus, duration, buffer, startPos,
			outBus;
			var pb, env, bf;
			pb = PlayBuf.ar(1, buffer, BufRateScale.kr(buffer),
				startPos: startPos * BufSampleRate.kr(buffer));
			env = EnvGen.kr(
				Env([0, 1, 1, 0], [0.1, duration-0.2, 0.1], [10, 0, 10]));
			Out.ar(filterOutBus, pb * env);
			bf = BFEncode1.ar(pb*env, 0, 0);
			Out.ar(outBus, pb);
		}),
		SynthDef(\PnoisePlayback, {arg filterOutBus, duration, buffer, startPos,
			outBus;
			var pb, env, bf, fft, out, chain;
			pb = PlayBuf.ar(1, buffer, BufRateScale.kr(buffer),
				startPos: startPos * BufSampleRate.kr(buffer));
			chain = FFT(LocalBuf(2048, 1), pb);
			chain = PV_NoiseSynthP(chain, 0.5pi, 4);
			out = IFFT(chain, 0, 2048) * XLine.kr(0.00001, 1, 4);
			out = out + GVerb.ar(out, 200, 12).sum;
			env = EnvGen.kr(
				Env([0, 1, 1, 0], [0.1, duration-0.2, 0.1], [10, 0, 10]));
			Out.ar(filterOutBus, pb * env);
			bf = BFEncode1.ar(out*env, 0, 0);
			Out.ar(outBus, out);
		}),
		SynthDef(\Pinput, {arg gate = 1, inBus, outBus, amp = 1, run = 1;
			var env, in;
			env = EnvGen.kr(Env([0, 1, 0], [0.1, 0.1], \sin, 1), gate, doneAction: 2);
			in = Limiter.ar(In.ar(inBus, 1) * amp * env, 0.5);
			Out.ar(outBus, in);
		}),
		SynthDef(\PinputRec, {arg gate = 1, buffer, startPos = 0, inBus, outBus, amp = 1,
			run = 1;
			var env, in;
			env = EnvGen.kr(Env([0, 1, 0], [0.1, 3], \sin, 1), run, doneAction: 2);
			in = Limiter.ar(In.ar(inBus, 1) * amp * env, 0.5);
			RecordBuf.ar(in.poll(1), buffer, offset: startPos * SampleRate.ir, loop: 0);
			Out.ar(outBus, in);
		}),
		SynthDef(\PLimitScale, {arg gate = 1, inBus, amp = 1, lag = 1;
			var in, env;
			env = EnvGen.kr(Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
			in = In.ar(inBus, 8);
			in = Limiter.ar(in);
			ReplaceOut.ar(inBus, in * (Lag2.kr(amp, lag)));
		}),
		// figure out a way to do this with a specific moment and no warps,

		SynthDef(\PfiltChordPastMoment, {arg gate = 1, inBus, vcBuf, fftBuf1, fftBuf2,
			tPoint, randInSecs, randRate = 0.1, outBus, rBufSecs, loc, spread;
			var point, chain1, chain2, cello, src, filt, filtOut, rev, inEnv, outEnv,
			l, r;
			spread = spread * 0.5;
			inEnv = EnvGen.kr(Env([0, 1, 0], [1, 1], \sin, 1), gate);
			//		outEnv = EnvGen.kr(Env([0, 1, 0], [1, 10], \sin, 1), gate, doneAction: 2);
			src = LeakDC.ar(In.ar(inBus, 1)) * inEnv;
			point = LFNoise2.kr(randRate).range(randInSecs) + tPoint * rBufSecs;
			cello = WarpZ.ar(1, vcBuf, point, 1, 0.11, -1, 6, 0.1, 1, 0.01, 0.1);
			filt = LeakDC.ar(cello);
			chain1 = FFT(fftBuf1, src);
			// if needed, enhance upper bins of chain2 for higher partials
			chain2 = FFT(fftBuf2, filt);
			chain1 = PV_SpectralMap(chain1, chain2, 0.0, 0, 1, 1);
			filt = filt + HPF.ar(HPF.ar(HPF.ar(filt, 1000), 1000, 10), 20);
			filtOut = IFFT(chain1) * 36.dbamp;
			rev = LeakDC.ar(GVerb.ar(filtOut, 140, 8));
			filtOut = LeakDC.ar(Spreader.ar(filtOut));
			l = BFEncode1.ar(filtOut[0] + rev[0], loc - spread);
			r = BFEncode1.ar(filtOut[1] + rev[1], loc + spread);
			Out.ar(outBus, l + r);
		}),
		SynthDef(\PfiltChordCurMoment, {arg gate = 1, inBus, vcIn, fftBuf1, fftBuf2,
			outBus, loc, spread;
			var point, chain1, chain2, cello, src, filt, filtOut, rev, inEnv, outEnv,
			l, r, dummy;
			spread = spread * 0.5;
			inEnv = EnvGen.kr(Env([0, 1, 0], [1, 1], \sin, 1), gate);
			src = LeakDC.ar(In.ar(inBus, 1)) * inEnv;
			cello = In.ar(vcIn, 1);
			filt = LeakDC.ar(cello); //PitchShift.ar(cello, 0.11, 0.95, 0, 0.01));
			// if needed, enhance upper bins of chain2 for higher partials
			filt = filt + HPF.ar(HPF.ar(HPF.ar(filt, 1000, 3.dbamp), 1000, 1), 1000);
			chain1 = FFT(fftBuf1, src);
			chain2 = FFT(fftBuf2, filt);
			chain1 = PV_SpectralMap(chain1, chain2, 0.0, Line.kr(-1, 1, 2), 1, 1);
			filtOut = Limiter.ar(
				CompanderD.ar(IFFT(chain1) * 48.dbamp,
					0.125, 1, 0.2, 0.01, 2),
				-12.dbamp, 0.01);
			// revtime was 25, damping 0.5
			rev = LeakDC.ar(GVerb.ar(filtOut, 140, 15, damping: 0.3, drylevel: 0.5));
			l = BFEncode1.ar(filtOut + rev.sum, loc);
			Out.ar(outBus, l);
		}),
		SynthDef(\PplaybackPoint, {arg buffer, outBus, pan, panRand, grainDur, grainDurRand,
			grainRate, grainRateRand, playPos, playPosRand, rBufSecs, envbuf = -1,
			effectSend = 99, effectSendAmp = 0;
			var trig, loc, grains, dur, pos, env;
			trig = Impulse.kr(LFNoise1.kr(0.2, grainRateRand, grainRate));
			loc = TRand.kr(pan - panRand, pan + panRand, trig);
			dur = TRand.kr(grainDur * (1 - grainDurRand), grainDur * (1 + grainDurRand), trig);
			pos = TRand.kr(playPos, playPos + playPosRand, trig) * rBufSecs;
			grains = BufGrainBBF.ar(trig, dur, buffer, grainRate, pos, envbuf, loc, 0, 1, 1);
			//		grains = GrainBuf.ar(2, trig, dur, buffer, 1, 0, 1, loc, envbuf);
			Out.ar(outBus, grains * -12.dbamp);
			Out.ar(effectSend, grains[0] * effectSendAmp)
		}),
		SynthDef(\PplaybackChase, {arg buffer, outBus, pan, panRand, grainDur, grainDurRand,
			grainRate, grainRateRand, playPos, playPosRand, rBufSecs, envbuf = -1,
			effectSend = 99, effectSendAmp = 0;
			var trig, loc, grains, dur, pos, env;
			trig = Impulse.kr(LFNoise1.kr(0.2, grainRateRand, grainRate));
			loc = TRand.kr(pan - panRand, pan + panRand, trig);
			dur = TRand.kr(grainDur * (1 - grainDurRand), grainDur * (1 + grainDurRand), trig);
			pos = (TRand.kr(playPos, playPos + playPosRand, trig) + Sweep.kr(1, 1)) * rBufSecs;
			grains = BufGrainBBF.ar(trig, dur, buffer, grainRate, pos, envbuf, loc, 0, 1, 1);
			Out.ar(outBus, grains);
			Out.ar(effectSend, grains[0] * effectSendAmp)
		}),
		// pan to -1 for mono routing
		SynthDef(\PpshiftWin, {arg inBus, outBus, pan = 0, noteDur = 1, level = 1, pshift = 1;
			var in, ps, env, envGen;
			env = Control.names([\env]).kr(Env.newClear(8).asArray);
			envGen = EnvGen.kr(env, timeScale: noteDur, levelScale: level, doneAction: 2);
			in = In.ar(inBus, 1);
			ps = PitchShift.ar(in, 0.11, pshift, 0, 0.02);
			Out.ar(outBus, BFEncode1.ar(ps * envGen, pan));
		}),
		SynthDef(\Ppshift, {arg gate = 1, inBus, outBus, pan = 0, level = 1, pshift = 1;
			var in, ps, env, envGen;
			env = Control.names([\env]).kr(Env.newClear(8).asArray);
			envGen = EnvGen.kr(env, gate, doneAction: 2) * level;
			in = In.ar(inBus, 1);
			ps = PitchShift.ar(in, 0.11, pshift, 0, 0.02);
			Out.ar(outBus, BFEncode1.ar(ps * envGen, pan));
		}),
		SynthDef(\Pperc, {arg outBus, buffer, rate = 1, starttime = 0, centerfreq = 440, amp, dur,
			srcBoost = 1, loc;
			var src, amptrack, noise, envTrack, filt, env, envGen;
			src = PlayBuf.ar(1, buffer, rate, 1, starttime * BufSampleRate.kr(buffer));
			env = Control.names([\env]).kr(Env.newClear.asArray);
			envGen = EnvGen.kr(env, doneAction: 2, timeScale: dur);
			envTrack = Amplitude.ar(src).max(0.001);
			noise = Resonz.ar(LPF.ar(GrayNoise.ar, 1000 + (4000 * envTrack)) * envTrack,
				centerfreq * [0.49, 0.7, 1, 2.03, 4.2], 0.01).sum;
			Out.ar(outBus, BFEncode1.ar((noise * envGen), loc));
		}),
		SynthDef(\PfiltWin, {arg outBus, inBus, dur, inDur, freq, loc;
			var src, filt, env, envGen;
			env = Control.names([\env]).kr(Env.newClear.asArray);
			envGen = EnvGen.kr(env, doneAction: 2, timeScale: dur);
			src = In.ar(inBus, 1) * EnvGen.kr(Env([0, 1, 0], [0.1, 0.9], [3, -3]), timeScale: inDur);
			filt = CombC.ar(src, 0.1, (freq*[0.5, 0.25]).reciprocal, 3).sum;
			filt = (filt * -24.dbamp) + Resonz.ar(filt, freq, LFNoise2.kr(0.1).range(0.0009, 0.0011)) * envGen;
			filt = Limiter.ar(filt, -12.dbamp);
			Out.ar(outBus, BFEncode1.ar(filt, loc));
		}),
		// can be used to stretch a moment -> also, feed into windowed pitchShifts;
		SynthDef(\PwarpMoment, {arg gate = 1, outBus, pan = 1, buf,
			pointStart, pointEnd;
			var warp, point;
			point = LFNoise2.kr(0.1).range(pointStart, pointEnd).dup(3);
			warp = WarpZ.ar(1, buf, point, 1, 0.11, -1, 6, 0.1, 1, 0.01, 0.01);
			Out.ar(outBus, BFEncode1.ar(warp, pan));
		}),
		// an EQd version of spotlight
		SynthDef(\Pspotlight, {arg buffer, loc, startPos, rate, pShift = 1, dur, outBus;
			var point, cf, cfgen, width, widthgen, mono, filt, gvl, gvr, locSpread;
			point = Line.kr(startPos, startPos + (dur * rate), dur) / BufDur.kr(buffer);
			mono = WarpZ.ar(1, buffer, point, pShift, 0.11, -1, 6, 0.1, 4, 0.01, 0.01);
			cf = EnvGen.kr(
				Control.names([\cf]).kr(Env.newClear(4)), timeScale: dur);
			width = EnvGen.kr(
				Control.names([\width]).kr(Env.newClear(4)), timeScale: dur);
			filt = BPeakEQ.ar(mono * 0.01, (cf * LFNoise2.kr(0.2).range(0.95, 1.05).dup(4)) *
				[0, 3, 5, 7].midiratio, width, 60).sum;
			filt = filt + BPeakEQ.ar(mono * 0.01, cf * [0, 3, 5, 7].midiratio, width * 10, 24).sum;
			#gvl, gvr = GVerb.ar(filt, 140, 6, spread: 45, maxroomsize: 141);
			locSpread = LFNoise1.kr(0.1).range(0.05, 0.15);
			Out.ar(outBus, BFEncode1.ar(gvl, loc - locSpread) +
				BFEncode1.ar(gvr, loc + locSpread) *
				EnvGen.kr(Control.names([\env]).kr(Env.newClear(8)),
					timeScale: dur,
					doneAction: 2))
		}),
		// bandpassed version
		SynthDef(\PspotlightBP, {arg buffer, loc, startPos, rate, pShift = 1,
			dur, outBus, amp = 1, cf, width;
			var point, mono, filt, gvl, gvr, locSpread;
			point = Line.kr(startPos, startPos + (dur * rate), dur) / BufDur.kr(buffer);
			mono = WarpZ.ar(1, buffer, point, pShift, 0.11, -1, 6, 0.1, 4,
				0.01, 0.01);
			cf = cf * LFNoise2.kr(0.05).range(0.95, 1.02);
			width = width * LFNoise2.kr(0.05).range(0.95, 1.02);
			filt = BBandPass.ar(mono * 0.01, (cf * LFNoise2.kr(0.2).range(0.95, 1.05).dup(4)) *
				[0, 3, 5, 7].midiratio, width, 60).sum;
			filt = filt + BBandPass.ar(mono * 0.01, cf * [0, 3, 5, 7].midiratio, width, 24).sum;
			#gvl, gvr = GVerb.ar(filt, 140, 6, spread: 90, maxroomsize: 141);
			locSpread = LFNoise1.kr(0.1).range(0.05, 0.15);
			Out.ar(outBus, BFEncode1.ar(gvl, loc - locSpread) +
				BFEncode1.ar(gvr, loc + locSpread) * amp *
				EnvGen.kr(Control.names([\env]).kr(Env.newClear(8)),
					timeScale: dur,
					doneAction: 2))		}),
		SynthDef(\PbarkDel, {arg gate = 1, timeScale = 1, inBus, outBus, loc,
			width = 0.9, freqmul = 0.95, maxdel = 1;
			var in, out, env, deltimes, feedback, bd, amps;
			env = Control.names([\env]).kr(Env.newClear(4).asArray);
			deltimes = Control.names([\deltimes]).kr(Array.fill(25, {0.5.rrand(1.0)}));
			feedback = Control.names([\feedback]).kr(Array.fill(25, {0.7.rrand(0.9)}));
			amps = Control.names([\amps]).kr(Array.fill(25, {1}));
			in = PitchShift.ar(In.ar(inBus), 0.11, freqmul, 0, 0.01);
			bd = BarkDelay.ar(in, deltimes, feedback, amps, maxdel, width, freqmul);
			Out.ar(outBus,
				BFEncode1.ar(bd.sum *
					EnvGen.kr(env, gate, timeScale: timeScale, doneAction: 2),
					loc));
		})
	);

	notes.load(s);

	/* ProcMods */
	init = ProcMod.new.function_({
		Routine({
			"Started".postln;
			isPlaying = true;
			usePracticeBuffer.if({
				/*				(pevents.index == 0).if({
				("proc events"++pevents.index).postln;
				notes[\PpracticePlayback].note(server: s, target: 0, addAction: 0)
				.buffer_(practiceBuffer).outBus_(celloIn).play;
				celloIn = notes[\Pinput].note(server: s, target: 0, addAction: 0)
				.inBus_(celloIn).amp_(0.dbamp)
				.outBus_(celloBus).play;
				})*/

			}, {
				celloNote = notes[\PinputRec].note(server: s, target: 0, addAction: 0)
				.inBus_(celloIn).amp_(0.dbamp)
				.outBus_(celloBus).buffer_(celloBuf).play;



			});
			{decoder.playGUI}.defer;
			1.wait;
			limit = notes[\PLimitScale].note(server: s,
				addAction: \tail, target: 0).inBus_(0).play;
		});
	});
	kill = {
		[celloIn, celloBus, grainBuf, bfBus, filterBus, mainEffectBus].do({arg me;
			me.free;
		});
		celloAna.stop;
		celloAna.close;
		practiceBuffer.notNil.if({
			practiceBuffer.free;
		});
		decoder.notNil.if({
			decoder.window.close;
		});
		limit.release;
		useIPad.if({
			{~setupIPad.value;}.defer(0.1);
			~oui.clearPage;
		});
		//~oui.clearPage;
		writeBufs.if({
			SystemClock.sched(0.1, {
				Routine.run({
					var stamp;
					stamp = Date.getDate.stamp;
					celloBuf.write(path: ("~/Desktop/Recs/"++Date.getDate.stamp++"PassacagliaCello.aif").standardizePath, sampleFormat: "float");
					s.sync(cond);
					"Written".postln;
					//							AppClock.sched(1.0, {(String.scDir ++ "/CorpiSonori.scd").load;});
					[celloBuf].do({arg me;
						me.free;
					});
				})
			})
		}, {
			[celloBuf].do({arg me;
				me.free;
			});
			// AppClock.sched(1.0, {(String.scDir ++ "/CorpiSonori.scd").load;});
		});
	};

	processInput = {arg id, amp, env, outBus, effectSend, buffer, playPointStart, playPointEnd,
		cleanOutBus = 0, cleanOutScaler = 0;
		ProcModR(env, amp, 1, outBus, id, addAction: 0, target: 0, server: s)
		.function_({arg group, routeBus, server, pm;
			var startPoint, endPoint, noteDur;
			// if we are testing, just use the celloBuf
			startPoint = pevents.stamp(playPointStart);
			endPoint = pevents.stamp(playPointEnd);
			noteDur = endPoint - startPoint;
			usePracticeBuffer.if({
				noteDur = buffer.duration;
			});
			notes[\PinputPlayback].note(duration: noteDur,
				target:group, server: server)
			.buffer_(buffer)
			.outBus_(routeBus)
			.duration_(noteDur)
			.startPos_(startPoint)
			.filterOutBus_(effectSend)
			.play;
			//		SynthDef(\PinputPlayback, {arg outBus, duration, buffer, startPos;
		})
	};

	noiseProcessInput = {arg id, amp, env, outBus, effectSend, buffer, playPointStart, playPointEnd,
		cleanOutBus = 0, cleanOutScaler = 0;
		ProcModR(env, amp, 1, outBus, id, addAction: 0, target: 0, server: s)
		.function_({arg group, routeBus, server, pm;
			var startPoint, endPoint, noteDur;
			// if we are testing, just use the celloBuf
			startPoint = pevents.stamp(playPointStart);
			endPoint = pevents.stamp(playPointEnd);
			noteDur = endPoint - startPoint;
			usePracticeBuffer.if({
				noteDur = buffer.duration;
			});
			notes[\PnoisePlayback].note(duration: noteDur,
				target:group, server: server)
			.buffer_(buffer)
			.outBus_(routeBus)
			.duration_(noteDur)
			.startPos_(startPoint)
			.filterOutBus_(effectSend)
			.play;
			//		SynthDef(\PinputPlayback, {arg outBus, duration, buffer, startPos;
		})
	};

	stretchPlayBack = {arg id, amp, env, outBus, buffer, playPoint, stretches;
		ProcModR(env, amp, 4, outBus, id, addAction: 0, target: 0, server: s)
		.function_({arg group, routeBus, server, pm;
			stretches.do({arg thisStretch;
				/*
				SynthDef(\PstretchPlayback, {arg outBus, buffer, startPos, stretch, loc;
				*/
				notes[\PstretchPlayback].note(target:group, server: server)
				.outBus_(routeBus)
				.buffer_(buffer)
				.startPos_(pevents.stamp(playPoint))
				.stretch_(thisStretch)
				.loc_(0.25pi.rand2)
				.play;

			});
		});
	};
	// playPoint and pointRand are time stamps from pevents
	playbackPoint = {arg id, amp, env, outBus, buffer, playPoint, pointRand,
		grainDur = 16, grainDurRand = 0.2, grainRate = 1, grainRateRand = 0.2,
		effectSend, effectSendAmp = 0;

		ProcModR(env, amp, 4, outBus, id, addAction: 0, target: 0, server: s)
		.function_({arg group, routeBus, server, pm;
			playPoint = pevents.stamp(playPoint);
			notes[\PplaybackPoint].note(target: group, server: server)
			.buffer_(buffer).outBus_(routeBus).pan_(0).panRand_(pi)
			.grainDur_(grainDur).grainDurRand_(grainDurRand).grainRate_(grainRate)
			.grainRateRand_(grainRateRand).playPos_(playPoint)
			.playPosRand_(pointRand).rBufSecs_(rBufTime)
			.envbuf_(grainBuf
				.effectSend_(effectSend).effectSendAmp_(effectSendAmp)
			).play;
		})
	};

	// playPoint and pointRand are time stamps from pevents
	playbackChase = {arg id, amp, env, outBus, buffer, playPoint, pointRand,
		grainDur = 16, grainDurRand = 0.2, grainRate = 1, grainRateRand = 0.2,
		effectSend, effectSendAmp = 0;
		ProcModR(env, amp, 4, outBus, id, addAction: 0, target: 0, server: s)
		.function_({arg group, routeBus, server, pm;
			playPoint = pevents.stamp(playPoint);
			notes[\PplaybackChase].note(target: group, server: server)
			.buffer_(buffer).outBus_(routeBus).pan_(0).panRand_(pi)
			.grainDur_(grainDur).grainDurRand_(grainDurRand).grainRate_(grainRate)
			.grainRateRand_(grainRateRand).playPos_(playPoint)
			.playPosRand_(pointRand).rBufSecs_(rBufTime)
			.envbuf_(grainBuf)
			.effectSend_(effectSend).effectSendAmp_(effectSendAmp).play;
		})
	};

	// make sure 'delay' is in the global Env as well
	filtCurChord = {arg id, amp, env, outBus, inBus, loc = 0, delay = 1, serverIn;
		ProcModR(env, amp, 4, outBus, id, addAction: 3, target: 1, server: serverIn)
		.function_({arg group, routeBus, server, pm;
			Task({
				var fft1, fft2;
				fft1 = CtkBuffer.buffer(4096, server: server).load;
				fft2 = CtkBuffer.buffer(4096, server: server).load;
				pm.releaseFunc_({
					SystemClock.sched(1.0, {
						fft1.free; fft2.free; ("FFT bufs freed for"+id).postln;
					});
				});
				server.sync;
				delay.wait;
				notes[\PfiltChordCurMoment].note(target: group, server: server)
				.inBus_(inBus)
				.vcIn_(inBus).fftBuf1_(fft1).fftBuf2_(fft2)
				.outBus_(routeBus)
				.loc_(loc * pi).spread_(0.25).play;
			})
		})
	};

	// loc and harms can be single values or patterns
	/* oooh! cool: Env([0, 1, 0], [10, 10]).asStream + Pwhite(0.0, 0.1).asStream
	can work for .asStream parameters!
	*/
	warpHarm = {arg id, amp, env, outBus, playPoint, pointRandSecs, loc, harms, overlaps,
		winDur;
		ProcModR(env, amp, 4, bfBus.bus, id, addAction: 0, target: 1, server: 1)
		.function_({arg group, routeBus, server, pm;
			Task({
				var src, route, start, end, wait, next, noteDur;
				route = CtkAudio.new(2, server: server).play;
				pm.releaseFunc_({route.free});
				start = pevents.stamp(playPoint) + 2;
				end = (start + pointRandSecs) * rBufTime;
				start = start * rBufTime;
				loc = loc.asStream;
				harms = harms.asStream;
				overlaps = overlaps.asStream;
				winDur = winDur.asStream;
				src = notes[\PwarpMoment].note(target: group, server: server)
				.outBus_(route).pan_(-1)
				.buf_(celloBuf).pointStart_(start).pointEnd_(end).play;
				// the windows that do the pitchShifting - remember the env
				loop({
					next = (noteDur = winDur.next) / overlaps.next;
					notes[\PpshiftWin].note(addAction: 1, target: group,
						server: server)
					.inBus_(route).outBus_(routeBus).pan_(loc.next * 0.5pi)
					.noteDur_(noteDur).pshift_(harms.next.midiratio)
					.env_(Env([0, 1, 1, 0], [0.2, 0.6, 0.2], \sin)).play;
					next.wait;
				})
			})
		})
	};

	inHarm = {arg id, amp, env, outBus, inBus, pointRandSecs, loc, harms, overlaps,
		winDur;
		ProcModR(env, amp, 4, bfBus.bus, id, addAction: 0, target: 1, server: 2)
		.function_({arg group, routeBus, server, pm;
			Task({
				var src, route, wait, next, noteDur;
				route = CtkAudio.new(2, server: server).play;
				pm.releaseFunc_({route.free});
				loc = loc.asStream;
				harms = harms.asStream;
				overlaps = overlaps.asStream;
				winDur = winDur.asStream;
				// the windows that do the pitchShifting - remember the env
				loop({
					next = (noteDur = winDur.next) / overlaps.next;
					notes[\PpshiftWin].note(addAction: 1, target: group,
						server: server)
					.inBus_(inBus).outBus_(routeBus).pan_(loc.next * 0.5pi)
					.noteDur_(noteDur).pshift_(harms.next.midiratio)
					.env_(Env([0, 1, 1, 0], [0.2, 0.6, 0.2], \sin)).play;
					next.wait;
				})
			})
		});
	};

	inHarmBank = {arg id, amp, env, outBus, inBus, harms, levels, loc;
		//(\Ppshift, {arg gate = 1, inBus, outBus, pan = 0, level = 1, pshift = 1;
		ProcModR(env, amp, 4, bfBus.bus, id, addAction: 0, target: 1, server: s)
		.function_({arg group, routeBus, server, pm;
			harms.asArray.do({arg thisHarm, i;
				var level;
				levels.isKindOf(Array).if({
					level = levels.wrapAt(i);
				}, {
					level = levels.value(i);
				});
				("harm " ++ thisHarm).postln;
				notes[\Ppshift].note(addAction: 1, target: group, server: server)
				.env_(Env([0, 1, 0], [0.1, 0.1], \sin, 1))
				.inBus_(inBus)
				.outBus_(routeBus)
				.pan_(loc.value)
				.level_(level)
				.pshift_(thisHarm)
				.play;
			});
			notes[\PfilterSend].note(addAction: 3, target: group, server:server)
			.inBus_(routeBus).outBus_(filterBus)
			.env_(Env([0, 1, 0], [0.1, 0.1], \sin, 1)).play;
		});
	};
	// winDur, overlaps, freqMul and loc can be values or patterns
	barkDel = {arg id, amp, env, outBus, inBus, winDur, overlaps, freqMul, loc,
		width = 0.5;
		ProcModR(env, amp, 4, bfBus.bus, id, server: s)
		.function_({arg group, routeBus, server, pm;
			Task({
				var next, noteDur, times, amps, fb, winEnv;
				notes[\PfilterSend].note(addAction: 3, target: group, server:server)
				.inBus_(routeBus).outBus_(filterBus)
				.env_(Env([0, 1, 0], [0.1, 0.1], \sin, 1)).play;
				winDur = winDur.asStream;
				overlaps = overlaps.asStream;
				freqMul = freqMul.asStream;
				loc = loc.asStream;
				width = width.asStream;
				winEnv = Env([0, 1, 1, 0], [0.2, 0.3, 0.5], [4, 0, -6]);
				loop({
					next = (noteDur = winDur.next) / overlaps.next;
					times = Array.fill(25, {0.25.rrand(0.55)});
					amps = Array.fill(25, {arg i; 0.5 + (i * 0.01).rand});
					fb = Array.fill(25, {arg i; 0.45 + (i * 0.02).rand});
					notes[\PbarkDel].note(target: group, server: server)
					.timeScale_(noteDur).inBus_(inBus).outBus_(routeBus)
					.loc_(loc.next * 0.5pi)
					.width_(width.next).freqmul_(freqMul.next)
					.maxdel_(0.6).env_(winEnv).deltimes_(times)
					.feedback_(fb).amps_(amps).play;
					next.wait;
				})
			})
		})
	};

	perc = {arg id, amp, env, outBus, buffer, startPoints, loc, rates, winDur,
		overlaps, baseFreq, freqMul;
		ProcModR(env, amp, 4, bfBus.bus, id, server: s)
		.function_({arg group, routeBus, server, pm;

			Task({
				var next, noteDur, winEnv, thisPoint;
				notes[\PfilterSend].note(addAction: 3, target: group, server:server)
				.inBus_(routeBus).outBus_(filterBus)
				.env_(Env([0, 1, 0], [0.1, 0.1], \sin, 1)).play;
				startPoints = startPoints.asStream;
				rates = rates.asStream;
				winDur = winDur.asStream;
				overlaps = overlaps.asStream;
				baseFreq = baseFreq.asStream;
				freqMul = freqMul.asStream;
				loc = loc.asStream;
				winEnv = Env([0, 1, 1, 0], [0.2, 0.6, 0.2], \sin);
				loop({
					thisPoint = pevents.stamp(startPoints.next).postln + 10.0.rand;
					next = (noteDur = winDur.next) / overlaps.next;
					notes[\Pperc].note(target: group, server: server)
					.outBus_(routeBus).buffer_(buffer).rate_(rates.next)
					.starttime_(thisPoint)
					.centerfreq_(baseFreq.next.value * freqMul.next).amp_(1)
					.dur_(noteDur).loc_(loc.next * 0.5pi).env_(winEnv).play;
					next.wait;
				})
			})
		})
	};

	spotBP = {arg id, amp, env, outBus, startPoints, loc, rates, winDur,
		overlaps, baseFreq, widths, randTimeInSecs = 30.0;
		ProcModR(env, amp, 4, bfBus.bus, id, server: s)
		.function_({arg group, routeBus, server, pm;
			Task({
				var next, noteDur, winEnv, thisPoint;
				notes[\PfilterSend].note(addAction: 3, target: group, server:server)
				.inBus_(routeBus).outBus_(filterBus)
				.env_(Env([0, 1, 0], [0.1, 0.1], \sin, 1)).play;
				startPoints = startPoints.asStream;
				rates = rates.asStream;
				winDur = winDur.asStream;
				overlaps = overlaps.asStream;
				baseFreq = baseFreq.asStream;
				loc = loc.asStream;
				widths = widths.asStream;
				winEnv = Env([0, 1, 1, 0], [0.2, 0.6, 0.2], \sin);
				loop({
					thisPoint = pevents.stamp(startPoints.next) + randTimeInSecs.rand;
					next = (noteDur = winDur.next.value) / overlaps.next.value;
					notes[\PspotlightBP].note(target: group, server: server)
					.outBus_(routeBus).buffer_(celloBuf).rate_(rates.next)
					.startPos_(thisPoint).cf_(baseFreq.next).pShift_(1)
					.width_(widths.next).amp_(1).dur_(noteDur)
					.loc_(loc.next * 0.5pi).env_(winEnv).play;
					next.wait;
				})
			})
		})
	};

	cascadingFilts = {arg id, amp, env, outBus, inBus, partials, winDur, overlaps;
		ProcModR(env, amp, 4, bfBus.bus, id, server: s)
		.function_({arg group, routeBus, server, pm, i;
			Task({
				var next, noteDur, winEnv, loc, locInc;
				notes[\PfilterSend].note(addAction: 3, target: group, server:server)
				.inBus_(routeBus).outBus_(filterBus)
				.env_(Env([0, 1, 0], [0.1, 0.1], \sin, 1)).play;
				winDur = winDur.asStream;
				overlaps = overlaps.asStream;
				partials = partials.asStream;
				//SynthDef(\PfiltWin, {arg outBus, inBus, dur, freq, loc;
				loc = 0;
				locInc = 0.3pi;
				winEnv = Env([0, 1, 1, 0], [0.2, 0.6, 0.2], \sin);
				i = 0;
				loop({
					var baseFreq, next, dur;
					baseFreq = celloAna.freq;
					dur = winDur.next;
					next = dur / overlaps.next;
					notes[\PfiltWin].note(target: group, server: server)
					.outBus_(routeBus)
					.inBus_(inBus)
					.inDur_(1)
					.dur_(dur)
					.freq_(baseFreq * partials.next)
					.loc_(loc)
					.env_(winEnv)
					.play;
					loc = loc + locInc;
					next.wait;
				});
			})
		});
	};

	pevents = ProcEvents([
		/*	0	*/		[nil, nil],
		/*	1	*/		[{celloNote.notNil.if({celloNote.run_(0)})}, nil],
		// = {arg id, amp, env, outBus, buffer, playPointStart, playPointEnd;
		/*  2   */      [
			[
				processInput.value(id: \pbEv2,
					amp:1,
					buffer: celloBuf,
					effectSend: filterBus,
					outBus: bfBus,
					env:Env([0, 1, 0], [0.1, 0.1], \sin, 1),
					playPointStart:0,
					playPointEnd:1,
				),
			],
			nil
		],
		/*  3   */      [
			[
				//filtCurChord = {arg id, amp, env, outBus, inBus, loc = 0, delay = 1, serverIn;
				filtCurChord.value(id: \filtEv3,
					amp: -24.dbamp,
					env:Env([0, 0, 1, 0], [0.1, 1, 10], \sin, 2),
					outBus:bfBus,
					inBus:filterBus,
					loc: 0,
					delay: 0.1,
					serverIn: s)

			],
			nil
		],
		/*  4   */      [
			[
				filtCurChord.value(id: \filtEv4,
					amp: -24.dbamp,
					env:Env([0, 0, 1, 0], [0.1, 1, 10], \sin, 2),
					outBus:bfBus,
					inBus:filterBus,
					loc: 0.5,
					delay: 0.1,
					serverIn: s)

			],
			nil
		],
		/*  5   */      [
			[
				filtCurChord.value(id: \filtEv5,
					amp: -24.dbamp,
					env:Env([0, 0, 1, 0], [0.1, 1, 10], \sin, 2),
					outBus:bfBus,
					inBus:filterBus,
					loc: 1.5,
					delay: 0.1,
					serverIn: s)

			],
			nil
		],
		/*  6   */      [
			[
				filtCurChord.value(id: \filtEv6,
					amp: -24.dbamp,
					env:Env([0, 0, 1, 0], [0.1, 1, 10], \sin, 2),
					outBus:bfBus,
					inBus:filterBus,
					loc: 0.3,
					delay: 0.1,
					serverIn: s)

			],
			nil
		],
		/*  7   */      [
			[
				filtCurChord.value(id: \filtEv7,
					amp: -24.dbamp,
					env:Env([0, 0, 1, 0], [0.1, 1, 10], \sin, 2),
					outBus:bfBus,
					inBus:filterBus,
					loc: 1.0,
					delay: 0.1,
					serverIn: s)

			],
			nil
		],
		/*  8   */      [
			[
				filtCurChord.value(id: \filtEv8,
					amp: -24.dbamp,
					env:Env([0, 0, 1, 0], [0.1, 1, 10], \sin, 2),
					outBus:bfBus,
					inBus:filterBus,
					loc: -0.3,
					delay: 0.1,
					serverIn: s)

			],
			nil
		],
		/*  9   */      [
			[
				processInput.value(id: \pbEv9,
					amp:1,
					buffer: celloBuf,
					effectSend: mainEffectBus,
					outBus: bfBus,
					env:Env([0, 1, 0], [0.1, 0.1], \sin, 1),
					playPointStart:0,
					playPointEnd:1,
				),
				inHarmBank.value(id: \inHarm9,
					amp:1,
					env:Env([0, 1, 0], [0.1, 10], releaseNode: 1),
					outBus:bfBus,
					inBus:mainEffectBus,
					harms:[-12, -7, 5, 7, 12, 17, 19].midiratio.collect({arg baseVal;
						CtkControl.lfo(LFNoise2, 1.0.rrand(0.4),
							CtkControl.env(Env([baseVal*1, baseVal*1, baseVal*0.95],
								[10, 10])),
							CtkControl.env(Env([baseVal*1, baseVal*1, baseVal*1.05],
								[10, 10])))}),
					levels:[-6, -6, -12, -3, -12, -18].dbamp.collect({arg baseVal, i;
						CtkControl.env(Env([-90.dbamp, baseVal], [(i+1)*2]))
					}),
					loc:{0.5.rand2});
				// 	inHarmBank = {arg id, amp, env, outBus, inBus, harms, levels, loc;
			],
			\pbEv2
		],
		/*  10  */      [
			[
				processInput.value(id: \pbEv10,
					amp:0,
					buffer: celloBuf,
					effectSend: mainEffectBus,
					outBus: bfBus,
					env:Env([0, 1, 0], [0.1, 0.1], \sin, 1),
					playPointStart:0,
					playPointEnd:1,
				),
				inHarmBank.value(id: \inHarm10,
					amp:1,
					env:Env([0, 1, 0], [0.1, 10], releaseNode: 1),
					outBus:bfBus,
					inBus:mainEffectBus,
					harms:[24, 23, 22.5, 22.1, 21.7, 21].midiratio.collect({arg baseVal;
						CtkControl.lfo(LFNoise2, 1.0.rrand(0.4),
							CtkControl.env(Env([baseVal*1, baseVal*1, baseVal*0.95],
								[10, 10])),
							CtkControl.env(Env([baseVal*1, baseVal*1, baseVal*1.05],
								[10, 10])))}),
					levels:[-18, -18, -18, -18, -18, -18].dbamp.collect({arg baseVal, i;
						CtkControl.lfo(LFNoise2, 0.5, baseVal*(-12.dbamp), baseVal)
					}),
					loc:{pi.rand2})
				// 	inHarmBank = {arg id, amp, env, outBus, inBus, harms, levels, loc;
			],
			[\pbEv9, \inHarm9]
		],
		/*   11   */     [
			[
				processInput.value(id: \pbEv11,
					amp:-24.dbamp,
					buffer: celloBuf,
					effectSend: mainEffectBus,
					outBus: bfBus,
					env:Env([0, 1, 0], [0.1, 0.1], \sin, 1),
					playPointStart:0,
					playPointEnd:1,
				),
				barkDel.value(id: \barkDel11a,
					amp:1,
					env:Env([0, 1, 0], [0.1, 20], [\sin, -4], 1),
					outBus:bfBus,
					inBus: mainEffectBus,
					winDur: 14,
					overlaps: 7,
					freqMul: {0.9.rrand(1.1)},
					loc:{pi.rand2},
					width: 0.5),
				barkDel.value(id: \barkDel11b,
					amp:1,
					env:Env([0, 1, 0], [0.1, 20], [\sin, -4], 1),
					outBus:bfBus,
					inBus: mainEffectBus,
					winDur: 16,
					overlaps: 5,
					freqMul: {1.9.rrand(2.1)},
					loc:{pi.rand2},
					width: 0.5),
				//	cascadingFilts = {arg id, amp, env, outBus, inBus, partials, winDur, overlaps;
				cascadingFilts.value(id: \filts11a,
					amp:1,
					env:Env([0, 1, 0], [0.1, 20], [\sin, -4], 1),
					outBus:bfBus,
					inBus:mainEffectBus,
					partials:{
						var data, pIdx, pData;
						data = (16 .. 30).select({arg i; i.isPrime or: {i.even}});
						pIdx = Pbrown(0, data.size-1, 1, inf);
						pData = Pindex(data, pIdx);
					}.value,
					winDur:6,
					overlaps: 24),
			],
			[\pbEv10, \inHarm10]

		],
		/*   12  */     [
			[
				processInput.value(id: \pbEv12,
					amp:-24.dbamp,
					buffer: celloBuf,
					effectSend: mainEffectBus,
					outBus: bfBus,
					env:Env([0, 1, 0], [0.1, 0.1], \sin, 1),
					playPointStart:0,
					playPointEnd:1,
				),
				cascadingFilts.value(id: \filts12,
					amp:1,
					env:Env([0, 1, 0], [0.1, 20], [\sin, -4], 1),
					outBus:bfBus,
					inBus:mainEffectBus,
					partials:{
						var data, pIdx, pData;
						data = (16 .. 32).select({arg i; i.isPrime or: {i.even}});
						pIdx = Pbrown(0, data.size-1, 1, inf);
						pData = Pindex(data, pIdx);
					}.value,
					winDur:2,
					overlaps: 24),
			],
			[\pbEv11, \barkDel11a, \barkDel11b, \filts11a],

		],

		/* 13 */     [
			[
				processInput.value(id: \pbEv13,
					amp:-24.dbamp,
					buffer: celloBuf,
					effectSend: mainEffectBus,
					outBus: bfBus,
					env:Env([0, 1, 0], [0.1, 0.1], \sin, 1),
					playPointStart:0,
					playPointEnd:1,
				),
				cascadingFilts.value(id: \filts13a,
					amp:1,
					env:Env([0, 1, 0], [0.1, 20], [\sin, -4], 1),
					outBus:bfBus,
					inBus:mainEffectBus,
					partials:{
						var data, pIdx, pData;
						data = (16 .. 32).select({arg i; i.isPrime or: {i.even}});
						pIdx = Pbrown(0, data.size-1, 1, inf);
						pData = Pindex(data, pIdx);
					}.value,
					winDur:2,
					overlaps: Pwrand([24, 18, 12, 6], [0.8, 0.05, 0.1, 0.05], inf);),
				cascadingFilts.value(id: \filts13b,
					amp:1,
					env:Env([0, 1, 0], [0.1, 20], [\sin, -4], 1),
					outBus:bfBus,
					inBus:mainEffectBus,
					partials:{
						var data, pIdx, pData;
						data = (2 .. 8).select({arg i; i.isPrime or: {i.even}});
						pIdx = Pbrown(0, data.size-1, 1, inf);
						pData = Pindex(data, pIdx);
					}.value,
					winDur:8,
					overlaps: Pwrand([12, 6, 3], [0.8, 0.1, 0.1], inf);),
			],
			[\pbEv12, \filts12],

		],
		/* 14 */ [
			[
				playbackChase.value(\pb14,
					amp:-12.dbamp,
					env:Env([0, 1, 0], [0.1, 0.1], \sin, 1),
					outBus:bfBus,
					buffer:celloBuf,
					playPoint:0 ,
					pointRand:0.2,
					grainDur: 8,
					grainDurRand: 0.2,
					grainRate: 1,
					grainRateRand: 0.2,
					effectSend:mainEffectBus,
					effectSendAmp:0.dbamp
				),
				playbackChase.value(\pb148va,
					amp:1,
					env:Env([0, 1, 0], [0.1, 0.1], \sin, 1),
					outBus:bfBus,
					buffer:celloBuf,
					playPoint:0 ,
					pointRand:0.2,
					grainDur: 4,
					grainDurRand: 0.2,
					grainRate: 0.5,
					grainRateRand: 0.2,
					effectSend:mainEffectBus,
					effectSendAmp:0.dbamp
				),
				playbackChase.value(\pb145th,
					amp:1,
					env:Env([0, 1, 0], [0.1, 0.1], \sin, 1),
					outBus:bfBus,
					buffer:celloBuf,
					playPoint:0 ,
					pointRand:0.2,
					grainDur: 6,
					grainDurRand: 0.2,
					grainRate: -7.midiratio,
					grainRateRand: 0.2,
					effectSend:mainEffectBus,
					effectSendAmp:0.dbamp
				),
				inHarmBank.value(id: \inHarm14,
					amp:-9.dbamp,
					env:Env([0, 1, 0], [0.1, 10], releaseNode: 1),
					outBus:bfBus,
					inBus:mainEffectBus,
					harms:[7, 12, 19].midiratio.collect({arg baseVal;
						CtkControl.lfo(LFNoise2, 1.0.rrand(0.4),
							CtkControl.env(Env([baseVal*1, baseVal*1, baseVal*0.95],
								[10, 10])),
							CtkControl.env(Env([baseVal*1, baseVal*1, baseVal*1.05],
								[10, 10])))}),
					levels:[-6, -6, -6].dbamp.collect({arg baseVal, i;
						CtkControl.lfo(LFNoise2, 0.5, baseVal*(-2.dbamp), baseVal*(2.dbamp))
					}),
					loc:{pi.rand2})
			],

			[\pbEv13, \filts13a, \filts13b]
		],

		/*   15   */     [
			[
				noiseProcessInput.value(id: \pbNoiseEv15,
					amp:0.dbamp,
					buffer: celloBuf,
					effectSend: mainEffectBus,
					outBus: bfBus.bus,
					env:Env([0, 1, 0], [0.1, 0.1], \sin, 1),
					playPointStart:0,
					playPointEnd:1,
				),
				barkDel.value(id: \barkDel15a,
					amp:1,
					env:Env([0, 1, 0], [0.1, 20], [\sin, -4], 1),
					outBus:bfBus.bus,
					inBus: mainEffectBus,
					winDur: 14,
					overlaps: 7,
					freqMul: {0.9.rrand(1.1)},
					loc:{pi.rand2},
					width: 0.5),
				barkDel.value(id: \barkDel15b,
					amp:1,
					env:Env([0, 1, 0], [0.1, 20], [\sin, -4], 1),
					outBus:bfBus.bus,
					inBus: mainEffectBus,
					winDur: 16,
					overlaps: 5,
					freqMul: {1.9.rrand(2.1)},
					loc:{pi.rand2},
					width: 0.5)
			],
			[\pb14, \pb148va, \pb145th, \inHarm14]
		],
		/* 16 */  [
			[
				/*
				spotBP = {arg id, amp, env, outBus, startPoints, loc, rates, winDur,
				overlaps, baseFreq, widths, randTimeInSecs = 30.0;
				*/
				spotBP.value(id: \spot16,
					amp:0.dbamp,
					env:Env([0, 1, 0], [1, 30], [4, -4], 1),
					outBus: bfBus.bus,
					startPoints: [0],
					loc:{pi.rand2},
					rates:1,
					winDur:{10.0.rrand(15.0)},
					overlaps: 3,
					baseFreq: {131 * [1, 2, 3, 4, 6, 8, 12, 16].choose},
					widths: 0.1,
					randTimeInSecs: 30);
			],
			[\pbNoiseEv15, \barkDel15a, \barkDel15b]
		],
		/*  17 */ [
			[
				/*
				stretchPlayBack = {arg id, amp, env, outBus, buffer, playPoint, stretches;
				*/
				stretchPlayBack.value(id: \stretch17,
					amp: -30.dbamp,
					env: Env([0, 1, 0], [10, 20], [4, -4], 1),
					outBus:bfBus.bus,
					buffer:celloBuf,
					playPoint: 0,
					stretches: [1, 0.9, 0.708, 0.6, 0.5, 0.3])
			],
			nil,

		],
		/* 18 */ [
			nil,
			[\stretch17]
		],
		/*  19 */ [
			nil,
			[\spot16],
		],

		/* END */
		[
			nil,
			[\filtEv3, \filtEv4, \filtEv5, \filtEv6, \filtEv7, \filtEv8]
		]
	],
	1, init, kill, "Passacaglia");

	pevents.perfGUI;
	p = pevents;
	pevents.showPMGUIs = true;
	recPath = ("~/Desktop/Recs/"++Date.getDate.stamp).standardizePath;
	("mkdir "++recPath).unixCmd;
	pevents.record(recPath ++"/", true, 'aiff', 'float');
	useIPad.if({
	pevents.onEvent_({arg event;
		var lastPage;
		{~setupIPad.value;}.defer(0.1);
	});

	});
});


)