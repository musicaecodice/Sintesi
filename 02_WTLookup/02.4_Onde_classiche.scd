//=================================================================
// Esistono alcune forme d'onda classiche con spettri ricchi di
// parziali.

// Quasi tutte però se realizzate attraverso una funzione d'onda che
// computa le ampiezze istantanee, non sono limitate in frequenza,
// ovvero producono fenomeni di aliasing.

// Per ovviare a questa problematica bisogna disegnarle partendo
// dalle loro caratteristiche spettrali attraverso metodi dedicati
// alla sintesi additiva a spettro fisso.

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

(
SynthDef(\wave_s, {arg buf=b, freq=500, amp=0, dur=1,t_gate=0,pan=0,done=0;
	               var sig,bpf,env,pann;
	                   sig   = Osc.ar(buf,freq);
	                   bpf   = Env.sine(dur);
	                   env   = EnvGen.ar(bpf,t_gate,doneAction:done);
	                   pann  = Pan2.ar(sig*amp*env,pan);
	               Out.ar(0,pann)}
         ).add;
)

//-----------------------------------------------------------------
// Onda a dente di sega

// Tutti gli armonici con ampiezze decrescenti 1/num_harm
// Buffer.sine1([ampiezze]) --> Frequenze in rapporto
// armonico di default.

(
Buffer.freeAll;

~punti  = 1024;                       // Numero di punti (size della tavola)
~npar   = 45;                         // Numero di parziali
~harm   = ~npar.collect({arg n; n});  // Tutti gli armonici (da 0)
~sign   = -1**~harm;                  // Segno alternato
~amps   = 1.0/(1+~harm*~sign);        // Ampiezze decrescenti

b = Buffer.alloc(s, ~punti);

b.sine1(~amps);
b.plot;
)

Synth(\wave_s, [\buf,b,\amp,1,\freq,rrand(70,82).midicps,\done,2,\t_gate,1]);

{Saw.ar(MouseX.kr(60,3000))}.play;   // UGen dedicata...
{LFSaw.ar(MouseX.kr(60,3000))}.play; // Con aliasing...

//-----------------------------------------------------------------
// Onda quadra

// Somma degli armonici dispari con ampiezze decrescenti secondo
// la seguente relazione: 1/numero dell'armonico.
// Buffer.sine2([n_arm],[ampiezze])

(
Buffer.freeAll;

~punti = 512;                           // Numero di punti (size della tavola)
~npar  = (45/2).asInteger;              // Numero di parziali
~harm  = ~npar.collect({arg n; 1+n+n}); // Armonici dispari
~amps  = 1/~harm;                       // Ampiezze decrescenti

c = Buffer.alloc(s, ~punti);

c.sine2(~harm,~amps);
c.plot;
)

Synth(\wave_s, [\buf,c,\amp,1,\freq,rrand(70,82).midicps,\done,2,\t_gate,1]);

{Pulse.ar(MouseX.kr(68,72).midicps)}.play; // UGen dedicata...
{LFPulse.ar(MouseX.kr(60,3000))}.play;     // Con aliasing...

//-----------------------------------------------------------------
// Onda triangolare
// Somma degli armonici dispari con ampiezze decrescenti secondo la
// seguente relazione: (1/numero dell'armonico)**2 a segno alternato.

(
Buffer.freeAll;

~punti = 512;                           // Numero di punti (size della tavola)
~npar  = (45/2).asInteger;                  // Numero di parziali
~harm  = ~npar.collect({arg n; 1+n+n}); // Armonici dispari
~sign  = ~npar.collect({arg n; -1**n}); // Segno alternato

~amps  = ~sign * (1/~harm**2);          // Ampiezze decrescenti

e = Buffer.alloc(s, ~punti);

e.sine2(~harm,~amps);
e.plot;
)

Synth(\wave_s, [\buf,e,\amp,1,\freq,rrand(70,82).midicps,\done,2,\t_gate,1]);

{VarSaw.ar(MouseX.kr(60,300),0,0.5)}.play; // UGen dedicata...
{LFTri.ar(MouseX.kr(60,3000))}.play;       // Con aliasing...

//-----------------------------------------------------------------
// Funzione Noise periodico con distribuzione lineare
// x[n] = random(-1/1)

(
Buffer.freeAll;

~punti = 512;                // Numero di punti (size della tavola)
~amp   = 1.0;                // Ampiezza di picco

g = ~punti.collect({~amp * rand2(1.0)});

i = Buffer.alloc(s, ~punti);

i.loadCollection(g);       // Carica FloatArray nel Buffer (sine)
i.plot;
)

Synth(\wave_s, [\buf,i,\amp,1,\freq,rrand(70,82).midicps,\done,2,\t_gate,1]);

//-----------------------------------------------------------------
// Salvare e caricare forme d'onda dai Buffers.

// Possiamo salvare il contenuto di un Buffer indipendentemente da
// come lo abbiamo realizzato sotto forma di soundfiles per poi
// ricaricarlo dinamicamente.


b = Buffer.alloc(s, 2048);
b.sine1([1,0.3,0.5,0.7]);
b.plot;
b.write("/Users/andreavigani/Desktop/addi.aiff");
b.read("/Users/andreavigani/Desktop/addi.aiff");

// Nella cartella wavetables ad esempio sono memorizzate numerose
// forme d'onda che possiamo caricare in un Array di buffers per poi
// richiamarle dinamicamente attraverso gli indici.

(
Buffer.freeAll;
~wt = SoundFile.collectIntoBuffers("wavetables/*".resolveRelative,s);
~wt.size; // Numero di Buffer (wavetables) caricati nel Server
)

y = ~wt[rand(~wt.size).postln]
Synth(\wave_s, [\buf,y,\amp,0.3,\freq,rrand(70,82).midicps,\done,2,\t_gate,1]);
