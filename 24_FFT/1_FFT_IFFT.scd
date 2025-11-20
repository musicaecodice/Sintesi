(
s = Server.local;
s.options.memSize_(2.pow(20)); // per Delay...
s.boot;
s.freqscope;
{s.plotTree}.defer(3);
)

// -----------------------------> Intro

// Molte tecniche di elaborazione del suono producono effetti
// nel DOMINIO DEL TEMPO principalmente in due modi:

// • modificando le ampiezze istantanee di un segnale (tecniche di modulazione
//   waveshaping, etc.)
//
// • modificando la loro posizione nel continuum temporale (delay, filtri.etc.).

// La Fast Fourier Transform (FFT) invece è un algoritmo computazionale che
// permette di trasforamre il suono nel DOMINIO DELLE FREQUENZE.

// Processo:
//
// Segnale --> Analisi FFT --> Data --> (elaborazione) --> Risintesi IFFT --> Segnale
//          (tempo --> freq)                              (freq --> tempo)


// -----------------------------> STFT (Short-Time Fourier Transform)

// Windowing del segnale:

(
var sig, env, win;
    sig = 3072.collect({rand2(1.0)});
	   env = 1024.collect({0})++Signal.hanningWindow(1024)++1024.collect({0});
	   win = sig * env;
[sig,env,win].plot
)

// Due parametri:

// • Window Size (in genere 512, 1024 o 2048).
//
//   + grande = maggiore risoluzione nelle frequenze
//   - grande = maggiore risoluzione nel tempo

// • Tipo di inviluppo

(
[Signal.hanningWindow(2048),
 Signal.hammingWindow(2048),
 Signal.welchWindow(2048)].plot;
)

// N.B. Introduce distorsioni nell'analisi dello spettro (convoluzione tra il
//      segnale originale e quello dell'inviluppo e a seconda del tipo l'analisi
//      può cambiare.

// -----------------------------> DTFT (Discrete Fourier Transform)

// Dopo il windowing la STFT applica il DTFT (un particolare algoritmo che sviluppa
// un tipo di trasformata di Fourier) ad ogni finestra analizzando i valori delle
// ampiezze istantanee che dal dominio temporale sono 'trasformati' e portati nel
// dominio spettrale (frequenze, ampiezze e fasi) sotto forma di numeri complessi.

"open https://www.youmath.it/lezioni/analisi-matematica/numeri-complessi.html".unixCmd;
"open http://www.carminecella.com/teaching/PauraComplessa.pdf".unixCmd;

(
var size=8, harm;    // forma d'onda con 8 parziali
//----------------------------------------------------------------------
// Forma d'onda

~size = 2048;                                              // FFT window
~sig = Signal.sineFill(~size,
	                   [1, 0, 0.5,  0, 0.5, 0.25, 0, 0.1], // magnitude (amps)
	                   [0, 0, pi/2, 0,  pi,    0, 0,  pi]  // fasi
                       );

//----------------------------------------------------------------------
// DFFT

~imag     = Signal.newClear(~size);               // Parte immaginaria
~cosTable = Signal.fftCosTable(~size);            // Richiesto per calcolare la FFT
~complex  = fft(~sig,~imag,~cosTable);            // Sotto forma di numeri complessi

~magn = ~complex.magnitude.normalize * ~sig.peak; // reale       --> magnitude
~fasi = ~complex.phase + (pi/2) % 2pi;            // immaginaria --> fase

//----------------------------------------------------------------------
// Visualizzazione

[~sig,             // Segnale (dominio temporale)
 ~magn[1..size+1], // Ampiezze (doppio di Nyquist a specchio)
 ~fasi[1..size+1]  // Fasi (tra 0 e 2pi)
].plot.plotMode_(\bars);
)

// alt + click sulla barra possiamo vedere il valore nella post window...
// Notiamo le proporzioni tra il grafico, l'array delle magnitudini e
// le sinusoidi...

// -----------------------------> Teorema Fourier

// Teorema di Fourier: ogni spettro complesso può essere analizzato come una
// sovrapposizione di sinusoidi ognuna con una propria:

// • Frequenza (BIN in Hz)
// • Ampiezza  (MAGNITUDE in dB)
// • Fase      (PHASE iniziale in radianti)

(
var size=8, parz;

    parz = Array.fill(size, {arg i;      // Array di Signal (uno per parziale)
	                         var amps;
	                             amps = [1] ++ (0 ! (size-1)); // [1,0,0,0,0...]
                             Signal.sineFill(~size, amps.rotate(i), [~fasi[i+1]]) * ~magn[i+1]
                             });
parz.plot(minval:-1,maxval:1);
)

// -----------------------------> Bins

// In questo tipo di trasformata lo spettro viene campionato (discretizzato) in
// punti precisi (BINS) posizionati a frequenze equidistanti.

// La distanza tra le frequenze è data da:
//
//      Sample Rate / Window size
//
// Ad esempio se la sr = 48.000 e il window size = 1024:

48000/1024; // 46.875 Hz

// Un bin frequenziale ogni 46.875 Hz da 0 Hz (DC offset) fino a SR/2 (frequenza di Nyquist)

a = 1024.collect({|i| (48000/1024)*i}); // Lista di tutte le frequenze dei bins
a = a[..512];                           // Quelle al di sopra di Nyquist sono ridondanti

a.size;     // Metà del window size...
a.postcs;

// Per una STFT con window size di 2048 otteniamo 1024 bins frequenziali e per ognuno di essi
// vengono misurate e memorizzate in un Buffer ampiezza (magnitude) e fase.

// -----------------------------> Frame

// L'insieme dei dati derivati dall'analisi di una singola window si chiama FRAME e contiene:

// • un magnitude spectrum con i valori delle ampiezze di ogni singolo bin.
// • un phase spectrum con i valori delle fasi iniziali di ogni singolo bin

// -----------------------------> Riassumendo...

// DTFT (algoritmo) -->
// FFT  (analisi di una finestra che produce un frame) -->
// STFT (sequenza di finestre di analisi nel tempo).

// Segnale audio mono...

(
Buffer.freeAll;
b = Buffer.read(s,"voce.wav".resolveRelative);
{b.plot}.defer(0.1);
)

// Una singola window per l'analisi (2048 samples)...

(
~size = 2048;
b.free;
b = Buffer.read(s,"voce.wav".resolveRelative,0.3*s.sampleRate,~size);
{b.plot}.defer(0.1);
)

// Osserviamo la ciclicità della forma d'onda...

// Visualizzazione:

(
~nbins = 100;  // numero di bins da visualizzare (cambia in 100)

~sig = Signal.newClear(~size);
b.getn(0,~size, {arg i; ~sig.waveFill({arg val, old,idx; i[idx]})});

{~imag     = Signal.newClear(~size);
 ~cosTable = Signal.fftCosTable(~size);
 ~complex  = fft(~sig,~imag,~cosTable);
 ~magn     = ~complex.magnitude.normalize * ~sig.peak;
 ~fasi     = ~complex.phase + (pi/2) % 2pi;

[~sig,~magn,~fasi].plot.plotMode_(\bars);
[~sig,~magn[1..~nbins+1],~fasi[1..~nbins+1]].plot.plotMode_(\bars)
}.defer(0.5);
)

// Notiamo DUE cose:

// • Ampiezze e fasi sono speculari alla metà del FRAME (Nyquist)

// • Fino al bin 150 c'è energia dopo poco o niente e questa
//   informazione può tornare utile per limitare in numero
//   di bins da analizzare e risparmiare CPU...

// -----------------------------> Overlap (hop size)

// Lo spettro di un suono varia dinamicamente nel tempo (inviluppo spettrale).

// FFT --> analisi di una singola finestra temporale molto corta.

// Se facciamo partire una nuova finestra di analisi prima della fine della
// precedente miglioriamo la definizione nell'analisi del segnale.

// Capiamo ora come window size più grandi difiniscono meglio il contenuto
// spettrale e peggio le sue variazioni nel tempo e viceversa window size
// più piccoli definiscono meglio le variazioni spettrali nel tempo.

// -----------------------------> IFFT (Inverse Fast Fourier Transform)

// Applicando il processo inverso possiamo ricostruire con una buona approssimazione
// il segnale originale nel dominio del tempo con la tecnica chiamata
// Overlap-add resynthesis (OA).

// ---> vedi IFFT.gif

// Se però vogliamo elaborare in qualche modo il risultato dell'analisi prima
// della risintesi (come ad esempio time stretching o altro) questa tecnica
// mostra dei limiti in quanto introduce artefatti nel suono come comb filter o
// riverberi indesiderati.

// Per realizzare questi due processi in SC dobbiamo utilizzare due UGens:

// chain  = FFT(buffer, input) --> Analisi
// output = IFFT(chain)        --> Risintesi

// -----------------------------> FFT()

// Questa UGen realizza l'analisi e scrive la spectral data in un Buffer o
// LocalBuf il cui size deve essere un multiplo di 2 e un multiplo del buffer
// size.

// Genera un segnale a control rate (solitamente chiamato chain) che è costante a -1.

// Solo quando una nuova FFT window comincia genera il numero corrispondente
// all'indice del Buffer dove seve scrivere il risultato dell'analisi.

Buffer.freeAll;
b = Buffer.alloc(s, 512);  // FFT buffer (mono!)
b.bufnum;                  // indice del buffer

(
{
FFT(b, SoundIn.ar)
}.plot(s.options.blockSize/s.sampleRate*16, minval: -2, maxval:b.bufnum + 4).plotMode_(\steps);
)

// La spectral data risultato dell'analisi non è nel segnale (chain) ma nel Buffer.

b.plot;

// E' scritta nel Buffer nel formato seguente:

// DC | nyquist | 1f (reale) | 1f (img) | 2f (reale) | 2f (img) | ... | (N-1)f (reale) | (N-1)f (img) |

// f = frequenza del bin (reale = mag, img = fase)
// N = window size / 2

// Parametri (nella maggior parte dei casi specifichiamo solo i primi due)

FFT(buffer,
	   sig,
	   hop,      // Overlap da 0.001 a 1 (no overlap)
    wintype,  // 0 = Sine    --> OK per PV_
	             // 1 = Hanning --> OK per Analisi senza risintesi
	   active,
	   winsize)  // Usualmente lo stesso del Buffer usato per l'analisi

// -----------------------------> IFFT()

// Questa UGen riconverte la spectral data nel dominio temporale...
// Anche se non lo specifichiamo lavora ad audio rate...

(
SynthDef(\MonoFFT, {arg outBuf=0;
                    var in, chain, sig;
                        in    = Saw.ar(440, 0.2);
                        chain = FFT(LocalBuf(2048), in); // Buffer interno alla SynthDef
	                       sig   = IFFT(chain);
                    Out.ar(outBuf, sig);
         }).add;
)

Synth(\MonoFFT);

// Se vogliamo utilizzare segnali stereo dobbiamo utilizzare la multichannel expansion:

(
SynthDef(\StereoFFT, {arg outBuf=0;
                      var in, chain, sig;
	                      in    = Saw.ar([440, 443], 0.2);         // Stereo
	                      chain = FFT(LocalBuf([2048,2048] ), in); // Due Buffer mono, non uno stereo
	                      sig   = IFFT(chain);
                      Out.ar(outBuf, sig);
         }).add;
)

Synth(\StereoFFT);
