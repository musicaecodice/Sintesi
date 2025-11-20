ServerOptions.devices;

s.options.inDevice_("Microfono MacBook Air");
//s.options.outDevice_("Altoparlanti MacBook Air");
s.options.outDevice_("Auricolari esterni");

s.reboot;
s.scope;
s.freqscope;
s.plotTree;

// -----------------------------> Tipologie di Segnali

// Tre
:

// • Rata
// • Range
// • Morfologia

// -----------------------------> Rata

// Audio rate vs Control rate

{[SinOsc.ar, SinOsc.kr]}.plot;

// Conversioni

{[WhiteNoise.kr,  A2K.kr(WhiteNoise.ar)]}.scope;  // Audio --> controllo (downsampling)
{[WhiteNoise.ar,  K2A.ar(WhiteNoise.kr)]}.scope;  // Controllo --> audio (upsampling)

// La seconda NO interpolazione...

// -----------------------------> Interprete --> Server

// Possiamo anche convertire int e float in un segnale audio

// Costante

{K2A.ar(0.6)}.plot(minval:-1,maxval:1);

// Smoothed (interpolato)

(
SynthDef(\lag, {arg amp=0, smth=0.2;
	            var sig, ksig;
	                sig  = SinOsc.ar!2;
	                ksig = Lag.kr(amp, smth).scope; // - 60 dB (esponenziale)
	            Out.ar(0, sig*ksig)
}).add;
)

a = Synth(\lag);

a.set(\amp, rand(1.0),\smth, 0.1);
a.set(\amp, rand(1.0),\smth, 1.9);
a.free;

(
SynthDef(\varlag, {arg freq=0, smth=0.2, curva=0;
	               var sig, ksig;
		               ksig = VarLag.kr(freq, smth, curva); // curva variabile
	                   sig  = SinOsc.ar(ksig!2);
	               Out.ar(0, sig*0.3)
}).add;
)

a = Synth(\varlag);

a.set(\freq, rrand(60,92).midicps,\smth, 0.5, \curva, 0);  // lineare
a.set(\freq, rrand(60,92).midicps,\smth, 0.5, \curva, 8);  // esponenziale
a.set(\freq, rrand(60,92).midicps,\smth, 0.5, \curva, -4); // logaritmico

a.free;

// -----------------------------> Server --> Interprete

(
SynthDef(\inviaM, {var sig;
                       sig = LFNoise0.kr(3);   // Segnale da campionare

                   SendReply.kr(Impulse.kr(2), // Rata di sottocampionamento
                                '/posa',       // Etichetta
                                sig);          // Segnale da inviare
                  }).add;

OSCdef.freeAll;
OSCdef.new(\ricevi, {arg val; val.postln},'/posa');
// val = [Etichetta, Nodo, -1, valore]
)

a = Synth(\inviaM);
a.free;
