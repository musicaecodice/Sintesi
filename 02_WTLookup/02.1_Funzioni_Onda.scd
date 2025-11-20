//=================================================================
// Possiamo definire il timbro di un suono disegnandone la forma
// d'onda calcolando ogni singolo valore di ampiezza istantanea
// attraverso una Funzione.

t = {arg a, b; a + b};
t.value(2,4);          // argomenti = INPUT risultato = OUTPUT

// ---------------> Funzione Sinusoide

// x[n] = a * sin(w * n + O)

// x   = OUTPUT
// [n] = INPUT

// Per ogni n in INPUT calcola un valore corrispondente in OUTPUT
// che corrisponde al valore di ampiezza istantanea:

t = {arg a,w,n; a * sin(w * 1 * n + 0)};

t.value(1, 0.01, 0);
t.value(1, 0.01, 1);
t.value(1, 0.01, 2);
t.value(1, 0.01, 3);
//...

// Automatizziamo il calcolo e collezioniamo i risultati in un Array

(
~punti  = 32;                 // Numero di punti (size della tavola)
~freq   = 1;                  // Numero di cicli per size della tavola
~amp    = 1.0;                // Ampiezza di picco
~w      = 2pi/(~punti/~freq); // Calcolo della velocità angolare (rad/sec)

p = ~punti.collect({arg n; ~amp * sin(~w * n + 2pi)}); // n assume ad ogni valutazione
                                                       // l'indice dell'Array
                                                       // partendo da 0
p.plot(discrete:true); // Visualizza
)

//=================================================================
// In SuperCollider possiamo generare forme d'onda in due modi:

// • Con la Classe Signal che genera un FloatArray (32 bit float)
//   e supporta operazioni matematiche Client side).

// • Invocando alcuni metodi d'istanza dedicati direttamente su di
//   un Buffer (Server side).

//=================================================================
// Signal

// Attraverso la classe Signal possiamo disegnare diverse forme
// d'onda utili in svariate tecniche di analisi, sintesi ed
// elaborazione del suono, al momento ne analizziamo solo due:

// ---------------> Genera una sinusoide o uno Spettro armonico:

~punti  = 32;
~amp    = [1.0];          // Array...
~amp    = [0.2,0.5,0.3];

//                 (Numero di punti, [Ampiezze di picco], [fasi])
p = Signal.sineFill(~punti,          ~amp,                 [2pi]);

p.plot(discrete:true);

// ---------------> I valori y sono calcolati attraverso una Funzione:

p = Signal.newClear(~punti);           // Crea un FloatArray di n 0

p.waveFill({arg i; i.postln}, -1, 1);  // i valori tra min e max

// ---------------> Funzione della sinusoide...

// sin(x) dove x è compresa tra 0 e 2pi (angolo giro)

(
p.waveFill({arg i;
	            sin(i)}, // operazioni matematiche (funzioni) su i
                0, 2pi); // min, max
)

p.plot(discrete:true);

// ----------------------------------------------------------------
// Da Signal a Buffer

// Per poter essere letti da un Oscillatore dobbiamo caricare i
// valori di generati in un Buffer (Signal genera un'Array che è
// Client side...)

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(1)
)

Buffer.freeAll;
b = Buffer.loadCollection(s, p);
b.plot;

// ----------------------------------------------------------------
// Wavetable format

// Possiamo trasformare un FloatArray (ma non un Array di altro tipo)
// in un formato ottimizzato per la rilettura da parte di Oscillatori
// tabellari che realizzano una Interpolazione lineare come Osc.ar()
// e che si chiama waveteble format.

// In questo formato il numero di campioni deve essere un multiplo di
// due.

p.postln;

w = p.asWavetable; // Trasforma il FloatArray in formato wavetable

w.plot;
// Se trasformato in wavetable format il numero di campioni è RADDOPPIATO:

p.size; // FloatArray
w.size; // Wavetable format (il doppio...)

// Per questo motivo dovremo utilizzare un Buffer size doppio

Buffer.freeAll;

b = Buffer.alloc(s, ~punti * 2);
b.loadCollection(w);
b.plot;
2pi
Buffer.freeAll;
b = Buffer.loadCollection(s, w); // Resize automatico...

// Possiamo salvare il Buffer come sound file:
b.write("/Users/andreavigani/Music/SuperCollider Recordings/suono_1.aiff");

//=================================================================
// Buffer
// (metodi .sine1 .sine2 e .sine3)

(
~punti = 1024;

Buffer.freeAll;

b = Buffer.alloc(s,~punti);

b.sine1([0.3,0.7,1.2], // Ampiezze dei parziali
	     true,         // Normalizza
	     true,         // asWavetable
	     true);        // Cancella prima
{b.plot}.defer(0.1)
)

x = {Osc.ar(b, 200, 0, 0.2)}.play;
x.free;

(
~punti = 1024;

Buffer.freeAll;
b = Buffer.alloc(s,~punti);
b.sine2([1,    2,  3], // Rapporti di frequenza dei parziali
	                   // (solo spettri armonici - numeri interi)
	    [0.3,0.7,1.2], // Ampiezze dei parziali
	     true,         // Normalizza
	     true,         // asWavetable
	     true);        // Cancella prima
{b.plot}.defer(0.1)
)

x = {Osc.ar(b, 200, 0, 0.2)}.play;
x.free;

(
~punti = 1024;

Buffer.freeAll;
b = Buffer.alloc(s,~punti);
b.sine3([1,    2,  3],  // Rapporti di frequenza dei parziali
	    [0.5,0.3,0.2],  // Ampiezze dei parziali
	    [2pi,pi,0.3pi], // Fasi dei parziali
        true,           // Normalizza
	    true,           // asWavetable
	    true);          // Cancella prima

{b.plot}.defer(0.1)
)

x = {Osc.ar(b, 200, 0, 0.2)}.play;
x.free;