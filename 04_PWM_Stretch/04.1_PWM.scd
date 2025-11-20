//=================================================================
// PWM - Pulse width modulation

// Duty cycle ([d] - ciclo di lavoro)

// E' la frazione di tempo (t) che un'entità passa in stato attivo
// rispetto ad un ciclo totale (T) e possiamo esprimerla in questo
// modo:

// d = t/T

// Il valore ottenuto sarà sempre compreso tra 0.0 e 1.0 che sono
// i suoi limiti rappresentanti due SEGNALI CONTINUI:

// 0 = silenzio
// 1 = DC offset

// La PWM è utilizzata per molti scopi, per quanto ci riguarda i
// principali dono due:

// • codificare segnali analogici continui in segnali digitali
//   confrontandone i valori di ampiezza istantanea con quelli di
//   un'onda a dente di sega o triangolare avente una frequenza
//   almeno dieci volte maggiore dell'ampiezza di banda del segnale
//   da codificare - vedi PWM.png.
//   In questo modo il duty cycle aumenta in modo proporzionale
//   all'ampiezza del segnale in ingresso.

// • tecnica di sintesi del suono per ottenere spettri complessi
//   che possono variare dinamicamente nel tempo.

//-----------------------------------------------------------------
// Pulse.ar()

// Consideriamo un ONDA QUADRA o TRENO DI IMPULSI che ha un duty
// cycle di 0.5 (1/2). Il suo spettro è caratterizzato dalla presenza
// dei soli armonici dispari ovvero 1:2 la cui ampiezza decade secondo
// la formula 1/numero_di_armonico.

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

(
SynthDef(\pulse_1, {arg freq=300, duty=0.5,amp=0,gate=0,pan=0,done=2;
	                   var sig,env;
	                       sig  = Pulse.ar(freq, duty);
	                       env  = Linen.kr(gate,doneAction:done);
	                       sig  = Pan2.ar(sig * amp * env,pan);
	                   Out.ar(0,sig)}
         ).add;
)

a = Synth(\pulse_1, [\amp,0.5,\duty,1/2,\gate,1]);

// armonici presenti:
// 1   3   5   7   9    11    13    15    17    19    21 ...

a.set(\duty,1/2);

// Se modifichiamo il duty cycle in 1/3 (0.333) un armonico su tre
// sarà assente e avremo quindi i seguenti armonici:

a.set(\duty,1/3);

// 1 2   4 5   7 8   10 11    13 14    16 17    19 20    ...

// Se modifichiamo il duty cycle in 1/4 (0.25) un armonico su quattro
// sarà assente e avremo quindi i seguenti armonici:

a.set(\duty,1/4);

// 1 2 3   5 6 7   9 10 11   13 14 15   17 18 19   21 ...

// Continuando s diminuire il duty cycle possiamo notare come
// l'ampiezza globale (overall amplitude) si abbassa (i tempi di
// silenzo in ogni ciclo sono maggiori) mentre la distribuzione
// dell'energia lungo lo spettro tende ad appiattirsi.

a.set(\duty,1/5);
a.set(\duty,1/10);
a.set(\duty,1/15);
a.set(\duty,1/20);
a.set(\duty,1/25);
a.set(\duty,1/30);
a.set(\duty,1/40);
a.set(\duty,1/50);
a.set(\duty,1/100);
a.set(\duty,1/1000);
a.set(\duty,1/5000);
a.set(\duty,1/44100);

a.set(\gate,0);

// Il duty cycle minimo reale di un sistema audio digitale è di
// 1/sample_rate il cui spettro idealmente è caratterizzato dalla
// presenza di tutti i suoni armonici ognuno dei quali con la stessa
// ampiezza.

{Impulse.ar}.plot

//-----------------------------------------------------------------
// Impulse.ar()

// In questo caso possiamo utilizzare la UGen Impulse che normalizza
// l'ampiezza generale a 1.

(
SynthDef(\pulse_2, {arg freq=300,amp=0,gate=0,pan=0,done=2;
	                var sig,env;
	                    sig   = Impulse.ar(freq);
	                    env   = Linen.kr(gate,doneAction:done);
	                    sig   = Pan2.ar(sig*amp*env,pan);
	                Out.ar(0,sig)}
         ).add;
)

a = Synth(\pulse_2, [\amp,0.5,\gate,1]);
a.set(\amp,1);
a.set(\freq,rrand(72,90).midicps);
a.set(\gate,0);

//-----------------------------------------------------------------
// Blip.ar()

// Il segnale generato da Impulse.ar() non è limitato in frequenza
// e può dare origine a fenomeni di ALIASING o FOLDOVER. In
// SuperCollider esiste però un'altra UGen che riproduce un
// oscillatore storico dei linguaggi MusicN (buzz) e che è stato
// implementato in diversi sintetizzatori commerciali degli anni
// '90 come Synth-O-Matic.


{[Impulse.ar,Blip.ar(440,20)]}.plot;

(
SynthDef(\pulse_3, {arg freq=300,nharm=20,amp=0,gate=0,pan=0,done=2;
	                var sig,env;
	                    sig   = Blip.ar(freq,nharm);
	                    env   = Linen.kr(gate,doneAction:done);
	                    sig   = Pan2.ar(sig*amp*env,pan);
	                Out.ar(0,sig)}
         ).add;
)

a = Synth(\pulse_3, [\amp,0.5,\gate,1]);

a.set(\nharm,10);
a.set(\nharm,3);
a.set(\nharm,[3,13,100].choose);
a.set(\gate,0);

// Fino a questo punto abbiamo preso in considerazione solo
// duty cycle compresi tra 1/2 o 0.5 (onda quadra) e 1/sr ma non
// quelli tra 0.5 e 1. Fortunatamente i comportamenti dello spettro
// in questo caso sono speculari: un segnale con duty cycle di 0.4 ha
// lo stesso spettro di uno con duty cycle di 0.6, uno con 0.3 e
// uno di 0.7 e così via...

a = Synth(\pulse_1, [\amp,0.5,\duty,0.5,\gate,1]);

a.set(\duty,0.4);
a.set(\duty,0.6);
a.set(\duty,0.3);
a.set(\duty,0.7);

a.set(\gate,0);

//-----------------------------------------------------------------
// VarSaw.ar()

(
SynthDef(\pulse_4, {arg freq=300, duty=0.5,amp=0,gate=0,pan=0,done=2;
	                var sig,env;
	                    sig   = VarSaw.ar(freq,0,duty);
	                    env   = Linen.kr(gate,doneAction:done);
	                    sig   = Pan2.ar(sig * amp * env,pan);
	                Out.ar(0,sig)}
         ).add;
)

a = Synth(\pulse_4, [\amp,0.5,\duty,1/2,\gate,1]);

a.set(\duty,1/3);
a.set(\duty,1/4);
a.set(\duty,1/5);

a.set(\gate,0);

//-----------------------------------------------------------------
// Mapping parametri

// Un solo valore controlla il timbro...due (quattro) possibilità
// di controllo.

// -------> 1) Timbro mappato argomenti

// Per maggiore compatibilità meglio stabilire un range tra -1 e + 1

(
SynthDef(\pulse_5, {arg freq=300, dur=0.1,duty=0.5,amp=0,t_gate=0,pan=0,done=2;
	                var sig,env;
	                    sig   = VarSaw.ar(freq, 0, duty);
	                    env   = EnvGen.ar(
		                        Env.perc(0.1*dur,0.9*dur),
		                        t_gate,doneAction:done);
	                    sig   = Pan2.ar(sig * amp * env,pan);
	                Out.ar(0,sig)}
         ).add;
)

(
r = Routine.new({
	             inf.do({
		                 Synth(\pulse_5, [\freq,300,\dur,0.2,\amp,0.5,\duty,rand(0.5),\t_gate,1]);
		                 0.1.wait;
	                     })
                 }).play
)

// -------> 2) Timbro mappato su segnale di controllo esterno

(
~mouseY = Bus.control(s, 1); // (server, n_canali)

SynthDef.new(\mouse, {arg busOut=0;
	                  var sig;
	                      sig = MouseY.kr(0.5,0);    // Tra 0.5 e 0
	                  Out.kr(busOut,sig)
             }).add;

{m = Synth(\mouse, [\busOut, ~mouseY])}.defer(1); // Synth per ksig
)

(
r = Routine.new({
	             inf.do({
		                 Synth(\pulse_5, [\freq,300,\dur,0.2,\amp,0.5,
			                              \duty,~mouseY.asMap,  // Mappato sul Bus di controllo
			                              \t_gate,1],
		                                  s,\addToTail);        // Dopo Synth Mouse
		                 0.1.wait;
	                     })
                 }).play
)

// -------> 3) Timbro mappato sull'inviluppo d'ampiezza

(
SynthDef(\pulse_6, {arg freq=300, dur=0.1,amp=0,t_gate=0,pan=0,done=2;
	                var sig,env,duty;
	                    env   = EnvGen.ar(
		                        Env.perc(0.1*dur,0.9*dur),
		                        t_gate,doneAction:done);
	                    duty  = env.linlin(0,1,0.5,0);      // Riscalato...
		                sig   = VarSaw.ar(freq, 0, duty);
	                    sig   = Pan2.ar(sig * amp * env,pan);
	                Out.ar(0,sig)}
         ).add;
)

Synth(\pulse_6, [\freq,rrand(60,72).midicps,\dur,2,\amp,0.5,\t_gate,1]);

a = Synth(\pulse_6, [\amp,0.5,\duty,1/2,\gate,1]);

// -------> 4) Timbro mappato su segnale di controllo interno

(
SynthDef(\pulse_7, {arg freq=300,amp=0,gate=0,pan=0,done=2;
	                var duty,sig,env,pann;
	                    duty  = MouseX.kr(0.5,0);
	                    sig   = VarSaw.ar(freq,0,duty);
	                    env   = Linen.kr(gate,doneAction:done);
	                    pann  = Pan2.ar(sig * amp * env,pan);
	                Out.ar(0,pann)}
         ).add;
)

a = Synth(\pulse_7, [\amp,0.5,\duty,1/2,\gate,1]);

(
SynthDef(\pulse_8, {arg freq=300,gate=0,pan=0,done=2;
	                var duty,amp,sig,env,pann;
	                    amp   = LFNoise1.kr(1).unipolar;
	                    duty  = LFNoise1.kr(1).range(0,0.5);
	                    sig   = VarSaw.ar(freq,0,duty);
	                    env   = Linen.kr(gate,doneAction:done);
	                    pann  = Pan2.ar(sig * amp * env,pan);
	                Out.ar(0,pann)}
         ).add;
)

(
a = Synth(\pulse_8, [\freq,300,\amp,0.3,\duty,1/2,\pan, -1,\gate,1]);
b = Synth(\pulse_8, [\freq,301,\amp,0.3,\duty,1/4,\pan,  1,\gate,1]);
)

a.set(\gate,0); b.set(\gate,0);


