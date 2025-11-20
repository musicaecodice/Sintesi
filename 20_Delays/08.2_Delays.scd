ServerOptions.devices; // Array devices connessi


s.options.inDevice_("Microfono MacBook Air");
//s.options.outDevice_("Altoparlanti MacBook Air");
s.options.outDevice_("Scarlett 18i20 USB");

s.options.memSize_(2.pow(20)); // Quando si usa Delays meglio incrementare
                               // l'allocazione di memoria sul Server

s.reboot;
s.scope;
s.plotTree;

(
// -----------------------------> Synth input

SynthDef.new(\mic, {arg inBus=0,outBus=0,amp=0;
	                   var sig;
	                       sig = SoundIn.ar(inBus) * amp.lag(0.02);
	                       sig = LeakDC.ar(sig);
	                   Out.ar(outBus,sig)
             }).add;

// -------------------> Synth router

SynthDef(\router, {arg inBus=0, outBus=0, fadeT = 1;
		                 var sig, init, gate;
		                     sig    = In.ar(inBus,1);
		                     init   = Impulse.kr(0);
		                     outBus = K2A.ar(outBus);
			                    gate   = HPZ1.ar(outBus).abs > 0;

	               Out.ar(outBus,
			              sig * EnvGen.ar(Env([0,0,1], [0,fadeT],\cub),gate+init));
			             Out.ar(DelayN.ar(outBus, fadeT, fadeT),
			              sig * EnvGen.ar(Env([0,1,0], [0,fadeT],\cub),gate));
	       }).add;
)
// -----------------------------> Bus e Gruppi

(
~micBus.free;
~delBus.free;

~micBus = Bus.audio(s,1); // Bus Microfono
~delBus = Bus.audio(s,1); // Bus Delay

~micGrp = Group.new;            // Gruppo sources
~fxGrp  = Group.after(~micGrp); // Gruppo elaborazioni

a = Synth(\mic,    [\inBus,0,       \outBus,~micBus,\amp,1],       ~micGrp); // Sig in
b = Synth(\router, [\inBus,~micBus, \outBus,~delBus, \fadeT, 0.5], ~micGrp, \addToTail);
)

// -----------------------------> DelayL.ar()

// Delay semplice con interpolazione lineare

// Tempo di ritardo max (sec)
// Tempo di ritardo (sec)
// Feedback (0/1)

// Nessun controllo sulla durata del fbk

// DelayN = senza interpolazione
// DelayC = interpolazione cubica

(
SynthDef(\del_1, {arg inBus=0, outBus=0, maxdel=10, del=0.5, fbk=0.0, mix=0,
	                     amp=0, gate=0, fade=0.2, pan=0, done=2;
	                 var in, local, sig, dly, env;
	                     in    = In.ar(inBus);    // Ingresso esterno mono
	                     local = LocalIn.ar(1);   // Ingresso interno mono (per feedback)
	                     sig   = in + local;
	                     dly   = DelayL.ar(sig, maxdel, del);
	                     dly   = LeakDC.ar(dly);
	                 LocalOut.ar(dly * fbk);      // Feedback sig
	                     env   = Linen.kr(gate,fade,1,fade,done);
	                     sig   = XFade2.ar(dly, sig, mix) * env * amp; // mix -1 = solo dly,
	                                                                   // 0 = entrambi,
	                                                                   // 1 = solo suono diretto
	                                                                   // valori intermedi = rapporto
	                     sig  = Pan2.ar(sig, pan);
	                 Out.ar(outBus, sig);
                  }).add;
)

c = Synth(\del_1,[\inBus,~delBus,\outBus,0,\amp,1,\fade,0.5, \gate,1],~fxGrp);    // Delay

c.set(\del,0.5,\mix, -1);   // solo dly
c.set(\del,0.5,\mix, -0.5); // suono diretto + piano della metà
c.set(\del,0.5,\mix, 0.5);  // Delay + piano della metà
c.set(\del,0.5,\mix, 0);

c.set(\fbk,0.6);
c.set(\fbk,0.99);
c.set(\fbk,0.1);
c.set(\fbk,0);
c.set(\gate,0);


// Fai linee di ritardo multiple pannate random

// -----------------------------> Ping pong Delay

// Nessuna balance tra suono diretto e ritardi

(
SynthDef(\del_2, {arg inBus=0, outBus=0, maxdel=2, del=0.5, fbk=0.0,
	                     amp=0, gate=0, fade=0.2, done=2;
	                 var in, local, sig, dly, env;
	                     in    = In.ar(inBus);
	                     local = LocalIn.ar(2) + [in, 0];     // Ingresso interno dual mono (per feedback)
	                     dly   = DelayL.ar(local, maxdel, del, 1);
		                    dly   = LeakDC.ar(dly);
	                     env   = Linen.kr(gate,fade,1,fade,done);
		                LocalOut.ar(dly.reverse * fbk); // reverse = ping pong effect
	                 Out.ar(outBus, local * env * amp);
                  }).add;
)


c = Synth(\del_2,[\inBus,~delBus,\outBus,0, \amp,1,\fade,0.5, \del, 0.8, \fbk,0.2, \gate,1],~fxGrp);    // Delay

c.set(\del,0.1);
c.set(\fbk,0.6);
c.set(\fbk,0.8);
c.set(\fbk,0.1);
c.set(\fbk,0);
c.set(\gate,0);

// -----------------------------> CombL.ar()

// Se vogliamo un controllo sulla durata temporale del fbk (-60 dB)

// CombN = senza interpolazione
// CombC = interpolazione cubica

(
SynthDef(\del_3, {arg inBus=0, outBus=0, maxdel=10, del=0.5, decayT=1, mix=0,
	                     amp=0, gate=0, fade=0.2, pan=0, done=2;
	                 var in, sig, dly, env;
	                     in    = In.ar(inBus);
	                     dly   = CombL.ar(in, maxdel, del, decayT);
	                     env   = Linen.kr(gate,fade,1,fade,done);
	                     sig   = LeakDC.ar(dly);    // Per fbk lunghi
		                 sig   = XFade2.ar(dly, in, mix) * env * amp;
	                     sig  = Pan2.ar(sig, pan);
                  Out.ar(0,sig);
                  }).add;
)

c = Synth(\del_3,[\inBus,~delBus,\outBus,0,\amp,1,\fade,0.5, \decayT,2, \gate,1],~fxGrp);    // Delay

c.set(\decayT,0.6);
c.set(\del,0.5,\mix, -1);  // solo dly
c.set(\del,0.5,\mix, 0.5);
c.set(\decayT,10);
c.set(\decayT,0);
c.set(\gate,0);

// -----------------------------> Delay variabile (trasposizione)

// Se utilizziamo un segnale di controllo continuo che modula il tempo di delay
// otteniamo delle trasposizioni

(
SynthDef(\del_4, {arg inBus=0, outBus=0, maxdel=10, rate=3, decayT=1, mix=0, delMin=0.1,delMax=0.4,
	                  amp=0, gate=0, fade=0.2, pan=0, done=2;
	              var in, sig, mod, dly, pann, env;
	                  in    = In.ar(inBus);
	                  mod   = LFNoise2.kr(rate).exprange(delMin,delMax);  // Delay variabile
	                  dly   = CombL.ar(in, maxdel, mod, decayT);
	                  env   = Linen.kr(gate,fade,1,fade,done);
	                  sig   = LeakDC.ar(dly);    // Per fbk lunghi
		              sig   = XFade2.ar(dly, in, mix) * env * amp;
	                  pann  = Pan2.ar(sig, pan);
	             Out.ar(outBus, pann);
                 }).add;
)


c = Synth(\del_4,[\inBus,~delBus,\outBus,0,\amp,1,\fade,0.5, \decayT,2, \gate,1],~fxGrp);    // Delay

c.set(\decayT,2);
c.set(\delMin,0.1,\delMax,0.8);
c.set(\rate,9);
c.set(\del,0.1,\mix, -1);  // solo dly
c.set(\del,0.5,\mix, 0.5);
c.set(\decayT,10);
c.set(\decayT,0);
c.set(\gate,0);

// -----------------------------> Tap delay (ping pong)

f = Buffer.alloc(s, s.sampleRate * 4, 1); // Creare un Buffer

(
SynthDef(\tap, {arg inBus=0,outBus=0,buf=0,dels=#[0.1,0.5], amp=0,gate=0,fade=0.2;
                var in, rec, env, out;
	                in  = In.ar(inBus);
                    rec = BufWr.ar(in, buf, Phasor.ar(0,1, 0, BufFrames.ir(buf),1));
		            env = Linen.kr(gate,fade,1,fade,2);
                    out = Tap.ar(buf, 1, dels);
	                out = out * amp * env;
	           Out.ar(outBus, out)
}).add;
)


c = Synth(\tap, [\inBus,~delBus,\outBus,0,\buf, f,\dels,[0.8,0.3],\amp,1,\gate,1], ~fxGrp);  // Delay
c.set(\gate,0);

// Non si possono cambiare i tempi dinamicamente ma si possono creare molte linee (multitap delay)

c = 20.collect({arg i; Synth(\tap, [\inBus,~delBus,\outBus,0,\buf,f,\dels,[rrand(0.1,4),rrand(0.1,4)],\amp,1/6,\gate,1], ~fxGrp)});

c.do({arg i; i.set(\dels,[rrand(0.1,4),rrand(0.1,4)])});

c.do({arg i; i.set(\gate,0)});

// -----------------------------> Delay filtrati

// Una ulteriore tecnica consiste nel filtrare il suono ritardato

// OnePole
// coeff -0.95 = Passa alto
// coeff +0.95 = Passa basso

(
SynthDef(\del_5, {arg inBus=0, outBus=0,maxdel=10, del=0.5, fbk=0.0, mix=0,coef=0,
	                  amp=0, gate=0, fade=0.2, pan=0, done=2;
	              var in, local, sig, dly, pann, env;
	                  in    = In.ar(inBus);    // Ingresso esterno mono
	                  local = LocalIn.ar(1);   // Ingresso interno mono (per feedback)
	                  sig   = in + local;
	                  dly   = DelayL.ar(sig, maxdel, del);
	                  dly   = OnePole.ar(dly,coef); // Filtro
	                  dly   = LeakDC.ar(dly);
	              LocalOut.ar(dly * fbk);      // Feedback sig
	                  env   = Linen.kr(gate,fade,1,fade,done);
	                  sig   = XFade2.ar(dly, sig, mix) * env * amp;
	                  pann  = Pan2.ar(sig, pan);
	             Out.ar(outBus, pann);
                 }).add;
)


(
c = 5.collect({arg i; Synth(\del_5, [\inBus,~delBus,
	                                 \outBus,0,
	                                 \buf, f,
	                                 \del, rrand(0.1,9),
	                                 \amp,1/5,
	                                 \coef, rand2(0.95),
	                                 \pan, rand2(1.0),
	                                 \mix, -1,              // solo Dly
	                                 \gate,1], ~fxGrp)});
)

c.do({arg i; i.set(\mix,-1)});
c.do({arg i; i.set(\fbk,rand(0.8))});
c.do({arg i; i.set(\pan,rand2(1.0))});
c.do({arg i; i.set(\del,rrand(0.2,9))});
c.do({arg i; i.set(\fbk,0.8)});
c.do({arg i; i.set(\coef,rand2(0.95))});
c.do({arg i; i.set(\amp,rrand(0.1,1))});
c.do({arg i; i.set(\gate,0)});


// -----------------------------> Delay come resonator

// Simile all'algoritmo di Karplus-Strong

(
SynthDef(\reson, {arg inBus=0, outBus=0, decayT=0.2,
	                  amp=0, gate=0, fade=0.2, pan=0, done=2;
	              var in, reson, dly, pann, env;
	                  in    = In.ar(inBus);
	                  reson = MouseY.kr(0.0001,0.01);
	                  reson.reciprocal.poll(10);      // Frequenza
	                  dly   = CombL.ar(in, 0.01, reson, decayT);
	                  env   = Linen.kr(gate,fade,1,fade,done);
	                  pann  = Pan2.ar(dly*env, pan);
	             Out.ar(outBus, pann);
                 }).add;
)

c = Synth(\reson,[\inBus,~delBus,\outBus,0,\amp,1,\fade,0.5, \gate,1],~fxGrp); // Delay

c.set(\decayT,rand(8.0).postln);
c.set(\gate,0);
