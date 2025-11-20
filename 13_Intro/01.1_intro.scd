s = Server.local;
s.boot;
s.scope;
s.plotTree;

//====================================
// Il computer come strumento musicale
//====================================

"open http://www.musicaecodice.it/Strumento/Strumento.php".unixCmd;

//====================================
// Catene elettroacustiche
//====================================

"open http://www.musicaecodice.it/Catene/Catene.php".unixCmd;

// 1) -------------------------> Sintesi in tempo reale:

play{0.1*GVerb.ar(SinOsc.ar(Select.kr(Hasher.kr(Duty.kr((1..4)/4,0,Dwhite(0,1)))*5,midicps([0,3,5,7,10]+60))).sum,200,3)/20};

// 2) -------------------------> Sintesi in tempo differito:

// Crea un sound file
s.prepareForRecord(Platform.userHomeDir ++ "/Desktop/Milano_2021_22/0Corsi_21_22/4_Sistemi_1/01_Intro/rec_1.aiff",1);

// Comincia la sintesi
(
play{t=Impulse.ar(6)+Dust.ar(1);x=(TExpRand.ar(_,_,t));Limiter.ar(GVerb.ar(GrainFM.ar(2,t,x.(1e-4,0.01),f=x.(80,400),f/4,9),9,0.5))};
)

s.record(duration:10); // Registra 10 secondi

Buffer.freeAll;
b = Buffer.read(s, "rec_1.aiff".resolveRelative); // carica il sound file in un Buffer
b.plot;                                           // visualizza
b.play;                                           // suona

// Ora possiamo editare il suond file in un audio sequencer...

// 3) -------------------------> Elaborazione in tempo differito:

(
Buffer.freeAll;
b = Buffer.read(s, "rec_1.aiff".resolveRelative); // carica il sound file in un Buffer

SynthDef(\grain_1, {arg bufn=0, trsp=1, amp=1, pos=0,punta=0,dur=0.2;
	                 var sig, bpf, env,pan;
	                     sig = PlayBuf.ar(1,bufn,
		                                  BufRateScale.kr(bufn) * trsp,
		                                  1,
		                                  punta  * BufFrames.kr(bufn));

	                     bpf = Env.triangle(dur);                // anche per Triangle
	                     env = EnvGen.kr(bpf,1,doneAction:2);
	                     pan = Pan2.ar(sig*env,pos);
	                Out.ar(0,pan)
}).add;

Routine.new({inf.do({
		Synth(\grain_1, [\bufn,b,\trsp,rrand(-12,12.0),\amp,rand(1.0),\pos,rand(1.0),\punta,rand(1.0),\dur,0.2]);
		rrand(0.1,0.5).wait;
	})}).play;
)

// Registra l'elaborazione...

s.prepareForRecord(Platform.userHomeDir ++ "/Desktop/Master_2021/4_Live_electr/rec_2.aiff",2);
s.record(duration:10);
b.plot;
b.play;

// Ora possiamo editare il suond file in un audio sequencer...

// 4) -------------------------> Elaborazione di un buffer in tempo reale (mouse):

(
Buffer.freeAll;
b = Buffer.read(s, "rec_1.aiff".resolveRelative); // load the sound file into one Buffer

SynthDef(\sctch_3, {arg buf=0, amp=0,smooth=0.2,fIn=0.2,fOut=0.2,pan=0,gate=0,done=2;
                    var punta,sig,fade,pann;
                        punta = MouseX.kr(0,BufFrames.kr(buf),0,smooth); // Puntatore
                        sig   = BufRd.ar(1, buf, K2A.ar(punta));
                        fade  = Linen.kr(gate,fIn,1,fOut,done);
                        pann  = Pan2.ar(sig*amp.lag(0.2)*fade,pan);
                    Out.ar(0, pann)
        }).add;

a = Synth(\sctch_3, [\buf,b,\amp,1,\pan,0,\gate,1]);
)

a.set(\gate,0);

// 5) -------------------------> Elaborazione del segnale in ingresso in tempo reale (Live Electronics):

// Elabora il sengale in ingresso...

{FreqShift.ar(LPF.ar(SoundIn.ar,8000,0.1),LFNoise0.kr(30,1000))}.play;

// Il segnale in ingresso elabora un altro segnale...
// (feature extraction)

(
SynthDef(\ampfollow_2, {arg attack=0.1, decay=1;
	                    var in, amp, src;
	                        in = Mix.new(SoundIn.ar([0,1]));
	                        amp = Amplitude.ar(in, attack, decay);
	                        src = Blip.ar(500,amp.linlin(0.0,1.0,0,100));
	                    Out.ar(0, src * amp);
                        }).add;
)

a = Synth(\ampfollow_2);

//================================
// Tipi di Live Electronics:
//================================

"open http://www.musicaecodice.it/Live_electronics/Live_electronics.php".unixCmd;