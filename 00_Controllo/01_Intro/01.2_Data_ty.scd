//=================================================================
// Data type

//-----------------------------------------------------------------
// Literals

12    // Int
23.34 // Float
$a    // Char

"ciao ciao" // String
"c i a o    c i a o"
" 23  + 34" // String
23    + 34     // Numbers

'ciao ciao' // Symbols
\ciao

a // Identifier o etichette
{var ciccio; }

Server // Classe o UGen

true    // Boolean
false
nil

// 0   1     2          3
#[12, 23, "ciccio", \ammappaleo] // Literal array

//-----------------------------------------------------------------
// Parentesi
// Tonde --> 3 possibilità:

// 1) Definire un blocco di codice

(

// Blocco di codice
//

)

// 2) Definire ordine delle operazioni

12 + 3 * 5;
12 + 5 * 3;

(12 + 3) * 5;
12 + (3 * 5);

// 3) Definire argomenti di un metodo o messaggio o abstract function

rand(10);

// Quadre --> Sequenceable Collection

//    0   1   2   3     Indice sottinteso

   #[12, 23, 34, 45] // Literal Array
    [12, 23, 34, 45] // Array
List[12, 23, 34, 45] // Lista

// Graffe --> Function

a = 123;
a = 123 + 34;

a = {123 + 34};

a.value;

(
a = {arg a, b;
	     a + b};
)

//       a   b
a.value(12, 23);

//-----------------------------------------------------------------
// Variabili

// --------> Globali

a = 123;

// --------> Ambientali

~ciao = 123;
~
// --------> Locali

(
var ciao, miao;
     ciao = 123;
     miao = 12;

     ciao + miao
)

(
{var ciao, miao;
     ciao = 123;
     miao = 12;

     ciao + miao
}.value
)

(
a = {arg ciao=12, miao=23;
     ciao + miao}
)

a.value;
a.value(50,60);