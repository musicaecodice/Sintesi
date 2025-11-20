s.boot;
s.scope;
s.freqscope;
s.plotTree;

// -------- RM

(
SynthDef.new(\rm, {arg amp=0,fpor=500,fmod=700;
	                  var por, mod, sig;
	                      por = SinOsc.ar(fpor);
		                  mod = SinOsc.ar(fmod);
	                      sig = por * mod * amp;
	                  Out.ar(0,sig)
}).add
)

a = Synth.new(\rm, [\fpor,450,\fmod,600,\amp,0.2]);
a.free;

// -------- AM

(
SynthDef.new(\am, {arg amp=0,fpor=500,fmod=700;
	                  var por, mod, sig;
	                      por = SinOsc.ar(fpor);
		                  mod = SinOsc.ar(fmod).unipolar; // Su segnale bipolare
	                      sig = por * mod * amp;
	                  Out.ar(0,sig)
}).add
)

a = Synth.new(\am, [\fpor,450,\fmod,600,\amp,0.2]);
a.free;

// --------- Ripasso

// Valore secco

a = {arg amp=0; SinOsc.ar(456,0,amp)  }.play;

a.run(false)
a.run(true)

a.set(\amp, rand(1.0));

(
r = Routine.new({
	                inf.do({  a.set(\amp, rand(1.0)); 0.1.wait  })
                 }).play
)

r.stop;
a.free;

// --------- Array
// Multichannel exp --> Crea tante istanze della UGen quanti gli items dell'Array

a = {arg amp=0; SinOsc.ar([456,567],0,0.2)  }.play;

// Mixa l'Array di canali in 1 mono

a = {arg amp=0; Mix(SinOsc.ar([456,567,2345,3678],0,0.1))  }.play;

a.set(\amp, rand(1.0));

(
r = Routine.new({
	                inf.do({  a.set(\amp, rand(1.0)); 0.1.wait  })
                 }).play
)

a.free;

// Valore secco --> Ksig (da .lag)
// Lag.kr(val, 0.2)

a = {arg amp=0; SinOsc.ar(456,0,amp.lag(2))}.play;
a = {arg amp=0; SinOsc.ar(456,0,Lag.kr(amp,0.2)}.play;

a.set(\amp, rand(1.0));

(
r = Routine.new({
	             inf.do({  a.set(\amp, rand(1.0)); 0.1.wait  })
                 }).play
)

a.free;

// KSIG
// Interazione

a = {arg amp=0; SinOsc.ar(456,0, SinOsc.ar(600).unipolar)}.play;

a.free;

// LFO
// Se sull'ampiezza --> Tremolo (frequnze sub audio (< 20Hz)
// Se frequnze audio (> 20Hz) = AM

a = {arg amp=0; SinOsc.ar(456,0, SinOsc.kr(MouseY.kr(1,1000).poll(10))).unipolar}.play;

a.free;

// Leggibilità del codice

(
a = {arg amp=0;
	 var por, mod,sig;
		 mod = SinOsc.ar(MouseX.kr(1,1000)) * 0.5 +  MouseY.kr(0,0.5).scope;
		 por = Saw.ar(400);
	     sig = mod * por * amp;
		 }.play;
)

a.set(\amp,1)

a.free;

// Modo empirico per farci qualcosa

(
SynthDef.new(\rm1, {arg amp=0,gate=0;
			        var por,mod,sig,env;
			            mod = SinOsc.ar(MouseY.kr(1,1000).poll(10, \mod));
						por = Saw.ar(MouseX.kr(1,1000).poll(10, \por));
			            sig = por * mod;
			            env = Linen.kr(gate,2,1,6,doneAction:2);
			        Out.ar(0,sig*env*amp)
		}).add;
)

a =	Synth.new(\rm1,[\amp,0.2,\gate,1])

(
		SynthDef.new(\rm2, {arg amp=0,mfreq=0,pfreq=0,lagt(1),gate=0;
			        var por,mod,sig,env;
			            mod = SinOsc.ar(mfreq.lag(lagt));
						por = Saw.ar(pfreq.lag(lagt));
			            sig = por * mod;
			            env = Linen.kr(gate,2,1,6,doneAction:2);
			        Out.ar(0,sig*env*amp)
		}).add;
)

a =	Synth.new(\rm2,[\amp,0.2,\gate,1])


// mod: 871
// por: 466

// mod: 278
// por: 14

(
SynthDef.new(\rm1, {arg amp=0,gate=0;
			                 var por,mod,sig,env;
			                     mod = SinOsc.ar(LFNoise1.kr(0.01).range(871,278));
						                  por = Saw.ar(LFNoise1.kr(0.01).range(466,14));
			                     sig = por * mod;
			                     env = Linen.kr(gate,2,1,6,doneAction:2);
			                 Out.ar(0,sig*env*amp)
		}).add;
)

a =	Synth.new(\rm1,[\amp,0.2,\gate,1]);
a.release;

(
SynthDef.new(\rm1, {arg amp=0,gate=0;
			                 var por,mod,sig,env;
			                     mod = Saw.ar([Line.kr(278,871,250),Line.kr(278,871,250)+1]);
						                  por = Saw.ar(XLine.kr(14,466,250));
			                     sig = por * mod;
			                     env = Linen.kr(gate,2,1,6,doneAction:2);
			                 Out.ar(0,sig*env*amp)
		}).add;
)

a =	Synth.new(\rm1,[\amp,0.2,\gate,1]);
a.set(\amp,0.8)
a.release;






