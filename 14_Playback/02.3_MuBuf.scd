s.reboot;
s.meter;
s.plotTree;

// -------------------------> Multi Buffer
s.waitForBoot{
Buffer.freeAll;
b = Buffer.read(s,"/Users/andreavigani/Desktop/Milano_2022_23/Programmi/4_Sistemi_1/02_Playback/suoni/voce.wav");
b = Buffer.read(s,"suoni/voce.wav".resolveRelative);
b.plot;
b.play;

~paths = ("suoni".resolveRelative ++ "/*.wav").pathMatch;

~bufs  = ~paths.collect({arg i; Buffer.read(s, i)}); // Array di Buffers...
~bufs.size;

~bufs[3].plot(minval:-1,maxval:1);

~bufs.at(0).play;
~bufs.at(1).play;
~bufs.at(2).play;
~bufs.at(3).play;

~bufs.at(rand(~bufs.size-1)).play;

// ---------------------------------- Player

// Senza inviluppo...

(
SynthDef(\myPlay, {arg buf=0, amp=0, pan=0;
                   var sig;
                       sig = PlayBuf.ar(1, buf, doneAction:2);
	                      sig = Pan2.ar(sig, pan);
                   Out.ar(0, sig * amp)
         }).add;
)


// ---------------------------------- Oneshot

(
Synth(\myPlay, [\buf, rand(~bufs.size-1), \amp, 0.5, \pan, -1]);
Synth(\myPlay, [\buf, rand(~bufs.size-1), \amp, 0.5, \pan, 1]);
)

Synth(\myPlay, [\buf, rand(~bufs.size-1), \amp, rand(1.0), \pan, rand2(1.0)]);

// ------------------------------------- CUES

// Freccia su   --> Incrementa
// Freccia giù  --> Decrementa
// Barra spazio --> Avanza
// Enter        --> Init

(
~cue = 0;                                // INIT
w = Window.new("Num", Rect.new(0,0,300,300));
h = NumberBox.new(w, Rect(5,5,290,290)).align_(\center).font_(Font("Helvetica", 200));
h.step_(1);                             // Valore incremento
h.action_({arg val;
	          ~cue = val.value.asInteger - 1}); // Recupera il valore quando si
                                             // naviga con le frecce che sarà
                                             // triggerato con barra spazio

// ---------------------------------> cuesK

w.view.keyDownAction_({arg ...args; // Ogni tasto premuto valuta la funzione
args.postln;

	                   if(args[3]==32,                         // Se Barra spazio...(unicode)
		                         {~cue = (~cue % ~bufs.size) + 1; // Incrementa
			                       h.value_(~cue) });                // Invia alla GUI

	                   if(args[3]==13,                 // Se Enter...INIT
		                           {~cue = 0;
		                            h.value_(~cue) });

		               switch(~cue,                   // Selettore dei cues
				              0, {~init.value},
		                1, {~cue1.value},
		                2, {~cue2.value},
				              3, {~cue3.value},
				              4, {~cue4.value},
				              5, {~cue5.value},
				              6, {~cue6.value},
				              7, {~cue7.value},
						            8, {~cue8.value},
				              9, {~cue9.value}
	                          )
                       });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;h.free});

// ---------------------------------> Partitura

~init = {"INIZIALIZZAZIONE".postln; s.freeAll};

~cue1 = {Synth(\myPlay, [\buf, ~bufs[0], \amp, 0.5, \pan, rand2(1.0)])};
~cue2 = {Synth(\myPlay, [\buf, ~bufs[1], \amp, 0.5, \pan, rand2(1.0)])};
~cue3 = {Synth(\myPlay, [\buf, ~bufs[2], \amp, 0.5, \pan, rand2(1.0)])};
~cue4 = {Synth(\myPlay, [\buf, ~bufs[3], \amp, 0.5, \pan, rand2(1.0)])};
~cue5 = {Synth(\myPlay, [\buf, ~bufs[4], \amp, 0.5, \pan, rand2(1.0)])};
~cue6 = {Synth(\myPlay, [\buf, ~bufs[5], \amp, 0.5, \pan, rand2(1.0)])};
~cue7 = {Synth(\myPlay, [\buf, ~bufs[6], \amp, 0.5, \pan, rand2(1.0)])};
~cue8 = {Synth(\myPlay, [\buf, ~bufs[7], \amp, 0.5, \pan, rand2(1.0)])};
~cue9 = {Synth(\myPlay, [\buf, ~bufs[8], \amp, 0.5, \pan, rand2(1.0)])};
)


// ---------------------------------- MAPPING

// Mapping diretto Tasto --> Evento
//
// Modo elegante...

(
~key = [$q,$w,$e,$r,$t,$y,$u,$i,$o]; // Array di tasti

w = Window.new("Num", Rect.new(0,0,300,300));
w.view.keyDownAction_({arg ...args; // Ogni tasto premuto valuta la funzione

	 ~key.do({arg i,id;  if(args[1]==i,{~cues[id].value})}); // loop test
                       });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;h.free});

// ---------------------------------> Partitura
// Array di funzioni

~cues = ~bufs.collect({arg i; {Synth(\myPlay, [\buf, i, \amp, 0.1, \pan, rand2(1.0)])}  });
)


// ---------------------------- Cross Players

// Barra spazio --> Trigger
// Enter        --> Init

(
Buffer.freeAll;

~paths = ("suoni".resolveRelative ++ "/*.wav").pathMatch;
// ~paths = (Platform.userHomeDir ++ "/Desktop/Milano_2021_22/Corsi_21_22/Suoni_1/" ++ "/*.wav").pathMatch;
// Prova con fade di 0.2...
~bufs  = ~paths.collect{arg i; Buffer.read(s, i)}; // Array di Buffers...

SynthDef(\myPlayX, {arg buf=0, amp=0, gate=0, pan=0, fade=1;
                    var sig, fades;
                        sig   = PlayBuf.ar(1, buf, doneAction:2);
	                       fades = VarLag.kr(gate,fade);
	                       sig   = Pan2.ar(sig * fades, pan);
                    Out.ar(0, sig * amp)
         }).add;

w = Window.new("Num", Rect.new(0,0,300,300));
h = NumberBox.new(w, Rect(5,5,290,290)).align_(\center).font_(Font("Helvetica", 200););
h.step_(1);

~cue = -1;

w.view.keyDownAction_({arg ...args;

                       switch(args[3],
                              32, {~cue  = ~cue + 1 % ~bufs.size;  // barra spazio --> incrementa
                                   h.value_(~cue);                 // visualizza

                                   if(s.numSynths > 0, {a.set(\gate,0)});      // Fade out
                                   a = Synth(\myPlayX, [\fade,2, \amp,1, \buf, ~bufs[~cue], \gate,1])},

                              13, {~cue = -1;                  // Se Enter...INIT
                                   h.value_(0);
                                   if(s.numSynths > 0, {a.set(\gate,0)}); })
                       });

w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;h.free});
)
}