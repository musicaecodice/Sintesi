//=================================================================
// La tecnica del BEATING consiste nel sommare al suono originale
// (sia esso puro o complesso) una o più copie di esso con una
// frequenza leggermente diversa che rimanga nell'ambito dei 10 Hz
// al di sopra o al di sotto (Deviazione)
//=================================================================

s.boot;
s.plotTree;
s.scope;
s.freqscope;

//=================================================================
// Beating

{Mix(SinOsc.ar([440,443]))}.play;       // ...la stessa cosa

{Mix(SinOsc.ar([440,442],0,[0.5,0.5]))}.play; // Bisogna riscalare l'ampiezza
                                              // somma = 1.0

// --------- Linen.kr()
(
SynthDef(\beat_1, {arg freq=500,amp=0,dev=0,gate=0,pan=0,done=0;
	               var sig,env,pann;
	                   sig   = Mix(SinOsc.ar([freq,freq+dev])) * 0.5;
	                   env   = Linen.kr(gate,  // gate
		                                3,     // Tempo di attacco
		                                1,     // Livello di sust
		                                1.0,   // Tempo di rilascio
		                                done); // Autodistruzione
	                   pann  = Pan2.ar(sig*amp*env,pan);
	               Out.ar(0,pann)}
         ).add;
)

a = Synth(\beat_1, [\freq,500,\amp,1,\dev,1,\pan,0,\done,2,\gate,1]);
a.set(\dev, 2);
a.set(\dev, 3);
a.set(\dev, 10);
a.set(\dev, rand2(10.0).postln);

a.set(\gate,0);  // Fade out
a.release(3);    // Come gate 0 ma specifica il tempo di fade out

//-----------------------------------------------------------------
// Sound design 1 - Scrutando orizzonti finiti...

a = Array.newClear(3);  // Crea un Array vuoto di 3 items (INIT)

(                       // Ad ogni trigger (valutazione)
a[0].release(2);        // Trigger fadeout
a[1].release(3);
a[2].release(6);

a = 3.collect({         // Trigger fade in (crossfade)
	           Synth(\beat_1, [\freq,rrand(600,1000),
		                       \amp, rand(1/3),
		                       \dev,rand2(10.0),
		                       \pan,0,
		                       \done,2,
		                       \pan,rand2(1.0),
		                       \gate,1]);
               })
)

// Fine...

(
a[0].release(2);
a[1].release(3);
a[2].release(6);
)

// N.B. Ogni Synth può avere più di due segnali a distanze
//      frequenziali diverse

//-----------------------------------------------------------------
// Sound design 2 - Delicatessen
(
SynthDef(\beat_2, {arg freq=500,amp=0,dur=1,t_gate=1,pan=0,done=0;
	               var dbpf,denv,sig,bpf,env,pann;
	                   dbpf  = Env.new([0,10,5,7,0],          // Livelli deviazioni
		                               [0.8,0.2,0.9,2].normalizeSum*dur);
	                   denv  = freq + EnvGen.kr(dbpf,t_gate); // Inviluppo frequenza deviazione
	                   sig   = Mix(Saw.ar([freq,denv])) * 0.5;
	                   bpf   = Env.sine(dur);                 // Inviluppo ampiezza
	                   env   = EnvGen.kr(bpf,t_gate,doneAction:done);
	                   pann  = Pan2.ar(sig*amp*env,pan);
	               Out.ar(0,pann)}
         ).add;
)

(
r = Routine.new({
	             inf.do({
                         Synth(\beat_2, [\freq,rrand(80,100).midicps,
			                             \amp,rand(1.0),
			                             \dur,10,
			                             \pan,rand2(1.0),
			                             \done,2,
			                             \t_gate,1]);
		                 rrand(1.0,5.0).wait;
	                     })
                  }).reset.play;
)

r.stop;
//=================================================================
// Chorusing
// Effetto chorus semplice: definire il numero di oscillazioni
// e generare due segnali con frequenze pari a:
// • freq + (beats/2)
// • freq - (beats/2)

(
SynthDef(\chorus_1, {arg freq=500,amp=0,beat=0, dur=1,t_gate=0,pan=0,done=0;
	                    var sig,bpf,env,pann;
	                        sig   = Mix(Pulse.ar([freq+(beat/2),
		                                       freq,
		                                       freq-(beat/2)])) * (1/3);
	                     bpf   = Env.perc(0.01,dur-0.01);
	                     env   = EnvGen.kr(bpf,t_gate, doneAction:done);
	                   pann  = Pan2.ar(sig*amp*env,pan);
	               Out.ar(0,pann)}
         ).add;
)

Synth(\chorus_1, [\freq,500,\amp,1,\beat,0,\dur,2,\pan,0,\done,2,\t_gate,1]);   // Senza chorus
Synth(\chorus_1, [\freq,500,\amp,1,\beat,0.5,\dur,2,\pan,0,\done,2,\t_gate,1]); // Due voci...
Synth(\chorus_1, [\freq,500,\amp,1,\beat,4,\dur,2,\pan,0,\done,2,\t_gate,1]);   // Più voci...
Synth(\chorus_1, [\freq,500,\amp,1,\beat,18,\dur,2,\pan,0,\done,2,\t_gate,1]);  // Due pitches

// Mapping inviluppo d'ampiezza sulla deviazione per INVILUPPO SPETTRALE

(
SynthDef(\chorus_2, {arg freq=500,amp=0,maxbeat=0, dur=1,t_gate=0,pan=0,done=0;
	                    var sig,bpf,env,pann;
	                        bpf   = Env.perc(0.01,dur-0.01);
	                        env   = EnvGen.kr(bpf,t_gate, doneAction:done) * amp;
		                       sig   = Mix(Pulse.ar([freq+(env/2*maxbeat),
		                                       freq,
		                                       freq-(env/2*maxbeat)]
	                                           )) * (1/3);
	                   pann  = Pan2.ar(sig*env,pan);
	               Out.ar(0,pann)}
         ).add;
)

Synth(\chorus_1, [\freq,500,\amp,1,\beat,0.5,\dur,4,\pan,0,\done,2,\t_gate,1]);    // No maping
Synth(\chorus_2, [\freq,500,\amp,1,\maxbeat,0.5,\dur,4,\pan,0,\done,2,\t_gate,1]); // Inviluppo
                                                                                   // Spettrale
//-----------------------------------------------------------------
// Sound design 3 - Cristallerie

(
r = Routine.new({
	             inf.do({
                         Synth(\chorus_2, [\freq,[100,87,85,88,90].choose.midicps,
			                               \amp,rand(1.0),
			                               \maxbeat,2,
			                               \dur,rrand(0.5,2.3),
			                               \pan,rand2(1.0),
			                               \done,2,
			                               \t_gate,1]);
		                 [0.02,0.1,0.2,0.5,1].choose.wait;
	                     })
                 }).reset.play;
)

r.stop;

//-----------------------------------------------------------------
// COsc.ar()
// Se vogliamo utilizzare un OSCILLATORE TABELLARE con il chorus
// esiste una UGen chiamata COsc.ar() che accetta i parametri
// appena esposti con qualsiasi forma d'onda

(
~punti  = 2048;

Buffer.freeAll;
p = Buffer.alloc(s,~punti);
p.sine3([1,    2,  3],  // Rapporti di frequenza dei parziali
	       [0.5,0.3,0.2],  // Ampiezze dei parziali
	       [2pi,2pi,2pi],  // Fasi dei parziali
        true,           // Normalizza
	       true,           // asWavetable
	       true);          // Cancella prima
)

(
SynthDef(\chorus_3, {arg buf=b,freq=500,amp=0,maxbeat=0, dur=1,t_gate=0,pan=0,done=0;
	                 var sig,bpf,env,pann;
	                     bpf   = Env.perc(0.01,dur-0.01);
	                     env   = EnvGen.kr(bpf,t_gate, doneAction:done) * amp;
		                    sig   = Mix(COsc.ar(buf,
		                                        freq,
		                                        env * maxbeat) * 0.5);
	                   pann  = Pan2.ar(sig*env,pan);
	               Out.ar(0,pann)}
         ).add;
)

Synth(\chorus_3, [\freq,500,\amp,1,\maxbeat,2,\dur,4,\pan,0,\done,2,\t_gate,1]);

//-----------------------------------------------------------------
// Sound design 4 - Arpeggiando

(
~note = [60,64,68,72,73,76,78,82].midicps;
~vels = [20,30,40,50,60,80,100,120]/127;

r = Routine.new({
	             inf.do({arg i;
		                 Synth(\chorus_3, [\freq,~note[i%~note.size],
			                               \amp, ~vels[i%~note.size],
			                               \maxbeat,2,
			                               \dur,1,
			                               \pan,rand2(1.0),
			                               \done,2,
			                               \t_gate,1]);
		                 rrand(0.05,0.18).wait;
	                     })
                  }).reset.play;
)

r.stop;

// Provare Sound design 2 + 3...


