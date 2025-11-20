ServerOptions.devices;

s.options.inDevice_("Microfono MacBook Air");
//s.options.outDevice_("Altoparlanti MacBook Air");
s.options.outDevice_("Auricolari esterni");

s.reboot;
s.scope;
s.freqscope;
s.plotTree;

s.options.numControlBusChannels; // Numero di Bus di controllo

// Tutti privati

// -----------------------------> Inviare argomenti a un Synth .map()

// Attraverso questi bus possiamo inviare argomenti a un Synth
// sia come number (int e float) che come segnali di controllo.

// Creiamo un Bus di controllo

~kbus1 = Bus.control(s, 1); // Crea un Bus di controllo mono
~kbus1.scope;               // Monitor visivo

~kbus1.set(0.5);

// Creiamo una SynthDef dove specificihamo argomenti a kr:

(
SynthDef(\sine, {arg amp=0.5,freq=400;
	             var sig;
	                 sig  = SinOsc.ar(freq)*amp;
	             Out.ar(0, sig)}, [0, 0]  // Rate 0 = control
         ).add;
)

(
// Sintassi alternativa...

SynthDef(\sine, {arg amp=0.5;
	             var sig, freq;
	                 freq = \freq.kr;
	                 sig  = SinOsc.ar(freq)*amp;
	             Out.ar(0, sig)},
         ).add;
)

// Creiamo delle SynthDef a kr per i segnali di controllo

(
SynthDef(\rsig, {arg out;
	             var sig;
	                 sig = LFNoise0.kr(3).range(300,600);
                  Out.kr(out, sig)}
         ).add;

SynthDef(\ksin, {arg out;
	             var sig;
	                 sig = SinOsc.kr(MouseY.kr(10,500)).range(200,800);
                  Out.kr(out, sig)}
         ).add;
)

a = Synth(\sine, [\freq, 400]);    // Argomenti...
a.set(\freq,rrand(200,500));       // Cambia il valore (number) dall'Interprete

b = Synth(\rsig, [\out, ~kbus1]);  // Scrive sul Bus di controllo
a.map(\freq, ~kbus1);              // Sostituisce l'argomento con i valori scritti sul Bus
                                   // (Server side)
a.set(\freq,rrand(200,500));       // Scollega il Bus di controllo

b.free; // Distrugge il Synth e sul Bus rimane l'ultimo valore...

c = Synth(\ksin, [\out, ~kbus1]);
a.map(\freq, ~kbus1);              // Un nuovo segnale di controllo...
a.set(\freq,rrand(200,500));
c.free;
a.free;

// -----------------------------> Leggere valori dal Bus .get()

// Server --> Interprete

~kbus2 = Bus.control(s, 1);

(
SynthDef(\randi, {arg out,rate;
	              var sig = LFNoise0.ar(rate);
	              Out.kr(out,sig)}               // controllo
         ).add;
)

y = Synth(\randi,[\out,~kbus2,\rate,10]);

~kbus2.get({arg val; val.postln});

// Ovviamente possiamo automatizzare il campionamento con Routine, Task e Clock

(
r = Routine.new({

	             inf.do({~kbus2.get.get({arg val; val.postln});
		                 0.2.wait
	                     })

                 }).play;
)

r.stop;
r.free;

// N.B. Se volessimo utilizzare il valore nell'Interprete possiamo assegnarlo a
//      una variabile.

a = Synth(\sine);

(
r = Routine.new({

	inf.do({ ~kbus2.get({arg val; a.set(\amp, val.linlin(-1,1,0,1).postln,\freq,500)});
		                 0.2.wait
	})
                 }).play;
)
