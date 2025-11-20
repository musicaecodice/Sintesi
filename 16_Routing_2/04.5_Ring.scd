s = Server.local;

s.options.inDevice_("Microfono MacBook Air"); // Device in ingresso
s.options.outDevice_("Auricolari esterni");   // Device in uscita
s.options.inDevice_("Altoparlanti MacBook Air");
s.options.numInputBusChannels_(1);            // numero canali in ingresso
s.options.numOutputBusChannels_(8);           // Numero canali in uscita

s.boot;
s.meter;
s.scope;
s.freqscope;
s.plotTree;


// -------------------> In

(
SynthDef(\sigIn, {arg inBus=0, outBus=0, gain=0;
	                 var sig;
	                     sig  = SoundIn.ar(inBus,gain.lag(0.02));
	                     sig  = LeakDC.ar(sig);
	                 Out.ar(outBus,sig)
                  }).add;

SynthDef(\ring1, {arg inBus=0, outBus=0, gain=0,pan=0;
	                 var port, mod, idx, pann;
	                     port  = In.ar(inBus, 1) * gain.lag(0.02);
                      idx   = MouseY.kr(0,1).poll(10, \idx);
                      mod   = SinOsc.ar(MouseX.kr(20,1000).poll(10,\fmod)) * idx;
	                     pann  = Pan2.ar(port * mod, pan);
	                Out.ar(outBus, pann)
                   }).add
)

// -------------------> Bus Audio e Gruppi

~ring    = Bus.audio(s, 1);  // Server, n_channels

~sources = Group.new;
~fx      = Group.after(~sources); // In basso...

// -------------------> Synths

a = Synth(\sigIn, [\inBus,0,    \outBus,~ring,\gain,1], ~sources);
b = Synth(\ring1, [\inBus,~ring,\outBus,0,    \gain,1], ~fx);

a.free;b.free;

// -------------------> Mapping (strumento aumentato)

(
SynthDef(\ring2, {arg inBus=0, outBus=0, gain=0,pan=0;
	              var port, mod, idx, pann;
	                  port  = In.ar(inBus, 1) * gain.lag(0.02);
	                  idx   = Amplitude.ar(port);                    // envelope follower = idx
	                  mod   = SinOsc.ar(LFNoise1.kr(0.1).range(20,1000)) * idx; // freq modulante random
	                  pann  = Pan2.ar(port * mod,pan);
	               Out.ar(outBus, pann)
                   }).add
)

a = Synth(\sigIn, [\inBus,0,    \outBus,~ring,\gain,1], ~sources);
b = Synth(\ring2, [\inBus,~ring,\outBus,0,    \gain,1], ~fx);

a.free;b.free;

// -------------------> Chorusing (strumento aumentato)

(
SynthDef(\ring3, {arg inBus=0, outBus=0, gain=0,pan=0;
	                 var port, mod, idx, fmod, pann;
	                     port  = In.ar(inBus, 1) * gain.lag(0.02);
	                     idx   = Amplitude.ar(port);
	                     fmod  = LFNoise1.kr(0.01).range(20,1000);
	                     mod   = Mix(SinOsc.ar([fmod,fmod+0.5])) * idx; // multichannel expansion
	                     pann  = Pan2.ar(port * mod,pan);
	                Out.ar(outBus, pann)
                   }).add
)

a = Synth(\sigIn, [\inBus,0,    \outBus,~ring,\gain,1], ~sources);
b = Synth(\ring3, [\inBus,~ring,\outBus,0,    \gain,1], ~fx);

a.free;b.free;

// -------------------> Frequency Shifter (strumento aumentato)

// Modulazione d'ampiezza a singola sideband
// Sposta tutti i parziali di un valore costante ma non preserva
// le relazioni frequenziali originali.

(
SynthDef(\fshift1, {arg inBus=0, outBus=0, gain=0,pan=0,mix=0;
	                   var sIn, sig, shift, idx, fmod, pann;
	                       sIn   = In.ar(inBus, 1) * gain.lag(0.02);
	                       shift = MouseY.kr(1,500).poll(10);       // Shift in Hz
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

~rev    = Bus.audio(s, 2);  // Bus stereo...

a = Synth(\sigIn,   [\inBus,0,    \outBus,~ring,      \gain,1], ~sources);
b = Synth(\fshift1, [\inBus,~ring,\outBus,~rev,\mix,0,\gain,1], ~fx);
c = Synth(\rev_1,   [\inBus,~rev,\outBus,0],                    ~fx, 'addToTail'); // Se nello stesso Gruppo...

s.freeAll;
