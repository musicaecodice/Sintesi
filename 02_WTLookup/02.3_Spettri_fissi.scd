//=================================================================
// Sintesi additiva a spettro fisso con frequenze in rapporto
// armonico.

// Possiamo generare una forma d'onda che produca uno spettro
// armonico con la possibilità di controllare per ogni parziale:

// • Rapporto di frequenze
// • Ampiezze
// • Fasi

// Possiamo impiegare uno a scelta tra i metodi illustrati nel
// paragrafo dedicato alle funzioni d'onda

//=================================================================

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

//-----------------------------------------------------------------
// Buffer

(
~punti  = 2048;

Buffer.freeAll;
b = Buffer.alloc(s,~punti);
b.sine3([1,    2,  3],  // Rapporti di frequenza dei parziali
	        [0.5,0.3,0.2],  // Ampiezze dei parziali
	        [2pi,2pi,2pi],  // Fasi dei parziali
         true,           // Normalizza
	        true,           // asWavetable
        );

{b.plot(bounds:600@400, minval: -1, maxval:1)}.defer(0.1)
)

//-----------------------------------------------------------------
// Strumento

(
SynthDef(\wave, {arg buf=b, freq=500, amp=0, dur=1, fade=0.1,t_gate=0,pan=0,done=0;
	                var sig,bpf,env,pann;
	                 sig   = Osc.ar(buf,freq);
	                 bpf   = Env.linen(fade, dur-(fade*2),fade,curve:\cub);
	                 env   = EnvGen.ar(bpf,t_gate,doneAction:done);
	                 pann  = Pan2.ar(sig*amp*env,pan);
	             Out.ar(0,pann)}
         ).add;
)

//-----------------------------------------------------------------
// Sound design 1 - Organo

Synth(\wave, [\buf,b,\amp,0.4,\freq,rrand(60,72).midicps,\done,2,\t_gate,1]);

//-----------------------------------------------------------------
// Sound design 2 - Run

(
r = Routine.new({
	             inf.do({
                         ~amps = 10.collect({rand(1.0)}).normalizeSum;
                         ~phas = 10.collect({rand(2pi)});
                         p = Signal.sineFill(~punti/2, ~amps, ~phas);
                         p = p.asWavetable;
                         b.loadCollection(p);
                         Synth(\wave, [\buf,b,
			                                    \freq,500,
			                                    \amp,rand(1.0),
			                                    \dur,rrand(0.05,0.08),
			                                    \fade,0.01,
			                                    \pan, [-1,1].choose,
			                                    \done,2,
			                                    \t_gate,1]);
	                     0.1.wait;
	                     })
                  }).play
)

r.reset.play; // Suona
r.stop;       // Stoppa

//-----------------------------------------------------------------
// Sound design 3 - Tappeto sonoro

(
~amps = 10.collect({rand(1.0)}).normalizeSum;
~phas = 10.collect({rand(2pi)});

p = Signal.sineFill(~punti/2, ~amps, ~phas);
b = Buffer.loadCollection(s, p.asWavetable);

v = Routine.new({
	             inf.do({
                         Synth(\wave, [\buf,b,
			                           \freq,rrand(50,100).midicps,       // Atonale
			                         //  \freq, [68,72,75,80].midicps.choose, // Triade
						               \amp,rand(1.0),
			                           \dur,rrand(4,8),
			                           \fade,rrand(0.2,8),
						               \pan, rand2(1.0),
			                           \done,2,
			                           \t_gate,1]);
		                 rrand(0.1,2).wait;
	                     })
                 }).play
)

v.reset.play; // Suona
v.stop;       // Stoppa

//=================================================================