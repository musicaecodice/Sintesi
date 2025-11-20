ServerOptions.devices; // Array devices connessi


s.options.inDevice_("Microfono MacBook Air");
//s.options.outDevice_("Altoparlanti MacBook Air");
s.options.outDevice_("Scarlett 18i20 USB");

s.reboot;
s.scope;
s.plotTree;

// -----------------------------> GrainIn

// Il modo più semplice ma molto basico...
// Si può cambiare l'inviluppo...

(
SynthDef(\glive_1,{arg outBus=0, inBus=0,
	                      gden=2, gdur=0.2, amp=0, pan=0, envbuf= -1,
	                      fadein=0.2,fadeout=1,gate=0;
	                  var trig, sig, env;

	                      trig = Impulse.ar(gden);
	                      sig  = SoundIn.ar(inBus, 1);   // Segnale in ingresso
	                      sig  = GrainIn.ar(2,
		                                       trig,
		                                       gdur,
		                                       sig,
		                                       TRand.kr(-1,1,trig),
		                                       envbuf,512,amp);
	                    env = Linen.kr(gate,fadein,1,fadeout,doneAction:2);
	                Out.ar(outBus,sig * env)
          }).add
)

a = Synth(\glive_1,[\inBus,0,\outBus,0,\gden,10,\gdur,0.1,\amp,1,\gate,1]);
a.set(\gden,8);
a.set(\gden,15);
a.set(\gate,0);

// -----------------------------> Inviluppi

e = Signal.hanningWindow(2048); // default
e = Signal.hammingWindow(2048);
e = Signal.welchWindow(2048);
e = Env.sine.asSignal(2048);
e = Env.triangle.asSignal(2048);
e = Env.linen(0.1,0.8,0.1).asSignal(2048);
e = Env.perc.asSignal(2048);

e = Buffer.loadCollection(s,e);
a.set(\envbuf, e);
e.plot;

a.set(\gate,0);

// -----------------------------> Puntatore

// Se vogliamo realizzare tecniche più articolate su un segnale in tempo reale
// dobbiamo prevedere alcuni passaggi preliminari:

// 1) Creare un Buffer vuoto stabilendone il size
// 2) Creare un Synth che legge il segnale in ingresso
// 3) Creare un Synth da utilizzare come fasore che ci serve sia per registrare
//    dinamicamente il Buffer sia come puntatore per la sintesi granulare.
// 4) Definire due Busses audio, uno per il segnale in ingresso, l'altro sul quale
//    scrivere/leggere il segnale del puntatore

// -----------------------------> GRAPH 17

// -----------------------------> Buffer vuoto

(
Buffer.freeAll;
b = Buffer.alloc(s, s.sampleRate * 1, 1); // Allocazione 1 secondo di memoria mono
)

(
// -----------------------------> Synth input

SynthDef(\mic, {arg inBus=0,outBus=0,amp=0;
	               var sig;
	                   sig = SoundIn.ar(inBus) * amp;
	                   sig = LeakDC.ar(sig);
	               Out.ar(outBus,sig)
                }).add;

// -------------------> Synth router

SynthDef(\router, {arg inBus=0, outBus=0, fadeT = 1;
		                 var sig, init, gate;
		                     sig    = In.ar(inBus,1);
		                     init   = Impulse.kr(0);
		                     outBus = K2A.ar(outBus);
			                    gate   = HPZ1.ar(outBus).abs > 0;

	                 Out.ar(outBus,
			                      sig * EnvGen.ar(Env([0,0,1], [0,fadeT],\cub),gate+init));
			               Out.ar(DelayN.ar(outBus, fadeT, fadeT),
			              sig * EnvGen.ar(Env([0,1,0], [0,fadeT],\cub),gate));
	       }).add;

// -----------------------------> Synth puntatore (esterno)

SynthDef(\pos, {arg outBus=0,buf=0,rate=1;
	               var sig;
	                   sig = Phasor.ar(0,BufRateScale.kr(buf)*rate,0,BufFrames.kr(buf));
	               Out.ar(outBus,sig);
                }).add;

// N.B. Con rate=0 si ferma all'ultimo samples...

// -----------------------------> Synth Recorder

SynthDef(\rec, {arg ptrBus=0, micBus=0, buf=0;
	               var ptr, sig;
	                   ptr = In.ar(ptrBus, 1);
	                   sig = In.ar(micBus, 1);
	               BufWr.ar(sig,buf,ptr);  // Dual mono...
}).add;
)

// -----------------------------> Bus audio

(
~micBus.free;
~recBus.free;
~ptrBus.free;
~micBus = Bus.audio(s,1); // Bus microfono
~recBus = Bus.audio(s,1); // Bus Registratore
~ptrBus = Bus.audio(s,1); // Bus Puntatore

// -----------------------------> Gruppi e Synth

~micGrp  = Group.new;
~ptrGrp  = Group.after(~micGrp);
~recGrp  = Group.after(~ptrGrp);
~granGrp = Group.after(~recGrp);

Synth(\mic,    [\inBus, 0, \amp,1, \outBus,~micBus],              ~micGrp);
Synth(\router, [\inBus, ~micBus,   \outBus,~recBus, \fadeT, 0.5], ~micGrp, \addToTail);
Synth(\pos,    [\buf,b,            \outBus,~ptrBus],              ~ptrGrp);
Synth(\rec,    [\ptrBus,~ptrBus,\micBus,~recBus, \buf, b],        ~recGrp);
)

b.plot; // verifica che stia scrivendo...
b.play;
s.defaultGroup.deepFree; // Cancella i Synth ma non i Gruppi

// -----------------------------> GrainBuf

// Essendo il puntatore sincrono con la registrazione nel Buffer non è possibile
// un time stretching...

// Altro problema: se il grano è centrale rispetto al puntatore oppure se
// vogliamo deviazioni random attorno al puntatore...clicks

// -----------------------------> GRAPH 18

// Soluzione per deviazioni random attorno al puntatore ritardato:

// -----------------------------> GRAPH 19

(
SynthDef(\g_live_2,{arg outBus=0, buf=0,
	                       gden=2, gdur=0.2, trsp=0, amp=0, pan=0, envbuf= -1,

		                      ptrBus = 0,        // Bus del puntatore

		                      maxDel = 1,        // (b-a)
	                       devR   = 0.2,      // (b-d/-d)
	                       minDel = 0.02,     // (c-a) sicurezza...

	                       fadein=0.2,fadeout=1,gate=0;

	                 var gfreq, trig, sig, env,
	                     pos, dev, dly, maxgdur;

	                     devR   = devR   * SampleRate.ir;        // Secondi --> samples
	                     maxDel = maxDel * SampleRate.ir;
	                     minDel = minDel * SampleRate.ir;

	                     trig = Impulse.ar(gden);                // pos in (a)

	                     dev  = LFNoise1.ar(gden).bipolar(devR); // Deviazione corrente (b-e)
	                     dly  = max(maxDel - dev, minDel);       // Ritardo clippato (e-c)

	                     pos = In.ar(ptrBus, 1);                 // Segnale puntatore

	                     pos = pos - dly;                        // Shift indietro (a --> e)
	                     pos = pos / BufFrames.kr(buf);          // Normalizzazione tra 0 e 1

	                     maxgdur = dly / trsp.midiratio;         // maxgdur = dly (b-e)
	                     maxgdur = maxgdur / SampleRate.ir;      // Samples --> secondi
	                     gdur    = min(gdur, maxgdur);           // Durata massima clippata

	                     sig  = GrainBuf.ar(2,trig,gdur,buf,trsp.midiratio,
		                                       pos,
		                                       2,pan,envbuf,512,amp);

	                     env = Linen.kr(gate,fadein,1,fadeout,doneAction:2);
	                Out.ar(outBus, sig * env)
          }).add
)

(
b.zero;    // pulisce il buffer ogni volta che creiamo un nuovo granulatore

Synth(\mic,    [\inBus, 0, \amp,1, \outBus,~micBus],              ~micGrp);
Synth(\router, [\inBus, ~micBus,   \outBus,~recBus, \fadeT, 0.5], ~micGrp, \addToTail);
Synth(\pos,    [\buf,b,            \outBus,~ptrBus],              ~ptrGrp);
Synth(\rec,    [\ptrBus,~ptrBus,\micBus,~recBus, \buf, b],          ~recGrp);

a = Synth(\g_live_2, [\out, 0,
	                     \buf, b,
	                     \outBus,0,
	                     \gdur,0.2,
	                     \gden, 2/0.2,
	                     \amp, 0.5,
	                     \trsp,0,
	                     \pan,0,
	                     \envbuf, -1,
                      \devR,  0,       // in secondi
	                     \ptrBus, ~ptrBus,
                      \maxDel, 1/3,    // Ritardo di 1/3 di secondo
                      \minDel, 0.02,
	                     \pan,0,
	                     \gate,1], ~granGrp );
)

a.set(\gdur,0.05);    // Ricostruisce il segnale con il ritardo specificato...
a.set(\gdur,0.2);     // Ritardo = maxDel
a.set(\maxDel, 0.02);
a.set(\gden,100);     // Densità alta = ricostruisco il segnale
a.set(\trsp,rand2(5).postln);
a.set(\devR, 0.3);
a.set(\trsp, 0);
a.set(\maxDel, 0.5);
a.set(\gdur,0.04);
a.set(\pan, 0);
a.set(\gate,0);

(
b.zero;
a = 5.collect({arg i;                      // Cinque granulatori...
	           Synth(\g_live_2, [\out,0,
	                             \buf,b,
			                           \outBus,0,
	                             \gdur,0.2,
			                           \gden, 2/0.2,
		                            \amp,i.linlin(0, 4,-3,-20).dbamp, // riscala l'ampiezza in eco...
	                             \trsp,0,
		                            \pan, rand2(1.0),
	                             \envbuf, -1,
                              \devR,  0.3,
	                             \posBus, ~ptrBus,
		                            \maxDel, rrand(0.2,0.6),  // Ritardi diversi...
                              \minDel,0.01,
			                           \pan,0,
	                             \gate,1], ~granGrp)
               });
)

a.do({arg i; i.set(\gdur, rrand(0.01,0.2))});
a.do({arg i; i.set(\trsp, rrand(-4,5))});
a.do({arg i; i.set(\gate, 0)});

s.freeAll; // Cancella tutto...

// -----------------------------> Freeze Grain

// Se specifichiamo rate = 0 al Synth del puntatore 'frizziamo' la registrazione
// e di conseguenza la posizione del grano

(
b.zero;
a = Synth(\g_live_2, [\out, 0,
	                  \buf, b,
				               \outBus,0,
	                  \gdur,0.2,
	                  \gden, 2/0.2,
	                  \amp,0.5,
	                  \trsp,0,
	                  \pan,0,
	                  \envbuf, -1,
                   \devR,  0,       // in secondi
	                  \posBus, ~ptrBus,
                   \maxDel, 1/3,    // Ritardo di 1/3 di secondo
                   \minDel, 0.02,
	                  \pan,0,
	                  \gate,1], ~granGrp );
)

~ptrGrp.set(\rate,0);
~ptrGrp.set(\rate,1);

a.set(\gdur,0.13);
a.set(\gden,15);
a.set(\trsp,rand2(4));
a.set(\gate,0);

// -----------------------------> Harmonizer

// Meglio TGrain di GrainBuf...

(
SynthDef(\g_live_3,{arg outBus=0,buf=0,
	                       gdur=0.1, amp=0, trsp=0, pan=0, ptrBus=0,
	                       fadein=0.2,fadeout=1,gate=0;
	                   var gfreq, pos, trig, sig, env;
	                       gfreq = 2.0/gdur;                                                  // 2 overlap...
	                       pos   = In.ar(ptrBus,1) / SampleRate.ir(buf);
	                       trig  = Impulse.ar(gfreq);
	                       sig   = TGrains.ar(2, trig, buf, trsp.midiratio, pos, gdur, pan, amp, 4);
		                      env   = Linen.kr(gate,fadein,1,fadeout);
	                    Out.ar(outBus, sig * env);
}).add;
)

(
~ptrGrp.set(\rate,1);
b.zero;
a = Synth(\g_live_3, [\buf,b,
					                 \outBus,0,
	                     \gdur,0.1,
		                    \amp, 0.5,
	                     \trsp, 0,
		                    \pan, 0,
	                     \ptrBus, ~ptrBus,
	                     \gate,1], ~granGrp)
)

a.set(\trsp, rand2(12).postln);
a.set(\trsp, 4);
a.set(\gdur,0.05);
a.free;

(
b.zero;
a = [-6,0,4,7].collect({arg i; Synth(\g_live_3, [
	                                                \buf,b,
					                                            \outBus,0,
	                                                \gdur,0.1,
		                                               \amp, 0.2,
	                                                \trsp, i,
	                                                \pan, rand2(1.0),
	                                                \ptrBus, ~ptrBus,
	                                                \gate,1], ~granGrp)})
)

a.do({arg i; i.set(\gdur,0.05)});
a.do({arg i; i.set(\pan,rand2(1.0))});
a.do({arg i; i.set(\amp,rand(1.0))});

a.do({arg i; i.set(\gate,0)});

s.freeAll;

// -----------------------------> PitchShift
// -----------------------------> Warp1

// Guardare gli Help files...