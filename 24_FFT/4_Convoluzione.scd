(
s = Server.local;
s.options.memSize_(2.pow(20)); // per Delay...
s.boot;
s.freqscope;
{s.plotTree}.defer(3);
)


// -----------------------------> Moltiplicazione

// Possiamo moltiplicare tutti i valori di ampiezza istantanea (campioni)
// di un segnale 'a' per un valore costante 'b' (ad esempio quando
// vogliamo riscalarne l'ampiezza):

(
a = [0.3,0.6,1.0,0.6,0.3]; // Segnale
b = 0.5;                   // Ampiezza di picco
t = a * b;                 // Risultato

[a++[0], b!6, t++[0]].plot(minval: -1,maxval:1).plotMode_(\bars);
)

// -----------------------------> Modulazioni

// Possiamo moltiplicare tutti i valori di ampiezza istantanea (campioni)
// di un segnale 'a' per quelli di un segnale 'b' (ring modulation):

(
a = [0.3,0.6,1.0,0.6,0.3]; // Segnale a
b = [0.1,0.3,0.5,0.6,0.9]; // Segnale b
t = a * b;                 // Risultato

[a++[0], b++[0], t++[0]].plot(minval:-1,maxval:1).plotMode_(\bars);
)

// -----------------------------> Convoluzione (dominio temporale)

// Tutti i valori di ampiezza istantanea (campioni) di un segnale 'a'
// sono moltiplicati per OGNI valore di un segnale 'b' che deve avere
// una dimensione finita (kernel).
// In questo modo si crea un array di valori che ha lunghezza pari alla
// dimensione del kernel (segnale 'b') per ogni singolo valore del
// segnale 'a'.

// La convoluzione è il risultato della somma dei valori di questi array
// shiftata di 1 campione nel tempo:

(
a = [0.3,0.6,1.0,0.6,0.3];    // Segnale
b = [1.0,0.03,0.03,1.0,0.03]; // Kernel

[a++(0!5),
 b++(0!5),a++(0!5),
 [0]++(0.03!5)++(0!4),
 (0!2)++(0.03!5)++(0!3),
 (0!3)++a++(0!2),
 (0!4)++(0.03!5)++[0],
 [0.3,0.6,1.0,0.9,0.9,1.0,0.6,0.3,0.03,0.0]
].plot(minval:-1,maxval:1).plotMode_(\bars);
)

// Se anche il segnale 'a' è finito nel tempo il numero di valori risultanti dalla
// convoluzione è:

// lungh[c] = lungh[a] + lungh[b] - 1

// -----------------------------> Convoluzione (dominio frequenziale)

// Nel dominio spettrale il risultato della convoluzione è dato dalla
// moltilicazione dei parziali presenti nei due spettri.

// In altre parole un segnale è filtrato da un'altro segnale.

// Se moltiplichiamo fra loro due segnali audio (dominio temporale - modulazioni)
// otteniamo la convoluzione degli spettri (sidebands...)

// Se moltiplichiamo fra loro due spettri (dominio frequenziale)
// otteniamo la convoluzione dei valori di ampiezza istantanea.

// Il processo della convoluzione non distingue se si tratta di ampiezze
// istantanee oppure di ampiezze dei singoli parziali...

// Questo processo è utilizzato per diversi scopi musicali:

// Filtri
// Riverberi
// Modulazioni
// Cross-Synthesis

"open http://www.dspguide.com/ch18/2.htm".unixCmd;

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
~source1 = Synth(\source,[\outBus,~fft1,\buf,b]);
~source2 = Synth(\source,[\outBus,~fft2,\buf,b]);
~mkX = {arg min=0,max=1; Out.kr(~mouseX, MouseX.kr(min,max))}.play;      // tra 0 e 1
~mkY = {arg min=0,max=1; Out.kr(~mouseY, MouseY.kr(min,max))}.play;      // tra 0 e 1
}.defer(1)
)

// -----------------------------> Convolution

// Realizza una convoluzione continua tra due segnali...

(
SynthDef(\conv_1, {arg inBus=#[0,1],outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0;
	                  var in,kernel,size,chain,env,sig;
	                      in     = In.ar(inBus[0],1);
		                     kernel = In.ar(inBus[1],1);
		                     size   = 2048;
// -----------------------------------------------------------------
	                   sig  = Convolution.ar(in,kernel,size,0.5);
// -----------------------------------------------------------------
	                   env   = Linen.kr(gate,fadeT,1,fadeT,2);
	                   sig   = sig * env * amp;
	                   sig   = Pan2.ar(sig, pan);
	               Out.ar(outBus, sig);
         }).add;
)

(
a = Synth(\conv_1, [\inBus,[~fft1,~fft2],\amp,0.2,\gate,1],s,'addToTail');
~source1.set(\amp,1,\tipo,3);        // LIVE...
~source2.set(\amp,1,\tipo,2,\buf,c); // SAMPLE...
)

(   // Convoluzione con se stesso...
~source1.set(\amp,1,\tipo,2,\buf,c,\amp,0.5);
~source2.set(\amp,1,\tipo,2,\buf,c,\amp,0.5);
)

(   // Riverbero...con frequenze di risonanza....
~source1.set(\amp,1,\tipo,1,\trsp,rand2(24),\amp,0.5); // SAW (IR)
~source2.set(\amp,1,\tipo,2,\amp,0.5);                 // SAMPLE
)

a.set(\gate,0);

// -----------------------------> Convolution2L

// Realizza una convoluzione tra un segnale e un kernel
// memorizzato che possiamo cambiare attraverso un trigger.
// Possibile stabilire xfade tra kernels

// Meno costoso a livello computazionale

(
SynthDef(\conv_2, {arg inBus=0,kBuf=0,kfade=2,outBus=0,amp=0.5,fadeT=0.5,gate=0,pan=0,
	                      t_trig=0;
	                  var in,size,chain,env,sig;
	                      in     = In.ar(inBus,1);
		                     size   = 2048;
// -----------------------------------------------------------------
	                   sig  = Convolution2L.ar(in,kBuf,t_trig,size,kfade,0.5);
// -----------------------------------------------------------------
	                   env   = Linen.kr(gate,fadeT,1,fadeT,2);
	                   sig   = sig * env * amp.lag(0.2);
	                   sig   = Pan2.ar(sig, pan);
	               Out.ar(outBus, sig);
         }).add;
)

(
a = Synth(\conv_2, [\inBus,~fft1,\kBuf,b,\amp,0.5,\gate,1],s,'addToTail');
~source1.set(\amp,1,\tipo,1); // SAW
)

a.set(\kBuf,c,\t_trig,1,\amp,0.05)
a.set(\kBuf,b,\t_trig,1,\amp,0.7)

d = Buffer.alloc(s, 2048); // Kernel piccolo...

(      // Valuta più volte....
50.do { |it| d.set(20 * it + 10, 1.0.rand) }; // Spettri random...
a.set(\kBuf,d,\t_trig,1,\amp,0.5)
)

a.set(\gate,0);
