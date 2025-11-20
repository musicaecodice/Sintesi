ServerOptions.devices; // Array devices connessi


s.options.inDevice_("Microfono MacBook Air");
//s.options.outDevice_("Altoparlanti MacBook Air");
s.options.outDevice_("Scarlett 18i20 USB");

s.reboot;
s.scope;
s.plotTree;

// ...se non abbiamo necessità di Sincro con players

// -------------------> Registrazione semplice

// -------------------> Apri RecBuf_1.png

// -------------------> Buffer vuoto

(
Buffer.freeAll;                           // Cancella tutti i Buffer...
b = Buffer.alloc(s, s.sampleRate * 3, 1); // Allocazione 1 secondo di memoria mono
)

// -------------------> Synth input

(
SynthDef.new(\mic, {arg inBus=0,outBus=0,amp=0;
	                   var sig;
	                       sig = SoundIn.ar(inBus) * amp.lag(0.02);
	                       sig = LeakDC.ar(sig);
	                   Out.ar(outBus,sig)
             }).add;

// -------------------> Router

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

// -------------------> RecordBuf

SynthDef.new(\rec1,{arg buf=0, inBus=0, loop=0, mix=0, done=2;
                    var in;
                        in = In.ar(inBus, 1);
                    RecordBuf.ar(in,            // Segnale da scrivere
                                 buf,           // Buffer da scrivere
                                 preLevel:mix,  // se 1 = aggiunge al contenuto se 0 = sovrascrive
                                 loop:loop,     // se 1 = loop
                                 doneAction:done);
             }).add;

// -------------------> Busses audio

~micBus = Bus.audio(s,1); // Bus microfono
~recBus = Bus.audio(s,1); // Bus Registratore
)

// -------------------> Gruppi e Synth mic in

s.freeAll;                       // Cancella Gruppi e Synth

(
~micGrp  = Group.new;
~recGrp  = Group.after(~micGrp);
~playGrp = Group.after(~recGrp); // Lo utilizzeremo in seguito...

Synth(\mic,    [\inBus, 0, \amp,1, \outBus,~micBus],              ~micGrp);
Synth(\router, [\inBus, ~micBus,   \outBus,~recBus, \fadeT, 0.5], ~micGrp, \addToTail);
)

// -------------------> Oneshot Rec

// Senza sovrascrittura

// Si autodistrugge ogni volta...

b.zero; // Pulisce il Buffer...

Synth(\rec1, [\buf,b,\inBus,~recBus,\mix,0,\loop,0,\done,2], ~recGrp); // mix = 0

b.plot; // Visualizza
b.play; // Suona

// Con sovrascrittura

b.zero; // Pulisce il Buffer...

Synth(\rec1, [\buf,b,\inBus,~recBus,\mix,0.3,\loop,0,\done,2], ~recGrp); // mix > 0 = gain

b.play; // Suona

// -------------------> Loop Rec

b.zero; // Pulisce il Buffer...

a = Synth(\rec1, [\buf,b,\inBus,~recBus,\mix,0,\loop,1,\done,0], ~recGrp); // loop = 1
a.set(\loop,0);

b.play;  // Suona - ATTENZIONE AI LARSEN
a.free;  // Cancella il singolo Synth


s.defaultGroup.deepFree; // Cancella tutti i Synth ma non i Gruppi...

// ...se invece abbiamo necessità di Sincro con players

// -------------------> Puntatore

// -------------------> Apri RecBuf_2.png

s.freeAll;               // Cancella tutti i Synth e i Gruppi...

(
// -------------------> Synth input

SynthDef.new(\mic, {arg inBus=0,outBus=0,amp=0;
	                   var sig;
	                       sig = SoundIn.ar(inBus) * amp.lag(0.02);
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

// -------------------> Synth puntatore (esterno)

SynthDef.new(\pos, {arg outBus=0,buf=0,rate=1;
	                   var sig;
	                       sig = Phasor.ar(0,BufRateScale.kr(buf)*rate,0,BufFrames.kr(buf));
	                   Out.ar(outBus,sig);
             }).add;

// N.B. Con rate=0 si ferma all'ultimo samples...

// -------------------> Synth recorder

SynthDef.new(\rec, {arg ptrBus=0, micBus=0, buf=0;
	                   var ptr, sig;
	                       ptr = In.ar(ptrBus, 1);
	                       sig = In.ar(micBus, 1);
	                   BufWr.ar(sig,buf,ptr);
}).add;
)

// -------------------> Bus audio

(
~recBus.free;
~ptrBus.free;
~micBus = Bus.audio(s,1); // Bus microfono
~recBus = Bus.audio(s,1); // Bus Registratore
~ptrBus = Bus.audio(s,1); // Bus Puntatore
)

// -----------------------------> Gruppi e Synth

(
~micGrp = Group.new;
~ptrGrp = Group.after(~micGrp);
~recGrp = Group.after(~ptrGrp);

Synth(\mic,    [\inBus, 0, \amp,1, \outBus,~micBus],              ~micGrp);
Synth(\router, [\inBus, ~micBus,   \outBus,~recBus, \fadeT, 0.5], ~micGrp, \addToTail);
Synth(\pos,    [\buf,b,            \outBus,~ptrBus],              ~ptrGrp);
Synth(\rec,    [\ptrBus,~ptrBus,\micBus,~recBus, \buf, b],        ~recGrp);
)

b.plot; // verifica che stia scrivendo...
b.play;

s.freeAll;
