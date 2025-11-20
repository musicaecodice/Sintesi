//=================================================================
// Partiture informatiche

(
s.boot;
s.scope;
s.freqscope;
{ s.plotTree }.defer(4)
)

(
SynthDef.new(\saw, {arg freq=400,amp=0,dur=1,t_gate=0,pan=0,done=2;
	                   var sig,env;
	                       sig = Saw.ar(freq);
	                       env = Env.perc(0.1*dur,0.9*dur);
	                       env = EnvGen.kr(env,t_gate,doneAction:done);
                        sig = sig*amp*env;
	                       sig = Pan2.ar(sig,pan);
	                   Out.ar(0, sig)
             }).add;

SynthDef(\blip, {arg freq=400, amp=0, nharm=3, dur=1,pan=0,t_gate=0,done=2;
	                var sig,env;
	                    sig = Blip.ar(freq, nharm);
	                    env = EnvGen.kr(Env.perc(0.1*dur, 0.9*dur),t_gate,doneAction:done);
	                    sig = Pan2.ar(sig*env*amp,pan);
	                Out.ar(0,sig)
                 }).add;
SynthDef(\wave_s, {arg buf=b, freq=500, amp=0, dur=1,t_gate=0,pan=0,done=0;
	                  var sig,bpf,env,pann;
	                      sig   = Osc.ar(buf,freq);
	                      bpf   = Env.sine(dur);
	                      env   = EnvGen.ar(bpf,t_gate,doneAction:done);
	                      pann  = Pan2.ar(sig*amp*env,pan);
	               Out.ar(0,pann)}
         ).add;
)

//=================================================================
// Thread unico

//-----------------------------------------------------------------
// Ambient Glassarmonica
// Triangolare

(
Buffer.freeAll;

~punti = 512;
~npar  = (45/2).asInteger;
~harm  = ~npar.collect({arg n; 1+n+n});
~sign  = ~npar.collect({arg n; -1**n});
~amps  = ~sign * (1/~harm**2);

e = Buffer.alloc(s, ~punti);

e.sine2(~harm,~amps);

r = Routine.new({
	             inf.do({
                      Synth(\wave_s, [\buf,e,
			                                   \amp,rand(0.6),
			                                   \freq,([46,48,50].choose +
				                                         [12,24,36,48].choose).midicps, // Ottave
			                                   \pan,rand2(1.0),
			                                   \dur,rrand(0.5, 5),
			                                   \done,2,
			                                   \t_gate,1]);
		                 [2,1,0.5,0.25,0.125].choose.wait;
	                     })
                }).play;
)

r.stop;

//=================================================================
// Processi paralleli (multithread)

//-----------------------------------------------------------------
// Duo free per trombetta giocattolo e armonica a bocca
// Sawtooth

(
Buffer.freeAll;

~punti  = 1024;
~npar   = 45;
~harm   = ~npar.collect({arg n; n});
~sign   = -1**~harm;
~amps   = 1.0/(1+~harm*~sign);

b = Buffer.alloc(s, ~punti);
b.sine1(~amps);

// Voce 1 - trombetta giocattolo
r = Routine.new({
	             inf.do({
                         Synth(\wave_s, [\buf,b,
			                             \amp,rand(1.0),
			                             \freq,rrand(60,82).midicps,
			                             \pan,rand2(1.0),
			                             \dur,rrand(0.02, 0.8),
			                             \done,2,
			                             \t_gate,1]);
		                 [0.01,0.02,0.1,0.2,0.5,1].choose.wait;
	                     })
                }).play;

// Voce 2 - armonica a bocca
d = Routine.new({
	             inf.do({
		                 Synth(\wave_s, [\buf,b,
			                             \amp,rand(1.0),
			                             \freq,[89,90,92].choose.midicps,
			                             \pan,rand2(1.0),
			                             \dur,rrand(0.02, 0.2),
			                             \done,2,
			                             \t_gate,1]);
		                [0.02,0.2,0.5,1].choose.wait;
	                    })
                 }).play;
)

r.stop;d.stop;

//-----------------------------------------------------------------
// Clarinetto basso intimamente agitato
// Square

(
Buffer.freeAll;

~punti = 512;
~npar  = (45/2).asInteger;
~harm  = ~npar.collect({arg n; 1+n+n});
~amps  = 1/~harm;

c = Buffer.alloc(s, ~punti);

c.sine2(~harm,~amps);

r = Routine.new({
	             inf.do({
                         Synth(\wave_s, [\buf,c,
			                             \amp,rand(0.5),
			                             \freq,[45,49,52,56].choose.midicps,
			                             \pan,rand2(1.0),
			                             \dur,rrand(0.6, 7),
			                             \done,2,
			                             \t_gate,1]);
		                 [0.1,0.2,0.5,1,3].choose.wait;
	                     })
                }).play;
d = Routine.new({
	             inf.do({
                         Synth(\wave_s, [\buf,c,
			                             \amp,rand(0.5),
			                             \freq,50.midicps,
			                             \pan,rand2(1.0),
			                             \dur,0.07,
			                             \done,2,
			                             \t_gate,1]);
		                 0.07.wait;
	                     })
                }).play;
)

r.stop;d.stop;

//-----------------------------------------------------------------
// Tabla
// Periodic noise

(
Buffer.freeAll;

~punti = 512;                // Numero di punti (size della tavola)
~amp   = 1.0;                // Ampiezza di picco

g = ~punti.collect({~amp * rand2(1.0)});

i = Buffer.alloc(s, ~punti);

i.loadCollection(g);       // Carica FloatArray nel Buffer (sine)

// Due "note" con due ritmi...
r = Routine.new({
	             inf.do({
                         Synth(\wave_s, [\buf,i,
			                             \amp,[0.3,1].choose,
			                             \freq,[60,72].choose.midicps,
			                             \pan,0,
			                             \dur,[0.01,0.03].choose,
			                             \done,2,
			                             \t_gate,1]);
		                 [0.25,0.125].choose.wait;  // Suddivisioni regolari...
	                     })
                 }).play;

// Altre due "note" con altri due ritmi...
d = Routine.new({
	             inf.do({
                         Synth(\wave_s, [\buf,i,
			                             \amp,[0.3,1].choose,
			                             \freq,[58,120].choose.midicps,
			                             \pan,0,
			                             \dur,[0.01,0.03].choose,
			                             \done,2,
			                             \t_gate,1]);
		                 [0.5,0.25].choose.wait;
	                     })
                 }).play;

// Ogni 5 secondi cambia il contenuto del Buffer
f = Routine.new({
	             inf.do({
                         g = ~punti.collect({arg n; ~amp * rand2(1.0)});
		                 b.loadCollection(g);
		                 5.wait;
	                     })
                 }).play;
)

r.stop;d.stop;f.stop;

//=================================================================
// Nested Routines
// Organizzazione determinisica con funzioni (sezioni)

(
~sec1 = {~bpm1 = 160;
         ~beat1 = 60/~bpm1;
	        ~metro1 = TempoClock.new(~bpm1/60);
         r = Routine.new({

	         inf.do({
		                Synth(\saw, [\freq,678,\amp,0.5,\dur,0.5*~beat1,\pan,0,\t_gate,1]);
	                 1.wait;
	                 })

                 }).play(~metro1)
         }
)

~sec1.value; // Fa partire la sequenza
r.stop;      // Stoppa la sequenza

(
~sec2 = {~bpm2 = 120;
         ~beat2 = 60/~bpm2;
	        ~metro2 = TempoClock.new(~bpm2/60);
         g = Routine.new({

	         inf.do({
		                Synth(\saw, [\freq,987,\amp,0.5,\dur,0.5*~beat2,\pan,0,\t_gate,1]);
	                 0.5.wait;
	                 })

                 }).play(~metro2)
         }
)

//-----------------------------------------------------------------
// Partitura

(
~bpm = 120;
~beat = 60/~bpm;
~metro = TempoClock.new(~bpm/60);
~score = Routine.new({
	                  ~sec1.value;
	                  2.wait;
	                  r.stop;
	                  ~sec2.value;
	                  3.wait;
	                  ~sec1.value;
	                  2.wait;
	                  g.stop;
	                  3.wait;
	                  r.stop
                      })
)

~score.reset.play(~metro);

//=================================================================
// Organizzazione non determinisica senza funzioni (sezioni)

(
r = Routine.new({
                 inf.do({
                         Synth(\blip, [\freq,100.midicps,\amp,1,
			                                    \nharm, 9,\dur,0.1,
	                                      \pan, 0,\t_gate,1]);
		                       0.1.wait;
	                     })
                });

u = Routine.new({
                 inf.do({
                         Synth(\blip, [\freq, [60,72].choose.midicps,
			                                    \amp, [1,0.3].wchoose([0.2,0.8]),
	                                      \nharm,9, \dur, 0.1,
			                                    \pan, rand2(1.0), \t_gate,1]);
		                 [0.01,0.1,0.5].choose.wait;
                         })
                 });
)

//-----------------------------------------------------------------

(
y = Routine.new({
	             inf.do({
		           if(rand(2) == 0,                         // Se è 0 AND...
			                     { if( r.isPlaying==false,  // non è già attiva...
				                           {r.reset.play; u.stop}
			                          )
			                      },
			                     { if( u.isPlaying==false,
				                           {u.reset.play; r.stop}
			                          )
		                          }
		             );
		            rrand(0.1,5).wait
	                  })
                }).play
)

y.stop; u.stop; r.stop;

