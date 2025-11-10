%{
	#include <string.h>
	#include "y.tab.h"
	int countln=1;              /* It takes track of the line number */
%}

%%

"Intero"                        { yylval.nd_obj.name = strdup(yytext); return INTERO; }
"Reale"                         { yylval.nd_obj.name = strdup(yytext); return REALE; }
"Carattere"                     { yylval.nd_obj.name = strdup(yytext); return CARATTERE; }
"Stringa"                       { yylval.nd_obj.name = strdup(yytext); return STRINGA; }
"LEGGI"                         { yylval.nd_obj.name = strdup(yytext); return READ; }
"STAMPA"                        { yylval.nd_obj.name = strdup(yytext); return WRITE; }
"<"                             { yylval.nd_obj.name = strdup(yytext); return LESS; }
"<="                            { yylval.nd_obj.name = strdup(yytext); return LEQ; }
">"                             { yylval.nd_obj.name = strdup(yytext); return GRTR; }
">="                            { yylval.nd_obj.name = strdup(yytext); return GEQ; }
"!="                            { yylval.nd_obj.name = strdup(yytext); return NEQ; }
"="                             { yylval.nd_obj.name = strdup(yytext); return EQUALS; }
"+"                             { yylval.nd_obj.name = strdup(yytext); return ADD; }
"-"                             { yylval.nd_obj.name = strdup(yytext); return SUB; }
"*"                             { yylval.nd_obj.name = strdup(yytext); return MUL; }
"/"                             { yylval.nd_obj.name = strdup(yytext); return DIV; }
"%"                             { yylval.nd_obj.name = strdup(yytext); return MOD; }
"AND"                           { yylval.nd_obj.name = strdup(yytext); return AND; }
"OR"                            { yylval.nd_obj.name = strdup(yytext); return OR; }
"SE"                            { yylval.nd_obj.name = strdup(yytext); return SE; }
"ALLORA"                        { yylval.nd_obj.name = strdup(yytext); return ALLORA; }
"ALTRIMENTI"                    { yylval.nd_obj.name = strdup(yytext); return ALTRIMENTI; }
"MENTRE"                        { yylval.nd_obj.name = strdup(yytext); return MENTRE; }
"<!"                            { yylval.nd_obj.name = strdup(yytext); return LEFTBRKT; }
"!>"                            { yylval.nd_obj.name = strdup(yytext); return RIGHTBRKT; }
"<-"                            { yylval.nd_obj.name = strdup(yytext); return LEFT; }
"->"                            { yylval.nd_obj.name = strdup(yytext); return RIGHT; }
[_].*                           { return NEWLINE; }
[\n][_].*                       { countln++; return NEWLINE; }
([\t]*[_].*)                    { return NEWLINE; }
[\n]([\t]*[_].*)                { countln++; return NEWLINE; }
[\n]                            { countln++; return NEWLINE; }
[ \t]                           { ; }

[a-zA-Z][_a-zA-Z0-9]*           { yylval.nd_obj.name = strdup(yytext); return ID; }
0|-?[1-9][0-9]*                 { yylval.nd_obj.name = strdup(yytext); return NUMINT; }
(0|-?[1-9][0-9]*)\.?[0-9]*      { yylval.nd_obj.name = strdup(yytext); return NUMDBL; }
['].[']                         { yylval.nd_obj.name = strdup(yytext); return CHAR; }
["][^"]*["]                     { yylval.nd_obj.name = strdup(yytext); return TEXT; }

%%

int yywrap() { return 1; }
