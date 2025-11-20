//=================================================================
// Wave Terrain Synthesis

// Partiamo dal principio del Wavetable Lookup.
// Possiamo computare i valori y di una wavetable bidimensionale
// attraverso una funzione d'onda
// UNA VARIABILE: wave(x)

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

//------------------------------------------------------------------
// 1_WTS

// f[x] = sin(x) --> x tra 0 e 2pi (angolo giro)

(
f = {arg x; sin(x)};                            // Funzione d'onda

SynthDef.new(\wts_1, {arg freq=400,amp=0,gate=0,pan=0,done=2;
	                  var phs, sig, env;
	                      phs = LFSaw.ar(freq, -1).range(0, 2pi); // Fasore da 0 a 2pi (angolo giro)
	                      sig = Limiter.ar( f.value(phs) );       // Valuta la funzione ad audio rate
	                      env = Linen.kr(gate,doneAction:done);
		                     sig = LeakDC.ar(sig);
	                      sig = Pan2.ar(sig*env*amp,pan);
	                  Out.ar(0,sig)
}).add;
)

a = Synth.new(\wts_1,[\amp,0.2,\gate,1])
a.release;

//------------------------------------------------------------------
// 2_Orbita_1

// Se definiamo una wavetable tridimensionale attraverso una funzione
// d'onda a DUE VARIABILI: wave(x[n], y[n]) possiamo rappresentarla
// come una superficie tridimensionale chiamandola Wave Terrain (WT).
// (vedi WT_0.1.png, WT_0.2.png e WT_0.3.png)
//
// Le ampiezze istantanee (valori y nel wavetable lookup bidimensionale)
// corrispondono all'altezza della figura (valori z) (vedi WT_1.png)
// e possono essere richiamate attraverso non uno ma due indici (x, y)
// come qualsiasi punto su di un asse cartesiano.

(
// Funzione con x e y...

f = {arg x, y; (x - y) * (x - 1) * (x + 1) * (y - 1) * (y + 1)}; // C.Roads

SynthDef.new(\wts_2, {arg freq=400,amp=0,gate=0,pan=0,done=2;
	                     var phs, x, y, sig, env;

// ------------------------------ Orbite (tra -1 e +1)

	                       phs = LFSaw.ar(freq, -1);  // Tra -1 e +1
		                      x   = phs * -1;            // Tra +1 e -1
	                       y   = phs;
		                     [x,y].scope;               // Metti visualizzazione XY

// ------------------------------

	                      sig = Limiter.ar( f.value(x, y) ); // Valuta la funzione ad audio rate
	                      env = Linen.kr(gate,doneAction:done);
		                     sig = LeakDC.ar(sig);
	                      sig = Pan2.ar(sig*env*amp,pan);
	                  Out.ar(0,sig)
}).add;
)

a = Synth.new(\wts_2,[\amp,0.2,\gate,1])
a.set(\freq,200)
a.release;

//------------------------------------------------------------------
// 3_Orbita_2
//
// Nel caso precedente la superficie è letta in modo diagonale (vedi WT_2.png)
// ma possiamo "esplorare" la superfice in qualsiasi modo. Queste
// esplorazioni si chiamano ORBITE e descrivono una sequenza di punti
// sulla superficie nel tempo.

// Ad esempio basterà calcolare il seno e il
// coseno del segnale lineare per delineare un'orbita circolare ottenendo
// uno spettro differente (vedi WT_3.png):

(
f = {arg x, y; (x - y) * (x - 1) * (x + 1) * (y - 1) * (y + 1)}; // C.Roads

SynthDef.new(\wts_3, {arg freq=400,amp=0,gate=0,pan=0,done=2;
	                  var phs, x, y, sig, env;

// ------------------------------ Orbite (tra -1 e +1)

	                      phs = LFSaw.ar(freq, -1).range(0, 2pi);  // Tra 0 e 2pi (angolo giro)
	                      x   = sin(phs);
	                      y   = cos(phs);
		                     [x,y].scope;               // Metti visualizzazione XY

// ------------------------------

	                      sig = Limiter.ar(f.value(x, y)); // Valuta la funzione ad audio rate
	                      env = Linen.kr(gate,doneAction:done);
		                  sig = LeakDC.ar(sig);
	                      sig = Pan2.ar(sig*env*amp,pan);
	                  Out.ar(0,sig)
}).add;
)

a = Synth.new(\wts_3,[\amp,0.2,\gate,1])
a.release;

//------------------------------------------------------------------
// 4_Orbita_3

// Oppure sfasare dinamicamente y per ottenere ellissi...

(
f = {arg x, y; (x - y) * (x - 1) * (x + 1) * (y - 1) * (y + 1)}; // C.Roads

SynthDef.new(\wts_3, {arg freq=400,amp=0,gate=0,pan=0,done=2;
	                  var phs,offph, x, y, sig, env;

// ------------------------------ Orbite (tra -1 e +1)

	                      phs   = LFSaw.ar(freq, -1).range(0, 2pi);  // Tra 0 e 2pi (angolo giro)
			                    offph = MouseY.kr(0,pi);  // Defasaggio
	                      //offph = Line.ar(0,pi,5);
	                      x     = sin(phs);
	                      y     = sin(phs + offph);
		                  [x,y].scope;

// ------------------------------

	                      sig = Limiter.ar(f.value(x, y));
		                  sig = LeakDC.ar(sig);
	                      env = Linen.kr(gate,doneAction:done);
	                      sig = Pan2.ar(sig*env*amp,pan);
	                  Out.ar(0,sig)
}).add;
)

a = Synth.new(\wts_3,[\amp,0.2,\gate,1])
a.release;

//------------------------------------------------------------------
// Raggio

// Possiamo anche cambiare dinamicamente il raggio dell'orbita con un
// fattore di moltiplicazione compreso tra 0.0 e 1.0

(
f = {arg x, y; (x - y) * (x - 1) * (x + 1) * (y - 1) * (y + 1)}; // C.Roads

SynthDef.new(\wts_3, {arg freq=400,amp=0,gate=0,pan=0,done=2;
	                  var phs,r,offph, x, y, sig, env;

// ------------------------------ Orbite (tra -1 e +1)

	                      phs   = LFSaw.ar(freq, -1).range(0, 2pi);  // Tra 0 e 2pi (angolo giro)
	                      r     = MouseY.kr(0, 1);        // Raggio
			                    offph = MouseX.kr(0,pi);        // Defasaggio
	                      x     = r * sin(phs);
	                      y     = r * sin(phs + offph);
		                  [x,y].scope;

// ------------------------------

	                      sig = Limiter.ar(f.value(x, y));
	                      env = Linen.kr(gate,doneAction:done);
		                  sig = LeakDC.ar(sig);
	                      sig = Pan2.ar(sig*env*amp,pan);
	                  Out.ar(0,sig)
}).add;
)

a = Synth.new(\wts_3,[\amp,0.2,\gate,1])
a.release;

//------------------------------------------------------------------
// Origine

// Oppure traslare l'origine sia di x che di y:

(
f = {arg x, y; (x - y) * (x - 1) * (x + 1) * (y - 1) * (y + 1)}; // C.Roads

SynthDef.new(\wts_3, {arg freq=400,amp=0,gate=0,pan=0,done=2;
	                  var phs,r,offph, cx,cy,x, y, sig, env;

// ------------------------------ Orbite (tra -1 e +1)

	                      phs   = LFSaw.ar(freq, -1).range(0, 2pi);  // Tra 0 e 2pi (angolo giro)
	                      r     = MouseY.kr(0, 1);       // Raggio
			                    offph = MouseX.kr(0,pi);       // Defasaggio
	                      cx    = MouseX.kr(-1, 1.0);    // Origine x
	                      cy    = MouseY.kr(-1, 1.0);    // Origine y
	                      x     = r * sin(phs) + cx;
	                      y     = r * cos(phs + offph) + cy;
		                  [x,y].scope;

// ------------------------------

	                      sig = Limiter.ar(f.value(x, y));
	                      env = Linen.kr(gate,doneAction:done);
	                      sig = LeakDC.ar(sig);
	                      sig = Pan2.ar(sig*env*amp,pan);
	                  Out.ar(0,sig)
}).add;
)

a = Synth.new(\wts_3,[\amp,0.2,\gate,1])
a.release;

// In questo caso la posizione del mouse "esplora" punti diversi della
// superfcie..

//------------------------------------------------------------------
// 5_Lissajous
//
// https://www.makers-itis-forli.it/fisica-in-casa/figure-di-lissajous/

(
f = {arg x, y; (x - y) * (x - 1) * (x + 1) * (y - 1) * (y + 1)}; // C.Roads

SynthDef.new(\wts_3, {arg xfreq=110, fratio = #[1,2], offph=0.25,
	                      xpos= 0, xdim=1, ypos= 0, ydim= 1,
	                      amp=0.2,gate=0,pan=0,done=2;
	                  var yfreq, xphs, yphs, xmin, xmax, ymin, ymax, sig, env;

// ------------------------------ Orbite (tra -1 e +1)

	     yfreq = xfreq * (fratio[0] / fratio[1]); // Calcola la frequenza di y
	     xphs  = LFSaw.ar(xfreq, -1).range(0, 2pi);
	     yphs  = LFSaw.ar(yfreq, -1).range(0, 2pi);
	     xmin  = xpos - xdim;
	     xmax  = xpos + xdim;
		    ymin  = ypos - ydim;
	     ymax  = ypos + ydim;
	     x     = Wrap.ar(sin(xphs),-1,1).range(xmin,xmax);
	     y     = Wrap.ar(sin(yphs + offph),-1,1).range(ymin,ymax);
         [x,y].scope;                 // Metti visualizzazione XY

// ------------------------------

	     sig = Limiter.ar(f.value(x, y));
	                      env = Linen.kr(gate,doneAction:done);
	                      sig = LeakDC.ar(sig);
	                      sig = Pan2.ar(sig*env*amp,pan);
	                  Out.ar(0,sig)
}).add;
)

a = Synth.new(\wts_3,[\amp,0.2,\gate,1])

a.set(\fratio,[rrand(1,10.0),rrand(1,10.0)],\xpos,0,\xdim,1,\ypos,0,\ydim,1);
a.set(\xpos,rand(1.0),\xdim,rand(1.0),\ypos,rand(1.0).postln,\ydim,rand(1.0));
a.release;

// Provare a mappare dei segnali sui parametri pos e dim

//------------------------------------------------------------------
// 6_Curva rodonea

// https://it.wikipedia.org/wiki/Rodonea

(
f = {arg x, y; (x - y) * (x - 1) * (x + 1) * (y - 1) * (y + 1)}; // C.Roads

SynthDef.new(\wts_3, {arg ratio=#[1,2],freq=#[227,258], r=1,rota=0,
	                      amp=0.2,gate=0,pan=0,done=2;
	                  var phs, n, rho, pol, cx,cy, sig, env;

// ------------------------------ Orbite (tra -1 e +1)

	     phs = LFSaw.ar(freq, -1).range(0, 2pi) * ratio[1];  // phs * denominatore
	     n   = ratio[0]/ratio[1];  // Ratio
	     rho = cos(n * phs);       // Calcola il rho
	     phs = phs + (rota*2pi);   // Rotazione
 	    x   = rho * sin(phs) ;    // Da polare a cartesiano
	     y   = rho * cos(phs);     // Da polare a cartesiano
		    cx  = MouseX.kr(-1, 1.0); // Origine x
	     cy  = MouseY.kr(-1, 1.0); // Origine y
	     x   = r * x + cx;
	     y   = r * y + cy;
         [x,y].scope;                 // Metti visualizzazione XY

// ------------------------------

	     sig = Limiter.ar(f.value(x, y));
	                      env = Linen.kr(gate,doneAction:done);
	                      sig = LeakDC.ar(sig);
	                      sig = Pan2.ar(sig*env*amp,pan);
	                  Out.ar(0,sig)
}).add;
)

a = Synth.new(\wts_3,[\amp,0.2,\ratio, [2,4],\r,0.5,\freq,[200,200],\gate,1])
a.set(\r,0.3,\rota,0.1);
a.set(\ratio, [2,4])
a.set(\ratio, [rrand(1,10),rrand(1,10)],\r,0.5)
a.release;

//------------------------------------------------------------------
// Noise

(
f = {arg x, y; (x - y) * (x - 1) * (x + 1) * (y - 1) * (y + 1)}; // C.Roads

SynthDef.new(\wts_3, {arg freq=400,amp=0,gate=0,pan=0,done=2;
	                  var phs,r,offph, cx,cy,x, y, sig, env;

// ------------------------------ Orbite (tra -1 e +1)

	                      phs   = LFNoise2.ar(freq).range(0, 2pi);  // Tra 0 e 2pi (angolo giro)
	                      r     = MouseY.kr(0, 1);    // Raggio
			                    offph = MouseX.kr(0,pi);    // Defasaggio
	                      cx    = MouseX.kr(-1, 1.0); // Origine di x
	                      cy    = MouseY.kr(-1, 1.0); // Origine di y
	                      x     = r * sin(phs) + cx;
	                      y     = r * cos(phs + offph) + cy;
		                  [x,y].scope;

// ------------------------------

	                      sig = Limiter.ar(f.value(x, y));
	                      env = Linen.kr(gate,doneAction:done);
	                      sig = LeakDC.ar(sig);
	                      sig = Pan2.ar(sig*env*amp,pan);
	                  Out.ar(0,sig)
}).add;
)

a = Synth.new(\wts_3,[\amp,0.2,\gate,1])
a.release;

//------------------------------------------------------------------
// Ellittica...
// Vedi WT_5.png    ... con battimenti stereo...

(
f = {arg x, y; (x - y) * (x - 1) * (x + 1) * (y - 1) * (y + 1)}; // C.Roads

SynthDef.new(\wts_3, {arg freq=#[200,201],amp=0,gate=0,pan=0,done=2;
	                  var phs,r,offph, cx,cy,x, y, sig, env;

// ------------------------------ Orbite (tra -1 e +1)

	                      phs   = LFSaw.ar(freq, -1).range(0, 2pi);  // Tra 0 e 2pi (angolo giro)
	                      r     = MouseY.kr(0, 1);    // Raggio
			                    offph = MouseX.kr(0,pi);    // Defasaggio
	                      cx    = MouseX.kr(-1, 1.0); // Origine x
	                      cy    = MouseY.kr(-1, 1.0); // Origine y
	                      x     = r * sin(2pi * phs + (pi/5)) + cx;
	                      y     = r * sin(2pi * phs) + cy;
		                  [x,y].scope;

// ------------------------------

	                      sig = Limiter.ar(f.value(x, y));
	                      env = Linen.kr(gate,doneAction:done);
	                      sig = LeakDC.ar(sig);
	                      sig = Pan2.ar(sig*env*amp,pan);
	                  Out.ar(0,sig)
}).add;
)

a = Synth.new(\wts_3,[\amp,0.2,\gate,1])

a.set(\r,0.6);
a.set(\freq, [rrand(200,205),rrand(200,205)])
a.release;

//====================================================================

// Musicalmente qualsiasi superficie tridimensionale può essere utilizzata
// come Wave Terrain sia quelle costruite attraverso funzioni matematiche,
// sia derivate da proiezioni topografiche arbitrarie come una mappa di rilievi
// di una determinata regione geografica.
// Devono però seguire due regole:
//
// --> x e y devono essere entrambe comprese tra -1 e +1
// --> le funzioni d'onda che generano x e y devono produrre valori continui
//     (in senso matematico) sul terreno
// --> x e y devono avere valore 0.0 ai limiti del terreno esattamente come
//     l'inizio e la fine delle wavetables bidimensionali.
//

// https://www.wolframalpha.com/

(
//f = {arg x, y; (x - y) * (x - 1) * (x + 1) * (y - 1) * (y + 1)}; // Roads
f = {arg x, y; (sin(x) + sin(y)).sqrt/2};                        // lepoard function
// f = {arg x, y; sin(2pi*x) * sin(2*pi*y)};                        // WT_5.png
// f = {arg x, y; (5/3)*(x-y)*((x*x)-1)*((y*y)-1)};                 // Stuart G. James
// f = {arg x, y; sin(pow(x+1, 4)*2pi)*sin(pow(y+1, 4)*2pi)}; // Mills, A. and R. C. De Souza.
// f = {arg x, y; sin(x*2pi+ 3*sin(y*2pi))};                  // Modulazione di fase
// f = {arg x, y; sin(pow(3*x,2) + pow(3*y,3))};              // Stuart G. James
// f = {arg x, y; cos(sin(12*x*y)/(pow(x,2) + pow(y,2)))};
// f.plot;

SynthDef.new(\wts_3, {arg ratio=#[1,2],freq=#[200,201],amp=0,gate=0,pan=0,done=2;
	                  var phs,r,offph, cx,cy,x, y, sig, env;
	                      phs = LFSaw.ar(freq, -1).range(0, 2pi);  // Tra 0 e 2pi (angolo giro)
	                      r   = MouseY.kr(0, 1);
	   // r = SinOsc.kr(MouseY.kr(0.5,4)).unipolar;         // KSig..
			              offph = MouseX.kr(0,pi);  // Defasaggio
	   // offph = SinOsc.kr(MouseX.kr(0.5,4)).range(0,pi);  // KSig...

	                      cx  = MouseX.kr(-1, 1.0);      // trasla l'origine di x
	                      cy  = MouseY.kr(-1, 1.0);      // trasla l'origine di y
	     x = r * cos(ratio[0]*phs)*cos(phs) + cx;                   // Orbita a fiore....
	     y = r * cos(ratio[1]*phs)*sin(phs) + cy;
		                  [x,y].scope;
	                      sig = Limiter.ar(f.value(x, y));
	                      env = Linen.kr(gate,doneAction:done);
	                      sig = LeakDC.ar(sig);
	                      sig = Pan2.ar(sig*env*amp,pan);
	                  Out.ar(0,sig)
}).add;
)

x.free;
