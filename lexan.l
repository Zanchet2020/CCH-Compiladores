%{
#include <iostream>
#include <string>
#include <cstring>
#include "bison.tab.h"
%}

%option noyywrap
%x COMMENT
%x TEMPLATE

delim     [ \t\n\r\a\b\f]
brancos   {delim}+

letra     [a-zA-Z]
digito    [0-9]

id        {letra}({letra}|{digito}|_)*
num_int   {digito}+

%%

<INITIAL,TEMPLATE>{brancos}      { }

    /* Ignora a linha "Arcanum:..." (Note o espaço antes do comentário) */
"Arcanum:"[^\n]*\n   { }

    /* Comentário multilinha: Arcanum[: ... :] */
"Arcanum[:"        { BEGIN(COMMENT); }

<COMMENT>":]"      { BEGIN(INITIAL); }
<COMMENT><<EOF>>   {
                      std::cerr << "Erro lexico: comentario multilinha nao fechado!\n";
                      exit(1);
                   }
<COMMENT>\n        { }
<COMMENT>.         { }


    /* --- MUDANÇA DE ESTADOS --- */

    /* Entra no Template */
"|:"               { BEGIN(TEMPLATE); return LPAR_EXPR; }

    /* Sai do Template */
<TEMPLATE>":|" {
    BEGIN(INITIAL);
    return RPAR_EXPR;
}

    /* --- REGRAS COMPARTILHADAS (INITIAL e TEMPLATE) --- */
    /* Isso evita duplicar código para operadores que existem nos dois contextos */

<INITIAL,TEMPLATE>"++" { return MAISMAIS; }
<INITIAL,TEMPLATE>"--" { return MENOSMENOS; }
<INITIAL,TEMPLATE>"==" { return IGUAL; }
<INITIAL,TEMPLATE>"!=" { return DIFERENTE; }
<INITIAL,TEMPLATE>"<=" { return MENORIGUAL; }
<INITIAL,TEMPLATE>">=" { return MAIORIGUAL; }

<INITIAL,TEMPLATE>"+"  { return MAIS; }
<INITIAL,TEMPLATE>"-"  { return MENOS; }
<INITIAL,TEMPLATE>"*"  { return MULT; }
<INITIAL,TEMPLATE>"/"  { return DIV; }
<INITIAL,TEMPLATE>"%"  { return MOD; }
<INITIAL,TEMPLATE>"<"  { return MENOR; }
<INITIAL,TEMPLATE>">"  { return MAIOR; }

<INITIAL,TEMPLATE>","  { return VIRGULA; }

    /* Acesso a vetores dentro e fora */
<INITIAL,TEMPLATE>"{"  { return LCOLCHETES; }
<INITIAL,TEMPLATE>"}"  { return RCOLCHETES; }


    /* --- REGRAS ESPECÍFICAS DO INITIAL --- */

    /* Delimitadores de bloco */
"[:"               { return LCHAVES; }
":]"               { return RCHAVES; }

"."                { return PEV; }
":"                { return DOISPONTOS; }

    /* Palavras reservadas */
"PRONUNTIARE"      { return PRINTF; }
"INSCULPIRE"       { return SCANF; }
"inteiro"          { return INT; }
"float"            { return FLOAT; }
"char"             { return CHAR; }
"CIRCA"            { return FOR; }
"ITERARE"          { return WHILE; }
"SIVERITAS"        { return IF; }
"ALITER"           { return ELSE; }
"REVERSIO"         { return RETURN; }
"SYMBOLUM"         { return DECLARACAO; }
"ET"               { return AND; }
"VEL"              { return OR; }
"NON"              { return NOT; }
"ACCIPIT"          { return ATRIB; }


    /* --- LITERAIS (INITIAL e TEMPLATE) --- */

<INITIAL,TEMPLATE>{num_int} {
    yylval.int_val = atoi(yytext);
    return NUM;
}

<INITIAL,TEMPLATE>{id} {
    yylval.str_val = new std::string(yytext);
    return ID;
}

<INITIAL,TEMPLATE>\"([^"\\]|\\.)*\" {
    std::string s(yytext);
    /* Remove as aspas */
    if (s.size() >= 2)
        s = s.substr(1, s.size() - 2);
    
    /* CORREÇÃO: Usando 's' em vez de yytext */
    yylval.str_val = new std::string(s);
    return STRING;
}


    /* --- TRATAMENTO DE ERROS --- */

<TEMPLATE><<EOF>> {
    std::cerr << "Erro lexico: template nao fechado (falta :|)\n";
    exit(1);
}

<TEMPLATE>. {
    std::cerr << "Erro lexico: token invalido no template '" << yytext << "'\n";
    exit(1);
}

    /* Catch-all para INITIAL */
. {
    std::cerr << "Erro lexico: token invalido '" << yytext << "'\n";
    exit(1);
}

%%