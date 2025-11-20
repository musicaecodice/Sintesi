s = Server.local;

s.options.inDevice_("Microfono MacBook Air"); // Device in ingresso
s.options.outDevice_("Auricolari esterni");   // Device in uscita
s.options.inDevice_("Altoparlanti MacBook Air");
s.options.numInputBusChannels_(1);            // numero canali in ingresso
s.options.numOutputBusChannels_(8);           // Numero canali in uscita

s.reboot;
s.meter;
s.scope;
s.plotTree;

s.reboot;

// Cambio Bus audio dinamico --> ampiezza 0 o click...

(
a = {arg outBus;
	 var sig = SinOsc.ar*0.5;
	Out.ar(outBus,sig)}.play;
)

a.set(\outBus,rand(2));
a.free;


// -------------------> Muting

// fadeout --> cambio bus --> fadein

(
([Env([1,0,1],[0.02,0.02], \lin),
  Env([1,0,1],[0.02,0.02], \cub)]).plot; // meglio...
)

// -------------------> HPZ1.ar

// Filtro differenziale a due punti.

// Implementa la formula:    out(i) = 0.5 * (in(i) - in(i-1))
// Genera trigger di 1 sample.

(
{var sig,hpz1;
	 sig  = LFNoise0.ar(1000);
     hpz1 = HPZ1.ar(sig);
 [sig, hpz1, hpz1 > 0, hpz1.abs > 0]
}.plot(bounds:600@400)
)

// -------------------> XFade in uscita...

(
SynthDef(\router,
          {arg inBus=0, outBus=0, fadeT = 1;
		   var gate,fadeIn,fadeOut,sig,initTrig;
		       sig      = In.ar(inBus,1);          // Segnale
		       initTrig = Impulse.kr(0);           // Init (primo fadeIn)
		       outBus   = K2A.ar(outBus);          // necessario per filtro
			   gate     = HPZ1.ar(outBus).abs > 0; // Trigger

		       fadeIn   = outBus;
	           fadeOut  = DelayN.ar(outBus, fadeT, fadeT);

			Out.ar(fadeIn,
			       sig * EnvGen.ar(Env([0,0,1], [0,fadeT],\cub),gate+initTrig));

			Out.ar(fadeOut,
			       sig * EnvGen.ar(Env([0,1,0], [0,fadeT],\cub),gate));
	       }).add;

SynthDef(\sine, {arg outBus=0;
	             var sig;
	                 sig = SinOsc.ar;
	             Out.ar(outBus,sig)
        }).add
)



(
a = 2.01;
b = Synth(\sine,   [\outBus, 9]);                       // Scrive sul Bus 9
c = Synth(\router, [\inBus,  9, \fadeT,0.1],b,\addAfter);

r = Routine({
	         inf.do({
		             c.set(\outBus,rand(2));
		             a.wait;
                     })
             }).play;
)

c.set(\fadeT,2);
a.free;b.free;c.free;r.stop.free;

// -------------------> Esempio Live

(
SynthDef(\voce, {arg inBus=0, outBus=0, gain=0;
	              var sig;
	                  sig  = SoundIn.ar(inBus, gain.lag(0.02));
	                  sig  = LeakDC.ar(sig);
	              Out.ar(outBus, sig)
                  }).add;

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

SynthDef(\ring3, {arg inBus=0, outBus=0, gain=0,pan=0;
	              var port, mod, idx, fmod, pann;
	                  port  = In.ar(inBus, 1) * gain.lag(0.02);
	                  idx   = LFNoise1.kr(1.5).range(0,1);
	                  fmod  = LFNoise1.kr(0.1).range(100,800);
	                  mod   = Mix(SinOsc.ar([fmod,fmod+0.5])) * idx;
	                  pann  = Pan2.ar(port * mod,pan);
	               Out.ar(outBus, pann)
                   }).add;

SynthDef(\fshift1, {arg inBus=0, outBus=0, gain=0,pan=0,mix=0;
	                var sIn, sig, shift, idx, fmod, pann;
	                    sIn   = In.ar(inBus, 1) * gain.lag(0.02);
	                    shift = 400;
	                    sig   = FreqShift.ar(sIn,shift);
		                sig   = XFade2.ar(sIn, sig, mix);
	                    pann  = Pan2.ar(sig,pan);
	                 Out.ar(outBus, pann)
                   }).add;

SynthDef(\rev_1, {arg inBus=0, outBus=0;
	              var sig,rev;
	                  sig = In.ar(inBus, 2);  // In.ar(bus, n_channels)
	                  rev = FreeVerb.ar(sig,0.5,0.8,0.7);
	              Out.ar(outBus,rev)
        }).add;
)

// -------------------> Bus Audio e Gruppi

(
~route   = Bus.audio(s, 1); // Mono
~ring    = Bus.audio(s, 1); // Mono
~fshift  = Bus.audio(s, 1); // Mono
~rev     = Bus.audio(s, 2); // Stereo

~sources = Group.new;
~fx      = Group.after(~sources); // In basso...
)

// -------------------> Synths

(
a = Synth(\voce,   [\inBus,0,      \outBus,~route, \gain, 1], ~sources);
b = Synth(\router,  [\inBus,~route, \outBus,~rev,   \fadeT,2], ~sources, \addToTail);

c = Synth(\ring3,   [\inBus,~ring,  \outBus,~rev,\gain,1,\pan,-0.5],       ~fx);
d = Synth(\fshift1, [\inBus,~fshift,\outBus,~rev,\gain,1,\pan, 0.5,\mix,0],~fx);
e = Synth(\rev_1,   [\inBus,~rev,   \outBus, 0],                           ~fx, \addToTail);
)

(
~dt = 2;
r = Routine.new({
	             inf.do({
                         b.set(\outBus,[~ring,~fshift,~rev].choose,\fadeT,~dt-0.01);
		                 ~dt.wait
	                     })
                 }).reset.play
)

r.stop;

s.freeAll;
