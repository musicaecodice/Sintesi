MIDIClient.init;      // Inizializza il MIDI


MIDIClient.sources;      // riporta un Array con i devices da cui ricevere
MIDIClient.destinations; // riporta un Array con i devices a cui inviare

(
MIDIIn.disconnectAll; // disconnette tutti i devices MIDI eventualmente connessi
MIDIIn.connectAll; // connette tutti i devices MIDI
)


MIDIFunc.trace(true);  // Monitor dei messaggi in ingresso
MIDIFunc.trace(false); // Termina il monitoraggio

(
MIDIdef.noteOn( \noteOn, {arg ...args; args.postln}); // velocity, note,      canale, uid
MIDIdef.noteOff(\noteOff,{arg ...args; args.postln}); // velocity, note,      canale, uid
MIDIdef.cc(     \control,{arg ...args; args.postln}); // valore,   numero cc, canale, uid
MIDIdef.touch(  \touch, {arg ...args; args.postln});  // valore,              canale, uid
)

MIDIdef(\noteOn).free; // Cancella una specifica MIDIdef
MIDIdef.freeAll;       // Cancella tutte le MIDIdef



OSCFunc.trace(true);  // Monitor
OSCFunc.trace(false); // Termina il monitoraggio

//            nome,    funzione,            indirizzo  porta
OSCdef.new(\criccio, {arg msg; msg.postln}, '/amp',       recvPort:8000)



