ServerOptions.devices;

s.options.inDevice_("Microfono MacBook Air");
//s.options.outDevice_("Altoparlanti MacBook Air");
s.options.outDevice_("Auricolari esterni");

s.reboot;
s.scope;
s.freqscope;
s.plotTree;

// -----------------------------> Bipolari (+/-)

{LFSaw.ar}.plot;

// -----------------------------> Unipolari

{Dust.ar(10000)}.plot(minval:-1,maxval:1);

{EnvGen.ar(Env.perc)}.plot(1,minval:-1,maxval:1);

{SinOsc.ar*0.2-0.5}.plot(minval:-1,maxval:1);

{SinOsc.ar*0.2+0.5}.plot(minval:-1,maxval:1); // DC offset


// -----------------------------> Riscalaggio

// Mapping su parametri di sintesi o elaborazione del suono.

// 1) Individuare il range originale del segnale.
// 2) Individuare il range sul quale lo vogliamo riscalare.
// 3) Scegliere la tecnica più appropriata (tre possibilità)

// • Argomenti mul e add
// • Metodi dedicati UGen (se +/-1)
// • Metodi generali

// -----------------------------> Argomenti mul e add

(     // Fattore di moltiplicazione
{[
SinOsc.ar(10),                    // tra +/- 1
SinOsc.ar(10, mul:5),             // tra +/- 5 (costante)
Line.ar(0,5,1),                   // rampa variabile
SinOsc.ar(10, mul:Line.ar(0,5,1)) // tra +/- 5 (variabile)
]}.plot(1,minval:-10,maxval:10);
)

(     // Fattore di addizione
{[
SinOsc.ar(10),                    // tra +/- 1
SinOsc.ar(10, mul:5,add:5),       // tra 0 e 5 (costante)
Line.ar(0,5,1),                   // rampa variabile
SinOsc.ar(10, add:Line.ar(0,5,1)) // tra 0 e 10 (variabile)
]}.plot(1,minval:-10,maxval:10);
)

(    // Combinazione...

a = {arg mult = 100, addi = 1000;          // Valori tra 900 e 1100
     var sigK = LFNoise0.kr(10,mult,addi); // 10 note al secondo
     SinOsc.ar(sigK, mul:0.2);             // Riscala l'ampiezza
    }.play
)

a.set(\mult,500);                          // Valori tra 500 e 1500
a.set(\addi,2000);
a.free;

// -----------------------------> Metodi dedicati all UGens

// .range(min, max)

(
{var a = LFNoise0.ar(10);
[a, a.range(-2,10)]
}.plot(1,minval:-10,maxval:10);
)

{SinOsc.ar(LFNoise0.ar(10).range(440, 6600), 0, 0.5) * 0.1 }.play;

// .exprange(min, max)

(
{var a = LFNoise0.ar(10);
[a, a.exprange(0.001,10)]
}.plot(1,minval:-10,maxval:10);
)

{SinOsc.ar(LFNoise0.ar(10).exprange(440, 6600), 0, 0.5) * 0.1 }.play;

// .curverange(min, max, curve)

(
{var a = LFNoise0.ar(10);
[a, a.curverange(0.001,10,-4)]
}.plot(1,minval:-10,maxval:10);
)

{SinOsc.ar(LFNoise0.ar(10).curverange(440, 6600, -4), 0, 0.5) * 0.1 }.play;

// .unipolar

(
{var a = LFNoise0.ar(10);
[a, a.unipolar]
}.plot(1,minval:-1,maxval:1);
)

{SinOsc.ar(440, 0, SinOsc.kr(1).unipolar)}.play;


// .bipolar(max)

(
{var a = LFPulse.ar(10);     // segnale unipolare
[a, a.bipolar(0.2)]
}.plot(1,minval:-1,maxval:1);
)

// -----------------------------> Metodi generali

(
{var a = Line.ar(-8,7,1);
[a, a.linlin(-8,7,-2,2)]
}.plot(1,minval:-10,maxval:10);
)

(
{var a = Line.ar(-8,7,1);
[a, a.linexp(-8,7,2,50)]
}.plot(1,minval:-50,maxval:50);
)

(
{var a = Line.ar(0,7,1);
[a, a.lincurve(0,7,-50,20,-9)]
}.plot(1,minval:-50,maxval:50);
)

// Ce ne sono anche altri ma meno utilizzati...