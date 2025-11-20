// ===========================================================

// Come per la waveshaping un'altro metodo (meno costoso a
// livello computazionale) consiste nel memorizzare in due
// Buffers i profili d'onda x e y per poi rileggerli con
// due segnali puntatori (orbite)

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

(
Buffer.freeAll;

~bx = Buffer.alloc(s, 1024, 1);
~bx.sine1([1],true,false);     // No wavetable format

~by = Buffer.alloc(s, 1024);
~by.sine1([1,6,9],true,false); // No wavetable format
)

~bx.plot;
~by.plot;

(
SynthDef.new(\wts_2, {arg bufx=b,bufy=c,freq=#[400,410],amp=0,gate=0,pan=0,done=2;
	                     var phs,r, offph,cx,cy,x, y, sig, sigx, sigy, env;

// ------------------------------ Orbite (tra -1 e +1)

	                      phs   = LFSaw.ar(freq, -1).range(0, 2pi);  // Tra 0 e 2pi (angolo giro)
	                      r     = LFNoise1.kr(0.4).unipolar;     // Raggio
			                    offph = LFNoise1.kr(0.4).range(0,pi);  // Defasaggio
	                      cx  = LFNoise1.kr(1.3);                // origine x
	                      cy  = LFNoise1.kr(0.5);                // origine y
	                      x   = r * sin(phs) + cx;
	                      y   = r * cos(phs + offph) + cy;
		                  [x,y].scope;

// ------------------------------

	                      sigx = BufRd.ar(1,bufx, x.range(0,BufFrames.kr(bufx))); // Tra 0 e n-1
	                      sigy = BufRd.ar(1,bufy, y.range(0,BufFrames.kr(bufy)));
	                      sig  = sigx * sigy;
	                      env  = Linen.kr(gate,doneAction:done);
	                      sig  = Pan2.ar(sig*env*amp,pan);
	                      sig  = LeakDC.ar(sig);
	                  Out.ar(0,sig)
}).add;
)

a = Synth.new(\wts_2, [\bufx,~bx,\bufy,~by,\freq,[200,201],\amp,0.5,\gate,1]);
a.set(\freq, [100,101])
a.release;



