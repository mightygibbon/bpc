%{
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>


    /* Datatype for symbol description */
    struct symbol {
        char * id_name;
        char * data_type;
        int line;
    };
    
    /* Datatype for symbol table handling */
    struct table_elem {
    	struct symbol row;
    	struct table_elem *next;
    };
	
    /* Datatype for parse tree nodes */
	struct node {
	  	struct node *left;
	  	struct node *right;
	  	char *token;
		char typenode[10];	/* NULL if is a variable */
    };
    
	
    static void yyerror(const char * msg);
	static void add_error(char *);
    static void save_type(void);
    static int search(char *);
	static void insert_row(struct table_elem *);
    static void add(void);
	static struct node * mknode(struct node *, struct node *, char *);
	static int check_declaration(char *);
	static int compare_types(char *, char *);
	static char * get_type(char *);
	static int check_assignment(char *, char *);
	static int check_compare(char *, char *);
	static int get_convtype(char *);
	static char * get_val(struct node *);
	static char * get_condition(struct node *);
	static char * get_conditions(struct node *);
	static char * get_declaration(struct node *);
	static char * get_assignment(struct node *);
	static char * get_while(struct node *);
	static char * get_if_else(struct node *);
	static char * get_io(struct node *);
	static char * get_statement(struct node *);
	static char * generate_code(struct node *);
	static void return_tree(struct node *, int);
	static void free_table(void);
	static void free_tree(struct node *);
	
    void free_all(void);
	void get_table(void);
    void get_tree(void);
	void get_code(FILE *);
	void get_errors(void);
	int yylex(void);


    extern int countln;                                     /* Variable for line number defined in lexer.l */
	extern char * yytext;
	
    static struct table_elem *first, *last, *selected;		/* Symbol table pointers */
	static struct node * head = NULL;						/* Head of the parse tree */
    static char type[10];             						/* Temp buffer for datatype setting */
	static char ** errors = NULL;
	static char * includes = "#include <stdio.h>\n#include <string.h>\n#include <stdlib.h>\n\n";
	static char * cts = "char * charToStr(char c) {char *temp = (char *) malloc (sizeof(char)); temp[0]=c; return temp;}\n";
	static char * cnct = "char * concat(char *dest, char *src) {char *temp; temp = strdup(dest); strcat(temp, src); return temp;}\n";
	static char * sbstr = "int isSubstr(char *str, char *substr) { if(strstr(str,substr)==NULL) return 0; else return 1; }\n";
	static char * gcn = "char getCharN(char *str, int n) {if(n<strlen(str)) return str[n]; else return 0; }\n";
	static char * dnc = "char *delNChar(char *str, int n, int s) { switch(s) { case 0: { if(n>=strlen(str)) { return strdup(\"\"); } else { char temp[strlen(str)-n+1]; for(int i=0; i<strlen(str); i++) { temp[i] = str[n+i]; } temp[strlen(str)+1]=0; return strdup(temp); } break; } case 1: { if(n>=strlen(str)) { return strdup(\"\"); } else { char temp[strlen(str)-n+1]; for(int i=0; i<strlen(str)-n; i++) { temp[i] = str[i]; } temp[strlen(str)-n+1]=0; return strdup(temp); } break; } } }\n";
	static char * getStr = "char * getStringa() { char temp[BUFSIZ]; scanf(\"%s\", temp); getchar(); return strdup(temp); }\n";
	static char * mn = "\nint main(){\n";
    
    int err_num = 0;
%}

%union { 
	struct { 
		char *name; 
		struct node* nd;
	} nd_obj;
} 

%token <nd_obj> INTERO REALE CARATTERE STRINGA READ WRITE LESS LEQ GRTR GEQ NEQ EQUALS ADD SUB MUL DIV MOD AND OR SE ALLORA ALTRIMENTI MENTRE LEFTBRKT RIGHTBRKT LEFT RIGHT ID NUMINT NUMDBL CHAR TEXT NEWLINE
 
%type <nd_obj> statements statement else conditions condition io type compare mathop logicop val value operation

%%

statements:		statement NEWLINE        		{ $$.nd = $1.nd; }
			| 	statement NEWLINE statements    { $$.nd = mknode($1.nd, $3.nd, "STATEMENTS"); head = $$.nd; }
    		;

statement:		type ID    				{
					add(); 
					$2.nd = mknode(NULL, NULL, $2.name); 
					$$.nd = mknode($1.nd, $2.nd, "DICHIARAZIONE");
				}    							
         	| 	ID LEFT val     			{
					int result_check;
					char temp_error[BUFSIZ], *typeRvalue;
					$1.nd = mknode(NULL, NULL, $1.name); 
					$$.nd = mknode($1.nd, $3.nd, "ASSEGNAMENTO");
					if (check_declaration($1.name)) {
						typeRvalue = (get_type($3.name) == NULL) ? $3.nd->typenode : get_type($3.name);
						result_check = check_assignment(get_type($1.name), typeRvalue);
						/* Check if datatypes of the assignment are compatible */
                        switch (result_check) {
							case -1: {
								sprintf(temp_error, "Line %d: Incompatible assignment Intero <- Stringa\n", countln);
								break;	
							}
							case -2: {
								sprintf(temp_error, "Line %d: Incompatible assignment Reale <- Stringa\n", countln);
								break;	
							}
							case -3: {
								sprintf(temp_error, "Line %d: Incompatible assignment Carattere <- Stringa\n", countln);
								break;	
							}
							case -4: {
								sprintf(temp_error, "Line %d: Incompatible assignment Stringa <- Intero\n", countln);
								break;	
							}
							case -5: {
								sprintf(temp_error, "Line %d: Incompatible assignment Stringa <- Reale\n", countln);
								break;	
							}
						}
						if (result_check<0) {
							add_error(temp_error);
						}
					}
				}						
         	| 	io     					{ $$.nd = $1.nd; }				
         	| 	MENTRE conditions ALLORA LEFTBRKT NEWLINE statements RIGHTBRKT   	{
					$$.nd = mknode($2.nd, $6.nd, $1.name);
				}  	
         	| 	SE conditions ALLORA LEFTBRKT NEWLINE statements RIGHTBRKT else	{
					struct node *se = mknode($2.nd, $6.nd, $1.name); 
					$$.nd = mknode(se, $8.nd, "SE-ALTRIMENTI");
				}
			|	{ $$.nd = NULL; }
         	;

else: 		ALTRIMENTI LEFTBRKT NEWLINE statements RIGHTBRKT	{
				$$.nd = mknode(NULL, $4.nd, $1.name);
			}	
    	| 	{ $$.nd = NULL; }			 	
    	;

conditions: 	condition logicop conditions    { $$.nd = mknode($1.nd, $3.nd, $2.name); }
			| 	condition                    	{ $$.nd = $1.nd; }    
          	;

condition: 		val compare val     	{ 
					int result_check;
					char temp_error[BUFSIZ], *typeLvalue, *typeRvalue;
					$$.nd = mknode($1.nd, $3.nd, $2.name);
					typeLvalue = (get_type($1.name) == NULL) ? $1.nd->typenode : get_type($1.name);
					typeRvalue = (get_type($3.name) == NULL) ? $3.nd->typenode : get_type($3.name);
					result_check = check_compare(typeLvalue, typeRvalue);
                    /* Check if datatypes of the condition are compatible */
					switch (result_check) {
						case -1: {
							sprintf(temp_error, "Line %d: Incompatible comparison between Intero and Stringa\n", countln);
							break;
						}
						case -2: {
							sprintf(temp_error, "Line %d: Incompatible comparison between Reale and Stringa\n", countln);
							break;
						}
						case -3: {
							sprintf(temp_error, "Line %d: Incompatible comparison between Carattere and Stringa\n", countln);
							break;
						}
						case -4: {
							sprintf(temp_error, "Line %d: Incompatible comparison between Stringa and Intero\n", countln);
							break;
						}
						case -5: {
							sprintf(temp_error, "Line %d: Incompatible comparison between Stringa and Reale\n", countln);
							break;
						}
						case -6: {
							sprintf(temp_error, "Line %d: Incompatible comparison between Stringa and Carattere\n", countln);
							break;
						}
					}
					if (result_check<0) {
						add_error(temp_error);
					}
				}           
         	;
		 
operation: 	mathop val val		{
				char temp_error[BUFSIZ], *typeLvalue, *typeRvalue;
				temp_error[0]=0;
				$$.nd = mknode($2.nd, $3.nd, $1.name);
				typeLvalue = (get_type($2.name) == NULL) ? $2.nd->typenode : get_type($2.name);
				typeRvalue = (get_type($3.name) == NULL) ? $3.nd->typenode : get_type($3.name);
                /* Check if datatypes are compatible, if so assign it to the operation */
				switch (compare_types(typeLvalue, typeRvalue)) {
					case 0: {
						if (strcmp(typeLvalue, "Stringa")) {
							strcpy($$.nd->typenode, typeLvalue);
						}
						else {
							if (!strcmp($1.name, "+")) strcpy($$.nd->typenode, "Stringa");
							else if (!strcmp($1.name, "%")) strcpy($$.nd->typenode, "Intero");
							else sprintf(temp_error, "Line %d: Invalid operand in operation %s %s %s, %s must be a Intero or Reale\n", 
                                            countln, $1.name, get_val($2.nd), get_val($3.nd), get_val($3.nd));
                        }
						break;	
					}
					case 1: {
						strcpy($$.nd->typenode, "Intero");
						break;	
					}
					case 2: {
						strcpy($$.nd->typenode, "Reale");
						break;	
					}
					case 3: {
						if (!strcmp($1.name, "+")) strcpy($$.nd->typenode, "Stringa");
						else if (!strcmp($1.name, "%")) strcpy($$.nd->typenode, "Intero");
						else sprintf(temp_error, "Line %d: Invalid operand in operation %s %s %s, %s must be a Intero or Reale\n", 
                                        countln, $1.name, get_val($2.nd), get_val($3.nd), get_val($3.nd));
						break;	
					}
					case 4: {
						if (!strcmp($1.name, "*")) strcpy($$.nd->typenode, "Carattere");
						else if (!strcmp($1.name, "-") || !strcmp($1.name, "/")) strcpy($$.nd->typenode, "Stringa");
						else sprintf(temp_error, "Line %d: Invalid operand in operation %s %s %s, %s must be a Stringa or Carattere\n", 
                                        countln, $1.name, get_val($2.nd), get_val($3.nd), get_val($3.nd));
						break;
					}
					case -1: {
						sprintf(temp_error, "Line %d: Incompatible types Intero and Stringa\n", countln);
						break;	
					}
					case -2: {
						sprintf(temp_error, "Line %d: Incompatible types Reale and Stringa\n", countln);
						break;	
					}
				}
				if(temp_error[0]) {
					add_error(temp_error);
				}
			}
         	;

io: 	READ RIGHT ID    			{ 
			if (check_declaration($3.name)) {
				$1.nd = mknode(NULL, NULL, $1.name); 
				$3.nd = mknode(NULL, NULL, $3.name); 
				$$.nd = mknode($1.nd, $3.nd, "I/O");
			}
		}
  	| 	WRITE LEFT val    			{ 
			if ($3.nd != NULL) {
				$1.nd = mknode(NULL, NULL, $1.name);
				$$.nd = mknode($1.nd, $3.nd, "I/O");
			}
  		}
  	;
		  
val:	ID				{ 
			if (check_declaration($1.name)) {
				$$.nd = mknode(NULL, NULL, $1.name);
			}
			else {
				$$.nd = NULL;
			}
		} 
	| 	value 			{ $$.nd = $1.nd; }
   	| 	operation		{ $$.nd = $1.nd; }
   	;

type: 	INTERO    		{ save_type(); $$.nd = mknode(NULL, NULL, $1.name); }
	| 	REALE    		{ save_type(); $$.nd = mknode(NULL, NULL, $1.name); }
    | 	CARATTERE    	{ save_type(); $$.nd = mknode(NULL, NULL, $1.name); }
    | 	STRINGA    		{ save_type(); $$.nd = mknode(NULL, NULL, $1.name); }
    ;

value: 		NUMINT    	{ strcpy($$.name, $1.name); $$.nd = mknode(NULL, NULL, $1.name); strcpy($$.nd->typenode, "Intero"); }
     	| 	NUMDBL     	{ strcpy($$.name, $1.name); $$.nd = mknode(NULL, NULL, $1.name); strcpy($$.nd->typenode, "Reale"); }   	
     	| 	CHAR       	{ strcpy($$.name, $1.name); $$.nd = mknode(NULL, NULL, $1.name); strcpy($$.nd->typenode, "Carattere"); } 	
     	| 	TEXT     	{ strcpy($$.name, $1.name); $$.nd = mknode(NULL, NULL, $1.name); strcpy($$.nd->typenode, "Stringa"); }   	
     	;

compare:	LESS    	
		|	LEQ    	
       	| 	GRTR    	
       	| 	GEQ    	
       	| 	EQUALS    	
       	| 	NEQ    	
       	;

mathop: 	ADD    	
      	| 	SUB    	
      	| 	MUL    	
      	| 	DIV    	
      	| 	MOD    	
      	;

logicop: 	AND    	
       	| 	OR	
       	;

%%

/* Function called by default by lex/yacc when a syntax error occurs */
static void yyerror(const char* msg) {
	char temp_error[BUFSIZ];
	sprintf(temp_error, "Line %d: %s\n", countln, msg);
	add_error(temp_error);
}

static void add_error(char * s) {
	errors = (char **) realloc(errors, (err_num+1)*sizeof(char *));
	errors[err_num++] = strdup(s);
}

/* Saves datatype of the last initialized variable */
static void save_type(void) {
    strcpy(type, yytext);
}

/* Tests if the variable was already declared */
static int search(char * id) {
	int res=0;
    for (selected=first; selected!=NULL; selected=selected->next) {
        if (!strcmp(selected->row.id_name, id)) {   
            res=1;
        } else if (selected->next == NULL) {
            last = selected;
        }
    }
    return res;
}

/* Inserts a row in the symbol table */
static void insert_row(struct table_elem * elem) {
	elem->row.id_name = strdup(yytext);
	elem->row.data_type = strdup(type);
	elem->row.line = countln;
}

/* Inserts a variable in the symbol table */
static void add(void) {
	char temp_error[BUFSIZ];
    if (first != NULL) {
		if (!(search(yytext))) {
			selected = last;
			selected->next = (struct table_elem *) malloc (sizeof(struct table_elem));
			selected = selected->next;
			insert_row(selected);
		} else {
			sprintf(temp_error, "Line %d: Multiple declarations of \"%s\"\n", countln, yytext);
			add_error(temp_error);
		}
    } else {
		first = (struct table_elem *) malloc (sizeof(struct table_elem));
		insert_row(first);
	}
}

/* Initializes the nod of nd_obj */
static struct node * mknode(struct node * l, struct node * r, char * t) {
	struct node *newnode = (struct node *) malloc(sizeof(struct node));
	newnode->left = l;
	newnode->right = r;
	newnode->token = strdup(t);
	return newnode;
}

/* Checks if a variable was declared before usage, generating an error if not */
static int check_declaration(char * c) {
    int res=1;
	if (!(search(c))) {
		char temp[BUFSIZ];
		errors = (char **) realloc(errors, (err_num+1)*sizeof(char *));
		sprintf(temp, "Line %d: Variable \"%s\" not declared before usage\n", countln, c);
		errors[err_num++] = strdup(temp);
		res=0;
	}
	return res;
}

/* Analyzes the datatypes of the operands to understand which casting to perform */
static int compare_types(char * type1, char * type2) {
	int res=0;	/* if it remains unchanged, then the two datatypes are the same */
	if ((!strcmp(type1, "Intero") && !strcmp(type2, "Carattere")) || (!strcmp(type1, "Carattere") && !strcmp(type2, "Intero"))) res=1;
	else if ((!strcmp(type1, "Reale") && (!strcmp(type2, "Intero") || !strcmp(type2, "Carattere"))) || (!strcmp(type2, "Reale") && (!strcmp(type1, "Intero") || !strcmp(type1, "Carattere")))) res=2;
	else if ((!strcmp(type1, type2) && !strcmp(type1, "Carattere")) || (!strcmp(type1, "Stringa") && !strcmp(type2, "Carattere")) || (!strcmp(type1, "Carattere") && !strcmp(type2, "Stringa"))) res=3;
	else if ((!strcmp(type1, "Stringa") && !strcmp(type2, "Intero")) || (!strcmp(type1, "Stringa") && !strcmp(type2, "Reale"))) res=4;
	else if ((!strcmp(type1, "Intero") && !strcmp(type2, "Stringa"))) res=-1;
	else if ((!strcmp(type1, "Reale") && !strcmp(type2, "Stringa"))) res=-2;
	return res;
}

/* Returns the datatype of the variable */
static char * get_type(char * var) {
	char *res=NULL;
	for (selected = first; selected != NULL; selected = selected->next) {
        if (!strcmp(selected->row.id_name, var)) {   
            res = selected->row.data_type;
        }
    }
	return res;	
}

/* Checks if the assignment is possible givent the datatype on the left and the one on the right */
static int check_assignment(char * ltype, char * rtype) {
	int res=0;	/* if it remains unchanged, then the two datatypes are the same */
    if (!strcmp(ltype, "Intero")) {
		if (!strcmp(rtype, "Reale")) res=1;
		else if (!strcmp(rtype, "Carattere")) res=2;
		else if (!strcmp(rtype, "Stringa")) res=-1;
	} else if (!strcmp(ltype, "Reale")) {
		if (!strcmp(rtype, "Intero")) res=3;
		else if (!strcmp(rtype, "Carattere")) res=4;
		else if (!strcmp(rtype, "Stringa")) res=-2;
	} else if (!strcmp(ltype, "Carattere")) {
		if (!strcmp(rtype, "Intero")) res=5;
		else if (!strcmp(rtype, "Reale")) res=6;
		else if (!strcmp(rtype, "Stringa")) res=-3;
	} else if (!strcmp(ltype, "Stringa")) {
		if (!strcmp(rtype, "Intero")) res=-4;
		else if (!strcmp(rtype, "Reale")) res=-5;
		else if (!strcmp(rtype, "Carattere")) res=7;
	}
	return res;
}

/* Checks if the comparison can be done given the datatype on the left and the one on the right */
static int check_compare(char * ltype, char * rtype) {
	int res=0;	/* if it remains unchanged, then the two datatypes are the same */
	if (!strcmp(ltype, "Intero")) {
		if (!strcmp(rtype, "Reale")) res=1;
		else if (!strcmp(rtype, "Carattere")) res=2;
		else if (!strcmp(rtype, "Stringa")) res=-1;
	} else if (!strcmp(ltype, "Reale")) {
		if (!strcmp(rtype, "Intero")) res=3;
		else if (!strcmp(rtype, "Carattere")) res=4;
		else if (!strcmp(rtype, "Stringa")) res=-2;
	} else if (!strcmp(ltype, "Carattere")) {
		if (!strcmp(rtype, "Intero")) res=5;
		else if (!strcmp(rtype, "Reale")) res=6;
		else if (!strcmp(rtype, "Stringa")) res=-3;
	} else if (!strcmp(ltype, "Stringa")) {
		if (!strcmp(rtype, "Intero")) res=-4;
		else if (!strcmp(rtype, "Reale")) res=-5;
		else if (!strcmp(rtype, "Carattere")) res=-6;
	}
	return res;
}

/* Returns the converted type in C given the one of BPC */
static int get_convtype(char * type) {
	int res;
	if (!strcmp(type, "Intero")) res=0;
	else if (!strcmp(type, "Reale")) res=1;
	else if (!strcmp(type, "Carattere")) res=2;
	else if (!strcmp(type, "Stringa")) res=3;
	return res;
}

/* Returns val converted in C */
static char * get_val(struct node * n) {
	char *val, *Lval, *Rval, *typeLvalue, *typeRvalue, convtype[7];
	if (n->left==NULL && n->right==NULL) {
		val = (char *) malloc (strlen(n->token)+1);
		sprintf(val, "%s", n->token);
	} else {
		typeLvalue = (get_type(n->left->token) == NULL) ? n->left->typenode : get_type(n->left->token);
		typeRvalue = (get_type(n->right->token) == NULL) ? n->right->typenode : get_type(n->right->token);
		Lval = get_val(n->left);
		Rval = get_val(n->right);
		switch (get_convtype(n->typenode)) {
			case 0: {
				strcpy(convtype, "int");
				break;
			}
			case 1: {
				strcpy(convtype, "double");
				break;
			}
			case 2: {
				strcpy(convtype, "char");
				break;
			}
			case 3: {
				strcpy(convtype, "char *");
				break;
			}
		}
		switch (compare_types(typeLvalue, typeRvalue)) {
			case 1:
			case 2: {
				val = (char *) malloc (24+strlen(Lval)+strlen(Rval));
				sprintf(val, "((%s)%s %s (%s)%s)", convtype, Lval, n->token, convtype, Rval);
				break;
			}
			case 3: {
				if(!strcmp(typeLvalue, "Stringa")) {
					if (!strcmp(n->token, "+")) {
						val = (char *) malloc (30+strlen(Lval)+strlen(Rval));
						sprintf(val, "strdup(concat(%s, charToStr(%s)))", Lval, Rval);
					} else if (!strcmp(n->token, "%")) {
						val = (char *) malloc (26+strlen(Lval)+strlen(Rval));
						sprintf(val, "isSubstr(%s, charToStr(%s))", Lval, Rval);
					}
				}
				else {
					if (!strcmp(n->token, "+")) {
						val = (char *) malloc (30+strlen(Lval)+strlen(Rval));
						sprintf(val, "strdup(concat(charToStr(%s), %s))", Lval, Rval);
					} else if (!strcmp(n->token, "%")) {
						val = (char *) malloc (24+strlen(Lval)+strlen(Rval));
						sprintf(val, "isSubstr(charToStr(%s), %s)", Lval, Rval);
					}
				}
				break;
			}
			case 4: {
				if (!strcmp(n->token, "*")) {
					val = (char *) malloc (18+strlen(Lval)+strlen(Rval));
					sprintf(val, "getCharN(%s, (int)%s)", Lval, Rval);
				} else if (!strcmp(n->token, "-")) {
					val = (char *) malloc (21+strlen(Lval)+strlen(Rval));
					sprintf(val, "delNChar(%s, (int)%s, 1)", Lval, Rval);
				} else if (!strcmp(n->token, "/")) {
					val = (char *) malloc (21+strlen(Lval)+strlen(Rval));
					sprintf(val, "delNChar(%s, (int)%s, 0)", Lval, Rval);
				}
				break;
			}
			default: {
				if(!strcmp(typeLvalue, "Stringa")) {
					if (!strcmp(n->token, "+")) {
						val = (char *) malloc (18+strlen(Lval)+strlen(Rval));
						sprintf(val, "strdup(concat(%s, %s))", Lval, Rval);
					} else if (!strcmp(n->token, "%")) {
						val = (char *) malloc (13+strlen(Lval)+strlen(Rval));
						sprintf(val, "isSubstr(%s, %s)", Lval, Rval);
					}
				} else {
					val = (char *) malloc (5+strlen(Lval)+strlen(Rval));
					sprintf(val, "(%s %s %s)", Lval, n->token, Rval);
				}
				break;
			}
		}
	}
	return val;
}

/* Returns the condition in C */
static char * get_condition(struct node * n) {
	char *condition, operator[3], *Lval, *Rval, *typeLvalue, *typeRvalue; 
	Lval = get_val(n->left);
	Rval = get_val(n->right);
	typeLvalue = (get_type(n->left->token) == NULL) ? n->left->typenode : get_type(n->left->token);
	typeRvalue = (get_type(n->right->token) == NULL) ? n->right->typenode : get_type(n->right->token);
	if (!strcmp(n->token, "<")) strcpy(operator, "<");
	else if (!strcmp(n->token, "<=")) strcpy(operator, "<=");
	else if (!strcmp(n->token, ">")) strcpy(operator, ">");
	else if (!strcmp(n->token, ">=")) strcpy(operator, ">=");
	else if (!strcmp(n->token, "=")) strcpy(operator, "==");
	else strcpy(operator, "!=");
	if (strcmp(typeLvalue, "Stringa")) {
		switch (check_compare(typeLvalue,typeRvalue)) {
			case 1:
			case 2: {
				condition = (char *) malloc (11+strlen(Lval)+strlen(Rval));
				sprintf(condition, "%s %s (int)%s", Lval, operator, Rval);
				break;
			}
			case 3: {
				condition = (char *) malloc (14+strlen(Lval)+strlen(Rval));
				sprintf(condition, "%s %s (double)%s", Lval, operator, Rval);
				break;
			}
			case 4: {
				condition = (char *) malloc (19+strlen(Lval)+strlen(Rval));
				sprintf(condition, "%s %s (double)(int)%s", Lval, operator, Rval);
				break;
			}
			case 5: {
				condition = (char *) malloc (12+strlen(Lval)+strlen(Rval));
				sprintf(condition, "%s %s (char)%s", Lval, operator, Rval);
				break;
			}
			case 6: {
				condition = (char *) malloc (17+strlen(Lval)+strlen(Rval));
				sprintf(condition, "%s %s (char)(int)%s", Lval, operator, Rval);
				break;
			}
			default: {
				condition = (char *) malloc (5+strlen(Lval)+strlen(Rval));
				sprintf(condition, "%s %s %s", Lval, operator, Rval);
				break;
			}
		}
	} else {
		condition = (char *) malloc (16+strlen(Lval)+strlen(Rval));
		sprintf(condition, "strcmp(%s, %s) %s 0", Lval, operator, Rval);
	}
	return condition;
}

/* Returns the conditions in C */
static char * get_conditions(struct node * n) {
	char *conditions, *Lval, *Rval;
	if(!strcmp(n->right->token, "AND") || !strcmp(n->right->token, "OR")) {	/* Multiple conditions branch */
		Lval = get_condition(n->left);
		Rval = get_conditions(n->right);
		conditions = (char *) malloc (5+strlen(Lval)+strlen(Rval));
		if (!strcmp(n->token, "AND")) {
			sprintf(conditions, "%s && %s", Lval, Rval);
		} else if (!strcmp(n->token, "OR")) {
			sprintf(conditions, "%s || %s", Lval, Rval);
		}
	} else {
		if (!strcmp(n->token, "AND")) {	/* Single pair of conditions branch */
			Lval = get_condition(n->left);
			Rval = get_condition(n->right);
			conditions = (char *) malloc (5+strlen(Lval)+strlen(Rval));
			sprintf(conditions, "%s && %s", Lval, Rval);
		} else if (!strcmp(n->token, "OR")) {
			Lval = get_condition(n->left);
			Rval = get_condition(n->right);
			conditions = (char *) malloc (5+strlen(Lval)+strlen(Rval));
			sprintf(conditions, "%s || %s", Lval, Rval);
		} else { /* Single condition branch */
			conditions = get_condition(n);
		}
	}
	return conditions;
}

/* Returns the declaration in C */
static char * get_declaration(struct node * n) {
	char *declaration, convtype[7];
	switch(get_convtype(get_type(n->right->token))) {
		case 0: {
			strcpy(convtype, "int");
			break;
		}
		case 1: {
			strcpy(convtype, "double");
			break;
		}
		case 2: {
			strcpy(convtype, "char");
			break;
		}
		case 3: {
			strcpy(convtype, "char *");
			break;
		}
	}
	declaration = (char *) malloc (8+strlen(n->right->token));
	sprintf(declaration, "%s %s;\n", convtype, n->right->token);
	return declaration;
}

/* Returns the assignment in C */
static char * get_assignment(struct node * n) {
	char *assignment, *Rval, *typeRvalue ;
	Rval = get_val(n->right);
	typeRvalue = (get_type(n->right->token) == NULL) ? n->right->typenode : get_type(n->right->token);
	switch(check_assignment(get_type(n->left->token), typeRvalue)) {
		case 0: {
			if(strcmp(get_type(n->left->token), "Stringa")) {
				assignment = (char *) malloc (strlen(n->left->token)+strlen(Rval));
				sprintf(assignment, "%s = %s;\n", n->left->token, Rval);
			} else {
				assignment = (char *) malloc (13+strlen(n->left->token)+strlen(Rval));
				sprintf(assignment, "strcpy(%s, %s);\n", n->left->token, Rval);
			}
			break;
		}
		case 1:
		case 2: {
			assignment = (char *) malloc (12+strlen(n->left->token)+strlen(Rval));
			sprintf(assignment, "%s = (int) %s;\n", n->left->token, Rval);
			break;
		}
		case 3:
		case 4: {
			assignment = (char *) malloc (15+strlen(n->left->token)+strlen(Rval));
			sprintf(assignment, "%s = (double) %s;\n", n->left->token, Rval);
			break;
		}
		case 5:
		case 6: {
			assignment = (char *) malloc (19+strlen(n->left->token)+strlen(Rval));
			sprintf(assignment, "%s = (char) (int) %s;\n", n->left->token, Rval);
			break;
		}
		case 7: {
			assignment = (char *) malloc (17+strlen(n->left->token)+strlen(Rval));
			sprintf(assignment, "%s = charToStr(%s);\n", n->left->token, Rval);
			break;
		}
	}
	return assignment;
}

/* Returns the while in C */
static char * get_while(struct node * n) {
	char *whileBlock, *whileCond, *whileCode;
	whileCond = get_conditions(n->left);
	whileCode = generate_code(n->right);
	whileBlock = (char *) malloc (14+strlen(whileCond)+strlen(whileCode));
	sprintf(whileBlock, "while (%s) {\n%s}\n", whileCond, whileCode);
	return whileBlock;
}

/* Returns the if-else in C */
static char * get_if_else(struct node * n) {
	char *ifBlock, *elseBlock, *ifCond, *ifCode, *elseCode;
	ifCond = get_condition(n->left->left);
	ifCode = generate_code(n->left->right);
	ifBlock = (char *) malloc (11+strlen(ifCond)+strlen(ifCode));
	sprintf(ifBlock, "if (%s) {\n%s}\n", ifCond, ifCode);
	if (n->right != NULL) {
		elseCode = generate_code(n->right->right);
		elseBlock = (char *) malloc (10+strlen(elseCode));
		sprintf(elseBlock, "else {\n%s}\n", elseCode);
		strcat(ifBlock,elseBlock);
	}
	return ifBlock;
}

/* Returns I/O operations from stdin and stdout in C */
static char * get_io(struct node * n) {
	char *inputOutput, convpattern[4], *type, *Rval;
	type = (get_type(n->right->token)!=NULL) ? get_type(n->right->token) : n->right->typenode;
	if (!strcmp(type, "Intero")) strcpy(convpattern, "%d");
	else if (!strcmp(type, "Reale")) strcpy(convpattern, "%lf");
	else if (!strcmp(type, "Carattere")) strcpy(convpattern, "%c");
	else if (!strcmp(type, "Stringa")) strcpy(convpattern, "%s");
	if (!strcmp(n->left->token, "LEGGI")) {
		inputOutput = (char *) malloc (18+strlen(n->right->token));
		if(strcmp(type, "Stringa")) {
			sprintf(inputOutput, "scanf(\"%s\", &%s);\n", convpattern, n->right->token);
		} else {
			sprintf(inputOutput, "%s = getStringa();\n", n->right->token);
		}
	} else {
		Rval = get_val(n->right);
		inputOutput = (char *) malloc (18+strlen(Rval));
		sprintf(inputOutput, "printf(\"%s\", %s);\n", convpattern, Rval);
	}
	return inputOutput;
}

/* General translation function to C */
static char * get_statement(struct node * n) {
	char *stat;
	if (!strcmp(n->token, "DICHIARAZIONE")) {
		stat = get_declaration(n);
	} else if (!strcmp(n->token, "ASSEGNAMENTO")) {
		stat = get_assignment(n);
	} else if (!strcmp(n->token, "MENTRE")) {
		stat = get_while(n);
	} else if (!strcmp(n->token, "SE-ALTRIMENTI")) {
		stat = get_if_else(n);
	} else if (!strcmp(n->token, "I/O")) {
		stat = get_io(n);
	}
	return stat;
}

/* Generates the whole code in C */
static char * generate_code(struct node * n) {
	char *Lbranch, *Rbranch;
	if (n!=NULL && !strcmp(n->token, "STATEMENTS")) {
		Lbranch = (n->left!=NULL) ? strdup(get_statement(n->left)) : strdup("");
		Rbranch = (n->right!=NULL) ? strdup(generate_code(n->right)) : strdup("");
		return strcat(Lbranch, Rbranch);
	} else {
		return strdup(get_statement(n));
	}
}

/* Function to print the parse tree */
static void return_tree(struct node * tree, int indent) {
	printf("%s\n", tree->token);
	if (tree->left) {
		for(int i=0; i<=indent; printf("\t"),i++);
		return_tree(tree->left, indent+1);
	} 
	if (tree->right) {
		for(int i=0; i<=indent; printf("\t"),i++);
		return_tree(tree->right, indent+1);
	}
}

/* Deallocates the symbol table */
static void free_table(void) {
	if(first) {
		selected = first;
		while(selected->next!=NULL) {
			last = selected;
			selected = selected->next;
			free(last);
		}
	}
}

/* Deallocates the parse tree */
static void free_tree(struct node * tree) {
	if (tree) {
		if (tree->left) {
			free_tree(tree->left);
		}
		if (tree->right) {
			free_tree(tree->right);
		}
		free(tree);
	}
}

/* Deallocates symbol table and parse tree */
void free_all() {
	free_table();
	free_tree(head);
}

/* Function to print the symbol table */
void get_table(void) {
	printf("SYMBOL\t\tDATATYPE\t\tLINE\n\n");
	for (selected = first; selected != NULL; selected = selected->next) {
		printf("%s\t\t%s\t\t%d\n", selected->row.id_name, selected->row.data_type, selected->row.line);
	}
	printf("\n");
}
    
/* Function to print the parse tree */
void get_tree(void) {
	return_tree(head, 0);
}

/* Function to get the compiled code */
void get_code(FILE *out) {
	char *code = generate_code(head);
	fprintf(out, "%s", includes);
	fprintf(out, "%s", cts);
	fprintf(out, "%s", cnct);
	fprintf(out, "%s", sbstr);
	fprintf(out, "%s", gcn);
	fprintf(out, "%s", dnc);
	fprintf(out, "%s", getStr);
	fprintf(out, "%s", mn);
	fprintf(out, "%s", code);
	fprintf(out, "}\n");
	free(code);
}

/* Prints the errors generated during compiling */
void get_errors(void) {
	printf("%d errors\n", err_num);
	for (int i=0; i<err_num; i++) {
		printf("%s", errors[i]);
		free(errors[i]);
    }
	free(errors);
}