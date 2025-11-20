MIDIClient.init;

MIDIIn.disconnectAll;
MIDIIn.connectAll;

MIDIFunc.trace(true);
MIDIFunc.trace(false); // Termina il monitoraggio

(
MIDIdef.noteOn( \noteOn, {arg ...args; args.postln}); // velocity, note,      canale, uid
MIDIdef.noteOff(\noteOff,{arg ...args; args.postln}); // velocity, note,      canale, uid
MIDIdef.cc(     \control,{arg ...args; args.postln}); // valore,   numero cc, canale, uid
)

// ------------------------------------------
// 1 strategia di routing
// una midi def per controller
(
MIDIdef.cc(\control1,{arg val; ~synt1.set(\amp,val)},70); // ccn
MIDIdef.cc(\control2,{arg val; ~synt1.set(\amp,val)},71);
MIDIdef.cc(\control3,{arg val; ~synt1.set(\amp,val)},72);
MIDIdef.cc(\control4,{arg val; ~synt1.set(\amp,val)},73);
MIDIdef.cc(\control5,{arg val; ~synt1.set(\amp,val)},74);
MIDIdef.cc(\control6,{arg val; ~synt1.set(\amp,val)},75);
MIDIdef.cc(\control5,{arg val; ~synt1.set(\amp,val)},76);
MIDIdef.cc(\control6,{arg val; ~synt1.set(\amp,val)},77);
)

// (+ elegante con i loop)

s.boot;
s.meter;
s.plotTree;
8.do({arg i; ("control"++i).postln  });

(
8.do({arg i;
	  MIDIdef.cc("control"++i,{arg val; ~synt1.set(\amp,val)},70+i);
      });
)

SynthDef.new(\sine, {arg amp=0; Out.ar(0,SinOsc.ar(Rand(600,1500)) * amp.lag(0.2))}).add;

a = Synth.new(\sine);

a.set(\amp, 0.3);

MIDIdef.cc(\control,{arg val; a.set(\amp,val/127)},70);

// Loop per i Synth

a = 8.collect({ Synth.new(\sine)  });
a[0].set(\amp, 0.3);
a[1].set(\amp, 0.1);

a.do({arg i;  i.free  }); // Distrugge tutti gli items

// Loop per i cc

(
8.do({arg i;
	  MIDIdef.cc("control"++i,{arg val; a[i].set(\amp,val/127)},70+i);
      });
)

// ------------------------------------------
// 2 strategia di routing
// 1 sola midi def per tipo di dato
(
a = 8.collect({ Synth.new(\sine)  });

MIDIdef.cc("control",{arg val, ccn;
	                  switch(ccn,
		                     70, {a[0].set(\amp,val/127)},
				             71, {a[1].set(\amp,val/127)},
				             72, {a[2].set(\amp,val/127)},
				             73, {a[3].set(\amp,val/127)},
				             74, {a[4].set(\amp,val/127)},
				             75, {a[5].set(\amp,val/127)},
				             76, {a[6].set(\amp,val/127)},
						     77, {a[7].set(\amp,val/127)}
	                         )
	                   });
)

// ------------------------------------------
// Inviluppi senza fase di sostegno

// Monofonico

SynthDef.new(\sine1, {arg freq=400, amp=0; Out.ar(0,SinOsc.ar(freq) * amp.lag(0.2))}).add;

a = Synth.new(\sine1);

(
MIDIdef.noteOn( \noteOn, {arg vel, note;
	                      a.set(\freq,note.midicps,
		                        \amp,vel/127)
                          }); // velocity,note,canale, uid
)

a.free;

(
SynthDef.new(\sine2, {arg freq=400, amp=0, dur=1,t_gate=0,done=0;
	                  var sig = SinOsc.ar(freq);
	                  var env = EnvGen.kr(Env.perc(0.1*dur,0.9*dur),t_gate,doneAction:done);
	           Out.ar(0,sig * env * amp)}).add;
)

a = Synth.new(\sine2);
a.set(\dur,2.2);

(
MIDIdef.noteOn(\noteOn1, {arg vel, note;
	                      a.set(\freq,note.midicps,
		                        \amp,vel/127,
		                        \t_gate,1)
                          }); // velocity,note,canale, uid
)
a.free;

// Polifonico

(
MIDIdef.noteOn(\noteOn3, {arg vel, note;
	                      Synth.new(\sine2, [
	                                         \freq,note.midicps,
		                                     \amp,vel/127,
		                                     \done,2,
		                                     \t_gate,1])
                          });
)

// ------------------------------------------
// Inviluppi con fase di sostegno


~notes = Array.newClear(128);   // Un Array vuoto di 128 items (tutte le note midi)

(
SynthDef(\envi,
              {arg freq=400, amp=0, gate=0,done=0;
               var sig,env;
                   sig = SinOsc.ar(freq);
		           env = EnvGen.kr(Env.asr(0.01,1,1),gate,doneAction:done);
               Out.ar(0,sig*env*amp)
               }
          ).add;
)

a = Synth.new(\envi);

a.set(\amp,0.5,\gate,1);
a.set(\gate,0)
a.free;

(
MIDIdef.noteOn(\on,                         // noteOn
                   {arg vel, pitch;
                    var item = ~notes.at(pitch);

		if(item.notNil, {item.set(\gate,0); ~notes.put(pitch, nil)});  // noteOff di sicurezza

                    item = Synth(\envi,[\freq,pitch.midicps,    // crea un Synth (noteOn)
                                        \amp,vel/127,
			                            \done,2,
			                            \gate,1]);

                    ~notes.put(pitch, item)}                     // lo mette nell'Array
               );

MIDIdef.noteOff(\off,                        // noteOff
	            {arg vel, pitch;
	             var item = ~notes.at(pitch);

	             if(item.notNil,{item.set(\gate,0); ~notes.put(pitch, nil)})
	             })
)













