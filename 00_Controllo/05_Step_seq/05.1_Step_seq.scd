//=================================================================
// Step sequencer

(
s.boot;
s.scope;
s.freqscope;
{s.plotTree}.defer(2)
)

(
SynthDef.new(\pwm, {arg freq=400, amp=0,dty=0.5,dur=0.1,t_gate=0,pan=0,done=2;
	                   var sig,env;
	                       sig = Pulse.ar(freq, dty);
	                       env = Env.perc(0.1*dur,0.9*dur);
	                       env = EnvGen.kr(env,t_gate,doneAction:done);
	                       sig = Pan2.ar(sig*amp*env,pan);
	                   Out.ar(0,sig)
                    }).add;
)

//-----------------------------------------------------------------
// Non deterministico

(
r = {
	 Routine.new({
	             8.do({
			           Synth.new(\pwm, [\freq,[50,90].choose.midicps,
	                              \amp, rand(1.0),
	                              \dty, rrand(0.01, 0.5),
	                              \dur, 0.1,
	                              \pan, rand2(1.0),
	                              \t_gate,1]);
			            (1/6).wait;
	                   });
                  }).play
     };
u = {
	 Routine.new({
	             16.do({
		               Synth.new(\pwm, [\freq,100.midicps,
	                                 \amp, rand(1.0),
	                                 \dty, rrand(0.01, 0.5),
	                                 \dur, 0.02,
				                              \pan, [-1,1].choose,
	                                 \t_gate,1]);
			           (1/12).wait;
	                   });
                  }).play
     };
)

(
~score = Routine.new({
	                  inf.do({
		                      [r, u].wchoose([0.7,0.3]).value;
		                      1.wait;
	                          })
                      }).play
)

~score.stop;

//-----------------------------------------------------------------
// Deterministico

6 % 4;  // Operatore modulo

(
~bpm   = 60;
~metro = TempoClock.new(~bpm/60);
~voce1 = [1, 0, 0, 1, 1, 0, 0, 0];
~voce2 = [0, 1, 1, 0, 0, 1, 1, 0];
~voce3 = [0, 0, 0, 1, 0, 1, 0, 1];

d = Routine.new({
	             inf.do({arg id;
		       //           id = id % ~voce1.size;
			      //           id.postln;
			               Synth.new(\pwm, [\freq,100.midicps,
	                                  \amp, ~voce1.wrapAt(id),
	                                  \dty, rrand(0.01, 0.5),
				                               \dur, 0.5 * (60/~bpm),
				                               \pan, [-1, 1].choose,
	                                  \t_gate,1]);

					              Synth.new(\pwm, [\freq,80.midicps,
			                                 \amp, ~voce2.wrapAt(id),
	                                   \dty, rrand(0.01, 0.5),
	                                   \dur, 0.125 * (60/~bpm),
				                                \pan, 0,
	                                   \t_gate,1]);
		                 Synth.new(\pwm, [\freq,[50,54].choose.midicps,
			                                 \amp, ~voce3.wrapAt(id),
	                                   \dty, rrand(0.01, 0.5),
	                                   \dur, 0.25*(60/~bpm),
				                                \pan, 0,
	                                   \t_gate,1]);

		                    0.25.wait;
	                        });
	})
)

// Variazioni algoritmiche

(
~bpm   = 60;
~metro = TempoClock.new(~bpm/60);
~voce1 = [1, 0, 0, 1, 1, 0, 0, 0];
~voce2 = [0, 1, 1, 0, 0, 1, 1, 0];
~voce3 = [0, 0, 0, 1, 0, 1, 0, 1];
~score = Routine.new({
	                  inf.do({
                        d.stop;
		                      d.reset.play(~metro);
		                      10.wait;
		                      ~voce1.scramble.postln;
		                      ~voce2.scramble.postln;
		                      ~voce3.scramble.postln;
	                          })
                      }).play(~metro)
)

~score.stop; r.stop;
