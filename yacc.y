%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbolTable.h"          //include symbolTable.h for symbol table
#define Trace(t) {if (Opt_P) printf("%s",t);}
#define fpt( o){ if(strlen(o)!=0) fprintf(yyout,"%s\n",o); isLastLineTag=0;}
#define fpt_cmt( o){fprintf(yyout,"/*%s*/\n",o);}
extern char *yytext;
extern FILE *yyin;
extern FILE *yyout;
extern int yyparse();
extern int lineno;
extern int yylex (void);
void init_main();
int isLastLineTag=0;
int isMain=0;
int isDecGlob=0;
int globalInteger=0;
int yyerror(char *s);            //define yyerror
int Opt_P = 1;
int whileBegin=0;
Symbol_Table symtable;           //new a symbol table object
string s_tmp;                    //declare a tmp string to store identifier
string relation="";
int gotoCount=0;
Entry* e_tmp;                     // declare a Entry* to store temporary function id when declaring a func
string className;
vector<Entry *> vec_En_tmp;      //declare a vector object to store Entry* for comma_exp
vector<int> vec_i_tmp;           //declare a vector object to store int for comma_exp
%}
/* tokens */
%union
{
         //declare union types
        int num;
        double fnum;
        char *str;
}

  //declare tokens
%token TRUE
%token  FALSE
%token  AND BOOLEAN CONST DO ELSE END FOR FUNCTION
%token  IF IMPORT IN INTEGER REAL LOCAL NIL NOT OR PRINT
%token  PRINTLN REPEAT RETURN STRING THEN UNTIL WHILE VOID READ
%token <num> integer
%token <str> identifier
%token <str> string
%token <fnum> real
%token <num> RELATIONAL

  //bind Expression and dec_type to num(int) to represent type, e.g. INTEGER STRING etc.
%type <num> dec_type
%type <num> Expression
  //precedence definition
%left OR
%left AND
%left NOT
%left RELATIONAL
%left '-' '+'
%left '*' '/' '%'
%left '^'
%nonassoc UMINUS

%%
  //start parsing with Program
Program     :
            | Program Statement
            ;
  //Declaration with a const token
const_Declare: CONST INTEGER identifier '=' integer {
               if(symtable.insert($3)==NULL){
                yyerror("[Declare] variable redefined");YYERROR ;
               }
               symtable.isConstant($3,true);
               symtable.addType($3,INTEGER);
               symtable.setConstI($3,$5);
               symtable.dump();
            }
            |CONST STRING identifier '=' string {
                           if(symtable.insert($3)==NULL){
                            yyerror("[Declare] variable redefined");YYERROR ;
                           }
                           symtable.isConstant($3,true);
                           symtable.addType($3,STRING);
                           symtable.setConstS($3,$5);
                           symtable.dump();
                        }
            |CONST BOOLEAN identifier '=' TRUE {
                           if(symtable.insert($3)==NULL){
                            yyerror("[Declare] variable redefined");YYERROR ;
                           }
                           symtable.isConstant($3,true);
                           symtable.addType($3,BOOLEAN);
                           symtable.setConstI($3,1);
                           symtable.dump();
              }
            |CONST BOOLEAN identifier '=' FALSE {
                           if(symtable.insert($3)==NULL){
                            yyerror("[Declare] variable redefined");YYERROR ;
                           }
                           symtable.isConstant($3,true);
                           symtable.addType($3,BOOLEAN);
                           symtable.setConstI($3,0);
                           symtable.dump();
              }
              |CONST BOOLEAN identifier '=' integer {yyerror("[Declare] Wrong Type");YYERROR ;}
              |CONST BOOLEAN identifier '=' string {yyerror("[Declare] Wrong Type");YYERROR ;}
              |CONST STRING identifier '=' integer {yyerror("[Declare] Wrong Type");YYERROR ;}
              |CONST STRING identifier '=' TRUE {yyerror("[Declare] Wrong Type");YYERROR ;}
              |CONST STRING identifier '=' FALSE {yyerror("[Declare] Wrong Type");YYERROR ;}
              |CONST INTEGER identifier '=' string {yyerror("[Declare] Wrong Type");YYERROR ;}
              |CONST INTEGER identifier '=' TRUE {yyerror("[Declare] Wrong Type");YYERROR ;}
              |CONST INTEGER identifier '=' FALSE {yyerror("[Declare] Wrong Type");YYERROR ;}
;
  //Normal Declarations
Declaration : dec_type identifier '=' {if(isMain&&symtable.isGlobal()){
             yyerror("[Declare Gloabl Variable] Gloabl variables should be defined before statements");
             YYERROR ;}
             isDecGlob=symtable.isGlobal();} Expression {
                           //type checking: if the type of Expression doesn't match with that of dec_type, return errors
                           if($1!=$5){yyerror("[Declaration] type error");YYERROR ;}
                           //insert into symbol table and set its type
                           int next=symtable.next();
                           if(symtable.insert($2)==NULL){
                            yyerror("[Declare] variable redefined");YYERROR ;
                           }
                           symtable.addType($2,$1);
                           if(symtable.isGlobal()){ //is global variable
                            fpt(("field static int "+ ctos($2)+" = "+itos(globalInteger)).c_str());
                           }
                           else{      // is local variable
                            fpt(("istore "+itos(next)).c_str());
                           }
                           isDecGlob=0;
                           symtable.dump();
            }
            | dec_type identifier {
                           //insert into symbol table and set its type
                           if(symtable.insert($2)==NULL){
                            yyerror("[Declare] variable redefined");YYERROR ;
                           }
                           else if(isMain&&symtable.isGlobal()){
                                         yyerror("[Declare Gloabl Variable] Gloabl variables should be defined before statements");
                                         YYERROR ;}
                           symtable.addType($2,$1);
                           if(symtable.isGlobal()){ //is global variable
                            fpt(("field static int "+ ctos($2)).c_str());
                           }
                           symtable.dump();
                        }
  //Array Declarations
            | dec_type identifier '[' const_exp ']' {
                           //insert into symbol table and set its type
                           if(symtable.insert($2)==NULL){
                            yyerror("[Declare] variable redefined");YYERROR ;
                           }
                           symtable.isArray($2,true);
                           symtable.addType($2,$1);
                           symtable.dump();
                        }
            ;
  //Function Declarations
dec_Function: FUNCTION dec_type identifier {/** insert into symbol table and set its type **/ if(isMain){
              yyerror("[Declare Func] Functions should be defined before statements");YYERROR ;}
if(symtable.insert($3)==NULL){
              yyerror("[Declare] variable redefined");YYERROR ;}symtable.setRetnType($3,$2);symtable.isFunc($3,true);}
                  '(' {/** create a symbol table **/ symtable.create();s_tmp=$3;e_tmp=symtable.lookup($3);} Formal_Arg ')' {
                    if(symtable.funcDeclare($3).size()==0){
                      yyerror("[CODE GEN ERROR] Wrong type");YYERROR ;
                    }
                    fpt(symtable.funcDeclare($3).c_str());
                  } Block END {/** drop a symbol table **/symtable.drop();fpt("}");}
            | FUNCTION VOID identifier {if(symtable.insert($3)==NULL){
             yyerror("[Declare] variable redefined");YYERROR ;
            }symtable.setRetnType($3,VOID);symtable.isFunc($3,true);e_tmp=symtable.lookup($3);}
                  '(' {/*create a symbol table*/symtable.create();s_tmp=$3;} Formal_Arg ')'
                  {
                    if(symtable.funcDeclare($3).size()==0){
                      yyerror("[CODE GEN ERROR] Wrong type");YYERROR ;
                    }
                    fpt(symtable.funcDeclare($3).c_str());
                  }
                  Block END {/*drop a symbol table*/symtable.drop();fpt("}");}
            ;
  //Block Declarations
Block       :
            | Block  Statement
            | Block  Statement ';'
            | Statement
            | Statement ';'
            ;

  //Statement Declarations

   //-----------assigning--------
Statement   : identifier '=' {init_main();} Expression   {
                     if(symtable.isArray($1)){           //checking if identifier is an array
                        yyerror("[Statement] array needs []");YYERROR ;
                     }
                     else if(symtable.isConstant($1)){   //checking if identifier is a constant
                        yyerror("[Statement] constant can't be reasigned");YYERROR ;
                     }
                     else if(symtable.isFunc($1)){       //checking if identifier is a Function
                        yyerror("[Statement] function can't be reasigned");YYERROR ;
                     }
                     else if(symtable.getType($1,0)!= $4){  //checking if the type of identifier matches that of Expression
                        yyerror("[Statement] types on the both sides of = should match");YYERROR ;
                     }
                     printf("identifier = Expression\n");
                     if(symtable.getType($1,0)== INTEGER||symtable.getType($1,0)== BOOLEAN)
                        {fpt(symtable.write($1,className).c_str());}
                     else{
                        yyerror("[CODE GEN ERROR] types should be either integer or boolean");YYERROR ;
                     }
                  }
   //-------- array assigning------
            | identifier '[' int_exp ']' '=' Expression{
                  if(!symtable.isArray($1) || !($6==symtable.getType($1,0))){  //checking if identifier is an array and if Expression matches the former's type
                     yyerror("[Statement] array assignment error");YYERROR ;
                  }
                  printf("identifier [ int_exp ] = Expression\n");
            }
   //----------other statements
            | Procedure             {printf("Procedure\n");}
            | PRINT {init_main();
                fpt("getstatic java.io.PrintStream java.lang.System.out");} Expression {
                printf("PRINT Expression\n");
                switch($3){
                case INTEGER:
                case BOOLEAN:
                fpt("invokevirtual void java.io.PrintStream.print(int)");
                break;
                case STRING:
                fpt("invokevirtual void java.io.PrintStream.print(java.lang.String)");
                break;
                default:
                  yyerror("[Statement] print type error");YYERROR ;
                }
            }
            | PRINTLN {init_main();
              fpt("getstatic java.io.PrintStream java.lang.System.out");} Expression {
              printf("PRINTLN Expression\n");
              switch($3){
              case INTEGER:
              case BOOLEAN:
              fpt("invokevirtual void java.io.PrintStream.println(int)");
              break;
              case STRING:
              fpt("invokevirtual void java.io.PrintStream.println(java.lang.String)");
              break;
              default:
                yyerror("[Statement] print type error");YYERROR ;
              }
            }
            | READ identifier       {init_main();printf("READ identifier\n");}
            | RETURN                {printf("RETURN\n");
                                      if(e_tmp->returnType!=VOID){
                                      yyerror("[Statement] return type error");YYERROR ;
                                      }
                                      else{
                                      fpt("return");
                                      }
                                    }
            | RETURN Expression     {printf("RETURN Expressionh\n");
                                      if((e_tmp->returnType==INTEGER||e_tmp->returnType==BOOLEAN)&&e_tmp->returnType==$2){
                                        fpt("ireturn");
                                      }
                                      else{
                                      yyerror("[Statement] return type error");YYERROR ;
                                      }
                                    }
            | cond_Statement        {printf("cond_Statement\n");}
            | loop_Statement        {printf("loop_Statement\n");}
            | const_Declare         {printf("const_Declare\n");}
            | dec_Function          {printf("dec_Function\n");}
            | Declaration           {printf("Declaration\n");}
            ;
  //Condition Statement
  //---------- if (bool_exp) then block else block end
cond_Statement : if_statement ELSE {symtable.drop();/**pop a symbol table**/
                                    fpt(("goto L"+itos(gotoCount)).c_str());
                                    gotoCount+=1;
                                    fpt(("L"+itos(gotoCount-2)+":").c_str());
                                    symtable.create();/**create a new symbol table**/}
                     Block  END {fpt(("L"+itos(gotoCount-1)+":").c_str());symtable.drop();isLastLineTag=1;/**pop a symbol table**/}

  //-----------if (bool_exp) then block end
               | if_statement END {fpt(("L"+itos(gotoCount-1)+":").c_str());
               symtable.drop();
               isLastLineTag=1;}
               ;
if_statement   :IF  '('  {init_main();} Bool_exp  ')'  THEN {
                   symtable.create();/**create a new symbol table**/
                   if(relation.size()!=0){
                      fpt((relation+" L"+itos(gotoCount)).c_str());
                      gotoCount+=1;
                      fpt("iconst_0");
                      fpt(("goto L"+itos(gotoCount)).c_str());
                      gotoCount+=1;
                      fpt(("L"+itos(gotoCount-2)+":").c_str());
                      fpt("iconst_1");
                      fpt(("L"+itos(gotoCount-1)+":").c_str());
                   }
                   fpt(("ifeq L"+itos(gotoCount)).c_str());
                   gotoCount+=1;
                   relation="";
               } Block
                ;
  //Loop Statement
  //------------while (bool_exp) do block end
loop_Statement : WHILE '(' {init_main();
                           if(!isLastLineTag){fpt(("L"+itos(gotoCount)+":").c_str());
                           whileBegin=gotoCount;
                           gotoCount+=1;}
                           else whileBegin=gotoCount-1;
                        } Bool_exp ')'  DO {symtable.create();
                        if(relation.size()!=0){
                           fpt((relation+" L"+itos(gotoCount)).c_str());
                           gotoCount+=1;
                           fpt("iconst_0");
                           fpt(("goto L"+itos(gotoCount)).c_str());
                           gotoCount+=1;
                           fpt(("L"+itos(gotoCount-2)+":").c_str());
                           fpt("iconst_1");
                           fpt(("L"+itos(gotoCount-1)+":").c_str());
                        }
                        fpt(("ifeq L"+itos(gotoCount)).c_str());
                        gotoCount+=1;
                        relation="";

                        } Block END {fpt(("goto L"+itos(whileBegin)).c_str());
                        fpt(("L"+itos(gotoCount-1)+":").c_str());symtable.drop();isLastLineTag=1;}
  //------------for id= Expression (type checking) , Expression do block end
               | FOR {init_main();} identifier '=' Expression  {
                                    init_main();
                                    if(symtable.isArray($3)){           //checking if identifier is an array
                                       yyerror("[For Statement] array needs []");YYERROR ;
                                    }
                                    else if(symtable.isConstant($3)){   //checking if identifier is a constant
                                       yyerror("[For Statement] constant can't be reasigned");YYERROR ;
                                    }
                                    else if(symtable.isFunc($3)){       //checking if identifier is a Function
                                       yyerror("[For Statement] function can't be reasigned");YYERROR ;
                                    }
                                    else if(symtable.getType($3,0)!= $5){  //checking if the type of identifier matches that of Expression
                                       yyerror("[For Statement] types on the both sides of = should match");YYERROR ;
                                    }
                                 }',' Expression DO {symtable.create();} Block END {symtable.drop();}
               ;
  //Formal arguments for function declarations
Formal_Arg  :
            | Formal_Arg ',' dec_type identifier {if(symtable.insert($4)==NULL){
             yyerror("[Declare] variable redefined");YYERROR ;
            } symtable.addType($4,$3);symtable.addType(s_tmp,$3);}
            | dec_type identifier {if(symtable.insert($2)==NULL){
             yyerror("[Declare] variable redefined");YYERROR ;
            }symtable.addType($2,$1);symtable.addType(s_tmp,$1);}
            ;
  //Expressions
  //--------------- + - * / check if both the experessions have the same types and if their types are either integer or real
Expression  :  Expression  '+'  Expression {if($1!=$3||($1!=INTEGER&&$1!=REAL)){yyerror("[Expression] Wrong type +");YYERROR;} else{$$=$1;fpt("iadd");} }
            |  Expression  '-'  Expression {if($1!=$3||($1!=INTEGER&&$1!=REAL)){yyerror("[Expression] Wrong type -");YYERROR;} else{$$=$1;fpt("isub");} }
            |  Expression  '*'  Expression {if($1!=$3||($1!=INTEGER&&$1!=REAL)){yyerror("[Expression] Wrong type *");YYERROR;} else{$$=$1;fpt("imul");} }
            |  Expression  '/'  Expression {if($1!=$3||($1!=INTEGER&&$1!=REAL)){yyerror("[Expression] Wrong type /");YYERROR;} else{$$=$1;fpt("idiv");} }
			|  Expression  '^'  Expression {if($1!=$3||($1!=INTEGER&&$1!=REAL)){yyerror("[Expression] Wrong type ^");YYERROR;} else{$$=$1;} }
            |  Expression  '%'  Expression {if($1!=$3||($1!=INTEGER&&$1!=REAL)){yyerror("[Expression] Wrong type %");YYERROR;} else{init_main();$$=$1;fpt("irem");} }
  //------------- boolean operation AND and OR, checking if both the expressions are BOOLEAN
            |  Expression AND Expression {
                  if($1!=$3||$1!=BOOLEAN){
                     yyerror("[Expression] Same type to AND");YYERROR ;
                  }
               $$=BOOLEAN;    //set expression as Boolean type
               fpt("iand");
            }
            |  Expression OR Expression {
               if($1!=$3||$1!=BOOLEAN){
                  yyerror("[Expression] Same type to OR");YYERROR ;
               }
               $$=BOOLEAN;   //set expression as Boolean type
               fpt("ior");
            }
  //------------- boolean operation > <> <= etc.
            |  Expression RELATIONAL Expression  {
               if($1!=$3||$1==BOOLEAN){   //checking if both the expressions are BOOLEAN
                  yyerror("[Bool_exp] Same type to compare");YYERROR ;
               }
               $$=BOOLEAN;   //set expression as Boolean type
               fpt("isub");
               switch($2){
                case 1:
                  relation="iflt";
                break;
                case 2:
                  relation="ifgt";
                break;
                case 3:
                  relation="ifeq";
                break;
                case 4:
                  relation="ifle";
                break;
                case 5:
                  relation="ifge";
                break;
                case 6:
                  relation="ifne";
                break;
               }
            }
            | NOT Expression {
               //checking if Expression is boolean
               if($2!=BOOLEAN){yyerror("[Expression] a boolean after not");YYERROR;}
               $$=BOOLEAN;   //set expression as Boolean type
               fpt("ixor");
            }
            | TRUE  {$$=BOOLEAN;
              if(!isDecGlob){fpt("iconst_1");}
              else{ globalInteger=1;}}    //set expression as Boolean type
            | FALSE  {$$=BOOLEAN;if(!isDecGlob){fpt("iconst_0");}else{ globalInteger=0;}}   //set expression as Boolean type
            |  '-'  Expression  %prec  UMINUS{$$=$2;
            fpt("ineg");
            }
  //------------- identifier checking if it exists in the symbol table and set expression's type to that of the identifier.
            |  identifier  {$$=symtable.getType($1,0);if(symtable.lookup($1)==NULL) {yyerror("[Expression] Identifier NOT FOUND");YYERROR;}
            symtable.dump();
              if(!isDecGlob){
                if(symtable.read($1,className).size()==0){
                  yyerror("[CODE GEN ERROR] Wrong type");YYERROR ;
                }
                fpt(symtable.read($1,className).c_str());
              }
            }
            |  string      {$$=STRING;if(!isDecGlob)fpt(("ldc \""+ctos($1)+"\"").c_str());}  //set expression's type to STRING
            |  integer     {$$=INTEGER;if(!isDecGlob){fpt(("sipush "+itos($1)).c_str());}else {globalInteger=$1;}}
            |  real        {$$=REAL;}
            |  '(' Expression ')' {$$=$2;}
  //------------ [++function calls++] as expressions push the entry of current identifier into vec_EN_tmp and push 0 int ovec_i_tmp as index before comma_exp
            |  identifier '(' {vec_En_tmp.push_back(symtable.lookup($1));vec_i_tmp.push_back(0);} comma_exp ')' {
                  //-----if the number of parameter of the function is more than that in the (), error too few parameter-----
                  if(vec_i_tmp[vec_i_tmp.size()-1]<vec_En_tmp[vec_En_tmp.size()-1]->vec_type.size()){yyerror("[Expression] Too few parameter!");YYERROR ;}
                  int type=symtable.getRetnType($1);                                      //get return type of identifier
                  if(type!=VOID&&type!=-1){$$=type;}                                      // if reurn type is void or undefined, error
                  else {yyerror("[Expression] Function returns void");YYERROR ;}
                  vec_En_tmp.pop_back();vec_i_tmp.pop_back();                             //pop both vec_En_tmp and vec_i_tmp
                  //symtable.dump();
                  if(symtable.read($1,className).size()==0){
                    yyerror("[CODE GEN ERROR] Wrong type");YYERROR ;
                  }
                  fpt(symtable.read($1,className).c_str());
            }
            ;
  //Boolean expression
Bool_exp    : Expression {
                  if($1!=BOOLEAN){        //checking if Expression is Boolean
                  yyerror("[Bool_exp] The Expression should be BOOLEAN");YYERROR;
                  }
               }
            ;
    //constant expression
const_exp   :  identifier {
                  if(!symtable.isConstant($1)){             //checking if Expression is constant
                     yyerror("[const_exp] identifier should be constant");YYERROR ;
                  }
                  else if(symtable.getType($1,0)!= INTEGER){  //checking if Expression is integer
                     yyerror("[const_exp] identifier should be integer");YYERROR ;
                  }
                  //symtable.dump();
                  if(symtable.read($1,className).size()==0){
                    yyerror("[CODE GEN ERROR] Wrong type");YYERROR ;
                  }
                  fpt(symtable.read($1,className).c_str());
               }
            |  integer
            ;
  //integer expression
int_exp     :  Expression {
                  if($1!=INTEGER){               //checking if Expression is integer
                  yyerror("[int_exp] The Expression should be integer");YYERROR;
                  }
               }
            ;
  //Procedure
    //--------------------procedure with comma_exp  push the entry of current identifier into vec_EN_tmp and push 0 int ovec_i_tmp as index before comma_exp
Procedure   :identifier '(' {init_main(); vec_En_tmp.push_back(symtable.lookup($1));vec_i_tmp.push_back(0);} comma_exp ')'{vec_En_tmp.pop_back();vec_i_tmp.pop_back();
  //symtable.dump();
    if(symtable.read($1,className).size()==0){
      yyerror("[CODE GEN ERROR] Wrong type");YYERROR ;
    }
    fpt(symtable.read($1,className).c_str());
}
  //---------------- pop both vec_En_tmp and vec_i_tmp
            ;
  //parameters used in function calls
comma_exp   :
            | comma_exp ',' Expression {
                  //check if the identifier exists and if it is a function
                  if(vec_En_tmp[vec_En_tmp.size()-1]!=NULL&&vec_En_tmp[vec_En_tmp.size()-1]->isFunc){
                     //checking if the arguments passed are too many
                     if(vec_En_tmp[vec_En_tmp.size()-1]->vec_type.size()<=vec_i_tmp[vec_i_tmp.size()-1]){
                        yyerror("[comma_exp] Too many paramenters");YYERROR;
                     }
                     //checking if the type of arguments matched that of identifier
                     else if($3!=vec_En_tmp[vec_En_tmp.size()-1]->vec_type[vec_i_tmp[vec_i_tmp.size()-1]++]){
                        yyerror("[comma_exp] Function parameters don't match");YYERROR;
                     }
                  }
                  else{
                     yyerror("[comma_exp] identifier NOT FOUND or is NOT a Function");YYERROR;
                  }
            }
            | Expression   {
               //check if the identifier exists and if it is a function
               if(vec_En_tmp[vec_En_tmp.size()-1]!=NULL&&vec_En_tmp[vec_En_tmp.size()-1]->isFunc){
                  //checking if the arguments passed are too many
                  if(vec_En_tmp[vec_En_tmp.size()-1]->vec_type.size()<=vec_i_tmp[vec_i_tmp.size()-1]){
                     yyerror("[comma_exp] Too many paramenters");YYERROR;
                  }
                  //checking if the type of arguments matched that of identifier
                  else if($1!=vec_En_tmp[vec_En_tmp.size()-1]->vec_type[vec_i_tmp[vec_i_tmp.size()-1]++]){
                     yyerror("[comma_exp] Function parameters don't match");YYERROR;
                  }
               }
               else{
                  yyerror("[comma_exp] identifier NOT FOUND or is NOT a Function");YYERROR;
               }
            }
            ;
  //basic types
dec_type    : INTEGER  { $$ = INTEGER; } //set dec_type to INTEGER
            | BOOLEAN  { $$ = BOOLEAN; } //set dec_type to BOOLEAN
            | STRING   { $$ = STRING; }  //set dec_type to STRING
            | REAL     { $$ = REAL; }    //set dec_type to REAL
            ;

%%
void init_output(){
fpt_cmt("-------------------------------------------------");
fpt_cmt(" Java Assembly Code ");
fpt_cmt("-------------------------------------------------");
fpt(("class "+className).c_str());
fpt("{");
}
void init_main(){
  if(!isMain&&symtable.isGlobal()){
    fpt("method public static void main(java.lang.String[])");
    fpt("max_stack 15");
    fpt("max_locals 15");
    fpt("{");
    isMain=1;
  }
}
void end_main(){
fpt("return\n}");
}
int yyerror(char *s)
{
 fprintf(stderr, "[ERROR]%s\n", s);
 return 0;
}
int main(int argc,char** argv){
   if (argc != 2) {
           printf ("Usage: sc filename\n");
           exit(1);
       }
       className=argv[1];
       int start=className.find_last_of("/");
       if (start!=0) start+=1;
       int end=className.find_last_of(".");
       className=className.substr(start,end-start);
       if((yyin = fopen(argv[1], "r"))==0){/* open input file */
           printf ("[ERROR] File %s does not exist\n",argv[1]);
           exit(1);
       }
       yyout= fopen((className+".jasm").c_str(),"w");
       init_output();
       /* perform parsing */
       if (yyparse() == 1){                 /* parsing */
           yyerror("Parsing error !");     /* syntax error */
      }
       else{
        init_main();
        end_main();
        fpt("}");
        printf("Success!\n");
        symtable.dump();
       }
       fclose( yyin );
       fclose( yyout );
}
