ServerOptions.devices;

s.options.inDevice_("Microfono MacBook Air");
//s.options.outDevice_("Altoparlanti MacBook Air");
s.options.outDevice_("Auricolari esterni");

s.reboot;
s.scope;
s.freqscope;
s.plotTree;

// -----------------------------> Morfologie

// • Impulsivi (1 sample)
// • Discreti  (Low Freq)
// • Uniformi  (senza discontinuità oppure omogenei)

// Ognuno dei quali può essere

// • Periodico
// • Aperiodico

(
{[
Impulse.kr(100),
Dust.kr(100),
LFSaw.kr(10),
LFNoise0.kr(10),
SinOsc.kr(10),
WhiteNoise.kr(1)
]}.plot(0.5)
)