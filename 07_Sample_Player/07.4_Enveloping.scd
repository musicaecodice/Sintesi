// ===========================================================
// Enveloping

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

// Come windowing ma la modifica dell'inviluppo d'ampiezza
// deve essere una caratteristica dell'elaborazione.

//-----------------------------------------------------------------
// Synth 1

// Inviluppo dello stesso tipo, parametri variabili


(
Buffer.freeAll;
b = Buffer.read(s,"suoni/bach.wav".resolveRelative);

SynthDef(\samp3, {arg buf=0,pos=0,dur=0.2,amp=0,trsp=0,dir=1,pan=0,
	                  t_gate=0,atk=0.1,done=2;
                  var sig,env;
                      sig = PlayBuf.ar(1, buf,
                                       BufRateScale.kr(buf) * trsp.midiratio
                                                            * dir,
                                       t_gate,
                                       BufSampleRate.kr(buf)* pos );
                     env = Env.perc(atk, dur-atk);
                     env = EnvGen.kr(env,t_gate,doneAction:done);
                     sig = Pan2.ar(sig * env * amp, pan);
                 Out.ar(0,sig)
                }).add;
)

//-----------------------------------------------------------------
// Gestione polifonia

// ------------------------------ Polifonico

(
~dur = rrand(0.1,1);

Synth(\samp3, [\buf,b,
	           \amp,rand(1.0),
	           \pos,rand(4.0),
	           \done,2,
	           \dur,~dur,
	           \atk, ~dur * rand(0.95), // Attacco variabile
	           \t_gate,1]);
)

// ------------------------------ Monofonico

a = Synth(\samp3, [\buf,b,\amp,1,\done,0]);

(
~dur = rrand(0.01,1);

a.set(\dur,~dur,
	  \atk, ~dur * rand(0.95),
	  \t_gate,1);
)

// ------------------------------ Sequenza

(
~durs = [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9];
~pos  = [0.1,0.3,0.5,0.7,0.9,1.1,1.3,1.5,1.7];
~atk  = [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9];

r = Routine.new({
                 ~durs.do({arg item,id;
                           Synth(\samp3, [\buf,b,
                                         \amp,1,
                                         \pos, ~pos.at(id),
                                         \done,2,
                                         \atk, ~atk.at(id),
                                         \t_gate,1]);
		                    (item+rrand(0.01,0.3)).wait // tempi delta...
	                       })
                 }).reset.play
)

r.stop

//-----------------------------------------------------------------
// Synth 2

// Inviluppi diversi e parametri variabili

(

//-------------------------------- GUI inviluppo

w = Window("EnvelopeView", 250@250);
e = EnvelopeView(w, 250@250).drawLines_(true).drawRects_(true);
w.front;
w.onClose = {e.free;w.free;d.free;f.free};

//-------------------------------- SynthDef

SynthDef(\samp4, {arg buf=0,pos=0,amp=0,trsp=0,dir=1,pan=0,t_gate=0,done=2;
                  var sig,env;
                      sig  = PlayBuf.ar(1, buf,
                                        BufRateScale.kr(buf) * trsp.midiratio
                                                             * dir,
                                        t_gate,
                                        BufSampleRate.kr(buf)* pos );
                      env = Env.newClear(4);         // Crea un inviluppo vuoto di 4 nodi
                      env = \env.kr(env.asArray);    // Crea un controllo dell'inviluppo
                      env = EnvGen.kr(env, t_gate, doneAction:done);
                      sig = Pan2.ar(sig * env * amp, pan);
                 Out.ar(0,sig)
                }).add;
)

(
d = 0.5;                           // Definiamo una durata
f = [Env.perc(0.1,1).duration_(d), // Riscala la durata
     Env.triangle(d),
     Env.sine(d),
     Env.linen(0.1,1,0.7).duration_(d)
     ].choose;                     // ne sceglie uno a caso

Synth(\samp4, [\buf,b,
               \amp,1,
               \pos,1,
               \done,2,
               \env, f,
               \t_gate,1]); // Polifonico
e.setEnv(f)                 // lo visualizza sull'interfaccia
)
