//=================================================================
// Tipologie di oscillatori

(
s.boot;
s.scope;
{s.plotTree}.defer(1)
)

// ----------------------------------------------------------------
// PlayBuf (Sample playback oscillator)

Buffer.freeAll;
b = Buffer.read(s, "voce.wav".resolveRelative);
b.plot;
b.play;

(
SynthDef(\ply1, {var sig;
	                 sig  = PlayBuf.ar(1,b,doneAction:2);
	             Out.ar(0,sig)
         }).add;
)

Synth(\ply1);

// ----------------------------------------------------------------
// BufRD (Buffer reading oscillator)

(
SynthDef(\ply2, {var sig;
	                 sig  = BufRd.ar(1,b,LFNoise2.ar(1) * BufFrames.kr(b));
	             Out.ar(0,sig)
         }).add;
)

a = Synth(\ply2);
a.free;

// ----------------------------------------------------------------
// Osc (Interpolating wavetable oscillator)

b.free;
b = Buffer.alloc(s, 512, 1);
b.sine1(1.0/[1,2,3,4,5,6], true, true, true);
b.plot;

(
SynthDef(\ply3, {var sig;
	                 sig  = Osc.ar(b,MouseY.kr(200,800) * 0.4);
	             Out.ar(0,sig!2)
         }).add;
)

a = Synth(\ply3);
a.free;