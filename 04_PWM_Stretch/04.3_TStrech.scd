//=================================================================
// Timbre stretching

// Ricordimo la wavetable lookup synthesis...

// --> 04.20_Lookup.png

// Un PERIODO del FASORE coincide con un PERIODO della WAVETABLE
// e dunque la FREQUENZA del FASORE (in Hz) determina anche la
// FREQUENZA dell'OSCILLATORE.

// Il concetto alla base del timbre stratching consiste nel
// rendere INDIPENDENTI i due PERIODI ad esempio riducendo del 50%
// il periodo della wavetable (Duty cycle = 50%):

// --> 04.20_Stch_1.png

// N.B. La wavetable è sempre di 100 samples...

// Rileggendo con lo stesso FASORE questa nuova wavetable otteniamo
// il 50% di silenzio tra una rilettura e la successiva della
// wavetable (lo stretching avviene al centro del periodo per
// preservare le fasi nel computo della serie di Fourier)

// --> 04.20_Stch_2.png

// Se:
// • DUPLICHIAMO la forma d'onda al 50% (b)
// • METTIAMO una delle due copie FUORI FASE di metà periodo:
//   a * sin(w * n + pi/w)
// • SOMMIAMO tra loro le due copie (in fase + fuorifase).

// --> 04.20_Stch_3.png

// Otteniamo esattamente la forma d'onda originale a frequenza
// doppia e anche tutti i parziali avranno frequenza doppia.

200 * [1,2,3] * 1; // Frequenze parziali 100% (in Hz)
200 * [1,2,3] * 2; // Frequenze parziali  50% (in Hz)

// La FUNZIONE D'ONDA si trasforma dunque in:

(
p = 100;  // 100% Duty cycle

// N.B. La frequenza è data dalla velocità angolare...

b = p.collect({arg n; (1 * sin(2 * 2pi/p * 1 * n + 0)) + // Primo armonico
	                  (1 * sin(2 * 2pi/p * 2 * n + 0)) + // Secondo armonico
	                  (1 * sin(2 * 2pi/p * 3 * n + 0))   // Terzo armonico
               });
b = b.normalize(-1,1);
b.plot(discrete:false);
)

// In questo caso (50% duty cycle) i PARZIALI RADDOPPIATI in
// frequenza dello spettro originale diventano i PARZIALI PARI dello
// spettro risultante mentre per i PARZIALI DISPARI se la forma
// d'onda si collega con continuità ad entrambe le estremità
// dell'asse x si comportano come quelle pari.

//=================================================================
// AUDIO

// Per poter cambiare dinamicamenti il timbro nel tempo (principale
// scopo di questa tecnica) non possiamo utilizzare due o più
// wavetables di size differente (o riscrivere la stessa dinamicamente)
// ma possiamo sfruttare il CLIPPING che si viene a creare quando
// richiamiamo INDICI minori di 0 oppure maggiori del size-1 di una
// wavetable. Ecco un esempio esemplificativo relizzato con un Array
// al posto della wavetable:

a = [0.5,0.7,0.9]; // Ampiezze istantanee
//    0   1   2       Indici

a.size;   // size = 3

a.at(-2); // clippato (nil)
a.at(-1); // clippato (nil)
//--------------------------
a.at(0);
a.at(1);
a.at(2); // size - 1
//--------------------------
a.at(3); // clippato (nil)
a.at(4); // clippato (nil)

// Dobbiamo RISCALARE il FASORE utilizzato per il wavetable lookup
// NON in un range compreso tra 0 e size-1 della wavetable, MA
// in uno compreso tra:
// INDICI NEGATIVI (che essendo clippati produrranno ampiezze = 0) e
// INDICI MAGGIORI del size della wavetable.

// --> 04.20_Stch_4.png

//-----------------------------------------------------------------
// Con BufRd.ar()
// Creiamo un Buffer NON in wavetable format (per questa tecnica
// dobbiamo utilizzare la UGen BufRD.ar() e non Osc.ar()).

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

(
Buffer.freeAll;
b = Buffer.alloc(s, 1024);   // Buffer di 1024 samples (p)
b.sine1([1,1,1],true,false); // Funzione d'onda
b.plot;
)

// Siccome il FASORE che andiamo ad utilizzare (LFSaw.ar() è BIPOLARE
// (tra -1 e +1) dobbiamo moltiplicare l'output * 0.5 ottenendo un
// range compreso tra -0.5 e + 0.5 che corrisponde a quanto calcolato
// a RIGA 161. Le operazioni successive sono concatenate in un'unica
// espressione...

{LFSaw.ar}.plot;

(
SynthDef(\stch_1, {arg buf=b, freq=500, f=1,amp=0,gate=0,pan=0,done=0,int=1;
	                  var p,c,sig,env,pann;
	                   p    = BufFrames.kr(buf);                         // Wavetable size (p)
	                   c    = LFSaw.ar(freq) *  0.5 * p * f + (p * 0.5); // Fasore Bipolare (a)
	                   sig  = BufRd.ar(1,buf,c,1,int);
	                   env  = Linen.kr(gate,doneAction:done);
	                   pann = Pan2.ar(sig*amp*env,pan);
	             Out.ar(0,pann)}
         ).add;
)

a = Synth(\stch_1, [\buf,b,\freq,400,\f,1,\amp,1,\int,4,\done,2,\gate,1]);
             // 200*[1,2,3] * 1;
a.set(\f,2); // 200*[1,2,3] * 2;
a.set(\f,3); // 200*[1,2,3] * 3;
a.set(\f,4); // etc
a.set(\f,5);
a.set(\f,6);
a.set(\f,7);
a.set(\f,8);
a.set(\f,9);
a.set(\f,10);
a.set(\gate,0);

//-----------------------------------------------------------------
// Spettri complessi
//
// Generiamo una wavetables con un'onda a dente di sega limitata in
// frequenza (Tutti gli armonici con ampiezze decrescenti 1/num_harm)

(
Buffer.freeAll;
b = Buffer.alloc(s, 1024);   // Buffer di 1024 samples (p)
~punti  = 512;                        // Numero di punti (size della tavola)
~npar   = 45;                         // Numero di parziali
~harm   = ~npar.collect({arg n; n});  // Tutti gli armonici (da 0)
~sign   = -1**~harm;                  // Segno alternato
~amps   = 1.0/(1+~harm*~sign);        // Ampiezze decrescenti

b.sine1(~amps,true,false); // Funzione d'onda
b.plot;
)

// Programmiamo un Synth dove possiamo controllare il FATTORE di
// stretching dinamicamente attraverso la posizione del Mouse
// sull'asse y dello schermo in un range compreso tra 1 (100% duty
// cycle) e 100 (1% duty cycle). Possiamo vedere i valori nella Post
// Window grazie al metodo '.poll'

(
SynthDef(\stch_2, {arg buf=b,freq=500,amp=0,gate=0,pan=0,done=0,int=1;
	               var p,f,c,sig,env,pann;
	                   p    = BufFrames.kr(buf);                         // Wavetable size (p)
	                   f    = MouseY.kr(1,10).poll;                      // Stretching factor
	                   c    = LFSaw.ar(freq) *  0.5 * p * f + (p * 0.5); // Fasore Bipolare (a)
	                   sig  = BufRd.ar(1,buf,c,1,int);
	                   env  = Linen.kr(gate,doneAction:done);
	                   pann = Pan2.ar(sig*amp*env,pan);
	             Out.ar(0,pann)}
         ).add;
)

a = Synth(\stch_2, [\buf,b,\freq,400,\amp,1,\int,4,\done,2,\gate,1]);
a.release;

// Come possimo notare MUOVENDO IL MOUSE:
//
// • Nel passaggio DINAMICO tra un numero intero e il successivo
//   come fattori di stretching si viene a creare una sorta di
//   "CROSSFADE" tra gli armonici.
//
// • All'AUMENTARE del FATTORE di STRETCHING lo spettro si APPIATTISCE
//   verso l'alto ovvero AUMENTANO le ampiezze delle FREQUENZE ACUTE
//   (e la serie di Fourier si allunga dello stesso fattore) e
//   DIMINUISCONO quelle delle FREQUENZE GRAVI.

//-----------------------------------------------------------------
// Mapping parametri

// Un solo valore controlla il timbro...due (quattro) possibilità
// di controllo.

// -------> 1) Timbro mappato argomenti

a = Synth(\stch_1, [\buf,b,\freq,400,\f,1,\amp,1,\int,4,\done,2,\gate,1]);

a.set(\f,rrand(1.0,10).postln);

(
r = Routine.new({
	             inf.do({
		                 a.set(\f,rrand(1.0,10).postln);
		                 0.1.wait;
	                     })
                 }).play
)

r.stop;
a.set(\gate,0)

// -------> 2) Timbro mappato su segnale di controllo esterno

// Trovare il range che ci aggrada...

(
~mouseY = Bus.control(s, 1); // (server, n_canali)

SynthDef.new(\mouse, {arg busOut=0;
	                  var sig;
	                      sig = MouseY.kr(1.8,1.87).poll(10); // Trovare il range che interessa
	                  Out.kr(busOut,sig)
             }).add;

{m = Synth(\mouse, [\busOut, ~mouseY])}.defer(1); // Synth per ksig

a = Synth(\stch_1, [\buf,b,\freq,400,\f,~mouseY.asMap,\amp,1,\int,4,\done,2,\gate,1],s,\addToTail);
)

// -------> 3) Timbro mappato sull'inviluppo d'ampiezza

// Trovare il range che ci aggrada...

(
SynthDef(\stch_3, {arg buf=b,freq=500,amp=0,dur=1,t_gate=0,pan=0,done=0,int=1;
	               var p,bpf,env,f,c,sig,pann;
	                   p    = BufFrames.kr(buf);
	                   bpf  = Env.perc(0.01,dur-0.01);
	                   env  = EnvGen.kr(bpf,t_gate,doneAction:done);
	                   f    = env.linlin(0,1,1,1.001).poll;   // Inviluppo riscalato
	                   c    = LFSaw.ar(freq) *  0.5 * p * f + (p * 0.5);
	                   sig  = BufRd.ar(1,buf,c,1,int);
	                   pann = Pan2.ar(sig*amp*env,pan);
	             Out.ar(0,pann)}
         ).add;
)

Synth(\stch_3, [\buf,b,\freq,rrand(50,62).midicps,\amp,rand(1.0),\dur,1.5,\int,4,\done,2,\t_gate,1]);

// -------> 4) Timbro mappato su segnale di controllo interno
// Con chorusing...

(
SynthDef(\stch_4, {arg buf=b,freq=500,freqT=0.1,amp=0,gate=0,pan=0,done=0,int=1;
	               var p,f,c,sig,env,pann;
	                   p    = BufFrames.kr(buf);
	                   f    = LFNoise1.kr(freqT   ).range(1.35,1.8).poll;
	                   c    = LFSaw.ar([freq,freq+0.5]) *  0.5 * p * f + (p * 0.5);
	                   sig  = BufRd.ar(1,buf,c,1,int);
	                   env  = Linen.kr(gate,doneAction:done);
	                   pann = Pan2.ar(sig*amp*env,pan);
	             Out.ar(0,pann)}
         ).add;
)

a = Synth(\stch_4, [\buf,b,\freq,200,\freqT,1,\amp,0.3,\int,4,\done,2,\gate,1]);
a.release;

