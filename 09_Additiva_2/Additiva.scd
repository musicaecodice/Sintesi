s = Server.local;
s.boot;
s.meter;
s.scope;
s.freqscope;
s.plotTree;

// ================================================================
// Sintesi Additiva a spettro fisso
// ================================================================
//
// Se vogliamo realizzare una sintesi additiva a spettro fisso
// abbiamo a disposizione tre diverse tecniche ognuna delle quali
// ha un differente costo computazionale:
//
// 1 Disegnare una forma d'onda nella wavetable riletta da un
//   oscillatore tabellare (poco costosa ma poco flessibile).
//
// 2 Realizzare tante copie (istanze) di un oscillatore sinusoidale
//   modificandone solo i parametri (multichannel expansion).
//
// 3 Sommare tra di loro i segnali in uscita di più oscillatori
//   sinusoidali - uno per ogni parziale (molto costosa ma
//   molto flessibile e adatta anche alla generazione di spettri
//   variabili).
//=================================================================
// 1)

(
b = Buffer.alloc(s, 512, 1);
b.sine3([1,3,5,6,9],                     // Freqs
	       [120,67,98,89,100].normalizeSum, // Amps
	       [0,pi,0.5pi,0.3,0]);             // Fasi
b.plot;
)

{Osc.ar(b,400)*0.5}.play;

// Inviluppo di ampiezza unico:

{Osc.ar(b,400)*EnvGen.ar(Env.perc,doneAction:2)}.play;

//=================================================================
// 2)
//
// MULTICHANNEL EXPANSION

s.options.numInputBusChannels_(1);
s.options.numOutputBusChannels_(8); // Cambia il numero di outputs
s.reboot;
s.meter;
s.scope;

{SinOsc.ar( 500             )}.play;
{SinOsc.ar([500,600,700,800])}.play;       // Freqs

{SinOsc.ar(500,0,[1,0.5,0.2,0.1])}.plot;   // Amps
{SinOsc.ar([500,600,700,800],0,[1,0.5,0.2,0.1])}.plot;

// Gli Array devono avere lo stesso numero di elementi altrimenti il
// più corto ricomincerà dall'inizio (wrap around)

{SinOsc.ar([500,600,700,800],0,[0.1,0.8])}.plot;

// Con la Classe Mix sommiamo i segnali in uscita da tutte le istanze
// in un unico segnale monofonico.

(
{Mix(SinOsc.ar([400, 567, 678, 1234,3456], // Inarmonico
	              [  0, 0.3, 0.6,-0.5],
	              [ 500,  30, 80,  100,   5].normalizeSum)
     )
}.play;
)

// Inviluppo di ampiezza unico:

(
SynthDef(\addi_1,{arg parz = #[1,3,8,10],     // Literal Array
	                  fond = 400,
	                  amps = #[0.1,0.1,0.1,0.1],
	                  dur = 0.1, pan = 0, amp = 1;
	              var sig, env;
	                  sig = SinOsc.ar(parz * fond, // Freqs
		                              0,           // Fasi
		                              amps);       // Ampiezze
	                  sig = Mix(sig);
	                  env = EnvGen.ar(Env.perc(0.01,dur-0.01),doneAction:2);
	                  sig = Pan2.ar(sig * env, pan);
	               Out.ar(0, sig * amp);          // Ampiezza globale
                   }).add;
)

Synth(\addi_1,[\dur,1]);

(
r = Routine.new({
	             inf.do({
		Synth(\addi_1,[\parz,[[1,5,9,14],[1,5,7,12],[1,7,8,15],[21,23,18,25]].choose,
			                            \fond, 800 + rand2(20.0), // Detuning...
			                            \dur, rrand(0.1,1)]);
		                 0.1.wait
	                     })
                 }).play
)

//=================================================================
// 3)

{SinOsc.ar(678,0,0.5)}.play; // Singolo parziale = Singolo oscillatore

(                            // Sintesi additiva...
{
SinOsc.ar(678, 0, 0.5)  +
SinOsc.ar(987, 0, 0.1)  +
SinOsc.ar(1234,0, 0.2)  +
SinOsc.ar(3456,0, 0.05) +
SinOsc.ar(4567,0, 0.15)
}.play;
)

// Costruiamo un Synth per un singolo parziale...

(
SynthDef(\parz, {arg freq = 500,   // frequenza del singolo parziale
	                 pamp = 0,     // ampiezza del singolo parziale
	                 pha  = 0,
	                 amp  = 0,     // ampiezza di generale di tutto lo spettro
	                 levs = #[0,1,0.5,0.3,0],   // livelli del singolo inviluppo
	                 tmps = #[0.1,0.3,0.2,0.4], // tempi del singolo inviluppo
	                 dur  = 1,     // Durata totale del suono
	                 pos  = 0,
	                 t_gate = 0;

	               var sig, env;
	                   sig = SinOsc.ar(freq, pha, pamp);      // Ampiezza singolo parziale
	                   env = Env.new(levs, tmps * dur, -4);
	                   env = EnvGen.ar(env, t_gate, doneAction:2);
	                   sig = sig * env * amp;                 // Ampezza di tutto il suono
                       sig = Pan2.ar(sig, pos);
	                Out.ar(0, sig)
         }).add;
)

// singolo parziale

Synth(\parz, [\pamp,1,\amp,1,\t_gate,1]);

// Spettro fisso inarmonico

(
Synth(\parz, [\freq, 500, \pamp, 0.5,\amp, 1,\dur, 1,\t_gate, 1]);
Synth(\parz, [\freq, 789, \pamp, 0.2,\amp, 1,\dur, 1,\t_gate, 1]);
Synth(\parz, [\freq, 1500,\pamp, 0.1,\amp, 1,\dur, 1,\t_gate, 1]);
Synth(\parz, [\freq, 2145,\pamp, 0.2,\amp, 1,\dur, 1,\t_gate, 1]);
)

// Spettro fisso armonico

(
a = 400; // Fondamentale

Synth(\parz, [\freq, a*1,\pamp, 0.5,\amp, 1,\dur, 1,\t_gate, 1]);
Synth(\parz, [\freq, a*4,\pamp, 0.2,\amp, 1,\dur, 1,\t_gate, 1]);
Synth(\parz, [\freq, a*5,\pamp, 0.2,\amp, 1,\dur, 1,\t_gate, 1]);
Synth(\parz, [\freq, a*9,\pamp, 0.1,\amp, 1,\dur, 1,\t_gate, 1]);
)

// Attraverso un loop...

(   // Spettro fisso inarmonico
10.do({
	   Synth(\parz, [\freq, rrand(800,5500),
	                 \pamp, rand(1.0) * 0.1,
		 		     \pha,  rand(2pi),
		             \amp, 1,
	                 \levs, [0,1,0.5,0.5,0],
	                 \tmps, [10,10,50,180].normalizeSum,
			         \dur,  0.5,
	                 \pos,  0,
	                 \t_gate, 1])
       });
)

(   // Spettro fisso armonico
10.do({
	   Synth(\parz, [\freq, 400 * rrand(1, 20),
	                 \pamp, rand(1.0) * 0.1,
		 		     \pha,  rand(2pi),
		             \amp, 1,
	                 \levs, [0,1,0.5,0.5,0],
	                 \tmps, [10,10,50,180].normalizeSum,
		             \dur,  0.1,
	                 \pos,  0,
	                 \t_gate, 1])
       });
)

(
r = Routine.new({
	             inf.do({
		                 10.do({
	                            Synth(\parz, [\freq, 400 * rrand(1, 20),
	                                          \pamp, rand(1.0) * 0.1,
		 		                              \pha,  rand(2pi),
		                                      \amp, 1,
	                                          \levs, [0,1,0.5,0.5,0],
	                                          \tmps, [10,10,50,180].normalizeSum,
		                                      \dur,  0.1,
	                                          \pos,  0,
	                                          \t_gate, 1])
                                 });
		                 0.1.wait;
	                     })
                  }).play;
)

// Separazione parametri di alto livello (controllo sonico/musicale)
// da quelli di basso livello scrivendo i parametri spettrali in Array

(
// --------------- Alto livello

~freqs = [1169,1733,854, 1596, 1480];              // 400 * [1,4,7,8,9];  // Frequenze...
~amps  = [10,  100,  80,   30,  171].normalizeSum; // Ampiezze relative
~levs  = [0.0, 1.0,  0.5, 0.5,  0.0];              // Il numero di items deve essere uguale
                                          // a quello dell'Array dichiarato nella SynthDef
~tmps  = [10,10,50,30].normalizeSum;
~amp   = 1;
~dur   = 3;
~pos   = 0.3;

// --------------- Basso livello

~freqs.size.do({arg i;                                 // numero degli armonici
	            Synth(\parz, [\freq, ~freqs.at(i),
		                      \pamp, ~amps.at(i),
		                      \amp,  ~amp,
		                      \levs, ~levs,
		                      \tmps, ~tmps,
		                      \dur,  ~dur,
		                      \pos,  ~pos,
		                      \t_gate,1])
              })
)

// ================================================================
// Sintesi Additiva a spettro variabile
// ================================================================
//
// Con la stessa SynthDef (o modificandola ulteriormente...) possiamo
// raelizzare anche sintesi additiva a spettro variabile (nel tempo).
//
// Inarmonico...

(
~freqs = [1169,1733,854,1596,1480];
~amps  = [10,100,80,30,171].normalizeSum;

~levs  = [[0.0,0.2,0.2,0.8,0.0],          // Array 2D di livelli (primo e utimo = 0)
	      [0.0,0.9,0.9,0.1,0.0],
	      [0.0,0.7,1.0,0.2,0.0],
	      [0.0,0.8,0.1,0.3,0.0],
	      [0.0,0.0,0.7,0.6,0.0]];

~tmps  = [[10,30,10,50].normalizeSum,     // Aray 2D di Tempi (somma = 1)
	      [20,10,30,40].normalizeSum,
	      [30,20,20,30].normalizeSum,
	      [40,15,35,20].normalizeSum,
	      [50,35,15,10].normalizeSum];

~amp   = 1;
~dur   = 20;
~pos   = 0.3;

~freqs.size.do({arg i;                                 // numero degli armonici
                                             // crea un Synth per ogni parziale
	      Synth(\parz, [\freq, ~freqs.at(i), // gli indici sono richiamati automaticamente
		                \pamp, ~amps.at(i),
		                \amp,  ~amp,
		                \levs, ~levs.at(i),
		                \tmps, ~tmps.at(i),
		                \dur,  ~dur,
		                \pos,  ~pos,
				        \t_gate,1])
      })
)

// Armonico...

(
~freqs = 440 * [1,4,7,8,9];
~amps  = [10,100,80,30,171].normalizeSum;

~levs  = [[0.0,1,0.2,0,0],          // Array 2D di livelli (primo e utimo = 0)
	      [0.0,0.9,0.2,0,0],
	      [0.0,0.5,1.0,0.2,0.0],
	      [0.0,0.4,0.1,0.1,0.0],
	      [0.0,0.0,0.3,0.1,0.0]];

~tmps  = [[1,50,10,64].normalizeSum,     // Aray 2D di Tempi (somma = 1)
	      [2,9,20,48].normalizeSum,
	      [3,2,15,37].normalizeSum,
	      [4,1,13,26].normalizeSum,
	      [5,6,17,65].normalizeSum];

~amp   = 1;
~dur   = 8;
~pos   = 0.3;

~freqs.size.do({arg i;
	      Synth(\parz, [\freq, ~freqs.at(i),
		                \pamp, ~amps.at(i),
		                \amp,  ~amp,
		                \levs, ~levs.at(i),
		                \tmps, ~tmps.at(i),
		                \dur,  ~dur,
		                \pos,  ~pos,
				        \t_gate,1])
      })
)

// Randomico...

(
~nump  = 7;
~freqs = ~nump.collect({ rrand(3000,5000) });
~amps  = ~nump.collect({  rand(1.0) });
~amps  = ~amps.normalizeSum;

~levs  = [0, rand(1.0), rand(1.0), 0];                   // 3 rampe nell'inviluppo
~tmps  = [ rrand(10,100), rrand(10,100),rrand(10,100)];
~tmps  = ~tmps.normalizeSum;

~amp   = rand(1.0);
~dur   = rrand(0.07,0.3);
~pos   = rand2(1.0);

~nump.do({arg i;
	      Synth(\parz, [\freq, ~freqs.at(i),
		                \pamp, ~amps.at(i),
		                \amp,  ~amp,
		                \levs, ~levs.at(i),
		                \tmps, ~tmps.at(i),
		                \dur,  ~dur,
		                \pos,  ~pos,
				        \t_gate,1])
      })
)

// Sound design 1

(
r = Routine.new({
	             inf.do({
~nump  = 7;
~freqs = ~nump.collect({ rrand(1000,5000) });
~amps  = ~nump.collect({  rand(1.0) });
~amps  = ~amps.normalizeSum;

~levs  = [0, rand(1.0), rand(1.0), 0];                   // 3 rampe nell'inviluppo
~tmps  = [ rrand(10,100), rrand(10,100),rrand(10,100)];
~tmps  = ~tmps.normalizeSum;

~amp   = rand(1.0);
~dur   = rrand(0.07,0.3);
~pos   = rand2(1.0);

~nump.do({arg i;
	      Synth(\parz, [\freq, ~freqs.at(i),
		                \pamp, ~amps.at(i),
		                \amp,  ~amp,
		                \levs, ~levs.at(i),
		                \tmps, ~tmps.at(i),
		                \dur,  ~dur,
		                \pos,  ~pos,
				        \t_gate,1])
      });
		(~dur*rrand(1,3.0)).wait;
	                       })
}).play
)

// Sound design 2

(
r = Routine.new({
	             inf.do({
~nump  = 7;
~fond  = rrand(60,80).midicps;    // In valori MIDI convertiti in Hz
~freqs = ~fond * [1,4,5,8,9,11,12];
~amps  = ~nump.collect({  rand(1.0) });
~amps  = ~amps.normalizeSum;

~levs  = [0, rand(1.0), rand(1.0), 0];                   // 3 rampe nell'inviluppo
~tmps  = [ rrand(10,100), rrand(10,100),rrand(10,100)];
~tmps  = ~tmps.normalizeSum;

~amp   = rand(1.0);
~dur   = rrand(5,13);
~pos   = rand2(1.0);

~nump.do({arg i;
	      Synth(\parz, [\freq, ~freqs.at(i),
		                \pamp, ~amps.at(i),
		                \amp,  ~amp,
		                \levs, ~levs.at(i),
		                \tmps, ~tmps.at(i),
		                \dur,  ~dur,
		                \pos,  ~pos,
				        \t_gate,1])
      });
		(~dur*rrand(0.2,1.5)).wait;
	                       })
}).play
)


