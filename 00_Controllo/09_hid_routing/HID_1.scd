// -------------------------------
// Mouse down action

(
w = Window.new("mouse",400@400);
w.view.mouseDownAction_({arg ...args;
                                args.postln;    // tutte le info
	// view, x, y, modifier, num (0,1,2),num clicks
                       });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free});
)

// Esempio

(1==1)&&(1==1) // Logical and     ||
(1==1).and(1==1)

(1==1)||(1==1) // Logical or
(1==1).or(1==1)

(
s.boot;
s.scope(1);
s.plotTree;
)

(
w = Window.new("mouse");
w.view.mouseDownAction_({arg ...args;
                         if(args[4] == 0,
                         {Synth(\sine,[\freq, args[1].linlin(0,400,300,2000),
				                                   \amp,args[2].linlin(0,400,1,0),
				                                   \t_gate, 1])});

	                        if( (args[4] == 1)&&(args[5] == 1),

	                            {a.set(\amp, args[2].linlin(0,400,1,0),\gate,1)},
		                           {a.set(\gate,0)});
                        });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;s.freeAll});

SynthDef(\sine , {arg freq=0, amp=0, t_gate=0;
	                 var sig,env;
	                     sig = SinOsc.ar(freq);
	                     env = EnvGen.kr(Env.perc,t_gate,doneAction:2);
	                 Out.ar(0,sig*env*amp);
                  }).add;
SynthDef(\noise , {arg amp=0,gate=0;
	                  var sig,env;
	                      sig = PinkNoise.ar;
		                     env = EnvGen.kr(Env.asr,gate);
	                 Out.ar(0,sig*env*amp.lag(3));
                  }).add;
{a = Synth(\noise)}.defer(0.2);
)

// -------------------------------
// Mouse up action

(
w = Window.new("mouse");
w.view.mouseDownAction_({arg ...args;
                         if(args[4] == 0,
                         {Synth(\sine,[\freq, args[1].linlin(0,400,300,2000),
				                                   \amp,  args[2].linlin(0,400,1,0),
				                                   \t_gate, 1])},
		         {a.set(\amp, args[2].linlin(0,400,0,1.0))}) // note On (proporzioni invertite)
                         });

w.view.mouseUpAction_({arg ...args;
	                      if(args[4] == 1,
		                     {a.set(\amp,0)}) // note Off
                      });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;s.freeAll});

SynthDef(\sine , {arg freq=0, amp=0, t_gate=0;
	          var sig,env;
	              sig = SinOsc.ar(freq);
	              env = EnvGen.kr(Env.perc,t_gate,doneAction:2);
	          Out.ar(0,sig*env*amp);
                  }).add;
SynthDef(\noise , {arg amp=0;
	               var sig;
	                   sig = PinkNoise.ar;
	               Out.ar(0,sig*amp.lag(0.2)); // fade di 0.2 secondi
                  }).add;
{a = Synth(\noise)}.defer(0.2);
)

// -------------------------------
// Mouse move action

(
w = Window.new("mouse");
w.view.mouseMoveAction_({arg ...args;
                                args.postln;    // tutte le info
			        args[1].postln; // solo posizione x
                       });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free});
)

// Esempio

(
w = Window.new("mouse");
w.view.mouseDownAction_({arg ...args;                  // note On (trigger)
                         a = Synth(\spectra, [\freq, args[1].linlin(0,400,300,2000),
		                           \gate, 1]);
                         });
w.view.mouseMoveAction_({arg ...args;                 // controllo continuo
	                        a.set(\amp,args[2].linlin(0,400,1,0),
		                             \harm, args[1].linlin(0,400,1,20))
                       });
w.view.mouseUpAction_({arg ...args;
                       a.set(\gate,0)                  // note Off (trigger)
                      });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;s.freeAll});

SynthDef(\spectra, {arg freq=0, amp=0, harm=1, gate=0;
	             var sig,env;
	                sig = Blip.ar(freq,harm);
	                 env = EnvGen.kr(Env.asr(0.3,1,5),gate,doneAction:2);
	             Out.ar(0,sig*env*amp);
                   }).add;
)

// -------------------------------
// Mouse over action

(
w = Window.new("mouse").acceptsMouseOver_(true);// bisogna specificare;
w.view.mouseOverAction_({arg ...args;
                                args.postln;    // tutte le info
			        args[1].postln; // solo posizione x
                       });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free});
)

(
w = Window.new("mouse").acceptsMouseOver_(true);
w.view.mouseOverAction_({arg ...args;
	                     a.set(\pos, args[1].linlin(0,400,0,1),    // posizione x
		                   \amp,1-args[2].linlin(0,400,0,1.0)) // posizione y
                       });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;a.free;b.free});

b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");

SynthDef(\scratch, {arg pos=0, amp=0, buf=0, smooth=0.2;
	            var sig,punt;
	                punt = BufFrames.ir(buf)*K2A.ar(pos).varlag(smooth);
	                sig = BufRd.ar(1,b,punt);
	            Out.ar(0,sig*amp.lag(0.2))
        }).add;

{a = Synth(\scratch, [\buf,b])}.defer(0.2);
)

// Server side

//          min max  warp lag time
{[MouseX.kr(0,   1,  0,      0.2), MouseX.kr(0.0001,1,1,0.2)]}.scope; // lineare vs esponenziale
{[MouseX.kr(0,1,0,0.2),            MouseX.kr(0.0001,1,0,8)]}.scope;   // lag time di 5 secondi...



(

a = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
SynthDef(\scratch,
	              {arg gate = 1, buffer;
	               var buf, speed, env;
	                   env   = Env.new([0,1,0], [0.1, 0.1], \sin, 1).kr(20,gate);
	                   speed = MouseX.kr(-10, 10);
	                   speed = speed - DelayN.kr(speed, 0.1, 0.1);
	                   speed = MouseButton.kr(1, 0, 0.3) + speed ;
	                   buf = PlayBuf.ar(1, buffer, speed * BufRateScale.kr(buffer), loop: 1);
	               Out.ar(0, (buf * env).dup );
}).add;

{b = Synth(\scratch, [\buffer, a])}.defer(0.3);
)

b.set(\gate, 0); a.free; b.free;

// -------------------------------
// -------------------------------
// KeyDownAction

(
w = Window.new("key");
w.view.keyDownAction_({arg ...args;
	                      args.postln;
	                      args[1].postln
                       });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free})
)

// Esempio selettore singolo

(
w = Window.new("key");
w.view.keyDownAction_({arg ...args;

	                if(args[1]==$q,              // uguale a...
		                {a.set(\t_gate,1)},  // se schiaccio 'q' (char)
                        )
              });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;a.free});

SynthDef(\if_1, {arg t_gate=0;
	         var sig, env;
	             sig = Saw.ar;
	             env = EnvGen.ar(Env.perc,t_gate);
	         Out.ar(0,sig*env);
}).add;

{a = Synth(\if_1)}.defer(0.2);
)

// Esempio selettore doppio

(
w = Window.new("key");
w.view.keyDownAction_({arg ...args;

	                if(args[1] != $p,           // diverso da...
		                {a.set(\gate,0)}, // se schiaccio qualsiasi altro tasto
		                {a.set(\gate,1)}) // se schiaccio 'p' (char)
                       });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;a.free});

SynthDef(\if_2, {arg gate=0;
	         var sig, env;
	             sig = Pulse.ar;
	             env = EnvGen.ar(Env.adsr,gate);
	         Out.ar(0,sig*env);
}).add;

{a = Synth(\if_2)}.defer(0.2);
)

// Split

(
w = Window.new("key");
w.view.keyDownAction_({arg ...args;
args.postln;
	                if(args[3] < 53,               // minore di...
		                {a.set(\brr,1,\t_gate,1)}, // se valore unicode < 53 (tasto 5)
		                {a.set(\brr,2,\t_gate,1)}) // se valore unicode > 53 (tasto 5)
                       });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;a.free});

SynthDef(\if_3, {arg t_gate=0,brr=1;
	         var sig, env;
	             sig = Crackle.ar(brr);
	             env = EnvGen.ar(Env.sine,t_gate);
	         Out.ar(0,sig*env);
}).add;

{a = Synth(\if_3)}.defer(0.2);
)

// Switch

// --------- switch(valore da comparare,
//                  valore_selettore, {func},
//                  valore_selettore, {func},
//                  valore_selettore, {func},
//                  ...,              {...});

(
w = Window.new("key");
w.view.keyDownAction_({arg ...args;
	               switch(args[1],
		                    $q, {b.play;        "SoundFile".postln},
		                    $w, {Synth(\noise); "Noise".postln},
		                    $e, {Synth(\blip);  "Blip".postln});
                       });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free});

b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
SynthDef(\noise, {Out.ar(0,ClipNoise.ar*EnvGen.ar(Env.perc,doneAction:2))}).add;
SynthDef(\blip, {Out.ar(0,Blip.ar*EnvGen.ar(Env.triangle,doneAction:2))}).add;
)

// KeyUpAction

(
w = Window.new("key");
w.view.keyUpAction_({arg ...args;
	                      args.postln;
	                      args[1].postln
                       });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free})
)


// FILTRO DATI 1

(
w = Window.new("key");

w.view.keyDownAction_({arg ...args;
	                   if(args[1]==$q, {a.set(\t_gate,1)}); // 'q' = Note On
                       });

w.view.keyUpAction_({arg ...args;
	                 if(args[1]==$q,{a.set(\t_gate,0)});    // Note Off
                     });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;a.free});

SynthDef(\if_1, {arg t_gate=0;
	         var sig, env;
	             sig = Saw.ar;
	             env = EnvGen.ar(Env.perc,t_gate);
	         Out.ar(0,sig*env);
}).add;

{a = Synth(\if_1)}.defer(0.2);
)

(
var ora, prec = 0;                           // inizializza la variabile

w = Window.new("key");
w.view.keyDownAction_({arg ...args;
                       ora = args[3];
		       if((ora != prec),     // se diverso dal precedente
		           {"noteOn".postln; // esegue
			    prec = ora });   // riassegna 'prec' all'ultimo
                       });                   // valore ricevuto

w.view.keyUpAction_({arg ...args;
                      prec = 0;         // reset Array (altrimenti se si rischiaccia
                                        // lo stesso tasto non funziona...)
                     "noteOff".postln;  // Azione
                     });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free})
)

// Esempio

(
~ora;
~prec = 0;

w = Window.new("key");

w.view.keyDownAction_({arg ...args;                        // 'q' = Note On
	               ~ora = args[1];
	               if(
		          (~ora == $q).and(~ora != ~prec), // se uguale a 'q' AND diverso dal precedente
		          {a.set(\gate,1);
			   ~prec = ~ora})
                       });

w.view.keyUpAction_({arg ...args;        // Note Off
	             if(~ora==$q,
		        {a.set(\gate,0);
			 ~prec = 0});    // Reset
                     });
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;a.free});

SynthDef(\if_1, {arg gate=0;
	         var sig, env;
	             sig = Saw.ar;
	             env = EnvGen.ar(Env.adsr,gate);
	         Out.ar(0,sig*env);
}).add;

{a = Synth(\if_1)}.defer(0.2);
)

