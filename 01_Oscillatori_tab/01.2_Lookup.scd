//=================================================================
// Lookup

// ----------------------------------------------------------------
// Rappresentazione (Array)

(
a = (0..30);
b = Signal.sineFill(30,[0.4,0.6,0.2]);
[a,b].plot(discrete:true);
)

// ----------------------------------------------------------------
// Audio (Buffer)

(
s.boot;
s.scope;
{s.plotTree}.defer(1)
)

b.free;
b = Buffer.read(s, "voce.wav".resolveRelative);

(
SynthDef.new(\play, {var pha, sig;
	                     pha = Phasor.ar(0,MouseY.kr(0,10),0,BufFrames.kr(b));
	                     pha.linlin(0,BufFrames.kr(b),0,1).scope;
	                     sig = BufRd.ar(1,b,pha);
	                 Out.ar(0,sig*0.2)}
             ).add;
)

Synth.new(\play);

b.free;
b = Buffer.alloc(s, 512, 1); // 512 campioni...
b.sine1([1,0.5,0.7,0.3],true,false);



