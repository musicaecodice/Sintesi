//=================================================================
// Cicli

(
"ciao".postln;
"ciao".postln;
"ciao".postln;
"ciao".postln;
)

//-----------------------------------------------------------------
// Funzione (parentesi graffe)

a = {arg a,b; a+b};
a.value(2,5);

//-----------------------------------------------------------------
// Control structures --> Richiama l'Help

4.do({"ciao".postln});

a = {arg a,b; a+b};
a.value(2,5);

4.do( {arg i; (100*i).postln} );

//-----------------------------------------------------------------
// Routine o Task

(
r = Routine.new({
	             "ciao".postln;
	             1.wait;
	             "ciao".postln;
		         1.wait;
	             "ciao".postln;
			     1.wait;
                 })
)

r.next;

r.reset;
r.play;

r.reset.play;

(
r = Routine.new({

	          3.do({"ciao".postln;
	                 1.wait;
	                })

                 }).play
)

(
r = Routine.new({

	          inf.do({"ciao".postln;
	                 1.wait;
	                 })

                 }).play
)

r.stop;
r.reset.play;

// OKKIO se non mettete almeno 1 .wait in un
// loop infinito SC va in crash...

//-----------------------------------------------------------------
// Clocks

t = SystemClock  // Alta priorità
t = TempoClock.new(0.3) // Bps
t = AppClock     // Bassa priorità

(
r = Routine.new({

	           5.do({"ciao".postln;
	                 1.wait;
	                 })

                 }).play(t) // Clock come argomento
)

~bpm =82;
t = TempoClock.new(~bpm/60) // Bpm --> Bps

//-----------------------------------------------------------------
// Audio

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

(
SynthDef.new(\ciccio, {arg freq=400,amp=0,dur=1,t_gate=0,pan=0,done=2;
	                   var sig,env;
	                       sig = Saw.ar(freq);
	                       env = Env.perc(0.1*dur,0.9*dur);
	                       env = EnvGen.kr(env,t_gate,doneAction:done);
	                       sig = Pan2.ar(sig*amp*env,pan);
	                    Out.ar(0,sig)
             }).add
)

(
Synth(\ciccio, [\freq,678,
	            \amp,0.5,
	            \dur,0.5,
	            \pan,0,
	            \t_gate,1]);
)

(
~bpm = 160;
~beat = 60/~bpm;

r = Routine.new({

	           5.do({
		             Synth(\ciccio, [\freq,678,
	                                 \amp,0.5,
	                                 \dur,0.5*~beat,
	                                 \pan,0,
	                                 \t_gate,1]);
	                 1.wait;
	                 })

                 }).play(TempoClock.new(~bpm/60))
)

5.do({arg i; i.postln})    // su integer --> 1 argomento

(
[45,56,67].do({arg item,id;      // su Array --> 2 argomenti
	           [id,item].postln
               })
)

(
//         0    1    2
~pitch = [60, 65, 96].midicps;
~amps  = [0.1, 0.5,   1];
~durs  = [1, 0.5,   0.1];
~pan   = [-1, 0,      1];

//~pitch.size;
//~pitch.at(3);

r = Routine.new({

	           ~pitch.size.do({arg i;
		             Synth(\ciccio, [\freq,~pitch.at(i),
	                                 \amp,~amps.at(i),
	                                 \dur,~durs.at(i),
	                                 \pan,~pan.at(i),
	                                 \t_gate,1]);
	                 1.wait;
	                 })

                 }).play
)


(
r = Routine.new({

	           inf.do({arg i;
		Synth(\ciccio, [\freq,rrand(400,1800),
	                                 \amp,rand(1.0),
	                                 \dur,rrand(0.01,1),
	                                 \pan,rand2(1.0),
	                                 \t_gate,1]);
	                 0.1.wait;
	                 })

                 }).play
)