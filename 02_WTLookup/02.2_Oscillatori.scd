//=================================================================
// Non interpolating wavetable lookup oscillator

// Si prendono i valori y (ampiezze istantanee) di un fasore (onda
// a dente di sega) per richiamare gli indici di una Wavetable
// all'interno della quale abbiamo memorizzato un eriodo di una
// qualsiasi forma d'onda.

// I valori del fasore sono generalmente compresi tra -1 e +1 nel
// caso di un'onda bipolare oppure tra 0 e +1 (nel caso di un onda
// unipolare).

(
~size = 100;  // Size del Buffer

~unipolare = Signal.newClear(~size);
~bipolare  = Signal.newClear(~size);

~unipolare.waveFill({arg i; i}, 0, 1);
~bipolare.waveFill({arg i; i}, -1, 1);

[~unipolare,~bipolare].plot(minval:-1,maxval:1,discrete:true);
)

// Per poter impiegare i valori di ampiezza istantanea (y) del
// fasore come indici (x) della wavetable dobbiamo però riscalarli
// in un ambito (range) commpreso tra 0 e il size-1 della wavetable
// da rileggere semplicemente moltiplicando l'onda unipolare per il
// size (nel caso fosse bipolare dobbiamo prima renderla unipolare).

(
~fasore = ~unipolare * ~size;    // Fasore tra 0 e size-1

~wave = ~size.collect({arg n; (1 * sin(2pi/p * 1 * n + 0)) + // Primo armonico
	                          (1 * sin(2pi/p * 2 * n + 0)) + // Secondo armonico
	                          (1 * sin(2pi/p * 3 * n + 0))   // Terzo armonico
                       });                                   // 1 periodo wavetable
~wave = ~wave.normalize(-1,1);                               // Tra +/-1

[~fasore++~fasore++~fasore++~fasore,~wave++~wave++~wave++~wave].plot(discrete:true);
)

// Un periodo del fasore coincide con un periodo della wavetable
// e dunque la frequenza del fasore (in Hz) determina anche la
// frequenza dell'oscillatore tabellare.

//=================================================================
// Audio

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(1)
)

//-----------------------------------------------------------------
// Disegnamo in un Buffer una forma d'onda periodica (un ciclo).

(
Buffer.freeAll;
~size = 1024;
b = Buffer.alloc(s,~size);
b.sine1([0.3,0.7,1.2], asWavetable:false); // In formato normale...
{b.plot}.defer(0.1)
)

//-----------------------------------------------------------------
// Creiamo un fasore.

// Ci sono due diverse tecniche per disegnare un fasore:

// ---------------> 1 Oscillatore a dente di sega (riscalato)
// LFSaw.ar()

(
{[
  LFSaw.kr(2),                  // Bipolare
  LFSaw.kr(2,-1),               // Fuori fase
  LFSaw.kr(2,-1)*0.5+0.5,       // Unipolare
]}.plot(1)
)

{LFSaw.kr(2,-1)*0.5+0.5*~size}.plot(1)  // Riscalato tra 0 e n-1

// In questo caso la frequenza in Hz del fasore sarà la frequenza
// dell'onda riletta.

// ---------------> 2 Contatore a sample rate (wrap around)
// Phasor.ar()

// In questo caso alla velocità della sample rate incrementa di uno
// step (che può essere 1 o altro) e c'è un wrap around tra un
// valore minimo e un valore massimo.

{Phasor.ar(0, 1, 0, 100)}.plot(0.01)

// Se vogliamo stabilire una frequenza in Hz dobbiamo effettuare
// qualche operazione per determinare il fattore di incremento

// size del Buffer * freq(Hz) / sample rate
               100 * 440      / 48000;     // Incremento = 0.91666666666667

(
{ Phasor.ar(0,
//            recupera il size        recupera la sample rate attuale
		      BufFrames.kr(b) * 20 / SampleRate.ir,
		      0,                               // Frame inizo lettura
	BufFrames.kr(b))}.plot(0.1)               // Frame fine lettura
)

//-----------------------------------------------------------------
// Con BufRd.ar()

(
SynthDef(\wave1, {arg buf=b, freq=500, amp=0, dur=1, atk=0.1,t_gate=0,pan=0,done=0,int=1;
	             var punta,sig,bpf,env,pann;
	                 punta = LFSaw.ar(freq,-1).range(0, BufFrames.kr(buf)); // .range...
	                 sig   = BufRd.ar(1,      // Numero canali
		                              buf,    // Buffer da leggere
		                              punta,  // Segnale puntatore
		                              1,      // Loop
		                              int);   // Interpolazione: 1, 2, 4
	                 bpf   = Env.perc(atk*dur, (1.0-atk)*dur);
	                 env   = EnvGen.ar(bpf,t_gate,doneAction:done);
	                 pann  = Pan2.ar(sig*amp*env,pan);
	             Out.ar(0,pann)}
         ).add;
)

// Interpolazione: osservare le differenze nello spettroscopio...

Synth(\wave2, [\buf,b,\freq,rrand(70,82).midicps,\amp,1,\int,1,\done,2,\t_gate,1]); // No interp.
Synth(\wave2, [\buf,b,\freq,rrand(70,82).midicps,\amp,1,\int,2,\done,2,\t_gate,1]); // Interp. lin
Synth(\wave2, [\buf,b,\freq,rrand(70,82).midicps,\amp,1,\int,4,\done,2,\t_gate,1]); // Interp. cub

(
SynthDef(\wave2, {arg buf=b, freq=500, amp=0, dur=1, atk=0.1,t_gate=0,pan=0,done=0,int=1;
	             var punta,sig,bpf,env,pann;
	                 punta = Phasor.ar(0,
		                               BufFrames.kr(buf) * freq / SampleRate.ir,
		                               0, BufFrames.kr(buf));
	                 sig   = BufRd.ar(1,      // Numero canali
		                              buf,    // Buffer da leggere
		                              punta,  // Segnale puntatore
		                              1,      // Loop
		                              int);   // Interpolazione: 1, 2, 4
	                 bpf   = Env.perc(atk*dur, (1.0-atk)*dur);
	                 env   = EnvGen.ar(bpf,t_gate,doneAction:done);
	                 pann  = Pan2.ar(sig*amp*env,pan);
	             Out.ar(0,pann)}
         ).add;
)

// Interpolazione: osservare le differenze nello spettroscopio...

Synth(\wave2, [\buf,b,\freq,rrand(70,82).midicps,\amp,1,\int,1,\done,2,\t_gate,1]); // No interp.
Synth(\wave2, [\buf,b,\freq,rrand(70,82).midicps,\amp,1,\int,2,\done,2,\t_gate,1]); // Interp. lin
Synth(\wave2, [\buf,b,\freq,rrand(70,82).midicps,\amp,1,\int,4,\done,2,\t_gate,1]); // Interp. cub

//=================================================================

// BufRD è un oscillatore generico che può essere utilizzato in
// diverse tecniche di rilettura di un Buffer. Per la wavetable
// Synthesis ci sono degli Oscillatori dedicati.

//-----------------------------------------------------------------
// OscN.ar()
// Oscillatore tabellare che non interpola
// Il Buffer deve obbligatoriamente contenere un numero di campioni
// pari a una potenza di 2 e NON ESSERE in WAVETABLE FORMAT.

(
Buffer.freeAll;
~size = 1024;
b = Buffer.alloc(s,~size);
b.sine1([0.3,0.7,1.2], asWavetable:false); // In formato normale...

SynthDef(\oscN, {arg buf=b, freq=500, amp=0, dur=1,t_gate=0,pan=0,done=0;
	             var sig,bpf,env,pann;
	                 sig   = OscN.ar(buf,freq);
	                 bpf   = Env.triangle(dur);
	                 env   = EnvGen.ar(bpf,t_gate,doneAction:done);
	                 pann  = Pan2.ar(sig*amp*env,pan);
	             Out.ar(0,pann)}
         ).add;
)

Synth(\oscN, [\buf,b,\freq,rrand(70,82).midicps,\amp,1,\dur,0.3,\done,2,\t_gate,1]);

//-----------------------------------------------------------------
// Osc.ar()
// Oscillatore tabellare con interpolazione lineare
// Il Buffer deve obbligatoriamente contenere un numero di campioni
// pari a una potenza di 2 ed ESSERE in WAVETABLE FORMAT.

(
Buffer.freeAll;
~size = 1024;
b = Buffer.alloc(s,~size);
b.sine1([0.3,0.7,1.2], asWavetable:true); // In wavetable format

// La sintassi è identica a OscN

SynthDef(\osc, {arg buf=b, freq=500, amp=0, dur=1,t_gate=0,pan=0,done=0;
	               var sig,bpf,env;
	                   sig  = Osc.ar(buf,freq);
	                   bpf  = Env.triangle(dur);
	                   env  = EnvGen.ar(bpf,t_gate,doneAction:done);
	                   sig  = Pan2.ar(sig*amp*env,pan);
	            Out.ar(0,sig)}
         ).add;
)

Synth(\osc, [\buf,b,\freq,rrand(70,82).midicps,\amp,1,\dur,0.3,\done,2,\t_gate,1]);

// SinOsc è come quest'ultimo Synth che legge un Buffer interno di 8192 campioni