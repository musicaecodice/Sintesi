s.boot;
s.freqscope;

// Carrier          Modular
{SinOsc.ar(400) * SinOsc.ar(900)}.play;                                // Ring
{SinOsc.ar(400) * SinOsc.ar(MouseX.kr(1,400).poll(3)).unipolar}.play;  // AM
{SinOsc.ar(400,0, SinOsc.ar(MouseX.kr(1,400).poll(3)).unipolar)}.play; // AM

{SinOsc.ar(400 + (SinOsc.ar(MouseX.kr(1,400).poll(3)) * 100) )}.play;      // FM
{SinOsc.ar(400, SinOsc.ar(MouseX.kr(1,400).poll(3)).range(0, 2pi) )}.play; // PM

// ---------------------------------------------- FM
// Tre parametri di controllo:
//
// • Frequenza portante
// • Frequenza modulante
// • Deviazione

(
SynthDef(\fm_1, {arg fpor=440,fmod=2,dev=1;
	             var mod,por;
	                 mod = fpor + (SinOsc.ar(fmod) * dev);
	                 por = SinOsc.ar(mod);
	             Out.ar(0,por)
                 }).add;
)

a = Synth(\fm_1); // Vibrato
a.set(\dev,200);
a.set(\fmod,400); // FM
a.free;

// C + k*M dove k è un intero. C. C+M, C-M, C+(2*M), C-(2*M), ...
// Le ampiezze dei parziali seguono le funzioni di Bessel.
//
// Le frequenze negative sono riflesse in positivo attraverso
// una moltiplicazione * -1 quindi tutti i parziali con la stessa
// frequenza sono sommati fra loro.
//
// ----------------------> C:M ratio
// Se vogliamo conoscere la fondamentale di uno spettro:
// E' il più basso C:M ratio di interi senza fattori comuni:
//
// C   : M   = N1 : N2
// 400 : 800 = 1  : 2
//
// da cui...
//
// C   / N1 = M   / N2 = fondamentale
// 400 / 1  = 800 / 2  = 400
//
// quindi...
//
// se N1 = 1:
//
//    N2 = 1: spettro con tutti gli armonici
//    N2 = M: ogni mth armonico è assente...
//
// Valori di N2 irrazionali o larghi e/o N1 generano spettri inarmonici
//
// Es 5/7  (1:1.4)
//

~fond = 200;

s.freqscope;
a = Synth(\fm_1, [\fpor,~fond*1,\fmod,~fond*1,\dev,1000]);
a.set(\fpor,~fond*1,\fmod,~fond*6);    // 4:3

// Un modo più musicale per generare spettri:

(
SynthDef(\fm_2, {arg fpor=440;
	             var mod,fmod,dev,por;
	                 fmod = MouseX.kr(1,500).poll(10,label:\fmod);
	                 dev  = MouseY.kr(0.1,100).poll(10,label:\dev);
	mod  = fpor + (SinOsc.ar([fmod,fmod + LFNoise1.kr(0.1).range(0,2)]) * dev);
	                 por = SinOsc.ar(mod);
	             Out.ar(0,por)
                 }).add;
)

a = Synth(\fm_2);

// ========================================= Modulation Index

// Un modo più musicale di controllare la FM

// I = D/M - Più è piccolo minore sarà la modulazione...
// (dove D può essere considerata anche l'ampiezza della modulante)
// da cui...
// C   + ((-1/1) * M * I)
// 440 + ((-1/1) * 2 * 1)

// mid = modulation index

(
SynthDef(\fm_3, {arg fpor=440, fmod=2, mid=0;
	                var mod,por;
	                    mod = fpor + (SinOsc.ar(fmod) * fmod * mid);
	                    por = SinOsc.ar(mod);
	                Out.ar(0,por)
                 }).add;
)

a = Synth(\fm_3); // Vibrato
a.set(\mid,7);
a.set(\fmod,400); // FM
a.free;

(
SynthDef(\fm_4, {arg fpor=440;
	                var mod,fmod,mid,por;
	                    fmod = MouseX.kr(1,500);
	                    mid  = MouseY.kr(0,50);
	                    mod  = fpor + (SinOsc.ar(fmod) * fmod * mid);
 por = SinOsc.ar([mod,mod+3]);
	                Out.ar(0,por)
                 }).add;
)

a = Synth(\fm_4);

// ========================================= Harmonicity ratio
//
// Siccome le frequenze delle sidebands sono distrubuite:
//
// C + (k*M) dove k è un intero, se M è  h * C tutto è relativo a C
// h = harmonicity index

(
SynthDef(\fm_5, {arg fpor=440, harm=0, mid=0;
	                var mod,fmod,por;
	                    fmod = fpor * harm;                // h * C
	                    mod  = fpor + (SinOsc.ar(fmod) * fmod * mid);
	                    por = SinOsc.ar(mod);
	                Out.ar(0,por)
                 }).add;
)

a = Synth(\fm_5); // Vibrato
a.set(\harm,0.23);
a.set(\mid,2);
a.free;

// IN questo caso il modulation index (mid) controlla la luminisità
// del suono attraverso la distribuzione dell'energia lungo
// lo spettro

(
SynthDef(\fm_6, {arg fpor=440;
	                var mod,harm, mid, fmod,por;

	                    harm = MouseX.kr(0,10).round(0.001);
	                    mid  = MouseY.kr(0.0,10.0);
	                    fmod = fpor * harm;
	                    mod  = fpor + (SinOsc.ar(fmod) * fmod * mid);
	                    por = SinOsc.ar(mod);
	                Out.ar(0,por)
                 }).add;
)

a = Synth(\fm_6);

// In SC ci sono tre UGens dedicate alla FM:
// Vibrato
// SinOscFB
// FM7 (SC3-plugins distribution)
// Potete richiamare gli Help files con esempi

// ---------------------------------------------- PM
//

(
SynthDef(\pm_1, {arg fpor=440, fmod=2, mid=0;
	                var mod, conv, por;
	                    conv = 2pi/SampleRate.ir;  // riscala il passo dei cambiamenti
	                    mod  = SinOsc.ar(fmod) * (fmod * mid) * conv;
	                    por  = SinOsc.ar(fpor, mod);
	                Out.ar(0,por)
                 }).add;
)

a = Synth(\pm_1);
a.set(\mid,80);
a.set(\fmod,7490);
a.free;

(
SynthDef(\pm_2, {arg fpor=440;
	                var mod, fmod,mid, conv, por;
		                   fmod = MouseX.kr(1,500);
	                    mid  = MouseY.kr(0,50);
	                    conv = 2pi/SampleRate.ir;    // riscala il passo dei cambiamenti
	                    mod  = SinOsc.ar(fmod) * (fmod * mid) * conv;
	                    por  = SinOsc.ar(fpor, mod);
	                Out.ar(0,por)
                 }).add;
)

a = Synth(\pm_2);
a.free;

// La velocità di cambio della fase è una frequenza
// dunque la modulazione di fase è strettamente legata alla FM
// Proviamo a sostituire l'oscillatore modulante con un fasore:

2pi/48000

(
SynthDef(\pm_3, {arg fpor=440, fmod=2, mid=0;
	                var mod, conv, por;
	                    conv = 2pi/SampleRate.ir;
	                    mod  = Phasor.ar(0, fpor * conv, 0, 2pi) + // da 0 a 2pi con un incremento (passo - freq)
	                                                            // riscalato da conv
	                        (SinOsc.ar(fmod) * (fmod * mid) * conv);
	                    por  = SinOsc.ar(0, mod);    // Frequenza 0...
	                Out.ar(0,por)
                 }).add;
)

a = Synth(\pm_3);
a.set(\mid,50);
a.set(\fmod,rrand(200,1234).postln); // PM
a.free;

// Nel caso precedente abbiamo sostituito la frequenza della portante
// con un fasore che legge la wavetable interna di SinOsc
//
// In SC c'è una UGen dedicata alla PM:

(
SynthDef(\pm_4, {arg fpor=440, fmod=2, mid=0, amp=0, dur=1, pan=0, t_gate=0, done=2;
		               var sig,bpf,env,pann;
	                    sig = PMOsc.ar(fpor,
		                                  fmod,
		                                  Line.kr(0.001,rand(mid),dur));
	                    bpf = Env.perc(0.01,dur-0.01);
	                    env = EnvGen.kr(bpf, t_gate, doneAction:done);
	                    pann = Pan2.ar(sig*env*amp, pan);
	                Out.ar(0,pann)
                 }).add;
)

(
Synth(\pm_4, [\fpor, rrand(90, 100).midicps,
	             \fmod, rrand(200,800),
	             \mid,  rand(10),
	             \amp,  rand(0.3),
	             \dur,  rrand(0.14,0.2),
	             \pan,  rand2(1.0),
              \t_gate,1]);
)

// Un modo per esplorare timbri...

{PMOsc.ar(1400, MouseX.kr(2,2000,1), MouseY.kr(0,1), 0)}.play;

(
{var fpor, ratio, mod, por;
	 fpor      = LFNoise0.kr(8, 20, 60).round(1).midicps;
	 ratio     = MouseX.kr(1,4);
	 mod       = SinOsc.ar(fpor * ratio) * MouseY.kr(0.1,10);
	 por       = SinOsc.ar(fpor, mod) * 0.5;
	 por
}.play
)
