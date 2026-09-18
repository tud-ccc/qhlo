lexer grammar qasm2Lexer;

// Naming follows the canonical OpenQASM 3 lexer:
//
// - Keywords and exact symbols use ALL_CAPS.
// - Tokens whose spelling contains additional information use PascalCase.

// --------------------------------------------------------------------------
// Language keywords
// --------------------------------------------------------------------------

OPENQASM
    : 'OPENQASM' -> pushMode(VERSION_IDENTIFIER)
    ;

INCLUDE
    : 'include' -> pushMode(ARBITRARY_STRING)
    ;

OPAQUE
    : 'opaque'
    ;

GATE
    : 'gate'
    ;

IF
    : 'if'
    ;

// Register types.

QREG
    : 'qreg'
    ;

CREG
    : 'creg'
    ;

// Quantum instructions.

RESET
    : 'reset'
    ;

MEASURE
    : 'measure'
    ;

BARRIER
    : 'barrier'
    ;

// Built-in gates.
//
// These cannot be lexed as Identifier because OpenQASM 2 identifiers begin
// with a lowercase letter.

U
    : 'U'
    ;

CX
    : 'CX'
    ;

// Built-in mathematical names.

PI
    : 'pi'
    ;

SIN
    : 'sin'
    ;

COS
    : 'cos'
    ;

TAN
    : 'tan'
    ;

EXP
    : 'exp'
    ;

LN
    : 'ln'
    ;

SQRT
    : 'sqrt'
    ;

// --------------------------------------------------------------------------
// Symbols
// --------------------------------------------------------------------------

LBRACKET
    : '['
    ;

RBRACKET
    : ']'
    ;

LBRACE
    : '{'
    ;

RBRACE
    : '}'
    ;

LPAREN
    : '('
    ;

RPAREN
    : ')'
    ;

SEMICOLON
    : ';'
    ;

COMMA
    : ','
    ;

ARROW
    : '->'
    ;

PLUS
    : '+'
    ;

MINUS
    : '-'
    ;

ASTERISK
    : '*'
    ;

SLASH
    : '/'
    ;

CARET
    : '^'
    ;

EqualityOperator
    : '=='
    ;

// --------------------------------------------------------------------------
// Literals and identifiers
// --------------------------------------------------------------------------

fragment Digit
    : [0-9]
    ;

fragment Digits
    : Digit+
    ;

fragment Exponent
    : [eE] [+-]? Digits
    ;

// OpenQASM 2's `real` production requires a decimal point.
//
// Valid:
//     1.0
//     1.
//     .5
//     1.0e-3
//
// Not a FloatLiteral:
//     1
//     1e3

FloatLiteral
    : (
          Digits '.' Digits?
        | '.' Digits
      )
      Exponent?
    ;

// nninteger from the OpenQASM 2 specification.
//
// Leading zeroes are intentionally excluded except for zero itself.

DecimalIntegerLiteral
    : '0'
    | [1-9] Digit*
    ;

// OpenQASM 2 identifiers begin with a lowercase ASCII letter.

Identifier
    : [a-z] [A-Za-z0-9_]*
    ;

// --------------------------------------------------------------------------
// Whitespace and comments
// --------------------------------------------------------------------------

Whitespace
    : [ \t]+ -> skip
    ;

Newline
    : [\r\n]+ -> skip
    ;

LineComment
    : '//' ~[\r\n]* -> channel(HIDDEN)
    ;

// --------------------------------------------------------------------------
// Version
// --------------------------------------------------------------------------
//
// Like the canonical OpenQASM 3 lexer, use a separate lexer mode because the
// version literal would otherwise overlap numerical literals.
//
// The semantic frontend should verify that the version is exactly 2.0.

mode VERSION_IDENTIFIER;

VERSION_IDENTIFIER_WHITESPACE
    : [ \t\r\n]+ -> skip
    ;

VersionSpecifier
    : [0-9]+ '.' [0-9]+ -> popMode
    ;

// --------------------------------------------------------------------------
// Include filename
// --------------------------------------------------------------------------
//
// OpenQASM 2 specifies the double-quoted include form.

mode ARBITRARY_STRING;

ARBITRARY_STRING_WHITESPACE
    : [ \t\r\n]+ -> skip
    ;

StringLiteral
    : '"' ~["\r\n]+ '"' -> popMode
    ;
