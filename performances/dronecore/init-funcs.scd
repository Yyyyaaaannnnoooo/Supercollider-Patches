

(
~init = {
  s.newBusAllocators;
  /*  ~size = 1024 * 2;
  ~waves = 16;
  ~hop = 0.25;
  ~win = 0;*/
  ~imagBus = Bus.control(s, ~size);
  ~imagBus2 = Bus.control(s, ~waves);
  ~lfo = Bus.control(s, 2);
  ~ratectrl = Bus.control(s, 1);
  ~micBus = Bus.audio(s, 2);
  ~recBus = Bus.audio(s, 2);
  ~recBus1 = Bus.audio(s, 2);
  ~recBus2 = Bus.audio(s, 2);
  // ~ch0 = Bus.audio(s, 2);
  ~ch1 = Bus.audio(s, 2);
  ~ch2 = Bus.audio(s, 2);
  ~ch3 = Bus.audio(s, 2);
  ~ch4 = Bus.audio(s, 2);
  ~ch5 = Bus.audio(s, 2);

  ~bc1 = Bus.control(s, 1);//wipe
  ~bc2 = Bus.control(s, 1);//pos
  ~bc3 = Bus.control(s, 1);//rate
  ~bc4 = Bus.control(s, 1);//lfo speed
  ~bc5 = Bus.control(s, 1);//lfo depth
  ~bc6 = Bus.control(s, 1);//fade
  ~bc1.set(0);
  ~bc2.set(0);
  ~bc3.set(1);
  ~bc4.set(0.0001);
  ~bc5.set(0);
  ~bc6.set(0);

  // ~mic = Group.new;
  // ~rec = Group.after(~mic);
  // ~synths = Group.after(~rec);
  ~synths = Group.new;
  ~fxs = Group.after(~synths);
  ~eoc = Group.after(~fxs);

};

~load_samples = {
  var subfolders, path;
  Buffer.freeAll;
  ~path = PathName(thisProcess.nowExecutingPath).parentPath;
  b = ();
  ~path.postln;
  subfolders = PathName(~path ++ "audio/20250711-samples/").entries;
  subfolders.do({
    arg dir;
    var buf_array;
    buf_array = dir.entries.collect({
      arg file;
      Buffer.readChannel(s, file.fullPath, channels: [0, 1]);
    });
    b[dir.folderName.asSymbol] = buf_array;
  });

  ~break = b[\kick];
  // ~hoov = b[\hoovers];
  ~kick = b[\vox2];
  ~vox = b[\vox3];
};

~load_fft_samples = {
  var subfolders;
  Buffer.freeAll;
  ~path = PathName(thisProcess.nowExecutingPath).parentPath;
  b = ();
  ~path.postln;
  subfolders = PathName(~path ++ "audio/fft-bus/").entries;
  subfolders.do({
    arg dir;
    var buf_array;
    buf_array = dir.entries.collect({
      arg file;
      Buffer.readChannel(s, file.fullPath, channels: [0, 1]);
    });
    b[dir.folderName.asSymbol] = buf_array;
  });

  ~recbufs_b = b[\break];
  // ~hoov = b[\hoovers];
  // ~recbufs_k = b[\kick];
  // ~recbufs_v = b[\vox];
};

// Buffer.read

// INIT fft buffers
~init_fft_bufs = {
  ~recbufs_b = ~break.collect({
    arg item, i;
    {Buffer.alloc(s, item.duration.calcPVRecSize(~size, ~hop), 1)}!2;
  });

  /*  ~recbufs_h = ~hoov.collect({
  arg item, i;
  Buffer.alloc(s, item.duration.calcPVRecSize(~size, ~hop), 2);
  });*/

  ~recbufs_k = ~kick.collect({
    arg item, i;
    {Buffer.alloc(s, item.duration.calcPVRecSize(~size, ~hop), 1)}!2;
  });

  ~recbufs_v = ~vox.collect({
    arg item, i;
    {Buffer.alloc(s, item.duration.calcPVRecSize(~size, ~hop), 1)}!2;
  });
};

"Init Functions Loaded".postln;

)
