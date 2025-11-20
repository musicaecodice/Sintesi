// --------------------------
// Elementi principali della finestra

w = Window.new("CiaoCiao",         // Nome che compare sulla barra in alto
               Rect(0,0,300,110)); // Posizione e size in pixels

w.front;                           // la fa comparire
w.alwaysOnTop_(true);              // la fa sempre stare davanti alle altre finestre sullo schermo
w.onClose_( {w.free} );

w.name_("urca");          // Cambiare il titolo
w.background_(Color.red); // Vedere l'help file di Color
w.alpha_(rand(1.0));      // Indice di trasparenza tra 0.0 e 1.0



(
w = Window.new("CiaoCiao", Rect(0,0,300,300));
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;h.free;n.free;k.free;b.free;p.free;d.free;t.free;z.free});

h = Slider.new(w, Rect(5,5,50,100));            // Crea uno slider x = 0 = sinistra / y = 0 = alto (in pixels)
n = NumberBox.new(w, Rect(65,5, 50,20));        // Crea un number box
k = Knob.new(w, Rect(65,30, 75,75));            // Crea un knob
b = Button.new(w, Rect(120,5, 50,20));          // Crea un number box
p = PopUpMenu.new(w, Rect(175,5, 100,20));      // Crea un pop up menu
d = Slider2D.new(w, Rect(145,30, 75,75));       // Crea un interfaccia XY
t = StaticText.new(w, Rect(225,30, 75,75));     // Crea un testo
z = MultiSliderView.new(w,Rect(5,110, 290,75)); // Crea un multislider
)

(
w = Window.new("Slider", Rect.new(0,0,265,210));
h = Slider.new(w, Rect(5,5,50,200));
w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;h.free});

//h.action_( {"ciao".postln} );  // Recupera valore
h.action_( {h.value.postln} );  // Recupera valore
)

// ---------------------------------------
// Ricevere valori

(
s.boot;
s.scope(1);
s.plotTree;

SynthDef(\slider, {arg amp=0;
	                  var sig;
                       sig = SinOsc.ar * amp.lag(0.2);
	                  Out.ar(0,sig)
}).add;

w = Window.new("Slider", Rect.new(0,0,60,210));
h = Slider.new(w, Rect(5,5,50,200));

w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;h.free;u.free});

h.action_({var val;           // Assegna il valore a una variabile
               val = h.value; // per poterlo riutilizzare nel codice
	              val.postln;
	          u.set(\amp, val)   // Invia il valore al Server
           });

{ u = Synth(\slider) }.defer(1);
)

// ---------------------------------------
// Inviare valori

h.value_( rand(1.0) ); // Singolo valore

(
r = Routine.new({    // Sequencing
	         inf.do({
		         h.value_(rand(1.0));
		         0.1.wait
                         })
                 }).reset.play;
)

(
r = Routine.new({    // Sequencing
	         inf.do({
		         h.value_(rand(1.0));
		         0.1.wait
                         })
                 }).reset.play(AppClock);
)

(
r = Routine.new({
	         inf.do({
		         { h.value_(rand(1.0)) }.defer;
		         0.1.wait
                         })
                 }).reset.play;
)

r.stop;

// ---------------------------------------
// Inviare e ricevere valori

h.action_({h.value.postln}); // Recupera il valore

h.valueAction_(rand(1.0));   // Invia il valore

(                            // Sequencing
r = Routine.new({
	         inf.do({
		         {h.valueAction_(rand(1.0))}.defer;
		         0.1.wait
                         })
                 }).reset.play;
)

r.stop;

// Provare ad interagire con il mouse sullo Slider...

// ---------------------------------------

(
w = Window.new("Slider", Rect.new(0,0,265,210));
h = Slider.new(w, Rect(5,5,50,200));
v = Slider.new(w, Rect(60,155,200,50));

w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;h.free});
)

h.orientation_(\horizontal); // Direzione leva
h.orientation_(\vertical);
h.knobColor_(Color.rand);    // Colore leva
h.background_(Color.rand);   // Colore sfondo


h.action_({h.value.postln}); // Recupera il valore



(
s.boot;
s.meter(2);
s.plotTree;

// ------------------------------ SynthDef

SynthDef(\sig, {var sig;
	            sig = SinOsc.ar(2).unipolar; // tra 0 e 1

// ------------------------------ Server --> Interprete

		SendReply.kr(Impulse.kr(50),  // rata di campionamento
		             '/pos',          // indirizzo o nome
		             sig);            // segnale da campionare

            //  Out.ar(0,sig)
               }).add;

{a = Synth(\sig)}.defer(0.1);

// ------------------------------ dal Server

OSCFunc.new({arg msg;
	     var val;
	         val = msg[3];      // recupera il valore
	     {h.value_(val)}.defer; // invia allo Slider
             },
             '/pos',                // indirizzo o nome
	     s.addr);               // eventuale NetAddr)

// ------------------------------ GUI

w = Window.new("Slider", Rect.new(0,0,60,210));
h = Slider.new(w, Rect(5,5,50,200));

w.front;
w.alwaysOnTop_(true);
w.onClose_({w.free;h.free;a.free});
)

(
s.boot;
s.meter(2,2);
s.plotTree;
s.freeAllBuffers;

f = Buffer.alloc(s,1024,1);                  // Crea un Buffer
w = Window.new("Slider", Rect(0,0,470,210)); // Crea una Window
h = Slider.new(w, Rect(5,5,50,200));         // Crea uno Slider
c = ScopeView.new(w, Rect(60,5,400,200));    // Crea uno ScopeWiew

c.bufnum = f.bufnum;      // Assegna il Buffer
c.server_(s);             // Assegna il Server
c.start;                  // Fa partire la visualizzazione

w.front;
w.alwaysOnTop_(true);
w.onClose_({f.free;w.free;h.free;c.free;a.free});

h.action_({a.set(\amp,h.value)}); // Recupera il valore e lo invia al Synth

SynthDef(\sig, {arg amp=0;
	        var sig, toScope;
	            sig     = BrownNoise.ar*amp.lag(0.02);
	            toScope = ScopeOut2.ar(sig, f); // Scrive nel Buffer
	        Out.ar(0,sig)                           // Ouput audio
               }).add;

{a = Synth(\sig)}.defer(0.3);
)

h.valueAction_(rand(1.0)); // Invia il valore ed esegue l'azione