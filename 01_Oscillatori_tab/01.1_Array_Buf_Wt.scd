//=================================================================
// Arrays, Buffers e Wavetables

// Tutte allocazioni di memoria

// ----------------------------------------------------------------
// Array (Client side)

//    0   1   2       Indici
a = [12, 23, 34];  // Items

a.plot; // Visualizza il contenuto (tasto 'm' cambia vista)

a = [\ciao, \miao, 34.5, SinOsc.ar]; // Qualsiasi tipo di data

// ----------------------------------------------------------------
// Buffer (Server side)

(
s.boot;
s.scope;
{s.plotTree}.defer(1)
)

// E' un 32-bit floating point Array multicanale.
// E' associata una rata di campionamento (che può essere diversa
// da quella del Server dove è riservato).

b = Buffer.alloc(s, 100, 1); // server, samples, n_chan

// Ad ogni Buffer viene assegnato un indice partendo da 0

b.free;         // Distrugge il Buffer
Buffer.freeAll; // Distrugge tutti i buffers sul Server

// Tre possibili utilizzi:

// ---------------> 1 Caricare soundfiles

b = Buffer.read(s, "voce.wav".resolveRelative);

b.play;  // Monitor uditivo
b.plot;  // Monitor visivo
b.free;

// ---------------> 2 Riservare uno spazio di memoria vuoto da
//                    riempire con segnali provenienti da una
//                    sorgente (microfoni o oscillatori)

c = Buffer.alloc(s, s.sampleRate * 2, 1); // 2 secondi...

SynthDef.new(\rec, {RecordBuf.ar(SoundIn.ar,c,loop:0,doneAction:2)}).play

c.play;  // Monitor uditivo
c.plot;  // Monitor visivo
c.free;

// ---------------> 3 Wavetable - Riservare uno spazio di memoria
//                    vuoto di dimensioni ridotte (512, 1024, 2048
//                    4096, 8192 samples) in cui disegnare un singolo
//                    ciclo di forma d'onda o altro tipo di data
//                    come ad esempio i risultati di un'analisi FFT,
//                    una tranfert functions, etc...

b = Buffer.alloc(s, 512, 1); // 512 campioni...
b.sine1([1,0.5,0.7,0.3],true,false);

SynthDef.new(\rec, {Out.ar(0,OscN.ar(b)*0.2)}).play;
b.plot;  // Monitor visivo
b.free;

//=================================================================
// Il size dei Buffer è in campioni e non da alcuna indicazione
// riguardo alla durata del Buffer se non viene messo in relazione
// con la rata di campionamento...
