s = Server.local;

s.options.inDevice_("Microfono MacBook Air"); // Device in ingresso
s.options.outDevice_("Auricolari esterni");   // Device in uscita
s.options.inDevice_("Altoparlanti MacBook Air");
s.options.numInputBusChannels_(1);            // numero canali in ingresso
s.options.numOutputBusChannels_(8);           // Numero canali in uscita

s.boot;

(
s.meter;
s.scope;
s.plotTree;
)

s.reboot;

(
// -----------------------------> Synth input

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
)

// -----------------------------> Bus e Gruppi

(
~micBus.free;
~onsBusIn.free;
~onsBusOut.free;

~micBus    = Bus.audio(s,1); // Bus Microfono
~onsBusIn  = Bus.audio(s,1); // Bus Envelope follower
~onsBusOut = Bus.audio(s,1); // Bus segnale uscita (audio 1 canale)

~micGrp  = Group.new;            // Gruppo sources
~folGrp  = Group.after(~micGrp); // Gruppo analisi
~playGrp = Group.after(~folGrp); // Gruppo synth

a = Synth(\mic,    [\inBus,0,        \outBus,~micBus, \amp,1],        ~micGrp); // Sig in
b = Synth(\router, [\inBus, ~micBus, \outBus,~onsBusIn, \fadeT, 0.5], ~micGrp, \addToTail);
)

// -----------------------------> Onset detection

// Diverse strategie...

// -----------------------------> Comparazione

// Comparare un segnale con una copia ritardata di se stesso:

// Stabilire una soglia in dBspl
// Stabilire una zona morta (dur) del trigger

(
SynthDef(\onsDet1, {arg inBus=0,outBus=0,atk=0.01,dec=0.01,dur=0.2,soglia=20; // soglia in dB
	                var sig, amp, del, diff, trig;
	                    sig  = In.ar(inBus,1);
	                    amp  = Amplitude.ar(sig,atk,dec); // Env follower
	                    del  = DelayN.ar(amp, 0.01,0.01); // Delay di 10ms
	                    diff = (amp / del.max(0.001)).ampdb *
	                            EnvGen.kr(Env([0, 0, 1], [0.1, 0.1])).poll;
	                    trig = Trig1.ar(diff > soglia, dur);
	                Out.ar(outBus, trig);

		// Invia all'Interprete...

	               SendTrig.ar(trig,153, 1);
         }).add;
)

(
c = Synth(\onsDet1, [\inBus,~onsBusIn,\outBus,~onsBusOut,\soglia,12], ~folGrp);
d = ~onsBusOut.scope; // monitor visivo...

	// Riceve dal Server...

e = OSCFunc.new({arg msg; msg.postln},'/tr', s.addr);
)

c.set(\soglia,32); // in dB

c.free;d.free;e.free;

// -----------------------------> Slope.ar()

// Oppure semplificare usando la UGen Slope...
// ma in questo caso non possiamo stabilire la "sensibilità"

(
SynthDef(\onsDet2, {arg inBus=0,outBus=0,atk=0.01,dec=0.01,dur=0.2,soglia=12;
	                var sig, amp, slope, trig;
	                    sig   = In.ar(inBus,1);
	                    amp   = Amplitude.ar(sig,atk,dec); // Env follower
	                    slope = Slope.ar(amp);             // Misura la rate di cambiamento per secondo
	                    trig  = Trig1.ar(slope > soglia, dur);
	                Out.ar(outBus, trig);

		// Invia all'Interprete...

	               SendTrig.ar(trig,153, 1);
         }).add;
)

(
c = Synth(\onsDet2, [\inBus,~onsBusIn,\outBus,~onsBusOut], ~folGrp);
d = ~onsBusOut.scope; // monitor visivo...

	// Riceve dal Server...

e = OSCFunc.new({arg msg; msg.postln},'/tr', s.addr);
)

c.free;d.free;e.free;

// -----------------------------> Mapping trigger

// Se stabiliamo ad esempio delle soglie possiamo generare un trigger...

(
SynthDef(\saw, {arg inBus=0,outBus=0;
	            var sig, gate, env;
	                gate = In.ar(inBus,1);
	                env  = EnvGen.kr(Env.adsr, gate);
	                sig  = Saw.ar(LFNoise0.kr([10,12]).range(300,1000));
	            Out.ar(outBus,sig * env * 0.5);
         }).add;

SynthDef(\noise, {arg outBus=0;
	              var sig, env;
	                  sig  = PinkNoise.ar;
	                  env  = EnvGen.kr(Env.perc(0.01,TRand.kr(0.02,0.1,1)),1, doneAction:2);
	              Out.ar(outBus,sig * env!2);
         }).add;
)

(
c = Synth(\onsDet1, [\inBus,~onsBusIn,\outBus,~onsBusOut,\soglia,12], ~folGrp);
d = Synth(\saw,   [\inBus,~onsBusOut,\outBus,0],        ~playGrp);

e = OSCFunc.new({arg msg; Synth(\noise,target:~playGrp)},'/tr', s.addr);
)

c.free;d.free;e.free;

// -----------------------------> Altre UGens...

// Queste UGens sono più complesse e utilizzano un'analisi FFT del segnale

Onsets
Coyote // Non FFT...
