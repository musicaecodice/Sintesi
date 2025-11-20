//=================================================================
// Wave Shaping Synthesis

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

//-----------------------------------------------------------------
// Shaper.ar()

(
Buffer.freeAll;

~punti = 1024;
~clip1 = Signal.newClear(~punti);

~clip1.waveFill({arg x; x},-1, 1); // Rampa lineare tra -1 e +1
~clip1 = ~clip1.clip2(0.5);        // Tranfert Funcion

b = Buffer.loadCollection(s,~clip1.asWavetableNoWrap); // Non ottimizzato per il wrap around...

{b.plot}.defer(1);
)

(
SynthDef.new(\wsh, {arg buf=b,freq=400,shp=0,amp=0,gate=0,pan=0,done=2;
	                var sig, sigIn, env;
	                    sigIn = SinOsc.ar(freq) * shp;
	                    sig   = Shaper.ar(buf, sigIn);
	                    env   = Linen.kr(gate,doneAction:done);
	                    sig   = Pan2.ar(sig*env*amp,pan);
	                    sig   = LeakDC.ar(sig);
	                Out.ar(0,sig)
}).add;

SynthDef.new(\mouse, {arg busOut=0;
	                  var sig;
	                      sig = MouseY.kr(0,1).poll(10);
	                  Out.kr(busOut,sig)
             }).add;

~mouseY = Bus.control(s, 1); // (server, n_canali)
{Synth(\mouse, [\busOut, ~mouseY])}.defer(1);
)

a = Synth.new(\wsh, [\buf,b,\freq,400,\shp,1,\amp,0.2,\gate,1],s,\addToTail);

a.set(\shp,0.5);
a.set(\shp, ~mouseY.asMap);