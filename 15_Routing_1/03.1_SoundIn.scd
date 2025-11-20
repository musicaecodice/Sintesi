s = Server.local;
s.boot;
s.quit;
ServerOptions.device;
s.options.inDevice_("Microfono MacBook Air"); // Device in ingresso
s.options.outDevice_("Scarlett 18i20 USB");   // Device in uscita
s.options.numInputBusChannels_(1);            // numero canali in ingresso
s.options.numOutputBusChannels_(4);           // Numero canali in uscita

s.reboot;

(
s.meter;
s.scope;
s.plotTree;
)

s.reboot;

// -------------------------> In.ar() / Out.ar()

(
// Generatore (solo Out mono)

SynthDef(\source_1, {arg outBus=0, den=2,dur=0.8;
	                    var trig,sig,env;
	                        trig = Dust.ar(den);
	                        sig  = Saw.ar(TRand.ar(70,82,trig).midicps);
	                        env  = Decay2.ar(trig,0.02,dur-0.02);
                     Out.ar(outBus,sig*env); // Out.ar(bus, sig)
        }).add;

// Modificatore (In + Out mono)

SynthDef(\fx_1, {arg inBus=0, outBus=0;
	                var sig,rev;
	                    sig = In.ar(inBus, 1);  // In.ar(bus, n_channels)
	                    rev = FreeVerb.ar(sig,0.5,0.8,0.7);
	                Out.ar(outBus,rev)
        }).add;
)


b = Synth(\source_1, [\outBus,  0]);

b.set(\outBus, 1); // Se cambiamo bus mentre viene scritto --> click!!
b.set(\outBus, 0);

b.free;

// ------------------------->  Bus Pubblici vs Privati

s.options.numInputBusChannels;    // ? numero canali in ingresso
s.options.numOutputBusChannels;   // ? Numero canali in uscita

// numOutputBusChannels + numInputBusChannels = Bus pubblici (partendo da 0)

s.options.firstPrivateBus; // Riporta indice primo Bus privato...

// NON UTILIZZARE BUS PUBBLICI PER ROUTING INTERNI!!

a = Synth(\fx_1, [\inBus,5, \outBus, 1]); // legge dal primo bus privato
                                          // Manda il segnale all'hardware
                                          // scrivendo sul primo bus pubblico
b = Synth(\source_1, [\outBus,  5]);      // Scrive sul primo bus privato

b.set(\outBus,1); // Out diretto...
b.set(\outBus,5); // Manda al riverbero

b.free; // Distrugge la source ma il riverbero è ancora attivo...
a.free;

// ------------------------->  Bus.audio()

// La Classe Bus assegna solo i Bus 'privati'

// Meglio specificare come etichetta il nome dei modificatori (mandata fx)
// piuttosto che quello del segnale in Output...

~revBus = Bus.audio(s, 1); // Server, n_channels
~revBus.index;             // Riporta il numero di Bus privato sul Server...

a = Synth(\fx_1, [\inBus,~revBus, \outBus, 0]); // ~revBus.index è uguale...
b = Synth(\source_1, [\outBus,  ~revBus]);

a.free;b.free;

// Se leggiamo la post window dopo aver eseguito il codice possiamo recuperare le
// seguenti informazioni:
//
// • tipo di bus (se audio o di controllo)
// • numero del bus (assegnato automaticamente)
// • numero di canali
// • Server sul quale è stato creato.

~revBus.index;       // Riporta il numero di bus (nel caso di un bus multicanale il primo...)
~revBus.numChannels; // Riporta il numero di canali
~revBus.rate;        // Riporta se ar o kr
~revBus.free;        // Cancella l'assegnazione alla variabile


// -------------------------> Stereo

// Generatore STEREO + Riverbero Stereo
// Dobbiamo sempre specificare il numero di canali IN e OUT...!

(
SynthDef(\source_2, {arg outBus=0, den=2,dur=0.8;
	                    var trig,sig,env,pan;
	                        trig = Dust.ar(den);
	                        sig  = Saw.ar(TRand.ar(70,82,trig).midicps);
	                        env  = Decay2.ar(trig,0.02,dur-0.02);
	                        pan  = Pan2.ar(sig*env,LFNoise1.ar(10)); // Pan random
	                    Out.ar(outBus,pan)
        }).add;

SynthDef(\fx_2, {arg inBus=0, outBus=0;
	                var sig,rev;
	                    sig = In.ar(inBus, 2);  // DUE CANALI
	                    rev = FreeVerb.ar(sig,0.5,0.8,0.7);
	               Out.ar(outBus,rev)
        }).add;
)

~revBus1 = Bus.audio(s, 2); // Bus 2 canali...
~revBus1.index;             // Bus 9 e 10...

a = Synth(\fx_2,     [\inBus,  ~revBus1, \outBus, 0]);
b = Synth(\source_2, [\outBus, ~revBus1]);

b.set(\outBus,0);         // Out diretto...
b.set(\outBus, ~revBus1); // Manda al riverbero

s.freeAll; // Distrugge tutti i Nodi...


// -------------------------> Ordine di creazione


// I Synth che ricevono in input un segnale DEVONO essere creati PRIMA
// di quelli che lo mandano...GURADARE PLOT TREE

// funziona...

a = Synth(\fx_2,     [\inBus,  ~revBus1, \outBus, 0]); // IN + OUT
b = Synth(\source_2, [\outBus, ~revBus1]);             // SOLO OUT

a.free;b.free;

// NON funziona...

b = Synth(\source_2, [\outBus, ~revBus1]);             // SOLO OUT
a = Synth(\fx_2,     [\inBus,  ~revBus1, \outBus, 0]); // IN + OUT

a.free;b.free;

// Perchè nel Server l'ordine di creazione è Head to Tail
// ---> L'ultimo Synth creato è messo in alto...

// Possiamo "forzare" la creazione sempre basso con argomenti:

b = Synth(\source_2, [\outBus, ~revBus1]);
a = Synth(\fx_2,     [\inBus,  ~revBus1, \outBus, 0],  s, 'addToTail');

a.free;b.free;

// Oppure subito dopo un'altro Synth:

b = Synth(\source_2, [\outBus, ~revBus1]);
a = Synth(\fx_2,     [\inBus,  ~revBus1, \outBus, 0],  b, 'addAfter'); // dopo 'b'

a.free;b.free;

// Oppure subito prima un'altro Synth:

a = Synth(\fx_2,     [\inBus,  ~revBus1, \outBus, 0])
b = Synth(\source_2, [\outBus, ~revBus1],  a, 'addBefore');       // prima di 'a';

a.free;b.free;

// -------------------------> Groups

// I Group sono contenitori di Nodi e Synth.
// Quando lanciamo SC c'è il default Group (guarda node tree...)

b = Synth(\source_2, [\outBus, 0]);
u = Group.new; // Crea un nuovo gruppo DENTRO il default group

b.free; // libera il Synth
u.free; // libera il Group

// Un tipico utilizzo dei Group:

// - 1 Group per le sources
// - 1 Group per gli effetti

~sources = Group.new;
~fx      = Group.after(~sources); // In basso...


// Assegnamo i diversi Synth a gruppi diversi


b = Synth(\source_2, [\outBus, ~revBus1],             ~sources);
a = Synth(\fx_2,     [\inBus,  ~revBus1, \outBus, 0], ~fx);

// In questo caso non ci dobbiamo preoccupare dell'ordine...

b.free;
a.free;

// Un altra caratteristica dei Group è che possiamo passare a tutti i
// Synth creati all'interno un unico argomento.

b = 4.do({Synth(\source_2, [\outBus, ~revBus1],  ~sources)}); // 4 istanze
a = Synth(\fx_2,     [\inBus,  ~revBus1, \outBus, 0], ~fx);

b[0].set(\dur,1);
~sources.set(\dur,0.1); // Passa l'argomento a tutte le istanze...
~sources.set(\den,0.5);
~sources.set(\den,6);
~sources.set(\outBus,~revBus1);

~sources.freeAll; // cancella i Synths nel Gruppo ma non il gruppo...

// Se invece desideriamo inviare un singolo valore a un preciso Synth:

// .collect() al posto di .do()

b = 4.collect({Synth(\source_2, [\outBus, ~revBus1],  ~sources)}); // 4 istanze
a = Synth(\fx_2,     [\inBus,  ~revBus1, \outBus, 0], ~fx);

b[0].set(\den,5,\amp,0.1); // Invia solo a un SYnth
b[1].free;                 // elimina solo un Synth

~sources.freeAll;


// -------------------------> SoundIn

(
SynthDef(\voce, {arg inBus=0, outBus=0, gain=0;
	                var sig;
	                    sig  = SoundIn.ar(inBus, gain.lag(0.02));
	                    sig  = LeakDC.ar(sig);   // Anti DC offset...
	                Out.ar(outBus, sig)
                 }).add
)

b = Synth(\voce, [\gain,0.5,\outBus, ~revBus1], ~sources);

s.freeAll;