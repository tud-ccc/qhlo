parser grammar qasm2Parser;

options {
    tokenVocab = qasm2Lexer;
}

// A complete OpenQASM 2 program must begin with the version statement.
//
// Included files are parsed through `includeFile`, since they are textually
// included into the enclosing program and do not contain their own version
// statement.
program
    : version statement* EOF
    ;

includeFile
    : statement* EOF
    ;

version
    : OPENQASM VersionSpecifier SEMICOLON
    ;

// OpenQASM 2 top-level statements.
//
// As in the OpenQASM 3 grammar, this grammar is primarily syntactic.
// Additional restrictions concerning declaration order, register types,
// gate-body operands, etc. belong to semantic analysis.
statement
    : includeStatement
    | oldStyleDeclarationStatement
    | gateStatement
    | opaqueDeclarationStatement
    | quantumOperation
    | ifStatement
    | barrierStatement
    ;

// Inclusion statements.

includeStatement
    : INCLUDE StringLiteral SEMICOLON
    ;

// Classical and quantum register declarations.
//
// OpenQASM 3 calls these "old-style declarations", so retaining that name
// gives the QASM 2 and QASM 3 parse trees a useful common vocabulary.
oldStyleDeclarationStatement
    : (CREG | QREG) Identifier designator SEMICOLON
    ;

// Gate and opaque declarations.

gateStatement
    : GATE Identifier
      (LPAREN params=identifierList? RPAREN)?
      qubits=identifierList
      scope
    ;

opaqueDeclarationStatement
    : OPAQUE Identifier
      (LPAREN params=identifierList? RPAREN)?
      qubits=identifierList
      SEMICOLON
    ;

// A gate body is intentionally more restricted than an ordinary statement
// sequence in OpenQASM 2.
scope
    : LBRACE gateOperation* RBRACE
    ;

gateOperation
    : gateCallStatement
    | barrierStatement
    ;

// Quantum operations.
//
// This rule is useful because an OpenQASM 2 `if` condition can guard exactly
// a quantum operation, not an arbitrary statement.
quantumOperation
    : gateCallStatement
    | measureArrowAssignmentStatement
    | resetStatement
    ;

// Built-in and user-defined gate invocation.
//
// U and CX require separate alternatives because OpenQASM 2 identifiers must
// begin with a lowercase letter, while the built-ins are spelled `U` and `CX`.
gateCallStatement
    : U LPAREN expressionList RPAREN gateOperand SEMICOLON
    | CX gateOperand COMMA gateOperand SEMICOLON
    | Identifier
      (LPAREN expressionList? RPAREN)?
      gateOperandList
      SEMICOLON
    ;

measureArrowAssignmentStatement
    : MEASURE gateOperand ARROW gateOperand SEMICOLON
    ;

resetStatement
    : RESET gateOperand SEMICOLON
    ;

barrierStatement
    : BARRIER gateOperandList SEMICOLON
    ;

// OpenQASM 2 has only one form of classical control flow.
ifStatement
    : IF
      LPAREN Identifier EqualityOperator DecimalIntegerLiteral RPAREN
      quantumOperation
    ;

// --------------------------------------------------------------------------
// Expressions
// --------------------------------------------------------------------------
//
// As in the canonical OpenQASM 3 grammar, ANTLR's direct left recursion is
// used to encode precedence.
//
// OpenQASM 2 uses `^` for exponentiation, rather than the OpenQASM 3 `**`.

expression
    : LPAREN expression RPAREN
        # parenthesisExpression

    | unaryOperator LPAREN expression RPAREN
        # callExpression

    | <assoc=right> expression op=CARET expression
        # powerExpression

    | op=MINUS expression
        # unaryExpression

    | expression op=(ASTERISK | SLASH) expression
        # multiplicativeExpression

    | expression op=(PLUS | MINUS) expression
        # additiveExpression

    | (
          Identifier
        | DecimalIntegerLiteral
        | FloatLiteral
        | PI
      )
        # literalExpression
    ;

unaryOperator
    : SIN
    | COS
    | TAN
    | EXP
    | LN
    | SQRT
    ;

// --------------------------------------------------------------------------
// Lists and operands
// --------------------------------------------------------------------------

expressionList
    : expression (COMMA expression)*
    ;

identifierList
    : Identifier (COMMA Identifier)*
    ;

gateOperandList
    : gateOperand (COMMA gateOperand)*
    ;

gateOperand
    : indexedIdentifier
    ;

indexedIdentifier
    : Identifier designator?
    ;

// Unlike OpenQASM 3, an OpenQASM 2 register size or index is specifically a
// non-negative integer literal, not a general expression.
designator
    : LBRACKET DecimalIntegerLiteral RBRACKET
    ;
