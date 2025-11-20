ServerOptions.devices;

s.options.inDevice_("Microfono MacBook Air");
//s.options.outDevice_("Altoparlanti MacBook Air");
s.options.outDevice_("Auricolari esterni");

s.reboot;
s.scope;
s.freqscope;
s.plotTree;

// -----------------------------> Triggers

// Due tipi: Impulsivo e Discreto

{[Impulse.kr(4),LFPulse.kr(4)]}.plot(1, minval:-1,maxval:1);

// -----------------------------> Trig tra 0 e 1

// Tipicamente segnale bipolare al passaggio tra 0 e 1

// Trig.ar()  --> sample and hold
// Trig1.ar() --> sempre 1

(
{var sig   = LFNoise0.ar(15),
     trig  = Trig.kr(sig),
     trig1 = Trig1.kr(sig);

[sig, trig, trig1]
}.plot(1)
)

// Possiamo specificare la zona morta...

(
{var sig  = SinOsc.ar(10),
     trig1 = Trig1.kr(sig,0.005),
     trig2 = Trig1.kr(sig,0.09),
     trig3 = Trig1.kr(sig,0.29);

[sig, trig1,trig2,trig3]
}.plot(1)
)

// se vogliamo un trigger impulsivo...

(
{var sig  = SinOsc.ar(10),
     trig1 = Trig1.kr(sig, 1/s.sampleRate); // Reciproco della rata di campionamento

[sig, trig1]
}.plot(1)
)

// -----------------------------> Trig quando aumenta

// Se il segnale da monitorare è discreto possiamo
// generare un trigger anche ogni volta che il valore aumenta,

// N.B. Se è continuo lo dobbiamo prima discretizzare attraverso
//      un sample and hold...

(
{var dur  = 0.01,
     sig  = LFNoise0.ar(10),                   // .ar perchè c'è Delay1
     trig = Trig1.ar(sig-Delay1.ar(sig), dur); // Delay1 ritarda di 1 campione
      [sig, trig]
}.plot(1);
)

// -----------------------------> Trig ad ogni cambio

(
{var dur  = 0.01,
     sig  = LFNoise0.ar(5),
     trig = Trig1.ar(abs(sig-Delay1.ar(sig)), dur); // abs = valore assoluto (no -0)
      [sig, trig]
}.plot(1);
)

// -----------------------------> Soglia semplice

// > soglia = 1 < soglia = 0
// < soglia = 1 > soglia = 0 (inverso)
// quando PASSA la soglia = 1 il campione dopo = 0 (impulsivo)

// Durata non prestabilita ma dipende dal segnale.

(
{var sig  = LFNoise0.kr(10),
     trig1 = sig > 0.3,
     trig2 = sig < 0.3,
	    trig3 = Changed.kr(sig, 0.3);

[sig, trig1,trig2,trig3]
}.plot(1)
)

{(MouseX.kr(0, 10) > 5).scope * SinOsc.ar}.play;                          // Moltiplica
{(MouseX.kr(0, 10) > 5).lag(1).scope * SinOsc.ar}.play;                   // Smoothed
{EnvGen.kr(Env.perc,MouseX.kr(0, 10) > 5) * SinOsc.ar}.scope;             // Env no sust solo su
{EnvGen.kr(Env.perc,Changed.kr(MouseX.kr(0, 10) > 5)) * SinOsc.ar}.scope; // Env no sust su e giù
{EnvGen.kr(Env.asr,MouseX.kr(0, 10) > 5) * SinOsc.ar}.scope;              // Env sust

// -----------------------------> Soglia doppia (Schmidt trigger)

// Se supera soglia superiore = 1
// Se scende sotto soglia inferiore = 0

{Schmidt.kr(MouseX.kr(0, 10), 2, 6)}.scope;	// argomenti: sig, min, max

// -----------------------------> InRange.kr()

// Se il valore è nel range = 1 altrimenti 0

{InRange.kr(MouseX.kr(0, 1), 0.2, 0.8)}.scope;	// argomenti: sig, min, max

// -----------------------------> Altre UGens dedicate...

"open http://doc.sccode.org/Browse.html#UGens%3ETriggers".unixCmd;


