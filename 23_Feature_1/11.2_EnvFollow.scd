s = Server.local;

s.options.inDevice_("Microfono MacBook Air"); // Device in ingresso
s.options.outDevice_("Auricolari esterni");   // Device in uscita
s.options.inDevice_("Altoparlanti MacBook Air");
s.options.numInputBusChannels_(1);            // numero canali in ingresso
s.options.numOutputBusChannels_(8);           // Numero canali in uscita

s.boot;

(
s.meter;
s.scope;
s.plotTree;
)

s.reboot;

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
~envfBusIn.free;
~envfBusOut.free;

~micBus     = Bus.audio(s,1); // Bus Microfono
~envfBusIn  = Bus.audio(s,1); // Bus Envelope follower
~envfBusOut = Bus.audio(s,2); // Bus segnale uscita (audio 2 canali)

~micGrp  = Group.new;            // Gruppo sources
~folGrp  = Group.after(~micGrp); // Gruppo analisi
~playGrp = Group.after(~folGrp); // Gruppo synth

a = Synth(\mic,    [\inBus,0,        \outBus,~micBus, \amp,1],        ~micGrp); // Sig in
b = Synth(\router, [\inBus, ~micBus, \outBus,~envfBusIn, \fadeT, 0.5], ~micGrp, \addToTail);
)

// -----------------------------> Envelope following

(
a = {var sig,siga,env1,env2,env3,env4;
	     sig = SoundIn.ar;                // Bipolare
	     siga = sig.abs;                  // Unipoare
	     env1 = LagUD.ar(siga,0.01,0.01); // Smoothing filter logaritmico
	     env2 = LagUD.ar(siga,0.01,0.1);
	     env3 = Amplitude.ar(sig,0.1,0.1);
	[sig,siga,env1,env2,env3] }.plot(1);
)

a.free;

// -----------------------------> Amplitude.ar()

(
// -----------------------------> Synth envelope follower

SynthDef(\envflw1, {arg inBus=0,outBus=0,atk=0.01,dec=0.01;
	                var sig, amp;
	                    sig = In.ar(inBus,1);
	                    amp = Amplitude.ar(sig,atk,dec);
		                amp.poll;
	                Out.ar(outBus,amp)
         }).add;
)

(
c = Synth(\envflw1, [\inBus,~envfBusIn,\outBus,~envfBusOut], ~folGrp);
d = ~envfBusOut.scope; // monitor visivo...
)

c.free;d.free;s.scope;

// -----------------------------> Mapping continuo

// Possiamo mappare il segnale continuo su un parametro qualsiasi di
// una tecnica di sintesi e/o campionamento eventualmente riscalato...

(
SynthDef(\noise, {arg inBus=0,outBus=0;
	              var sig, env;
	                  sig = PinkNoise.ar!2;
	                  env = In.ar(inBus,1);  // segnale dell'envelope follower
	               Out.ar(outBus,sig * env)
         }).add;
)

(
c = Synth(\envflw1, [\inBus,~envfBusIn,\outBus,~envfBusOut,\dec,0.6], ~folGrp);
d = Synth(\noise,   [\inBus,~envfBusOut,\outBus,0],                   ~playGrp);
)

// testare atk e dec differenti...

c.set(\atk,0.1,\dec,0.2);

c.free;d.free;

// -----------------------------> Mapping trigger

// Se stabiliamo invece delle soglie possiamo generare un trigger...

(
SynthDef(\envflw2, {arg inBus=0,outBus=0,atk=0.01,dec=0.01,soglia=0.3,dur=0.1;
	                var sig, amp, trig;
	                    sig  = In.ar(inBus,1);
	                    amp  = Amplitude.ar(sig,atk,dec);
	                    trig = Trig1.ar(amp > soglia, dur); // Trigger
	                Out.ar(outBus,[amp,trig]);

			// Invia all'Interprete...

	                SendTrig.ar(trig,
		                        100,  // id del trigger (nel caso fossero + di 1)
                                amp); // Segnale da inviare
         }).add;

SynthDef(\sine1, {arg inBus=0,outBus=0;
	              var sig, gate, env;
	                  gate = In.ar(inBus,2);  // 2 canali...
	                  env  = EnvGen.kr(Env.perc, gate[1]);
	                  sig  = SinOsc.ar(TRand.ar(500,1000,gate))!2;
	              Out.ar(outBus, sig * env * gate[0]);
         }).add;
)

(
c = Synth(\envflw2, [\inBus,~envfBusIn,\outBus,~envfBusOut,\dec,0.6,\soglia, 0.01,\dur,0.2], ~folGrp);
d = Synth(\sine1,   [\inBus,~envfBusOut,\outBus,0],     ~playGrp);

	// Riceve dal Server...

e = OSCFunc.new({arg msg; msg.postln},'/tr', s.addr);
)

c.set(\soglia,0.01)
c.free;d.free;e.free;

// -----------------------------> Noise Gate - Compander.ar()

// Se il segnale è sotto una soglia non passa...

(
n = {arg soglia=0.01;
     var in, ngate;
	     in    = SoundIn.ar;
	     ngate = Compander.ar(in, in, soglia, 10, 1, 0.01, 0.2);
	     ngate!2
}.play
)

n.set(\soglia,0.1)
n.free;

// -----------------------------> Noise Gate + Amlitude follower

// In alcune situazioni può essere utile inserire un noise gate
// prima dell'envelope following...

(
SynthDef(\envflw3, {arg inBus=0,outBus=0,atk=0.01,dec=0.01,soglia=0.01;
	                var sig, env;
	                    sig = In.ar(inBus,1);
	                    sig = Compander.ar(sig, sig, soglia, 10, 1, 0.01, 0.2);
	                    env = Amplitude.ar(sig, atk,dec);
	                Out.ar(outBus,[env, env.pow(0.5)])
         }).add;

SynthDef(\saw, {arg inBus=0,outBus=0,soglia=0.3;
	            var sig, env;
	                env  = In.ar(inBus,1);
	                sig  = Saw.ar([560,563]);
	            Out.ar(outBus,sig * env * 0.5);

         }).add;
)

(
c = Synth(\envflw3, [\inBus,~envfBusIn,\outBus,~envfBusOut,\dec,0.6,\soglia,0.2], ~folGrp);
d = Synth(\saw,     [\inBus,~envfBusOut,\outBus,0,\soglia, 0.2],      ~playGrp);
)

c.free;d.free;

// -----------------------------> Altre UGens...

// Amplitude following

Amplitude    // amplitude follower
PeakFollower // peak amp tracker

// Amplitude minimum/maximum

Peak           // Ampiezza di picco
DetectSilence  // Se il segnale rimane sotto una soglia per un tempo dato genera 1

// Processori d'ampiezza

Compander  // Compressore,expander, limiter, noise gate
