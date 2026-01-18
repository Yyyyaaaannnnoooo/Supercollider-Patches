(

~wekinator_port = 6448;

~remote = NetAddr("127.0.0.1", ~wekinator_port);

~emit = {
  arg value;
  "EMIT".postln;
  value.postln;
  ~remote.sendMsg("/wek/inputs", value);
};

~emit_bundle = {
  arg bundle;
  var args = ["/wek/inputs"];
  bundle.do({arg item, i; args = args.add(item);});

  args.postln;
  ~remote.sendBundle(0, args);
}



)

OSCFunc.trace

(

r = {
  loop{
    var args;
    // ~emit.(args);
    ~emit_bundle.({1.0.rand}!33);
    0.5.wait;
  }
}.fork;

)

r.stop



(
OSCdef(
  key: \image,
  func: {
    arg msg, time, addr, recvPort;
    var ch = 0;
    msg.postln;
    msg.removeAt(0);
    // ch = msg.removeAt(0).postln;

    "~~~ New Composition ~~~".postln;
    ~stop.();
    ~make_scores.(msg)
  },
  path: '/md5');

OSCdef(
  key: \panic,
  func: {
    arg msg, time, addr, recvPort;
    var ch = 0;
    // msg.postln;
    // msg.removeAt(0).postln;
    // PANIC MODE!!!
    "~~~ PANIC MODE! ~~~".postln;
    ~emit_composition.("~~~ PANIC MODE! ~~~");
    Pdef.removeAll;
  },
  path: '/panic');

)