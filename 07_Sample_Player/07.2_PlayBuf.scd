// ===========================================================
// PlayBuf

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

// Inviluppo trapezoidale per evitare clicks.

// Due possibili modi di indicare la posizione di partenza nel
// Buffer:

// ------------------------------ Valori assoluti

// In secondi da convertire in frames recuperando dinamicamente
// la rata di campionamento alla quale è stato registrato il
// soundfile caricato.

// b.sampleRate (Client side) vs BufSampleRate.kr (Server side)

// ------------------------------ Valori relativi (tra 0 e 1)

// Valori da convertire in frames recuperando dinamicamente
// il size del Buffer in frames.

// b.numFrames (Client side) vs BufFrames.kr (Server side)

(
Buffer.freeAll;
b = Buffer.read(s,"suoni/voce.wav".resolveRelative);

SynthDef(\samp1, {arg buf=0,pos=0,dur=0.2,amp=0,trsp=0,dir=1,
	                     pan=0,t_gate=0,done=2;
                  var sig,env;
                      sig = PlayBuf.ar(1, buf,
                                       BufRateScale.kr(buf) * trsp.midiratio // Trasposizione...
                                                            * dir,           // ...e direzione
                                       t_gate,                               // Trigger
		                              BufSampleRate.kr(buf)* pos);   // Posizione tra 0 e dur (sec)

	                                // BufFrames.kr(buf) * pos);   tra 0 e 1

                      env = Env.linen(0.01,dur-0.02,0.01);
                      env = EnvGen.kr(env,t_gate,doneAction:done);
                      sig = Pan2.ar(sig*env*amp,pan);
                  Out.ar(0,sig)
                 }).add;
)

// BufRateScale.kr --> fattore di riscalaggio dell'incremento
// del puntatore (o velocità di lettura...) nel caso in cui ci
// sia discrepanza tra rata di campionamento alla quale è stato
// registrato il Buffer e quella in uso dal Server.

(
Synth(\samp1,[\buf,b,     // oppure b.bufnum
	             \pos, 2.3,  // Secondi    0.34 (0/1)
              \dur, 0.2,
              \amp,1,
              \trsp, 0,
              \dir, 1,
              \pan, 0,
              \done,2,
              \t_gate,1
             ])
)
