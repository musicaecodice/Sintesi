(
s = Server.local;
s.options.memSize_(2.pow(20)); // per Delay...
s.boot;
s.freqscope;
{s.plotTree}.defer(3);
)

// -----------------------------> Risintesi

// Ci sono tre possibili modi per elaborare la spectral data memorizzata in un Buffer.
// Tipicamente il percorso è il seguente:

// SigIN --> FFT --> Operazioni sui bins --> IFFT --> SigOUT

// 1) Operazioni sui bins di un solo segnale analizzato
// 2) Operazioni su ogni singolo bin di un segnale analizzato
// 3) Operazioni sui bins di due segnali analizzati


// -----------------------------> Utilità...

(
Buffer.freeAll;
b = Buffer.read(s,"suoni/voce.wav".resolveRelative);
c = Buffer.read(s,"suoni/bach.wav".resolveRelative);

SynthDef(\source, {arg amp=0,outBus=9,buf=0,tipo=0,trsp=0;
	                  var sig;
	                      sig = Select.ar(tipo, [WhiteNoise.ar,
		                                     Saw.ar([40,47,52,56,58,61,63].midicps*trsp.midiratio,0.05).sum,
		                                      PlayBuf.ar(1,buf,BufRateScale.kr(buf),loop:1),
		                                      SoundIn.ar(0)]);
	               Out.ar(outBus,sig*amp)
         }).add;

~fft1   = Bus.audio(s,1);   // Segnale da analizzare
~fft2   = Bus.audio(s,1);   // Segnale da analizzare

{
~source1 = Synth(\source,[\outBus,~fft1,\buf,b]);
~source2 = Synth(\source,[\outBus,~fft2,\buf,b])
}.defer(1)
)

// -----------------------------> pvcalc

// Se vogliamo elaborare magnitudini e fasi di un solo segnale.

// Ad ogni analisi (Frame) riporta due Arrays, uno per le magnitudini e uno per le fasi
// sui quali possiamo effettuare qualsiasi tipo di operazione consentita con Array.
// Restituisce gli Array trasformati

// La funzione viene valutata solo una volta quando inviamo la SynthDef al Server
// mentre gli argomenti vengono passati ogni FRAME dell'analisi...

// Elaborazioni tipiche:

// – Morphing

(
SynthDef(\pvcalc, {arg inBus=0,outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0;
	                  var in,size,ksig,chain,env,sig;
	                      in    = In.ar(inBus,1);          // Segnale da analizzare
	                      size  = 2048;

	                      ksig  = WhiteNoise.kr;           // SE vogliamo cambiamenti continui

	                      chain = FFT(LocalBuf(size), in); // FFT
	                      chain = chain.pvcalc(size,       // il size del Buffer per la FFT

		                       {arg mag, fasi;          // Funzione dove effettuare i calcoli...
// -----------------------------------------------------------------
		  //	[mag.reverse,fasi.scramble];   // solo la prima volta...
					   [mag * ksig, fasi]  // ad ogni frame moltiplica TUTTO l'Array per il singolo valore di ksig
// -----------------------------------------------------------------
		                       },
		                       frombin: 0,             // Il primo bin da leggere
		                       tobin:  250,            // (diminuisce il carico CPU)
		                       zeroothers:1);          // 1 = non processa i bins > tobin

	                   env   = Linen.kr(gate,fadeT,1,fadeT,2);
	                   sig   = IFFT(chain) * env * amp;  // Produce [mag,phase]
	                   sig   = Pan2.ar(sig, pan);
	               Out.ar(outBus, sig);
           }).add;
)

a = Synth(\pvcalc, [\inBus,~fft1,\amp,1,\gate,1],s,'addToTail');

~source1.set(\amp,1);
~source1.set(\tipo,1,\trsp,0);
~source1.set(\tipo,2,\buf,b);
~source1.set(\tipo,3);

a.set(\gate,0)

// -----------------------------> pvcollect

// Se vogliamo effettuare operazioni sui singoli bin di un solo segnale.

// Elaborazioni tipiche:

// – Filtri ideali
// – Delay spettrali

// Gli argomenti della funzione restituiscono per ogni bin:
// magnitude, fase, bin, idx

// bin = bin number che comincia dal primo bin selezionato
//       0 = DC (non la frequenza).
// idx = numero di iterazione (sempre da 0)

(
SynthDef(\pvcollect, {arg inBus=0,outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0,
	                      lowBin= 0, hiBin=256;
	                  var in,size,ksig,chain,env,sig;
	                      in    = In.ar(inBus,1);          // Segnale da analizzare
	                      size  = 2048;

		                  ksig  = LFNoise1.kr(0.1).range(0.1,4);// SE vogliamo cambiamenti continui

	                      chain = FFT(LocalBuf(size), in);

	                      chain = chain.pvcollect(size, {arg mag,phase,bin,idx;
// -----------------------------------------------------------------
			                    if((bin > lowBin) * (bin < hiBin), mag, 0); // Filtro
		                     //    mag + DelayN.kr(mag, 4, ksig)              // Delay
// -----------------------------------------------------------------
		                                               });

	                      env = Linen.kr(gate,fadeT,1,fadeT,2);
	                      sig = IFFT(chain) * env * amp;
	                      sig = Pan2.ar(sig, pan);
	                  Out.ar(outBus, sig);
         }).add;
)

a = Synth(\pvcollect, [\inBus,~fft1,\gate,1],s,'addToTail');

~source1.set(\amp,1);

~source1.set(\tipo,1,\trsp,0);
~source1.set(\tipo,2,\buf,c);
~source1.set(\tipo,3);

a.set(\lowBin,0,  \hiBin,   50); // Passa basso
a.set(\lowBin,50, \hiBin,  100); // Passa banda
a.set(\lowBin,100,\hiBin, 1024); // Passa alto

a.set(\gate,0);

// -----------------------------> pvcalc2

// Se vogliamo effettuare operazioni sui bin di due segnali...
// Due FFT: operazioni su magnitudini e fasi delle due analisi...

// Elaborazioni tipiche:

// – Cross Synthesis
// – Convoluzione

(
SynthDef(\pvcalc2, {arg inBus=#[0,1],outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0,
	                   xfade=0.5;
	               var in1,in2,size,ksig,chain1,chain2,chain,env,sig;
	                   in1   = In.ar(inBus[0],1);          // Segnale 1
		               in2   = In.ar(inBus[1],1);          // Segnale 2
	                   size  = 2048;

		               ksig  = LFNoise1.kr(0.1).range(0.1,4);// SE vogliamo cambiamenti continui

	                   chain1 = FFT(LocalBuf(size), in1);
		               chain2 = FFT(LocalBuf(size), in2);

	                   chain1 = chain1.pvcalc2(chain2, size, {arg mag1,phase1,mag2,phase2;
// -----------------------------------------------------------------
		                       mag1 = (mag1 * xfade) + (mag2 * (1-xfade));
		                       [mag1, phase2]
// -----------------------------------------------------------------
		                                               });

	                      env = Linen.kr(gate,fadeT,1,fadeT,2);
	                      sig = IFFT(chain1) * env * amp;
	                      sig = Pan2.ar(sig, pan);
	                  Out.ar(outBus, sig);
         }).add;
)

a = Synth(\pvcalc2, [\inBus,[~fft1,~fft2],\gate,1],s,'addToTail');

(
~source1.set(\amp,1,\tipo,2,\buf,b);
~source2.set(\amp,1,\tipo,1,\trsp,rand(12).postln);
a.set(\xfade,rand(1.0).round(0.01).postln);
)

a.set(\gate,0);

// Questi tre oggetti sono molto costosi a livello computazionale.

// In SuperCollider esistono però numerose UGens dedicate alle
// diverse tecniche di analisi ed elaborazione spettrale:

// (Help file --> Browser --> UGens --> FFT)

