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
~pchBusIn.free;
~pchBusOut.free;

~micBus       = Bus.audio(s,1);   // Bus Microfono
~pchBusIn     = Bus.audio(s,1);   // Bus Pitch follower (audio)
~pchBusOut    = Bus.control(s,2); // Bus uscita (controllo 2 canali)
~pchAmpBusOut = Bus.control(s,3); // Bus uscita (controllo 3 canali)

~micGrp  = Group.new;            // Gruppo sources
~folGrp  = Group.after(~micGrp); // Gruppo analisi
~playGrp = Group.after(~folGrp); // Gruppo synth

a = Synth(\mic,    [\inBus,0,        \outBus,~micBus, \amp,1],       ~micGrp); // Sig in
b = Synth(\router, [\inBus, ~micBus, \outBus,~pchBusIn, \fadeT, 0.5], ~micGrp, \addToTail);
)

// -----------------------------> Pitch following

// Due UGens in ordine crescente di precisione ma anche di consumo di cpu...

// -----------------------------> Pitch.ar()

// Solo a kr

// # freq, hasPitch = una sintassi usata per assegnare i valori degli items di un array
//                    direttamente a due variabili

// hasFreq = 0 nessuna stima di pitch
//         = 1 pitch stimato

(
SynthDef(\pchflw1, {arg inBus=0,outBus=0,high=1000,low=60,median=1;
	                var sig, freq, hasFreq;
	                    sig = In.ar(inBus,1);
	                    sig = LPF.ar(sig, 2000);           // Filtro passa basso

	                    #freq, hasFreq = Pitch.kr(sig,     // Segnale
		                                          high,    // Pitch di riferimento
		                                          low,     // Pitch più basso
		                                          high,    // Pitch più acuto
		                                          median:median, // Median filter
	                                              );
	                    freq.poll;
	                    hasFreq.poll;
	               Out.kr(outBus,[freq,hasFreq])
          }).add;
)

c = Synth(\pchflw1, [\inBus,~pchBusIn,\outBus,~pchBusOut,\median,7],~folGrp);
c.free;

// -----------------------------> Tartini.ar()

// hasFreq non è solo 1 o 0 ma un valore di precisione tra 0 e 1
// Più preciso ma non necessariamente migliore a livello percettivo...
// dipende dal mapping...

(
SynthDef(\pchflw2, {arg inBus=0,outBus=0;
	                var sig, freq, hasFreq;
	                    sig = In.ar(inBus,1);
	                    sig = LPF.ar(sig, 2000);

	                    #freq, hasFreq = Tartini.kr(sig);
	                    freq.poll;
	                    hasFreq.poll;
	               Out.kr(outBus,[freq,hasFreq])
          }).add;
)

c = Synth(\pchflw2, [\inBus,~pchBusIn,\outBus,~pchBusOut],~folGrp);
c.free;

// -----------------------------> Mapping continuo

(
SynthDef(\sine1, {arg inBus=0,outBus=0;
	             var sig,freq,amp;
	                 freq = In.kr(inBus,2);
	                 sig  = Mix(SinOsc.ar(freq[0] * [0.5,1,3])); // sinusoide su 3 ottave...
	                 amp  = freq[1].lag(0.2) * 0.2;              // smoothing...
	             Out.ar(outBus,sig * amp!2)
         }).add;
)

(  // Con Pitch.ar() ...
c = Synth(\pchflw1, [\inBus,~pchBusIn,\outBus,~pchBusOut,\median,7],~folGrp);
d = Synth(\sine1,   [\inBus,~pchBusOut],                           ~playGrp);
)

c.free;d.free;

(  // Con Tartini.ar() ...
c = Synth(\pchflw2, [\inBus,~pchBusIn,\outBus,~pchBusOut,\median,7],~folGrp);
d = Synth(\sine1,   [\inBus,~pchBusOut],                           ~playGrp);
)

c.free;d.free;


// -----------------------------> Pitch + Amp follow

// I parametri fluttuano...
// Una possibile soluzione è inserire un Amplitude follower...

(
SynthDef(\pchflw3, {arg inBus=0,outBus=0,atk=0.01,dec=0.01,ft=2000;
	                var sig, amp, freq, hasFreq;
	                    sig = In.ar(inBus,1);
	                    amp = Amplitude.kr(sig, atk, 0.01); // Amplitude follower
	                    sig = LPF.ar(sig, ft);              // Filtro passa basso
	                    #freq, hasFreq = Tartini.kr(sig);   // Pitch follower
	                    freq.poll;
	                    hasFreq.poll;
	               Out.kr(outBus,[freq, hasFreq, amp])      // 3 canali...
          }).add;

// -----------------------------> Synth sine

SynthDef(\sine3, {arg inBus=0,outBus=0,soglia=0.05;
	              var sig,freq,env;
	                  freq = In.kr(inBus, 3);
	                  sig  = Mix(SinOsc.ar(freq[0] * [0.5,1,3])); // sinusoide su 3 ottave...
	                  env  = (freq[2] > soglia).lag(0.4) * 0.2;   // Se ampiezza > soglia = 1
	              Out.ar(outBus, sig * freq[1] * env!2)
         }).add;
)

(
c = Synth(\pchflw3, [\inBus,~pchBusIn,\outBus,~pchAmpBusOut, \median,7],~folGrp);
d = Synth(\sine3,   [\inBus,~pchAmpBusOut],                            ~playGrp);
c.set(\soglia,0.1)
)

c.free;d.free;

// -----------------------------> Mapping trigger

// Ad esempio se un pitch è compreso tra un minimo e un massimo manda un trigger...

(
SynthDef(\pchflw4, {arg inBus=0,outBus=0, low=200,high=300;
	                var sig, freq, hasFreq,trig1,trig2,trig;
	                    sig = In.ar(inBus,1);
	                    sig = LPF.ar(sig, 2000);
	                    #freq, hasFreq = Tartini.kr(sig);
                        freq.poll;
	                    trig1 = freq > low;
	                    trig2 = freq < high;
	                    trig  = Trig1.ar((trig1 + trig2 -1).poll, 0.5); // Limita la ridondanza...
	                Out.kr(outBus,[freq,hasFreq]);

		// Invia all'Interprete...

	                SendTrig.ar(trig,
		                        113,   // id del trigger (nel caso fossero + di 1)
                                freq); // Segnale da inviare
          }).add;

SynthDef(\sine4, {arg freq;
	              var sig,env;
	                  sig  = Mix(SinOsc.ar(freq * [0.5,1,3])); // sinusoide su 3 ottave...
	                  env  = EnvGen.kr(Env.perc,doneAction:2);
	              Out.ar(0, sig * env * 0.2!2)
         }).add;
)

(
c = Synth(\pchflw4, [\inBus,~pchBusIn,\outBus,~pchBusOut], ~folGrp);

	// Riceve dal Server...

e = OSCFunc.new({arg msg; msg.postln; Synth(\sine4, [\freq,msg[3]],~playGrp)},'/tr', s.addr);
)

c.free;e.free;

// Fai esempio con freqshift relativo...

