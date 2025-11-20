ServerOptions.devices;

(
s = Server.local;
s.options.device_("Scarlett 18i20 USB");
s.options.memSize_(2.pow(20)); // per Delay...
s.boot;
s.freqscope;
s.meter;
{s.plotTree}.defer(3);
)

// -----------------------------> Risintesi

// Ci sono diverse tecniche per ri-sintetizzare la spectral data generata
// da una FFT e memorizzata in un Buffer oltre all'Overlap-add resynthesis.

// Una delle più utilizzate è il Phase Vocoder.

// In questa tecnica dopo aver ottenuto un Frame contenente i valori di magnitude e phase
// per ogni bin li converte in due inviluppi:

// • uno per l'ampiezza della sinusoide corrispondente al bin.
// • uno per la frequenza della sinusoide corrispondente al bin.

// In SC ci sono molte UGens dedicate alle elaborazioni spettrali (PV_UGens):

// SigIN --> FFT --> PV_UGens --> IFFT --> SigOUT

// Principali tecniche di elaborazione:

// Delays spettrali
// Filtri spettrali o morphing  (singolo segnale)
// Freeze spettrale   (singolo segnale)
// Cross Synthesis    (due segnali)

// In questi esempi mapperemo gli argomenti su dei segnali di controllo per rendere
// più musicale l'esplorazione delle possibilità ma potremmo utilizzare anche dei
// valori costanti...

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
~mouseX = Bus.control(s,1); // Bus di controllo che potranno tornare utili...
~mouseY = Bus.control(s,1);

{
~source1 = Synth(\source,[\outBus,~fft1,\buf,c]);
~source2 = Synth(\source,[\outBus,~fft2,\buf,c]);
~mkX = {arg min=0,max=1; Out.kr(~mouseX, MouseX.kr(min,max))}.play;      // tra 0 e 1
~mkY = {arg min=0,max=1; Out.kr(~mouseY, MouseY.kr(min,max))}.play;      // tra 0 e 1
}.defer(1)
)

// -----------------------------> Delay (1 segnale)

// Differenza con i Delay non spettrali: si può cambiare dinamicamente
// il tempo di delay senza artefatti nel suono ma è molto costoso
// a livello computazionale...

(
SynthDef(\sdel_1, {arg inBus=0,outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0,
	                   maxdel=1,del= 0;
	               var in,size,chain,env,sig;
	                   in    = In.ar(inBus,1);          // Segnale da analizzare
	                   size  = 2048;

	                   chain = FFT(LocalBuf(size), in);
// -----------------------------------------------------------------
	                   chain = chain.pvcollect(size, {arg mag,fasi,bin;

		         //     mag + DelayN.kr(mag, maxdel, del.linlin(0,1,0,maxdel)) // Semplice
		         //     mag + DelayN.kr(mag, 1, del * rand(maxdel))            // Ogni bin del random
                      [mag + DelayN.kr(mag, 1, del * rand(maxdel)), // Ogni bin del random
			           fasi * rand(pi)]                             // Modifica delle fasi...
				                               },0,256,-1);
// -----------------------------------------------------------------

	                      env = Linen.kr(gate,fadeT,1,fadeT,2);
	                      sig = IFFT(chain) * env * amp;
	                      sig = Pan2.ar(sig, pan);
	                  Out.ar(outBus, sig);
         }).add;
)

(
a = Synth(\sdel_1, [\inBus,~fft1,\amp,1,\gate,1],s,'addToTail');
~source1.set(\amp,1,\tipo,3);    // LIVE INPUT!!!!
)

a.set(\del,0.6);           // Invia il valore
a.set(\del,~mouseX.asMap); // Collega il Bus di controllo
a.set(\gate,0);

// -----------------------------> Filtro BrickWall (1 segnale)

// Passano solo i bins sopra o sotto una soglia compresa tra +/-1
// Come filtro passa basso/passa alto

(
SynthDef(\bwall, {arg inBus=0,outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0,
	                  lpf=20000,hpf=20;
	              var in,size,chain,env,sig;
	                  in    = In.ar(inBus,1);          // Segnale da analizzare
		              size  = 2048;
	                  chain = FFT(LocalBuf(size), in);
// -----------------------------------------------------------------
	                  chain = PV_BrickWall(chain, lpf.linlin(20,20000,-1,0)); // Passa basso
	                  chain = PV_BrickWall(chain, hpf.linlin(20,20000,0,1));  // Passa alto
// -----------------------------------------------------------------
	                  env   = Linen.kr(gate,fadeT,1,fadeT,2);
	                  sig   = IFFT(chain) * env * amp;
	                  sig   = Pan2.ar(sig, pan);
	              Out.ar(outBus, sig);
         }).add;
)

(
a = Synth(\bwall, [\inBus,~fft1,\amp,1,\gate,1],s,'addToTail');
~source1.set(\amp,1,\tipo,2);    // SYNTH INPUT...
~mkX.set(\min,20,\max,10000);
~mkY.set(\min,20,\max,10000);
)

a.set(\lpf,1000, \hpf,20);   // Lowpass filter
a.set(\lpf,20000,\hpf,1000); // Hipass filter
a.set(\lpf,1500, \hpf,1000); // Bandpass
a.set(\lpf,350, \hpf,350,\amp,1); // singolo bin...
a.set(\lpf,450, \hpf,350,\amp,1); // formanti...

a.set(\lpf,~mouseY.asMap,\hpf,~mouseX.asMap); // Collega il Bus di controllo
~source1.set(\amp,1,\tipo,2,\buf,c);    // SYNTH INPUT...

a.set(\gate,0);

// Banco di filtri...

a = 4.collect({ Synth(\bwall, [\inBus,~fft1,\amp,0.2,\gate,1],s,'addToTail') });

(
a[0].set(\hpf,100, \lpf,150);
a[1].set(\hpf,400, \lpf,750);
a[2].set(\hpf,1600, \lpf,3000);
a[3].set(\hpf,7000, \lpf,15000);
)

a.do({arg i,id; a[id].set(\gate,0)});

// -----------------------------> Filtro RectComb (1 segnale)

// teeth = numero di denti del pettine
// phase = fase iniziale (tra 0 e 1)
// width = duty cycle di ogni filtro   (tra 0 e 0.5)

(
SynthDef(\rcomb, {arg inBus=0,outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0,
	                  teeth=10,fase=0,width=0.5;
	              var in,size,chain,env,sig;
	                  in    = In.ar(inBus,1);          // Segnale da analizzare
		                 size  = 2048;
	                  chain = FFT(LocalBuf(size), in);
// -----------------------------------------------------------------
	                  chain = PV_RectComb(chain, teeth, fase, width);
// -----------------------------------------------------------------
	                  env   = Linen.kr(gate,fadeT,1,fadeT,2);
	                  sig   = IFFT(chain) * env * amp;
	                  sig   = Pan2.ar(sig, pan);
	              Out.ar(outBus, sig);
         }).add;
)

(
a = Synth(\rcomb, [\inBus,~fft1,\amp,1,\gate,1],s,'addToTail');
~source1.set(\amp,1,\tipo,2,\buf,c);    // SYNTH INPUT...
~mkX.set(\min,1,\max,256);
~mkY.set(\min,0.01,\max,0.5);
)

a.set(\fase,0.0);
a.set(\fase,0.1);
a.set(\fase,0.2);
a.set(\fase,0.3);
a.set(\fase,0.4);
a.set(\fase,0.5);
a.set(\fase,0.6);
a.set(\fase,0.7);
a.set(\fase,0.8);
a.set(\fase,0.9);
a.set(\fase,1.0);

a.set(\teeth, 22);
a.set(\width,0.01);

a.set(\width,~mouseY.asMap,\teeth,~mouseX.asMap); // Collega il Bus di controllo

a.set(\gate,0);

// -----------------------------> Filtro MagAbove/MagBelow (1 segnale)

// Vedi anche PV_MagBelow...
// Passa solo i bins che sono sopra una soglia di ampiezza

(
SynthDef(\magab, {arg inBus=0,outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0,
	                  soglia=1;
	              var in,size,chain,env,sig;
	                  in    = In.ar(inBus,1);          // Segnale da analizzare
		              size  = 2048;
	                  chain = FFT(LocalBuf(size), in);
// -----------------------------------------------------------------
	                  chain = PV_MagAbove(chain, soglia);
		            //  chain = PV_MagBelow(chain, soglia);
// -----------------------------------------------------------------
	                  env   = Linen.kr(gate,fadeT,1,fadeT,2);
	                  sig   = IFFT(chain) * env * amp;
	                  sig   = Pan2.ar(sig, pan);
	              Out.ar(outBus, sig);
         }).add;
)

(
a = Synth(\magab, [\inBus,~fft1,\amp,1,\gate,1],s,'addToTail');
~source1.set(\amp,1,\tipo,2,\buf,c);    // SYNTH INPUT...
~mkX.set(\min,0,\max,40);
)

a.set(\soglia,rrand(1,10).postln);
a.set(\soglia,~mouseX.asMap); // Collega il Bus di controllo

~source1.set(\amp,1,\tipo,3);    // LIVE INPUT!!!!

a.set(\gate,0);

// -----------------------------> Filtro MagSmear (1 segnale)

// Fa una media delle ampiezze tra bins vicini
// Numero di vicini da mediare su ogni lato
// più bins di smear più aumenta la cpu più il segnale è noisy

(
SynthDef(\smear, {arg inBus=0,outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0,
	                  bins=1;
	              var in,size,chain,env,sig;
	                  in    = In.ar(inBus,1);          // Segnale da analizzare
		              size  = 2048;
	                  chain = FFT(LocalBuf(size), in);
// -----------------------------------------------------------------
	                  chain = PV_MagSmear(chain, bins);
// -----------------------------------------------------------------
	                  env   = Linen.kr(gate,fadeT,1,fadeT,2);
	                  sig   = IFFT(chain) * env * amp;
	                  sig   = Pan2.ar(sig, pan);
	              Out.ar(outBus, sig);
         }).add;
)

(
a = Synth(\smear, [\inBus,~fft1,\amp,1,\gate,1],s,'addToTail');
~source1.set(\amp,1,\tipo,2,\buf,c);    // SYNTH INPUT...
~mkX.set(\min,1,\max,200);
)

a.set(\bins,rrand(1,40).postln);
a.set(\bins,~mouseX.asMap); // Collega il Bus di controllo

a.set(\gate,0);


// -----------------------------> Freeze (1 segnale)

// Quando freeze > 0 freeze le magnitudini correnti

(
SynthDef(\freez, {arg inBus=0,outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0,
	                  freeze=0;
	              var in,size,chain,env,sig;
	                  in    = In.ar(inBus,1);
		              size  = 2048;
	                  chain = FFT(LocalBuf(size), in);
// -----------------------------------------------------------------
	                  chain = PV_MagFreeze(chain, freeze);
// -----------------------------------------------------------------
	                  env   = Linen.kr(gate,fadeT,1,fadeT,2);
	                  sig   = IFFT(chain) * env * amp;
	                  sig   = Pan2.ar(sig, pan);
	              Out.ar(outBus, sig);
         }).add;
)

(
a = Synth(\freez, [\inBus,~fft1,\amp,1,\gate,1],s,'addToTail');
~source1.set(\amp,1,\tipo,3);    // LIVE INPUT...
~mkX.set(\min,-1,\max,1);
)

a.set(\freeze,1);
a.set(\freeze,0);
a.set(\freeze,~mouseX.asMap); // Collega il Bus di controllo

a.set(\gate,0);

// -----------------------------> Scratch (1 segnale)

// Prima dobbiamo analizzare un SF e memorizzare i dati di analisi
// in un Buffer:

(
~path = "/Users/andreavigani/Desktop/Milano_2021_22/0Corsi_21_22/Suoni_2/bach.wav";
~sf = SoundFile.new(~path);
~sf.openRead;
~sf.close;
~size = 2048;

e = Buffer.alloc(s, ~sf.duration.calcPVRecSize(~size,0.25)); // Buffer per data analisi
c = Buffer.read(s, ~path);                                   // Buffer con sf
)

(
SynthDef("pvrec", {arg recBuf=1, sndBuf=2;
                   var in, chain, bufnum;
                       bufnum = LocalBuf.new(~size);
                       in    = PlayBuf.ar(1,sndBuf,BufRateScale.kr(sndBuf),doneAction:2);
                       chain = FFT(bufnum, in, 0.25, 1); // Hann window...
                       chain = PV_RecordBuf(chain, recBuf,0,1,0,0.25,1);

    }).add;
)

a = Synth("pvrec", [\recBuf, e, \sndBuf, c]);

c.write(~path++".scpv", "wav", "float32"); // Possiamo salvare l'analisi in un file...

(
SynthDef(\sctch, {arg outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0,
	                  buf=0,punta=0;
	              var chain,env,sig;
	                  chain = LocalBuf(~size);
// -----------------------------------------------------------------
	                  chain = PV_BufRd(chain, buf, punta);
// -----------------------------------------------------------------
	                  env   = Linen.kr(gate,fadeT,1,fadeT,2);
	                  sig   = IFFT(chain) * env * amp;
	                  sig   = Pan2.ar(sig, pan);
	              Out.ar(outBus, sig);
         }).add;
)

(
a = Synth(\sctch, [\inBus,~fft1,\buf,e,\amp,1,\gate,1],s,'addToTail');
~mkX.set(\min,0,\max,1);
a.set(\punta,~mouseX.asMap); // Collega il Bus di controllo
)

a.set(\gate,0);

// -----------------------------> Morph (Cross-synthesis)

// Una variante di morphing spettrale
// Sostituisce gradualmente i bins del segnale A con quelli del segnale B
// morph: 0 --> 1

(
SynthDef(\cross1, {arg inBus=#[0,1],outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0,
	                   morph=0;
	               var inA,inB,size,chainA,chainB,chain,env,sig;
	                   inA    = In.ar(inBus[0],1);
		               inB    = In.ar(inBus[1],1);
		               size   = 2048;
		               chainA = FFT(LocalBuf(size), inA);
			           chainB = FFT(LocalBuf(size), inB);
// -----------------------------------------------------------------
	                   chain  = PV_Morph(chainA, chainB, morph);
// -----------------------------------------------------------------
	                   env   = Linen.kr(gate,fadeT,1,fadeT,2);
	                   sig   = IFFT(chain) * env * amp;
	                   sig   = Pan2.ar(sig, pan);
	               Out.ar(outBus, sig);
         }).add;
)

(
a = Synth(\cross1, [\inBus,[~fft1,~fft2],\amp,1,\gate,1],s,'addToTail');
~source2.set(\amp,1,\tipo,1);        // SAW...
~source1.set(\amp,1,\tipo,2,\buf,c); // SAMPLE...
~mkX.set(\min,0,\max,1);
)

a.set(\morph,~mouseX.asMap); // Collega il Bus di controllo

a.set(\gate,0);

// -----------------------------> XFade (Cross-synthesis)

// Interpola i bins tra due buffers
// XFade: 0 --> 1

(
SynthDef(\cross2, {arg inBus=#[0,1],outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0,
	                   morph=0;
	               var inA,inB,size,chainA,chainB,chain,env,sig;
	                   inA    = In.ar(inBus[0],1);
		               inB    = In.ar(inBus[1],1);
		               size   = 2048;
		               chainA = FFT(LocalBuf(size), inA);
			           chainB = FFT(LocalBuf(size), inB);
// -----------------------------------------------------------------
	                   chain  = PV_XFade(chainA, chainB, morph);
// -----------------------------------------------------------------
	                   env   = Linen.kr(gate,fadeT,1,fadeT,2);
	                   sig   = IFFT(chain) * env * amp;
	                   sig   = Pan2.ar(sig, pan);
	               Out.ar(outBus, sig);
         }).add;
)

(
a = Synth(\cross2, [\inBus,[~fft1,~fft2],\amp,1,\gate,1],s,'addToTail');
~source2.set(\amp,1,\tipo,1);        // SAW...
~source1.set(\amp,1,\tipo,2,\buf,c); // SAMPLE...
~mkX.set(\min,0,\max,1);
)

a.set(\morph,~mouseX.asMap); // Collega il Bus di controllo

a.set(\gate,0);

// -----------------------------> SoftWipe (Cross-synthesis)

// Combina i bins bassi di un segnale con quelli alti di un altro interpolandoli
// wipe: -1 --> 1

// wipe 0   --> inA
// wipe < 0 --> inB sostituisce inA dall'alto al basso
// wipe > 0 --> inB sostituisce inA dal basso al'alto

(
SynthDef(\cross3, {arg inBus=#[0,1],outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0,
	                   morph=0;
	               var inA,inB,size,chainA,chainB,chain,env,sig;
	                   inA    = In.ar(inBus[0],1);
		               inB    = In.ar(inBus[1],1);
		               size   = 2048;
		               chainA = FFT(LocalBuf(size), inA);
			           chainB = FFT(LocalBuf(size), inB);
// -----------------------------------------------------------------
	                   chain  = PV_SoftWipe(chainA, chainB, morph);
// -----------------------------------------------------------------
	                   env   = Linen.kr(gate,fadeT,1,fadeT,2);
	                   sig   = IFFT(chain) * env * amp;
	                   sig   = Pan2.ar(sig, pan);
	               Out.ar(outBus, sig);
         }).add;
)

(
a = Synth(\cross3, [\inBus,[~fft1,~fft2],\amp,1,\gate,1],s,'addToTail');
~source2.set(\amp,1,\tipo,1);        // SAW...
~source1.set(\amp,1,\tipo,2,\buf,c); // SAMPLE...
~mkX.set(\min,-1,\max,1);
)

a.set(\morph,~mouseX.asMap); // Collega il Bus di controllo

a.set(\gate,0);

// Cercate altre possibilità negli Help Files...