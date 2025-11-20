//=================================================================
// Randomness

//-----------------------------------------------------------------
// Notazioni

rand(10); // Abstract function (Functional notation)
10.rand;  // Receiver notation

10.rand.postln; // Monitor numerico
//-----------------------------------------------------------------
// Generatori random lineari

rand(10);   // Riporta un numero pseudocasuale tra 0 e 9 (n-1)
rand(10.0); // tra 0 e 0.9999999999999

rrand(10,20);     // tra min e max
rrand(10.0,20.0);

rand2(10); // tra + e - n

[12,34,56,67].choose; // Sceglie tra gli items dell'array

a = 10000.collect({rand(1.0)});
a.plot(discrete:true);

//-----------------------------------------------------------------
// Generatori stocastici

0.9.coin; // 0.9 + probabile vero
          // 0.5 lineare
          // 0.1 + probabile falso

1.0.sum3rand; // Distribuzione quasi a campana
a = 10000.collect({1.0.sum3rand});
a.plot(discrete:true);


exprand(10,100); // Più probabilità verso il numero + basso
a = 10000.collect({exprand(10,100)});
a.plot(discrete:true);

gauss(0,3);  // centro , deviazione
a = 10000.collect({gauss(10,1)});
a.plot(discrete:true);

i = 0;
a = 10000.collect({i = i + rand2(1) }); // Random walk
a.plot(discrete:true);

[12,34,56,67].wchoose([0.6,0.1,0.1,0.2]); // Sceglie tra gli items dell'array
                                          // con probabilità

a = 10000.collect({[12,34,56,67].wchoose([0.6,0.1,0.1,0.2])});
a.plot(discrete:true);

//=================================================================
// Strutture di controllo

// Boolean:   true, false, nil

//-----------------------------------------------------------------
// if(test, {true}, {false});
// Tra due stati

if( rand(1.0) > 0.5, {"ciao"} );
if( rand(2) == 0, {"zero"}, {"uno"} );

// switch(val,
//        test1, {};
//        test2, {};
//        test3, {};
//        test4, {};
//        )

//-----------------------------------------------------------------
// Tra più stati (un solo valore di test)
// Come select e/o route di Max

i = 0;

(
switch( i,
	    0, {"cue_1".postln},
		1, {"cue_2".postln},
		2, {"cue_3".postln},
		3, {"cue_4".postln},
       );

i = i + 1;
)

//-----------------------------------------------------------------
// Tra più stati (diversi tipi di test)

// case
//     {test1} {}
//     {test2} {}
//     {test3} {}
//     {test4} {}

(
i = rand(10).postln;

case
{i > 5} {"maggiore di cinque".postln}
{i == 4} {"è quattro".postln}
{i < 5} {"minore di cinque".postln}
)
