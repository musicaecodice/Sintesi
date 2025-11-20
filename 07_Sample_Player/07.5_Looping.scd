// ===========================================================
// Looping

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

// Tre principali differenze rispetto alle altre tecniche da
// tenere in considerazione nella programmazione:

// 1) Non singolo evento ma flusso sonoro di eventi.
// 2) Il trigger delle singole letture è caratteristica dello
//    strumento. Dovrebbe essere programmato nella SynthDef e
//    non un semplice controllo esterno inviato dall'Interprete.
//    Impulse.ar come segnale di controllo per i triggers.
// 3) Muting.
// 4) Fade in e fade out del flusso sonoro (secondo trigger)

//-----------------------------------------------------------------
// Synth 1

Env.new([1,0,1,1],[0.01,0.01,1-0.02]).plot  // Muting...

// Se manteniamo l'inviluppo trapezoidale ne momento in cui andiamo
// a cambiare alcuni parametri prima del fade out otteniamo un click.
// Per questo motivo dobbiamo adottare una tecnica di inviluppo
// chiamata Muting.

(
Buffer.freeAll;
b = Buffer.read(s,"suoni/bach.wav".resolveRelative);

SynthDef(\samp4, {arg buf=0,amp=0,trsp=0,dir=1,fIn=0.2,fOut=1,pan=0,gate=0,done=2,
                      pos=0,dur=0.2;
                  var durs,trig,sig,env,fade;
	                  durs  = dur * trsp.midiratio;          // Durata riscalata (sec)

// ------------------------------ Trigger interno
                      trig  = Impulse.ar(durs.reciprocal);   // Durata in secondi ---> Hz
// ------------------------------
                      sig   = PlayBuf.ar(1, buf,
                                         BufRateScale.kr(buf) * trsp.midiratio * dir,
                                         DelayN.ar(trig,0.01,0.01),    // Ritardo del trigger
                                         BufSampleRate.kr(buf) * pos); // Posizione

// ------------------------------ Inviluppo singole windows (muting)
                      env  = Env.new([1,0,1,1],[0.01,0.01,durs-0.02]);
                      env  = EnvGen.ar(env, trig);                     // Trigger non ritardato

// ------------------------------ Fade In/Out flusso sonoro
                      fade = Linen.kr(gate,fIn,amp,fOut,done);
                      sig  = Pan2.ar(sig * env * fade, pan);
                 Out.ar(0, sig)
                }).add;
)

//-----------------------------------------------------------------
// Gestione polifonia

// Essendo un flusso di eventi può essere solo monofonico
// Possiamo realizzare una polifonia non dinamica creando un istanza
// di Synth per ogni voce.

a = Synth(\samp4, [\buf,b,\amp,1,\gate,1]);

a.set(\trsp,rand2(3),\dur,rrand(0.2,1),\pos,rand(3.0),\dir,[-1,1].choose)

a.set(\trsp,0,\dur,rrand(0.1,1),\pos,rand(b.duration-2));

a.set(\gate,0);
a.release(6);    // uguale a gate 0 con tempo di fade dinamico


//-----------------------------------------------------------------
// Synth 2

// Se vogliamo inserire delle pause tra le ripetizioni...
// La pausa è specificata come fattore della durata tra 0 e 1.

(
SynthDef(\samp5, {arg buf=0,pos=0,dur=0.2,pausa=0,amp=0,
                      trsp=0,dir=1,fIn=0.2,fOut=1,pan=0,gate=0,done=2;
                  var durs,trig,sig,env,fade;
                      durs  = dur * trsp.midiratio;
                      trig  = Impulse.ar(durs.reciprocal);
                      sig   = PlayBuf.ar(1, buf,
                                         BufRateScale.kr(buf)*trsp.midiratio*dir,
                                         DelayN.ar(trig,0.01,0.01),
                                         BufSampleRate.kr(buf)*pos);

// ------------------------------ Muting con pause

                      env  = Env.new([1,0,0,1,1],
		                             [0.01,pausa*durs,0.01,durs-0.02-(pausa*durs)]);
// ------------------------------
                      env  = EnvGen.ar(env,trig);
                      fade = Linen.kr(gate,fIn,1,fOut,done);
                      sig  = Pan2.ar(sig*env*fade*amp.lag(0.2),pan);
                  Out.ar(0, sig)
                }).add;
)

a = Synth(\samp5, [\buf,b,\amp,1,\gate,1]);

a.set(\pausa,0.1);

a.set(\trsp,rand2(3),\dur,rrand(0.2,1),\pos,rand(3.0),\dir,[-1,1].choose)

a.set(\trsp,0,\dur,rrand(0.1,1),\pos,rand(b.duration-2));

a.release(6);

