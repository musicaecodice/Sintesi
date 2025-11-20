// ===========================================================
// Buffers

// Mettere tutti i soundfiles che vogliamo utilizzare in una
// cartella all'interno della cartella dove è anche il patch
// di SC che li utilizza.

// Nome_progetto (Cartella)
//      |
//      |___ main.scd (file)
//      |
//      |___ suoni (cartella)
//             |
//             |____ ciao.wav (file)
//             |____ miao.wav (file)
//             |____ uiao.wav (file)
//             |____ etc...

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

s.options.numBuffers;        // numero di Buffer che possono
                             // essere creati nel Server
s.options.numBuffers_(2000); // Si può cambiare (poi reboot)

//-----------------------------------------------------------------
// Path

// ------------------------------ Assoluto

// Trascinare il file nell'interprete...
// Come stringa...

"/Users/andreavigani/Desktop/Milano_2022_23/Programmi/3_Campionamento/07_Sample_Player/suoni/bach.wav"

// ------------------------------ Relativo

// Se all'interno della cartella del progetto possiamo inviarlo
// a chiunque senza dover cambiare la parte assoulta del path.

"suoni/crotal.wav".resolveRelative; // Aggiunge il path assoluto

//-----------------------------------------------------------------
// Caricare un singolo sounfiles in un Buffer
// resize automatico

(
Buffer.freeAll;
b = Buffer.read(s, "suoni/voce.wav".resolveRelative);
)

// Info sul Buffer

b.bufnum;        // numero (indice) del buffer
b.plot;          // visualizza il contenuto in un Plotter
b.play;          // 'suona' il buffer (solo per monitorarne il contenuto)
b.path;          // riporta il path assoluto del file caricato

b.numFrames;     // riporta il numero di Frames
b.numChannels;   // riporta il numero di canali
b.sampleRate;    // riporta la rata di campionamento (che portebbe essere diversa da quella del file caricato)
s.sampleRate;
b.duration;      // riporta la durata in secondi

b.query;         // riporta le informazioni precedenti attraverso un solo comando

b.zero;          // cancella contenuto
b.free;          // distrugge

// ------------------------------ una porzione di file

(
Buffer.freeAll;
b = Buffer.read(s, "suoni/voce.wav".resolveRelative,
	            b.sampleRate * 1.0,   // Primo frame da caricare
	            b.sampleRate * 0.1);  // Durata in frames
)

b.play;

// ------------------------------ un solo canale
// (di file stereo o multicanale)

(
Buffer.freeAll;
b = Buffer.readChannel(s, "suoni/voce.wav".resolveRelative,channels:[0]);
)

b.plot;

//-----------------------------------------------------------------
// Caricare una cartella di sounfiles in un Array di Buffer

// 1 - Array di path assoluti

~paths = ("suoni".resolveRelative ++ "/*.wav").pathMatch;

// legge solo i files con l'estensione specificata...

// 2 - Array di Buffers

(
Buffer.freeAll;
~bufs  = ~paths.collect{arg i; Buffer.read(s, i)};
)

~bufs.at(3).play; // Richiama i singoli Buffer...
~bufs[3].play;
