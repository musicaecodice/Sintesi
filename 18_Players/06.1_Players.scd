ServerOptions.devices; // Array devices connessi


s.options.inDevice_("Microfono MacBook Air");
//s.options.outDevice_("Altoparlanti MacBook Air");
s.options.outDevice_("Auricolari esterni");

s.reboot;
s.scope;
s.plotTree;

// -----------------------------> Buffer vuoto

(
Buffer.freeAll;
b = Buffer.alloc(s, s.sampleRate * 3, 1); // Allocazione 1 secondo di memoria mono
)

c = Buffer.read(s,"/Users/andreavigani/Desktop/Milano_2021_22/0Corsi_21_22/Suoni_1/crotal_A#6.wav");

(
// -----------------------------> Synth input

SynthDef.new(\mic, {arg inBus=0,outBus=0,amp=0;
	                var sig;
	                    sig = SoundIn.ar(inBus) * amp;
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

// -----------------------------> Synth Recorder

SynthDef.new(\rec1,{arg buf=0, inBus=0, loop=0, mix=0, done=2;
                    var in;
                        in = In.ar(inBus, 1);
                    RecordBuf.ar(in,buf,preLevel:mix,loop:loop,doneAction:done);
             }).add;

// -----------------------------> Bus audio

~micBus.free;
~recBus.free;
~micBus = Bus.audio(s,1); // Bus microfono
~recBus = Bus.audio(s,1); // Bus Registratore
)

// -----------------------------> Gruppi e Synth

(
~micGrp = Group.new;
~recGrp = Group.after(~micGrp);
~plyGrp = Group.after(~recGrp);

Synth(\mic,    [\inBus, 0, \amp,1, \outBus,~micBus],              ~micGrp);
Synth(\router, [\inBus, ~micBus,   \outBus,~recBus, \fadeT, 0.5], ~micGrp, \addToTail);
)

// -----------------------------> PlayBuf

(
SynthDef(\ply1, {arg buf=0,outBus=0,pos=0,dur=0.2,amp=0,trsp=0,dir=1,pan=0,t_gate=0,done=2;
                 var sig,bpf,env,pann;
                     sig  = PlayBuf.ar(1, buf,
                                       BufRateScale.kr(buf) * trsp.midiratio // Trasposizione...
                                                            * dir,           // ...e direzione
                                       t_gate,                               // Trigger
                                       BufSampleRate.kr(buf)* pos            // Posizione
	                                   );
                   //  bpf  = Env.linen(0.01,dur-0.02,0.01);                   // Windowing
	bpf = Env.perc(0.01,dur-0.01);
                     env  = EnvGen.kr(bpf,t_gate,doneAction:done);
                     pann = Pan2.ar(sig*env*amp,pan);
                 Out.ar(0,pann)
                }).add;
)

Synth(\rec1, [\buf,b,\inBus,~recBus,\mix,0,\loop,0,\done,2], ~recGrp); // Oneshot rec...

(
Synth(\ply1,[\buf,b,      // Verifica...
	         \outBus, 0,
             \pos, 0.6,
             \dur, 0.8,
             \amp,1,
	         \trsp, 0,
             \dir, 1,
             \pan, 0,
             \done,2,
             \t_gate,1
             ], ~plyGrp)
)

// -----------------------------> Slicing

~rec = Synth(\rec1, [\buf,b,\inBus,~recBus,\mix,0,\loop,1,\done,0], ~recGrp); // loop rec...

// Mortazza...
(
~nfrag = 20;                // Numero di frammenti
~dur   = b.duration/~nfrag; // durata del singolo frammento
~pos   = 0;                 // posizione iniziale
~pausa = 0.1;               // se > 0 = pausa se < 0 = sovrapposizione (time stretching)

a = Synth(\ply1, [\buf,b,\done,0,\outBus, 0,],~plyGrp);
r = Routine.new({
                 inf.do({
                         a.set(\pos, ~pos.postln,
                               \dur, ~dur,
                               \amp,rand(1.0),
                               \trsp,rand2(3),
                               \dir, [1,-1].choose,
                               \pan,0,
                               \t_gate,1);
		                 ~pos = (~pos+~dur) % b.duration;      // incremento della posizione ad ogni loop
                         (~dur+~pausa).wait
	                     })
                }).play
)

r.stop;
a.free;

// Flash...
(
r = Routine.new({
                 inf.do({
                         Synth(\ply1, [\buf,b,
                                       \out, rand(2),
                                       \pos,rand(b.duration)-0.3, // per evitare il click...
                                       \dur,rrand(0.05,0.3),
                                       \amp,rand(1.0),
                                       \trsp,rand2(5),
                                       \dir, [1,-1].choose,
                                       \pan,rand2(1.0),
                                       \done,2,
                                       \t_gate,1
                                       ],~plyGrp);
                         rrand(0.05,0.3).wait
	                     })
                }).reset.play
)

r.stop;

// Fisarmonica...
(
r = Routine.new({
                 inf.do({var dt = [0.25,0.5,0.125].choose;
                         Synth(\ply1, [\buf,b,
                                       \pos,rand(b.duration)-dt, // per evitare il click...
                                       \dur,dt*0.5,
                                       \amp,0.4,
                                       \dir, [1,-1].choose,
                                       \pan,rand2(1.0),
                                       \done,2,
                                       \t_gate,1
                                       ],~plyGrp);
                         dt.wait
	                     })
                }).reset.play
)

r.stop;

// -----------------------------> Enveloping

// Modificare l'inviluppo del suono riletto rispetto all'originale

// -----------------------------> Looping

// Necessario trigger interno...(Impulse.ar())

// Necessario il muting...

// Necessario fadein/fadeout del processo...

// Meglio oneshot rec...

~rec.free; // Spegne il rec loop

b.zero;    // Pulisce il buffer

Synth(\rec1, [\buf,b,\inBus,~recBus,\mix,0.5,\loop,0,\done,2], ~recGrp); // Oneshot rec...
                                                                         // con sovrascrittura...

(
SynthDef(\ply2, {arg buf=0,outBus=0,amp=0,trsp=0,dir=1,fIn=0.2,fOut=1,pan=0,gate=0,done=2,
                     pos=0,dur=0.2;
                 var durs,trig,sig,bpf,env,fade,pann;
                     durs  = dur * trsp.midiratio;          // Durata
                     trig  = Impulse.ar(durs.reciprocal);
                     sig   = PlayBuf.ar(1, buf,
                                        BufRateScale.kr(buf)*trsp.midiratio*dir,
                                        DelayN.ar(trig,0.01,0.01),     // Delay per muting...
                                        BufSampleRate.kr(buf)*pos);    // Posizione
                      bpf  = Env.new([1,0,1,1],[0.01,0.01,durs-0.02]); // Inviluppo per muting...
                      env  = EnvGen.ar(bpf,trig);                      // Windowing
                      fade = Linen.kr(gate,fIn,amp,fOut,done);         // Fade in/out processo
                      pann = Pan2.ar(sig*env*fade,pan);
                 Out.ar(outBus,pann)
                }).add;
)

a = Synth(\ply2, [\buf,b,\outBus,0,\amp,1,\gate,1],~plyGrp);
a.set(\trsp,rand2(3),\dur,rrand(0.2,0.5),\pos,rand(2.5),\dir,[-1,1].choose)
a.set(\trsp,0,\dur,rrand(0.1,1),\pos,rand(b.duration-2));
a.set(\gate,0);

(
d = 3.collect({ Synth(\ply2, [\buf,b,\outBus,0,\amp,1/4,\trsp,rand2(3),\dur,rrand(0.2,0.5),\pos,rand(2.5),\dir,[-1,1].choose,\gate,1],~plyGrp)});
)

d.do({arg i,id; d[id].set(\pos,rand(2.5),\dur,rrand(0.4,0.4))});

d.do({arg i,id; d[id].set(\gate,0)});

// -----------------------------> BufRd

// Utilizza un segnale puntatore per navigare nel Buffer...

~rec = Synth(\rec1, [\buf,b,\inBus,~recBus,\mix,0,\loop,1,\done,0], ~recGrp); // loop rec...

// Mouse...

(
SynthDef(\ply3, {arg buf=0, outBus=0,amp=0,smooth=0.2,fIn=0.2,fOut=0.2,pan=0,gate=0,done=2;
                 var punta,sig,fade,pann;
                     punta = MouseX.kr(0,BufFrames.kr(buf),0,smooth); // Puntatore
                     sig   = BufRd.ar(1, buf, K2A.ar(punta));
                     fade  = Linen.kr(gate,fIn,1,fOut,done);
                     pann  = Pan2.ar(sig*amp.lag(0.2)*fade,pan);
                 Out.ar(outBus, pann)
        }).add;
)

a = Synth(\ply3, [\buf,c,\outBus,0,\amp,1,\pan,0],~plyGrp);
a.set(\gate,1);
a.set(\smooth,2);
a.set(\smooth,0.02);
a.set(\smooth,rrand(0.1,2).postln);
a.set(\gate,0);

// Segnali di controllo...

~rec.free;  // Funziona meglio con oneshot...

(
SynthDef(\ply4, {arg buf=0, outBus=0,amp=0,ksig=0,frq=0.1,fIn=0.2,fOut=0.2,pan=0,gate=0,done=2;
                 var punta,sig,fade,pann;
                     punta = Select.ar(ksig,                              // Puntatore
                                          [LFNoise1.ar(frq).range(0,BufFrames.kr(buf)-1), // 0
                                           LFNoise2.ar(frq).range(0,BufFrames.kr(buf)-1), // 1
                                           LFTri.ar(frq).range(0,BufFrames.kr(buf)-1),    // 2
                                           LFCub.ar(frq).range(0,BufFrames.kr(buf)-1)     // 3
                                          ]);
                        sig   = BufRd.ar(1, buf, punta);
                        fade  = Linen.kr(gate,fIn,1,fOut,done);
                        pann  = Pan2.ar(sig*amp.lag(0.2)*fade,pan);
                    Out.ar(outBus, pann);
        }).add;
)

Synth(\rec1, [\buf,b,\inBus,~recBus,\mix,0,\loop,0,\done,2], ~recGrp); // Oneshot rec...

a = Synth(\ply4, [\buf,b,\outBus,0,\amp,1,\pan,0],~plyGrp);

a.set(\gate,1);
a.set(\ksig,rand(4).postln);
a.set(\ksig,1);
a.set(\frq,1/b.duration/2);
a.set(\frq,0.2);
a.set(\gate,0);

