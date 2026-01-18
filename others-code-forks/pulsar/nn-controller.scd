(
// original code from here: https://learn.flucoma.org/learn/regression-neural-network/
~paramsbuf = Buffer.alloc(s,10);
~init_controller = {
  var synth, multislider, win, xyslider;
	var xydata = FluidDataSet(s);
	var paramsdata = FluidDataSet(s);
	var xybuf = Buffer.alloc(s,2);
	var counter = 0;
	var predicting = false;
	var mlp = FluidMLPRegressor(s,
		[7],
		activation:FluidMLPRegressor.sigmoid,
		outputActivation:FluidMLPRegressor.sigmoid,
		maxIter: 1000,
		learnRate:0.1,
		batchSize:1,
		validation:0
	);


	~paramsbuf = Buffer.alloc(s,10);

	win = Window("ChaosSynth", Rect(10, 10, 840, 320)).front;

	multislider = MultiSliderView(win,Rect(10, 10, 400, 300))
	.elasticMode_(1)
	.isFilled_(1)
	.action_({
		arg ms;
		~paramsbuf.setn(0,ms.value);
	})
	.value_(0.5.dup(10));

	xyslider = Slider2D(win,Rect(420,10,300,300))
	.action_{
		arg view;
		xybuf.setn(0,[view.x,view.y]);

		if(predicting){
			mlp.predictPoint(xybuf,~paramsbuf,{
				~paramsbuf.getn(0,10,{
					arg prediction;
					defer{
						multislider.value_(prediction);
					}
				});
			});
		};
	};

	Button(win,Rect(730,10,100,20))
	.states_([["Add Points"]])
	.action_{
		var id = "point-%".format(counter);
		xydata.addPoint(id,xybuf);
		paramsdata.addPoint(id,~paramsbuf);
		counter = counter + 1;

		xydata.print;
		paramsdata.print;
	};

	Button(win,Rect(730,40,100,20))
	.states_([["Save Data"]])
	.action_{
		FileDialog({
			arg folder;
			folder.postln;
			xydata.write(folder+/+"xydata.json");
			paramsdata.write(folder+/+"paramsdata.json");
		},{},2,0,true);
	};

	Button(win,Rect(730,70,100,20))
	.states_([["Load Data"]])
	.action_{
		FileDialog({
			arg folder;
			xydata.read(folder+/+"xydata.json");
			paramsdata.read(folder+/+"paramsdata.json");
		},fileMode:2,acceptMode:0,stripResult:true);
	};

	Button(win,Rect(730,100,100,20))
	.states_([["Train"]])
	.action_{
		mlp.fit(xydata,paramsdata,{
			arg loss;
			loss.postln;
		});
	};

	Button(win,Rect(730,130,100,20))
	.states_([["Save MLP"]])
	.action_{
		Dialog.savePanel({
			arg path;
			if(PathName(path).extension != "json"){
				path = "%.json".format(path);
			};
			mlp.write(path);
		});
	};

	Button(win,Rect(730,160,100,20))
	.states_([["Load MLP"]])
	.action_{
		Dialog.openPanel({
			arg path;
			mlp.read(path);
		});
	};

	Button(win,Rect(730,190,100,20))
	.states_([["Not Predicting"],["Predicting"]])
	.action_{
		arg but;
		predicting = but.value.asBoolean;
	};

	s.sync;
}
)

~init_controller.()

~paramsbuf.plot