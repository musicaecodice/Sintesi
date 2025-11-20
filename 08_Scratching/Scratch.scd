s.boot;
s.meter;
s.plotTree;

(
Buffer.freeAll;
b = Buffer.read(s,"suoni/bach.wav".resolveRelative);

SynthDef(\sctch_1, {arg buf=0,amp=0,start=0,end=0.2,trsp=0,pan=0;
                    var dur,ini,fine,punta,sig,bpf,env,pann;
                        dur   = abs(start-end) * trsp.midiratio.reciprocal; // Durata in secondi
                        ini   = SampleRate.ir*start;                        // Inizio in frames
                        fine  = SampleRate.ir*end;                          // Fine in frames
                        punta = Line.ar(ini, fine, dur);
                        sig   = BufRd.ar(1, buf, punta);
                        bpf   = Env.linen(0.01,dur-0.02,0.01);
                        env   = EnvGen.kr(bpf,1,doneAction:2);
                        pann  = Pan2.ar(sig*env*amp.lag(0.2),pan);
                    Out.ar(0, pann)
        }).add;
)

Synth(\sctch_1, [\buf,b,\amp,1,\trsp,0,\pan,0]);
Synth(\sctch_1, [\buf,b,\amp,1,\trsp,4,\start,0,\end,b.duration]); // Intero Buffer
Synth(\sctch_1, [\buf,b,\amp,1,\trsp,rand2(4),\start,rand(b.duration),\end,rand(b.duration)]);


(
Buffer.freeAll;
b = Buffer.read(s,"suoni/voce.wav".resolveRelative);

SynthDef(\sctch_2, {arg buf=0, amp=0,start=0,end=0.2,trsp=0,fIn=0.2,fOut=1,pan=0,gate=0,done=2;
                    var dur,ini,fine,trig,punta,sig,bpf,env,fade,pann;
                        dur   = abs(start-end) * trsp.midiratio.reciprocal;
                        ini   = SampleRate.ir*start;
                        fine  = SampleRate.ir*end;
                        trig  = Impulse.ar(dur.reciprocal);
                        punta = Phasor.ar(DelayN.ar(trig,0.01,0.01),           // ritardo per Muting
                                          BufRateScale.ir(buf)*trsp.midiratio, // Incremento
                                          ini,fine,
                                          ini);                                // Punto di reset
                        sig   = BufRd.ar(1, buf, punta);
                        bpf   = Env.new([1,0,1,1],[0.01,0.01,dur-0.02]);       // Muting
                        env   = EnvGen.ar(bpf,trig);
                        fade  = Linen.kr(gate,fIn,1,fOut,done);
                        pann  = Pan2.ar(sig*env*amp.lag(0.2)*fade,pan);
                    Out.ar(0, pann)
        }).add;
)

a = Synth(\sctch_2, [\buf,b,\amp,1,\trsp,0,\pan,0]);
a.set(\gate,1);
a.set(\start,1.3,\end,2);
a.set(\start,rand(2.0),\end,rrand(1.5,4.1));
a.set(\trsp,0);
a.set(\start,0,\end,b.duration);              // Intero buffer
a.set(\gate,0);

(
Buffer.freeAll;
b = Buffer.read(s,"suoni/voce.wav".resolveRelative);

SynthDef(\sctch_3, {arg buf=0, amp=0,smooth=0.2,fIn=0.2,fOut=0.2,pan=0,gate=0,done=2;
                    var punta,sig,fade,pann;
                        punta = MouseX.kr(0,BufFrames.kr(buf),0,smooth); // Puntatore
                        sig   = BufRd.ar(1, buf, K2A.ar(punta));
                        fade  = Linen.kr(gate,fIn,1,fOut,done);
                        pann  = Pan2.ar(sig*amp.lag(0.2)*fade,pan);
                    Out.ar(0, pann)
        }).add;
)

a = Synth(\sctch_3, [\buf,b,\amp,1,\pan,0]);
a.set(\gate,1);
a.set(\smooth,2);
a.set(\smooth,0.02);
a.set(\smooth,rrand(0.1,2).postln);
a.set(\gate,0);

(
Buffer.freeAll;

~path = "suoni/bach.wav".resolveRelative;

b = Buffer.read(s,~path);
f = SoundFile.openRead(~path);  // Crea un'istanza di Soundfile

SynthDef(\sctch_4, {arg buf=0, amp=0,pos=0,smooth=0.2,fIn=0.2,fOut=0.2,pan=0,gate=0,done=2;
                    var punta,sig,fade,pann;
                        punta = SampleRate.ir * pos.varlag(smooth); // Puntatore
                        sig   = BufRd.ar(1, buf, K2A.ar(punta));
                        fade  = Linen.kr(gate,fIn,1,fOut,done);
                        pann  = Pan2.ar(sig*amp.lag(0.2)*fade,pan);
                    Out.ar(0, pann)
        }).add;

//---------------------------------------------------------------
// Synth

{a = Synth(\sctch_4, [\buf,b,\amp,1,\pan,0])}.defer(0.5);

//---------------------------------------------------------------
// GUI

w = Window.new("SoundFileView", Rect.new(0,0,550,210));
w.acceptsMouseOver_(true);
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;a.free});

t = SoundFileView.new(w, Rect(5,5, 540, 200));
t.soundfile_(f);
t.read(0, f.numFrames); // N.B. Per file molto lunghi è meglio usare: t.readWithTask;
t.timeCursorOn_(true);
t.timeCursorColor_(Color.red);
t.gridOn_(false);
t.refresh;

//---------------------------------------------------------------
// Azioni

t.mouseOverAction_({arg ...args;
                    a.set(\pos,args[1].linlin(0,536,0,b.duration));
                    });
)

a.set(\gate,1);
a.set(\smooth,1);
a.set(\smooth,0.02);
a.set(\smooth,0.5);
a.set(\gate,0);

(
Buffer.freeAll;

~path = "suoni/bach.wav".resolveRelative;
b = Buffer.read(s,~path);
f = SoundFile.openRead(~path);  // Crea un'istanza di Soundfile

SynthDef(\sctch_5, {arg buf=0, amp=0,ksig=0,frq=0.1,fIn=0.2,fOut=0.2,pan=0,gate=0,done=2;
                    var punta,sig,fade,pann;
                        punta = Select.ar(ksig,                              // Puntatore
                                          [LFNoise1.ar(frq).range(0,BufFrames.kr(buf)), // 0
                                           LFNoise2.ar(frq).range(0,BufFrames.kr(buf)), // 1
                                           LFTri.ar(frq).range(0,BufFrames.kr(buf)),    // 2
                                           LFCub.ar(frq).range(0,BufFrames.kr(buf))     // 3
                                          ]);
                        sig   = BufRd.ar(1, buf, K2A.ar(punta));
                        fade  = Linen.kr(gate,fIn,1,fOut,done);
                        pann  = Pan2.ar(sig*amp.lag(0.2)*fade,pan);
                    Out.ar(0, pann);

// ------------------------------ Server --> Interprete x visualizzazione

		SendReply.kr(Impulse.kr(50),  // rata di campionamento
		             '/posa',         // indirizzo o nome
		             punta);          // segnale da campionare
        }).add;

//---------------------------------------------------------------
// Synth

{a = Synth(\sctch_5, [\buf,b,\amp,1,\pan,0])}.defer(0.5);

//---------------------------------------------------------------
// Visualizzazione su GUI

w = Window.new("SoundFileView", Rect.new(0,0,550,210));
w.acceptsMouseOver_(true);
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;a.free});

t = SoundFileView.new(w, Rect(5,5, 540, 200));
t.soundfile_(f);
t.read(0, f.numFrames); // N.B. Per file molto lunghi è meglio usare: t.readWithTask;
t.timeCursorOn_(true);
t.timeCursorColor_(Color.red);
t.gridOn_(false);
t.refresh;

//OSCdef.freeAll;
o = OSCdef.new(\pos, {arg pos; {t.timeCursorPosition_(pos[3])}.defer(0)},'/posa')
)

a.set(\gate,1);
a.set(\ksig,rand(4).postln);
a.set(\frq,1);
a.set(\gate,0);

