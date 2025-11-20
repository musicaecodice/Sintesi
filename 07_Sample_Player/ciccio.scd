Buffer.freeAll;
b = Buffer.read(s, "suoni/crotal.wav".resolveRelative);
b.numChannels;
b.duration;
(
SynthDef.new(\caio, {arg buf=0,amp=0,start=0,pan=0,trasp=0,done=2;
	                 var sig ;
	                     sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * trasp.midiratio,
		                                  startPos: BufSampleRate.kr(buf) * start,
		                                  doneAction:done);
	                     sig = sig * amp;
	                     sig = Pan2.ar(sig, pan);
	                 Out.ar(0, sig)
                     }).add;
)

s.plotTree

(
Synth.new(\caio, [\buf, b,
	              \amp, 1,
	              \start, 0,
	              \trasp, rand2(4),
	              \pan, -0.3,
	              \done, 2]
          );
)