// --------------------------------
// 1 riconoscimento devices collegati

MIDIClient.init;

(
MIDIIn.disconnectAll; // disconnette tutti i devices MIDI eventualmente connessi
MIDIIn.connectAll; // connette tutti i devices MIDI
)

// --------------------------------
// 2 monitoraggio messaggi in ingresso
//   esplorazione possibilità device

MIDIFunc.trace(true);  // comincia il monitoraggio
MIDIFunc.trace(false); // Termina il monitoraggio


// --------------------------------
// 3 recuperare i valori

(
MIDIdef.noteOn( \noteOn, {arg ...args; args.postln}); // velocity, note,      canale, uid
MIDIdef.noteOff(\noteOff,{arg ...args; args.postln}); // velocity, note,      canale, uid
MIDIdef.cc(     \control,{arg ...args; args.postln}); // valore,   numero cc, canale, uid
)

MIDIdef(\noteOn).free; // Cancella una specifica MIDIdef
MIDIdef.freeAll;       // Cancella tutte le MIDIdef

// --------------------------------
// Synth mono

(
s.reboot;
MIDIIn.disconnectAll;  // disconnette tutti i devices MIDI
MIDIIn.connectAll;     // connette tutti i devices MIDI
)

(
// ------------------------------ SynthDef e Synth (monofonico)

SynthDef(\midi,
              {arg freq=440, amp=0, smooth=0.02, gain=0;
               var sig;
                   sig = SinOsc.ar(freq)*amp.lag(smooth);
               Out.ar(0,sig*gain,lag(0.2))
               }
          ).add;

{~synth = Synth(\midi)}.defer(0.1);

// ------------------------------ Ascolta i devices esterni

MIDIdef.cc(\masterOut, {arg val;                  // solo primo argomento (valore del cc)
	                           val.postln;
                        ~synth.set(\gain,val/127) // master out tra 0 e 1
           });
MIDIdef.noteOn(\noteOn,{arg vel,note;
	                       vel.postln;
                        ~synth.set(\freq,note.midicps, // frequenze in Hz
                                   \amp,vel/127);      // ampiezza tra 0 e 1
           });
MIDIdef.noteOff(\noteOff,{~synth.set(\amp,0)});        // note off
)

~synth.set(\smooth,5); // cambia il tempo di fade in e fade out

// --------------------------

(
s.reboot;
MIDIIn.disconnectAll;  // disconnette tutti i devices MIDI
MIDIIn.connectAll;     // connette tutti i devices MIDI
)

(
SynthDef(\midi_poli,
                 {arg freq=440, amp=0, smooth=0.02,trig=0;
		  var sig,env;
		  sig = SinOsc.ar(freq)*amp.lag(smooth);
		  env = EnvGen.kr(Env.perc,trig,doneAction:2);
                  Out.ar(0,sig*env)
                  }
          ).add;

MIDIdef.noteOn(\noteOn1,{arg vel, note;
	                 Synth(\midi_poli,[\freq,note.midicps,\amp,vel/127,\trig,1])
               })
)
"ciao"++0
MIDIdef.cc(\control_0,{arg val; val.postln});    // da tutti i controller
MIDIdef.cc(\control_1,{arg val; val.postln},1);  // solo dal cc 1 chan 0
MIDIdef.cc(\control_2,{arg val; val.postln},2);  // solo dal cc 2 chan 0
MIDIdef.cc(\control_3,{arg val; val.postln},3);  // solo dal cc 3 chan 0

MIDIdef.cc(\control_1,{arg val; val.postln},1,0);  // solo dal cc 1 chan 0
MIDIdef.cc(\control_2,{arg val; val.postln},1,1);  // solo dal cc 1 chan 1
MIDIdef.cc(\control_3,{arg val; val.postln},1,2);  // solo dal cc 1 chan 2


10.collect({arg id; MIDIdef.cc("control"++id,{arg val; val.postln},id)});

[23,45,67].collect({arg id,i; MIDIdef.cc("control"++i,{arg val; val.postln},id)});


c = MIDIOut.new(0);
c.latency_(0);      // Set latency to 0 sec

//       canale, pitch,     velocity
c.noteOn(0,      80, rand(127));
c.noteOff(0,     80, 0);
c.allNotesOff(0);


//       canale, ccn,  val
c.control(0,     1,   rand(127));