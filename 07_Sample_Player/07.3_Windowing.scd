// ===========================================================
// Windowing

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

//-----------------------------------------------------------------
// Synth"/Users/andreavigani/Desktop/sting.wav"

(
Buffer.freeAll;
b = Buffer.read(s,"suoni/voce.wav".resolveRelative);

SynthDef(\samp2, {arg buf=0,pos=0,dur=0.2,amp=0,trsp=0,dir=1,pan=0,
	                  t_gate=0,done=2;
                  var sig,env;
                      sig = PlayBuf.ar(1, buf,
                                       BufRateScale.kr(buf) * trsp.midiratio
                                                            * dir,
                                       t_gate,
                                       BufSampleRate.kr(buf)* pos
	                                   );
                     env = Env.linen(0.01,dur-0.02,0.01);
                     env = EnvGen.kr(env,t_gate,doneAction:done);
                     sig = Pan2.ar(sig * env * amp, pan);
                 Out.ar(0,sig)
                }).add;
)

//-----------------------------------------------------------------
// Gestione polifonia

b.duration;

// ------------------------------ Polifonico

(
~dur = rrand(0.1,0.8); // va calcolata prima per sottrarre il valore alla scelta della posizione

Synth(\samp2,[\buf,b,
              \pos, rrand(0+~dur,b.duration-~dur), // tra 0 e la lunghezza del Buffer - durata
              \dur, ~dur,
              \amp,rand(1.0),
              \trsp, rand2(4.0),     // +/- due toni (float = non temperato)
              \dir, [1,-1].choose,
              \pan, rand2(1.0),
              \done,2,
              \t_gate,1
              ])
)

// ------------------------------ Monofonico

a = Synth(\samp2);

(
~dur = rrand(0.1,0.8);   // Prima...

a.set(\buf,b,
      \pos, rrand(0+~dur,b.duration-~dur), // ...evita clicks...
      \dur, ~dur,
      \amp,rand(1.0),
      \trsp, rand2(4.0),
      \dir, [1,-1].choose,
      \pan, rand2(1.0),
      \done,0,              // No autodistruzione..
      \t_gate,1)
)

a.free;

//-----------------------------------------------------------------
// Deterministico

// ------------------------------ Slicing

// Possimo "fare a fettine" un sound file con valori random per
// ottenere una sequenza deterinistica

// J.Cage  Randomness vs Indeterminacy

~nfrag = 50;   // Numero di fettine...
~pos = ~nfrag.collect{rrand(0.02,0.7)}.round(0.01);
~dur = ~nfrag.collect{rrand(0.02,0.7)}.round(0.01);
~amp = ~nfrag.collect{rand(1.0)}.round(0.01);
~del = ~nfrag.collect{rrand(0.5,3.5)}.round(0.01);
~dir = ~nfrag.collect{[1,-1].choose}.round(0.01);

(
~pos = [5.82,9.11,9.76,0.39,9.21,2.85,2.31,0.05];
~dur = [1.40,0.46,1.18,2.39,0.69,1.15,3.41,1.55];
~amp = [0.40,0.65,0.85,1.00,0.70,0.50,0.30,0.10];
~del = [1.48,0.54,2.41,1.26,3.07,0.89,1.16,0.89];
~dir = [1,   -1,  -1,  1,   1,   -1,  1,   1   ];
~pan = [-1,-0.8,-0.6,-0.4,  0,  0.4,0.6,   1   ];

r = Routine.new({
                 ~del.size.do({arg id;
                          Synth(\samp2, [\buf,b,
                                        \pos, ~pos[id],
                                        \dur, ~dur[id],
                                        \amp, ~amp[id],
                                        \trsp, 0,
                                        \dir,~dir[id],
                                        \pan,~pan[id],
                                        \done,2,
                                        \t_gate,1
                                        ]);
		                 ~del[id].wait
	                     })
                }).play
)

// ------------------------------ Time stretching...

// se ~stch > 0 = pausa se ~stch < 0 = sovrapposizione

(
~nfrag = 80;                // Numero di frammenti
~dur   = b.duration/~nfrag; // durata del singolo frammento
~pos   = 0;                 // posizione iniziale
~stch = -0.1;               // se > 0 = pausa se < 0 = sovrapposizione (time stretching)

r = Routine.new({
                 ~nfrag.do({
                            Synth(\samp2, [\buf,b,
                                          \pos, ~pos.postln,
                                          \dur, ~dur,
                                          \amp,1,  //rand(1.0),
                                          \trsp,rand2(3),
                                          \dir, [1,-1].choose,
                                          \pan,0,
                                          \done,2,
                                          \t_gate,1
                                          ]);
                            ~pos = ~pos+~dur;      // incremento della posizione ad ogni loop
                            (~dur+~stch).wait
	                     })
                }).play
)

r.stop;

//-----------------------------------------------------------------
// Non Deterministico

// ------------------------------ Flash...

// Parametri controllati secondo caratteristiche proprie della
// specifica tecnica di elaborazione.

// Pensare multicanale...

(
r = Routine.new({
                 inf.do({
                         Synth(\samp2, [\buf,b,
                                        \out, rand(2),
                                        \pos,rand(b.duration)-1,
                                        \dur,rrand(0.05,0.3),
                                        \amp,rand(1.0),
                                        \trsp,rand2(5),
                                        \dir, [1,-1].choose,
                                        \pan,rand2(1.0),
                                        \done,2,
                                        \t_gate,1
                                        ]);
                         rrand(0.05,1).wait
	                     })
                }).reset.play
)

r.stop;

// ------------------------------ Fisarmonica...

// Pensare mono come se fosse uno strumento acustico

(
r = Routine.new({
                 inf.do({var dt = [0.1,0.5,1].choose;
                         Synth(\samp2, [\buf,b,
                                        \pos,[0.1,0.5,0.7].choose,
                                        \dur,dt,
                                        \amp,0.4,
                                        \dir, [1,-1].choose,
                                        \pan, 0,
                                        \done,2,
                                        \t_gate,1
                                        ]);
                         dt.wait
	                     })
                }).reset.play
)

r.stop;

