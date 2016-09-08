%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"
#define MAX_LINE_LENG 256
#define TABLE_SIZE 500
#define LIST     strcat(buf,yytext)
#define token(t) {LIST; /*printf("<%i>\n",t);*/return t;}
#define tokenInteger(t,i) {LIST; /*printf("<%i:%d>\n",t,i);*/yylval.num=i;return t;}
#define tokenReal(t,r) {LIST; /*printf("<%i:%lf>\n",t,r);*/yylval.fnum=r;return t;}
#define tokenString(t,s) {LIST;/* printf("<%i:%s>\n",t,s);*/yylval.str=strdup(s);return t;}
int linenum = 1;
char buf[MAX_LINE_LENG];

/*declarations related to string processing*/
char* dynamicConcatenate(char* to, char* from); //dynamically allocating array size when concatenation
char* strptr; //string pointer
int strToInt(char* snum);   //convert string into integer
char* preprocessToken(char* token);   //preprocess tokens before print them out. e.g. if -> IF; ( -> '('

/*declarations related to symbol tables */
char** ptrTable;            //pointer points to symbol table
int entNum=0;               //number of entry
char** create();
int lookup(char* s);
int insert(char* s);
void dump();

%}
  /*Declare two states*/
%x IN_DOUBLE_QUOTE COMMENT

  /*-------------------------------Declare tokens-------------------------------------------*/
ID     [A-Za-z][A-Za-z0-9]*
INT    [0-9]+
REAL   [+-]?{INT}"."{INT}([Ee][+-]?{INT})?
OP     ([\*\/+\-\^%=])
DELIMITERS [\{\}\[\]\(\),;:]
%%
  /* ----------------------------Start defining rules---------------------------------------*/
  /*=====comments======*/
  /* Ignore characters after // until the end of the line*/
\/\/.*\n  {LIST;printf("%d: %s", linenum, buf);linenum++;buf[0] = '\0';}

  /* Deal with comment like /** / */
  /* when "/*" is encountered, change state into COMMENT */
\/\*      {LIST;BEGIN COMMENT;}

  /*When "* /" is encountered, change state into INITIAL*/
<COMMENT>\*\/ {LIST;BEGIN INITIAL;}

  /*Ignore all character between "/*" and "* /" */
<COMMENT>.      {LIST;}

  /*If the comment is not finished by the end of the line,*/
  /*print out the line but still stay in COMMENT state.*/
<COMMENT>[\n\r]     {LIST;printf("%d: %s", linenum, buf);linenum++;buf[0] = '\0';}

  /*=======tokens=========*/

  /*Take DELIMITERS,KEYWD,OP,BOOL as token*/

{DELIMITERS}|{OP}  {LIST;return(yytext[0]);}

"<"      {yylval.num=1;token(RELATIONAL);}
">"      {yylval.num=2;token(RELATIONAL);}
"=="     {yylval.num=3;token(RELATIONAL);}
"<="     {yylval.num=4;token(RELATIONAL);}
">="     {yylval.num=5;token(RELATIONAL);}
"~="     {yylval.num=6;token(RELATIONAL);}
true     {token(TRUE);}
false    {token(FALSE);}
and      {token(AND);}
boolean  {token(BOOLEAN);}
const    {token(CONST);}
do       {token(DO);}
else     {token(ELSE);}
end      {token(END);}
for      {token(FOR);}
function {token(FUNCTION);}
if       {token(IF);}
import   {token(IMPORT);}
in       {token(IN);}
integer  {token(INTEGER);}
real     {token(REAL);}
local    {token(LOCAL);}
nil      {token(NIL);}
not      {token(NOT);}
or       {token(OR);}
print    {token(PRINT);}
println  {token(PRINTLN);}
repeat   {token(REPEAT);}
return   {token(RETURN);}
string   {token(STRING);}
then     {token(THEN);}
until    {token(UNTIL);}
while    {token(WHILE);}
void     {token(VOID);}
read     {token(READ);}
  /*if " is encountered, reset strptr and transit state into IN_DOUBLE_QUOTE (string mode)"*/
\"          {LIST;free(strptr);strptr=NULL;BEGIN IN_DOUBLE_QUOTE;}

  /*using strToInt to convert string into int before print it out*/
{INT}       {tokenInteger(integer, strToInt(yytext));}
{REAL}      {tokenReal(real, atof(yytext));}
{ID}        {tokenString(identifier,yytext);}
{INT}{ID}   {
                LIST;
                printf("%d:%s\n", linenum, buf);
                printf("Wrong ID:’%s’\n",yytext);
                exit(-1);
            }

  /*=========String========*/
  /*if the input does not contain ", append the input to a strptr*/
<IN_DOUBLE_QUOTE>[^\"]* {LIST;strptr=dynamicConcatenate(strptr,yytext);}

  /*if the input is "", append " to strptr*/
<IN_DOUBLE_QUOTE>\"\"   {LIST;strptr=dynamicConcatenate(strptr,"\"");}

  /*if the input is ", print strptr and change state into INITIAL*/
<IN_DOUBLE_QUOTE>\"     {BEGIN INITIAL;tokenString(string,strptr);}


  /*ignore whitespace*/
[ \t]*   {LIST;}
[\n\r]        {
          LIST;
          printf("%d: %s", linenum, buf);
          linenum++;
          buf[0] = '\0';
          }
.       {
          LIST;
          printf("%d:%s\n", linenum, buf);
          printf("bad character:’%s’\n",yytext);
          exit(-1);
        }

<<EOF>>     {
       return 0;
 }

%%
int yywrap()
{
	return 1;
}
/*
int main(int argc, char* argv[]) {
  create(); //create symbol table
  yylex() ;
  dump();   //print out symbol table
  return EXIT_SUCCESS ;
}
*/
/*implem dynamically concatenation*/
char* dynamicConcatenate(char* to,char* from){
  int lenFrom=strlen(from);
  char* tmp;
  if(to!=NULL){                    //if target is not NULL
    int lenTo=strlen(to);
    tmp=(char*)malloc(sizeof(char)*(lenTo+lenFrom));     //allocate a space with size= to+ from
    strcpy(tmp,to);
    strcat(tmp,from);
    free(to);                       //release the space of the original to
    to=NULL;
  }
  else{
    tmp=(char*)malloc(sizeof(char)*(lenFrom));  //if to is NULL, allocate a space with the size
    strcpy(tmp,from);                    // of from and copy the content of from to it.
  }
  return tmp;
}

/*Convert string into integer*/
int strToInt(char* snum){
  int nInt=0;
  int index=0;
  while(snum[index])
  {
    if(!nInt)
        nInt= ( (int) snum[index]) - 48;
    else
    {
        nInt = (nInt *= 10) + ((int) snum[index] - 48); //'0'=48
    }
    index++;
  }
  return(nInt);
}

  /*Implementing preprocessToken
    function: preprocess tokens before print them out. e.g. if -> IF; ( -> '('
  */
char* preprocessToken(char* token){
  char* ptr;
  int len=strlen(token);
  /*
  if(len==1||token[0]<'a'||token[0]>'z'){       //if token's length is one or the first character of token is not an alphabet,
    ptr=dynamicConcatenate(NULL,"'");           //wrap the token with ''
    ptr=dynamicConcatenate(ptr,token);
    ptr=dynamicConcatenate(ptr,"'");
    return ptr;
  }
  */
  int i,diff='A'-'a';
  for(i=0;i<len;i++){                           //convert s into upper-case
    if(token[i]<='z'&&token[i]>='a'){
      token[i]+=diff;
    }
  }
  return token;
}

  /*Implement create*/
char** create(){
  ptrTable=(char**)malloc(sizeof(char*)*TABLE_SIZE);      //dynamically allocate a 2-d array to ptrTable.
  entNum=0;
  return ptrTable;
}

  /*Implement lookup*/
int lookup(char* s){
  int i=0;
  for(;i<entNum;i++){                 //traverse the symbol table and return the index once the value of the index matches s
    if(strcmp(s,ptrTable[i])==0){
      return i;
    }
  }
  return -1;                        //return -1 if there is no s in the table
}
  /*Implement insert*/
int insert(char* s){
  int look=lookup(s);
  if(look>-1) return look;                          //if s is already in the table, return the index of it.
  else if(entNum<TABLE_SIZE){                       //otherwise, make sure the table is still available to insert s into it.
    ptrTable[entNum]=dynamicConcatenate(NULL,s);    //make a copy of s by concatenating NULL with s and store the copy into the table
    return entNum++;
  }
  return -1;    //return -1 for error
}

  /*Implement dump: print out all identifier in symbol table*/
void dump(){
  int i=0;
  printf("Symbol Table:\n");
  for(;i<entNum;i++){
    printf("[%d]:'%s'\n",i,ptrTable[i]);
  }
}
