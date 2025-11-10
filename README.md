# The language
The language on which the compiler works is a psuedo-code that implements all the constructs of structured programming: sequence, selection, iteration. The language has four different data types: Intero (equals to *int* of C), Reale (equals to *double* of C), Carattere (equals to *char* of C), and Stringa (equals to an array of *char* of C), furthermore it doesn't support any type of structured data type.

## BNF of the grammar
```
<statements> ::= <statement> "\n" | <statement> "\n" <statements>

<statement> ::= <type> <id> | <id> " <- " <val> | <io> | "MENTRE " <conditions> " ALLORA <!\n" <statements> "!>" | "SE " <conditions> " ALLORA <!\n" <statements> "!> " <else> |

<else> ::= "ALTRIMENTI <!\n" <statements> "!>" |

<conditions> ::= <condition> <logicop> <conditions> | <condition>

<condition> ::= <val> <compare> <val>

<operation> ::= <mathop> <val> <val>

<io> ::= "LEGGI -> " <id> | "STAMPA <- " <val>

<val> ::= <id> | <value> | <operation>

<id> ::= [a-zA-Z][_a-zA-Z0-9]*

<type> ::= "Intero" | "Reale" | "Carattere" | "Stringa"

<value> ::= 0|-?[1-9][0-9]* | (0|-?[1-9][0-9]*)\.?[0-9]* | ['].['] | ["][^"]*["] 

<compare> ::= "<" | "<=" | ">" | ">=" | "=" | "!="

<mathop> ::= "+" | "-" | "*" | "/" | "%"

<logicop> ::= "AND" | "OR"
```

### Code example
```
Intero a
Intero b
Intero r
LEGGI -> a
LEGGI -> b
SE a < b ALLORA <!
	r <- a
	a <- b
	b <- r
!>
MENTRE b != 0 ALLORA <!
	r <- % a b
	a <- b
	b <- r
!>
STAMPA <- "The GCD is "
STAMPA <- a
STAMPA <- "\n"
```

## Functioning

### MENTRE
```
MENTRE <condition> ALLORA <!
	[block]
!>
```
The construct is the equivalent of a preconditioned while, where the condition is at first evaluated and if it's true the block is executed.

### SE-ALTRIMENTI
```
SE <condition> ALLORA <!
	[true block]
!> ALTRIMENTI <!
	[false block]
!>
```
The construct is the equivalent of an if-then-else, it can be used also an if-then, by not writing "ALTRIMENTI".

### I/O
```
LEGGI -> <id>
STAMPA <- <val>
```
The input is given with the keyword "LEGGI", while the output with "STAMPA", which permits the concatenation with the operator +, only between Stringa and Carattere:
```
Stringa a
Stringa b
LEGGI -> a
LEGGI -> b
STAMPA <- + a b
```

### Conditions
In the conditions of MENTRE and SE constructs, more conditions can be concatenated with the logical operator AND and OR. It is not possible to establish a priority with parenthesis, so the evaluation is done in short-circuit from left to right.
```
MENTRE a < 0 AND continue = 1 <!
	[blocco]
!>
```
The comparing operators available are: <, <=, >, >=, =, !=.

### Arithmetical operators
The arithmetical operators use on Intero, Reale or Carattere have the classic functioning:
- \+ : sum;
- \- : difference;
- \* : product;
- / : division;
- % : module;

If these are use on Stringa, they have the following behavior:
- \+ : concatenation
```
+ <val>.Carattere/<val>.Stringa <val>.Carattere/<val>.Stringa
```
- \- : it returns the Stringa with n chars removed from right
```
- <val>.Stringa <val>.Intero
```
- \* : it returns the char in the specified position, if the index is not valid, it returns 0
```
* <val>.Stringa <val>.Intero
```
- / : it returns the Stringa with n chars removed from left
```
/ <val>.Stringa <val>.Intero
```
- % : it returns 1 if the Stringa or Carattere given is a substring
```
% <val>.Stringa <val>.Carattere/<val>.Stringa
```

### Types compatibility

#### Assignments
The valid assignments, considering the first as the left value and the second as the right, are:
- Intero: Intero, Reale, Carattere;
- Reale: Intero, Reale, Carattere;
- Carattere: Intero, Reale, Carattere;
- Stringa: Carattere, Stringa.

#### Comparisons
The valid comparisons, considering the first as the left value and the second as the right, are:
- Intero: Intero, Reale, Carattere;
- Reale: Intero, Reale, Carattere;
- Carattere: Intero, Reale, Carattere;
- Stringa: Stringa.

#### Operations
The operations define the final data type of the expressions, so, considering the cases where the data types are different:
- Intero-Carattere: evaluated as Intero;
- Reale-Intero/Carattere : evaluated as Reale;
- Stringa-Carattere: evaluated as Stringa in case of +, in case of % as Intero;
- Stringa-Intero: evaluated as Stringa in case of \*, as Stringa in case of - or /. 
