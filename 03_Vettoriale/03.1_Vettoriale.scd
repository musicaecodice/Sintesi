//=================================================================
// Sintesi Vettoriale
(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

//-----------------------------------------------------------------
// Array di Buffer

(
Buffer.freeAll;
b = Buffer.allocConsecutive(4,      // Numero di Buffer
                            s,      // Server
                            1024);  // Size di ogni singolo Buffer (multiplo di 2)
)

(
b[0].sine1([1,0.3,0.5,0.7],true,true);  // asWavetable !!!
b[1].sine1([0.2,0.4,1.3,0.6],true,true);
b[2].sine1([1,0.2,0.5,0.6,1.3,0.5],true,true);
b[3].sine1([1.3,0.3,0.5,0.7,0.8,0.9,0.2,0.3],true,true);
)

b.at(0);
b[0].plot;

b.do(_.free); // libera l'Array di Buffer


//-----------------------------------------------------------------
// Sintesi vettoriale

(
SynthDef(\vec_1, {arg buf=0,bufn=4,freq=400,amp=0,pan=0,gate=0,done=2;
                  var pos,sig,env;
                      pos  = MouseX.kr(buf,bufn.asFloat).poll(10);
                      sig  = VOsc.ar(pos, freq);
                      env  = Linen.kr(gate,doneAction:done);
                      sig  = Pan2.ar(sig*amp*env,pan);
                  Out.ar(0, sig)
        }).add;
)

a = Synth(\vec_1, [\buf,b[0],\bufn,b.size-1,\freq,400,\amp,1,\pan,0,\gate,1]);
a.set(\gate,0);

//-----------------------------------------------------------------
// Mapping parametri

// Un solo valore controlla il timbro...due (quattro) possibilità
// di controllo.

// -------> 1) Timbro mappato argomenti

// Per maggiore compatibilità meglio stabilire un range tra -1 e + 1

(
SynthDef(\vec_2, {arg buf=0,bufn=4,pos= -1,freq=400,amp=0,pan=0,gate=0,done=2;
                  var sig, env;
                      sig = VOsc.ar(pos.linlin(-1,1,buf,bufn).lag(0.02), freq);
                      env = Linen.kr(gate,doneAction:done);
                      sig = Pan2.ar(sig*amp*env,pan);
                  Out.ar(0, sig)
        }).add;
)

a = Synth(\vec_2, [\buf,b[0],\bufn,b.size-1,\freq,400,\amp,1,\pan,0,\gate,1]);
a.set(\pos,rand2(1.0).postln);
a.set(\gate,0);

// -------> 2) Timbro mappato su segnale di controllo esterno

(
~mouseY = Bus.control(s, 1); // (server, n_canali)

SynthDef.new(\mouse, {arg busOut=0;
	                  var sig;
	                      sig = MouseY.kr(-1,1).poll(10);
	                  Out.kr(busOut,sig)
             }).add;

{m = Synth(\mouse, [\busOut, ~mouseY])}.defer(1); // Synth per ksig

a = Synth(\vec_2, [\buf,b[0],\bufn,b.size-1,
	               \freq,400,\amp,1,\pan,0,\gate,1],
                   s, \addToTail);    // Deve essere dopo il Synth del Mouse
)

a.set(\pos,~mouseY.asMap);     // Mappa il parametro sul control bus...
a.set(\pos,rand2(1.0).postln); // Scollega il bus...
a.set(\gate,0); m.free;

// -------> 3) Timbro mappato sull'inviluppo d'ampiezza

(
SynthDef(\vec_3, {arg buf=0,bufn=4,freq=400,dur=1,amp=0,pan=0,t_gate=0,done=2;
                  var sig,bpf,env;
                      bpf   = Env.sine(dur);
                      env   = EnvGen.ar(bpf,t_gate,doneAction:done);
                      sig   = VOsc.ar(env.linlin(0,1,buf,bufn-1), freq);
                      sig   = Pan2.ar(sig*amp*env,pan);
                  Out.ar(0, sig)
        }).add;
)

(
Synth(\vec_3, [\buf,b,\bufn,4,
               \freq,rrand(70, 96).midicps,
               \dur,rrand(1,8),
               \amp,rand(1.0),
               \pan,rand2(1.0),
               \t_gate,1]);
)

// -------> 4) Timbro mappato su segnale di controllo interno

(
SynthDef(\vec_4, {arg buf=0,bufn=4,freq=400,kfreq=0.5,dur=1,amp=0,pan=0,gate=0,done=2;
                  var sig,ksig,env;
                      env   = Linen.kr(gate,doneAction:done);
	              //    ksig  = MouseY.kr(buf,bufn.asFloat);
	                  ksig  = LFNoise1.kr(kfreq).range(buf,bufn-1); // Ksig riscalato
                      sig   = VOsc.ar(ksig, freq);
                      sig   = Pan2.ar(sig * amp * env, pan);
                  Out.ar(0, sig)
        }).add;
)

(
a = Synth(\vec_4, [\buf,b,\bufn,4,
                   \freq,rrand(70, 96).midicps,
                   \dur,rrand(0.1,2),
                   \amp,rand(1.0),
                   \pan,rand2(1.0),
                   \gate,1]);
)

a.set(\kfreq,2);
a.set(\kfreq,0.7);
a.set(\gate,0);

//-----------------------------------------------------------------
// Chorusing

(
SynthDef(\vec_3, {arg buf=0,bufn=4,freq=#[440,445,435],amp=0,pan=0,gate=0,done=2;
                  var pos,sig,env,pann;
                      pos   = LFNoise1.kr(0.2).range(0.0,bufn-1);
                      sig   = VOsc3.ar(pos, freq[0],freq[1],freq[2]);
                      env   = Linen.kr(gate,doneAction:done);
                      pann  = Pan2.ar(sig*amp.lag(2)*env);
                  Out.ar(0, pann)
        }).add;
)

(
a = Synth(\vec_3, [\buf,b[0],
                   \bufn,b.size-1,
                   \freq, 3.collect({rrand(200,1000)}).postln,
                   \amp,0.3,
                   \pan,0,
                   \gate,1]);
)

a.set(\freq,[438,440,442]);

a.set(\gate,0);
