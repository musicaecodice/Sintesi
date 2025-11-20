ServerOptions.devices;

s.options.inDevice_("Microfono MacBook Air");
//s.options.outDevice_("Altoparlanti MacBook Air");
s.options.outDevice_("Auricolari esterni");

s.reboot;
s.scope;
s.freqscope;
s.plotTree;

// -----------------------------> Impulsivi --> Continui

{WhiteNoise.ar * 0.5}.scope;

{WhiteNoise.ar * EnvGen.ar(Env.perc,1)}.scope;

{WhiteNoise.ar * Impulse.ar(5)}.scope

// Decay.ar e Decay2.ar

(
{var rate = 5,
	 trig = Impulse.kr(rate),      // trigger
     env  = Decay.kr(trig,1/rate); // inviluppo con decay
	[trig,env,WhiteNoise.ar*env]                 // segnale
}.plot(1)
)

(
{var rate = 5,
	 trig = Impulse.ar(rate),      // trigger
     env  = Decay.ar(trig,1/rate); // inviluppo con decay
WhiteNoise.ar(env)                 // segnale
}.play
)

(
SynthDef(\dec , {arg rate=5;
	             var dur,trig,env;
	                 dur  = 1/rate;    // Hz --> sec
	                 trig = Impulse.ar(rate!2);
	                 env  = Decay.ar(trig, dur);
	          Out.ar(0, WhiteNoise.ar(env) )
}).add;
)

a = Synth(\dec);
a.set(\rate,rrand(0.5,20).postln);
a.free;

(
SynthDef(\dec2, {arg freq=400,amp=0,dur=0.2, atk=0.01;
	             var rate,dec,trig,env;
	                 rate = 1/dur;        // sec --> Hz
	                 dec  = dur - atk;
	                 trig = Impulse.ar(rate!2);
	                 env  = Decay2.ar(trig,atk,dec);
	     Out.ar(0, SinOsc.ar(freq) * env * amp)
}).add;
)

a = Synth(\dec2, [\amp,0.5]);
a.set(\atk,rrand(0.008,0.1).postln);
a.set(\dur,rrand(0.05,0.8));
a.free;

(
a.do({arg i; i.free});
a = 5.collect({Synth(\dec2,[\freq,rrand(300,9000),\dur,rrand(0.1,0.5),\atk,rrand(0.01,0.03),\amp,0.1])});
)

// -----------------------------> Discreti --> Continui

// Smoothing (Lag, VarLag e affini...)

(
{var imp = LFNoise0.kr(10);
[imp,
 Lag.kr(imp,0.01),
 Lag.kr(imp,0.1),
 Lag.kr(imp,0.8),
 Lag.kr(imp,1.2)
]}.plot(1,minval:-1,maxval:1)
)

(
{var ksig  = LFNoise0.ar(50);
 [ksig,
  Lag.ar(ksig),
  Lag2.ar(ksig),        // come 2 Lag in cascata (curva esponenziale)
  Lag3.ar(ksig),        // come 3 Lag in cascata (curva cubica)
  VarLag.ar(ksig,0.01,0,\lin)]
}.plot(1)
)

// -----------------------------> Discreti --> Impulsivi

// Changed.kr() genera 1 ad ogni cambiamento di valore

(
SynthDef(\chan, {arg rate=5;
	             var ksig,trig,env,sig;
	                 ksig = LFNoise0.ar(rate).scope;
                     trig = Changed.ar(ksig!2);
	                 env  = Decay2.ar(trig,0.01,rate.reciprocal-0.01);
	                 sig  = SinOsc.ar(ksig.range(80,86).midicps);
	        Out.ar(0,sig*env*ksig.unipolar)
}).add;
)

a = Synth(\chan);


a.set(\rate,rrand(2,10).postln);

// -----------------------------> Continui --> Discreti (Sample and hold)

(
{var sig   = LFNoise2.ar(133),      // Segnale da campionare
     nsamp = 100,                   // numero di campioni (Hz)
     samp  = Impulse.ar(nsamp),     // Segnale che campiona
     out   = Latch.ar(sig, samp);
[sig,samp,out]
}.plot(0.1)
)