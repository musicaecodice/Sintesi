//=================================================================
// Funzioni d'onda

// Attraverso una funzione d'onda possiamo scrivere tutti i valori
// di AMPIEZZA ISTANTANEA relativi a un CICLO di ONDA PERIODICA
// per poi rileggerli attraverso OSCILLATORI TABELLARI.
//
// f[n] = a * sin(w * n + O) --> Funzione della sinusoide

(
~punti  = 100;                // Numero di punti (size della tavola)
~freq   = 1;                  // Numero di cicli per size della tavola
~amp    = 1.0;                // Ampiezza di picco
~w      = 2pi/(~punti/~freq); // Calcolo della velocità angolare (rad/sec)

p = ~punti.collect({arg n; ~amp * sin(~w * n + 2pi)}); // n assume ad ogni valutazione
                                                       // l'indice dell'Array
                                                       // partendo da 0

p.plot(minval: -1, maxval:1,discrete:true); // Visualizza
)

//-----------------------------------------------------------------
// Funzioni di trasferimento (Transfer function)

// Una funzione di trasferimento caratterizza il comportamento di
// un SISTEMA DINAMICO TEMPO INVARIANTE mettendo in relazione un
// valore in INPUT con un valore in OUTPUT.
//
// Prendiamo come esempio la formule di CONVERSIONE tra AMPIEZZA
//
// LINEARE e DECIBEL:
//
// dB[n] = 20 * log[10](n/1) --> Transfer function da lin a dB

~punti = 100; // Numero di punti della tavola

~lin = ~punti.collect({arg n; n/100}); // Rampa lineare tra 0 e 1

// Prendiamo come valori in INPUT (n) della funzione la rampa lineare
// tra 0 e 1 e PER OGNI VALORE uno dopo l'altro applichiamo la
// FUNZIONE DI TRASFERIMENTO:

~db  = ~lin.collect({arg n; 20*log10(n+0.001)/1.0});

// N.B. Abbiamo aggiunto + 0.001 in quanto con 0 questa funzione
// restituisce -inf e non potremmo visualizzarlo in un plotter.

[~lin,~db].plot(discrete:true); // Visualizza INPUT (lineare) e OUTPUT (dB)

//=================================================================
// In SC Possiamo applicare funzioni di trasferimento direttamente
// sui valori di ampiezza istantanea in uscita da una UGen.

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

//-----------------------------------------------------------------
// Clipping

(
~mouseY = Bus.control(s, 1); // (server, n_canali)

SynthDef.new(\wsh_1, {arg freq=400,amp=0,clip=1,gate=0,pan=0,done=2;
	                     var sig, env;
	                         sig   = SinOsc.ar(freq);
	                         sig   = sig.clip2(clip);  // Funzione di trasferimento
		                     sig   = LeakDC.ar(sig);   // Rimuove DC offset
	                         env   = Linen.kr(gate,doneAction:done);
	                         sig   = Pan2.ar(sig * env * amp, pan);
	                     Out.ar(0,sig);
                      }).add;

SynthDef.new(\mouse, {arg busOut=0;
	                     var sig;
	                         sig = MouseY.kr(1,0);
	                    Out.kr(busOut,sig)
             }).add;
)

(
m = Synth(\mouse, [\busOut, ~mouseY]);                  // Synth per ksig
a = Synth.new(\wsh_1, [\amp,0.5,\gate,1],s,\addToTail); // Synth per out
)

a.set(\clip, 0.1);
a.set(\clip, ~mouseY.asMap);
a.release;


// Se il timbro di un suono è composto dalla somma di più sinusoidi
// a frequenze e ampiezze differenti la distorsione dei parziali non
// sarà uguale per tutti...

(
{var in,amp;
	    amp = MouseY.kr(0,0.99).poll(10);
	    in = SinOsc.ar(69.midicps, 0, 0.7*amp) +
	         SinOsc.ar(73.midicps, 0, 0.2*amp) +
	         SinOsc.ar(76.midicps, 0,0.1*amp);
	    in.clip2(0.5);
}.scope;
)

// Parziali in rapporto armonico distorti rafforzano la percezione
// della fondamentale (inesistente...)
(
{var in, amp;
	  amp = MouseY.kr(0,0.99).poll(10);
	  in  = SinOsc.ar(4*110, 0, amp) +
	        SinOsc.ar(5*110, 0, amp) +
	        SinOsc.ar(6*110, 0, amp);
  in.clip2(0.5);
}.scope;
)

//-----------------------------------------------------------------
// Minimum
// Clippa solo la parte positiva

12.min(0.5)

(
~mouseY = Bus.control(s, 1); // (server, n_canali)

SynthDef.new(\wsh_1, {arg freq=400,amp=0,clip=1,gate=0,pan=0,done=2;
	                     var sig, env;
	                         sig   = SinOsc.ar(freq);
	                         sig   = sig.min(clip);    // Funzione di trasferimento
	                         sig   = LeakDC.ar(sig);   // Rimuove DC offset
	                         env   = Linen.kr(gate,doneAction:done);
	                         sig   = Pan2.ar(sig * env * amp, pan);
	                     Out.ar(0,sig);
                      }).add;

SynthDef.new(\mouse, {arg busOut=0;
	                     var sig;
	                         sig = MouseY.kr(1,0);
	                     Out.kr(busOut,sig)
             }).add;
)

(
m = Synth(\mouse, [\busOut, ~mouseY]);                  // Synth per ksig
a = Synth.new(\wsh_1, [\amp,0.5,\gate,1],s,\addToTail); // Synth per out
)

a.set(\clip,0.5);
a.set(\clip,~mouseY.asMap);
a.release;

//-----------------------------------------------------------------
// Maximum
// Clippa solo la parte negativa

12.max(0.5)

(
~mouseY = Bus.control(s, 1); // (server, n_canali)

SynthDef.new(\wsh_1, {arg freq=400,amp=0,clip=1,gate=0,pan=0,done=2;
	                     var sig, env;
	                         sig   = SinOsc.ar(freq);
	                         sig   = sig.max(clip);    // Funzione di trasferimento
	                         sig   = LeakDC.ar(sig);   // Rimuove DC offset
	                         env   = Linen.kr(gate,doneAction:done);
	                         sig   = Pan2.ar(sig * env * amp, pan);
	                     Out.ar(0,sig);
                      }).add;

SynthDef.new(\mouse, {arg busOut=0;
	                     var sig;
	                         sig = MouseY.kr(1,0);
	                     Out.kr(busOut,sig)
             }).add;
)

(
m = Synth(\mouse, [\busOut, ~mouseY]);                  // Synth per ksig
a = Synth.new(\wsh_1, [\amp,0.5,\gate,1],s,\addToTail); // Synth per out
)

a.set(\clip,0.5);
a.set(\clip,~mouseY.asMap);
a.release;

//-----------------------------------------------------------------
// Softclip
// Distorce con una regione perfettamente lineare tra -0.5 e 0.5

(
SynthDef.new(\wsh_1, {arg amp=0,gate=0,pan=0,done=2;
	                     var sig, env;
		                      //  sig   = SinOsc.ar;
	                         sig   = SoundIn.ar(0);
	                         sig   = sig.softclip;    // Funzione di trasferimento
	                         sig   = LeakDC.ar(sig);   // Rimuove DC offset
	                         env   = Linen.kr(gate,doneAction:done);
	                         sig   = Pan2.ar(sig * env * amp, pan);
	                     Out.ar(0,sig);
                      }).add;
)


a = Synth.new(\wsh_1, [\amp,0.5,\gate,1],s,\addToTail); // Synth per out
a.release;

(
a = Signal.sineFill(512,[1]);
[a,a.softclip].plot;
)

//-----------------------------------------------------------------
// Distort
// Distorsione non lineare

(
SynthDef.new(\wsh_1, {arg amp=0,gate=0,pan=0,done=2;
	                     var sig, env;
		                //  sig   = SinOsc.ar;
	                      sig   = SoundIn.ar(0);
	                      sig   = sig.distort;    // Funzione di trasferimento
	                      sig   = LeakDC.ar(sig);   // Rimuove DC offset
	                      env   = Linen.kr(gate,doneAction:done);
	                      sig   = Pan2.ar(sig * env * amp, pan);
	                  Out.ar(0,sig);
                      }).add;
)


a = Synth.new(\wsh_1, [\amp,0.5,\gate,1],s,\addToTail); // Synth per out
a.release;

(
a = Signal.sineFill(512,[1]);
[a,a.distort].plot;
)

//-----------------------------------------------------------------
// Squared (quadrato)
// Parte negativa diventa positiva = ottava sopra con DC offset

(
SynthDef.new(\wsh_1, {arg amp=0,gate=0,pan=0,done=2;
	                     var sig, env;
		                      //sig   = SinOsc.ar;
	                         sig   = SoundIn.ar(0);
	                         sig   = sig.squared;       // Funzione di trasferimento
	                         sig   = LeakDC.ar(sig);   // Rimuove DC offset
	                         env   = Linen.kr(gate,doneAction:done);
	                         sig   = Pan2.ar(sig * env * amp, pan);
	                     Out.ar(0,sig);
                      }).add;
)


a = Synth.new(\wsh_1, [\amp,0.5,\gate,1],s,\addToTail); // Synth per out
a.release;

(
a = Signal.sineFill(512,[1]);
[a,a.squared*2-1].plot;
)

//-----------------------------------------------------------------
// Cubed
// Fondamentale e terzo armonico...

(
SynthDef.new(\wsh_1, {arg amp=0,gate=0,pan=0,done=2;
	                     var sig, env;
		                        sig   = SinOsc.ar;
	                      //sig   = SoundIn.ar(0);
	                         sig   = sig.cubed;       // Funzione di trasferimento
	                         sig   = LeakDC.ar(sig);   // Rimuove DC offset
	                         env   = Linen.kr(gate,doneAction:done);
	                         sig   = Pan2.ar(sig * env * amp, pan);
	                     Out.ar(0,sig);
                      }).add;
)


a = Synth.new(\wsh_1, [\amp,0.5,\gate,1],s,\addToTail); // Synth per out
a.release;

(
a = Signal.sineFill(512,[1]);
[a,a.cubed].plot;
)

//-----------------------------------------------------------------
// Square root (Radice quadrata)
// Spettro dell'onda triangolare

(
SynthDef.new(\wsh_1, {arg amp=0,gate=0,pan=0,done=2;
	                     var sig, env;
		                        sig   = SinOsc.ar;
	                      //sig   = SoundIn.ar(0);
	                         sig   = sig.sqrt;       // Funzione di trasferimento
	                         sig   = LeakDC.ar(sig);   // Rimuove DC offset
	                         env   = Linen.kr(gate,doneAction:done);
	                         sig   = Pan2.ar(sig * env * amp, pan);
	                     Out.ar(0,sig);
                      }).add;
)


a = Synth.new(\wsh_1, [\amp,0.5,\gate,1],s,\addToTail); // Synth per out
a.release;

(
a = Signal.sineFill(512,[1]);
[a,a.sqrt].plot;
)

//=================================================================
// Un'altra tecnica che possimo utilizzare consiste nel memorizzare
// la tranfer function in un Buffer e rileggerla con Shaper.ar()

(
Buffer.freeAll;

~punti = 1024;
~clip1 = Signal.newClear(~punti);

~clip1.waveFill({arg x; x},-1, 1); // Rampa lineare tra -1 e +1
~clip1 = ~clip1.clip2(0.5);        // Tranfert Funcion

b = Buffer.loadCollection(s,~clip1.asWavetableNoWrap); // Non ottimizzato per il wrap around...

{b.plot}.defer(1);
)

(
SynthDef.new(\wsh, {arg buf=b,freq=400,shp=0,amp=0,gate=0,pan=0,done=2;
	                var sig, sigIn, env;
	                    sigIn = SinOsc.ar(freq) * shp;
	                    sig   = Shaper.ar(buf, sigIn);
	                    env   = Linen.kr(gate,doneAction:done);
	                    sig   = Pan2.ar(sig*env*amp,pan);
	                    sig   = LeakDC.ar(sig);
	                Out.ar(0,sig)
}).add;

SynthDef.new(\mouse, {arg busOut=0;
	                  var sig;
	                      sig = MouseY.kr(0,1).poll(10);
	                  Out.kr(busOut,sig)
             }).add;

~mouseY = Bus.control(s, 1); // (server, n_canali)
{Synth(\mouse, [\busOut, ~mouseY])}.defer(1);
)

a = Synth.new(\wsh, [\buf,b,\freq,400,\shp,1,\amp,0.2,\gate,1],s,\addToTail);

a.set(\shp,0.5);
a.set(\shp, ~mouseY.asMap);
a.free;
