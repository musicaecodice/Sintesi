//=================================================================
// Funzione di trasferimento Polinomi di Chebyshev di prima specie
// T0[n] = 1
// T1[n] = n
// T2[n] = 2n**2 - 1
// T3[n] = 4n**3 - 3n
// T4[n] = 8n**4 - 8n**2 + 1
// T5[n] = 16n**5 - 20n**3 + 5n
// ...

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

(
Buffer.freeAll;

SynthDef.new(\wsh, {arg buf=b,freq=400,shp=0,amp=0,gate=0,pan=0,done=2;
	                var sig, sigIn, env;
	                    sigIn = SinOsc.ar(freq) * shp;
	                    sig   = Shaper.ar(buf, sigIn);
	                    env   = Linen.kr(gate,doneAction:done);
	                    sig   = Pan2.ar(sig*env*amp,pan);
	                    sig   = LeakDC.ar(sig);
	                Out.ar(0,sig)
}).add;

SynthDef.new(\mouse, {arg busOut=0;
	                  var sig;
	                      sig = MouseY.kr(0,1);
	                  Out.kr(busOut,sig)
             }).add;

~mouseY = Bus.control(s, 1); // (server, n_canali)
{Synth(\mouse, [\busOut, ~mouseY])}.defer(1);
)

~punti = 512;                           // Numero di punti della tavola
~lin = ~punti.collect({arg n; n/256-1}); // Rampa lineare tra -1 e 1
~lin.plot(bounds:600@400, minval: -1, maxval:1,discrete:true);

//------------------------------------------------------------------
// T1[n] = n
// Primo armonico

~cheb1 = ~lin.collect({arg n; n})
~cheb1.plot(bounds:600@400, minval: -1, maxval:1,discrete:true);

// Ampiezza primo armonico (lineare)
a = Signal.chebyFill(~punti, [1], zeroOffset: true, normalize: true);
a.asWavetable;
b = Buffer.loadCollection(s,a);

b.free;
b = Buffer.alloc(s,~punti);
b.cheby([1],true,true,true); // amps, normalize, asWavetable, clearFirst
b.plot(bounds:600@400, minval: -1, maxval:1);

a = Synth.new(\wsh, [\buf,b,\freq,400,\shp,1,\amp,0.2,\gate,1],s,\addToTail);

a.set(\shp,0.5);
a.set(\shp, ~mouseY.asMap);
a.free;

//------------------------------------------------------------------
// T2[n] = 2n**2 - 1
// Secondo armonico

~cheb2 = ~lin.collect({arg n; 2*(n**2) - 1})
~cheb2.plot(bounds:600@400, minval: -1, maxval:1,discrete:true);

b.free;
b = Buffer.alloc(s,~punti);
b.cheby([1,1],true,true,true); // amps, normalize, asWavetable, clearFirst
b.plot(bounds:600@400, minval: -1, maxval:1);

a = Synth.new(\wsh, [\buf,b,\freq,400,\shp,1,\amp,0.2,\gate,1],s,\addToTail);

a.set(\shp,0.5);
a.set(\shp, ~mouseY.asMap);
a.free;

// N.B. Notiamo la differenza tra la funzione calcolata punto per
//      punto e la stessa realizzata con Signal.chebyFill:
//      • la prima va da -1 a + 1
//      • la seconda va da 0 a 1
// Questo perchè nella seconda l'argomento zeroOffset è settato su
// 'true' e fa sì che il punto al centro della tavola dal quale
// comincia la lettura cominci da 0 senza discontinuità (click)
// alla lettura del primo ciclo.
//------------------------------------------------------------------
// T3[n] = 4n**3 - 3n
// Terzo armonico

b = Buffer.alloc(s,~punti);
b.cheby([0,0,1],true,true,true);
b.plot(bounds:600@400, minval: -1, maxval:1);

//------------------------------------------------------------------
// T4[n] = 8n**4 - 8n**2 + 1
// Quarto armonico

b = Buffer.alloc(s,~punti);
b.cheby([0,0,0,1],true,true,true);
b.plot(bounds:600@400, minval: -1, maxval:1);

//------------------------------------------------------------------
// T5[n] = 16n**5 - 20n**3 + 5n
// Quinto armonico

b = Buffer.alloc(s,~punti);
b.cheby([0,0,0,0,1],true,true,true);
b.plot(bounds:600@400, minval: -1, maxval:1);

//------------------------------------------------------------------
// Sintesi Additiva a spettro variabile

b.free;
b = Buffer.alloc(s,~punti);
b.cheby([1,0.2,0.7,0.3,1],true,true,true);
b.plot(bounds:600@400, minval: -1, maxval:1);

a = Synth.new(\wsh, [\buf,b,\freq,400,\shp,1,\amp,0.2,\gate,1],s,\addToTail);

a.set(\shp,0.5);
a.set(\shp, ~mouseY.asMap);
a.free;
