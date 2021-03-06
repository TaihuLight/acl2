(in-package "ACL2")
(defun ACL22SMT () 
  (list
    (list #\# #\Space "Copyright" #\Space #\( "C" #\) #\Space "2015" #\, #\Space "University" #\Space "of" #\Space "British" #\Space "Columbia"  #\Newline )
    (list #\# #\Space "Written" #\Space #\( "originally" #\) #\Space "by" #\Space "Mark" #\Space "Greenstreet" #\Space #\( "13th" #\Space "March" #\, #\Space "2014" #\)  #\Newline )
    (list #\#  #\Newline )
    (list #\# #\Space "License" #\: #\Space "A" #\Space "3" "-" "clause" #\Space "BSD" #\Space "license" #\.  #\Newline )
    (list #\# #\Space "See" #\Space "the" #\Space "LICENSE" #\Space "file" #\Space "distributed" #\Space "with" #\Space "this" #\Space "software"  #\Newline )
    (list  #\Newline )
    (list "from" #\Space "z3" #\Space "import" #\Space "Solver" #\, #\Space "Bool" #\, #\Space "Int" #\, #\Space "Real" #\, #\Space "BoolSort" #\, #\Space "IntSort" #\, #\Space "RealSort" #\, #\Space "And" #\, #\Space "Or" #\, #\Space "Not" #\, #\Space "Implies" #\, #\Space "sat" #\, #\Space "unsat" #\, #\Space "Array" #\, #\Space "Select" #\, #\Space "Store" #\, #\Space "ToInt" #\, #\Space "Q" #\, #\Space "If"  #\Newline )
    (list  #\Newline )
    (list "def" #\Space "sort" #\( "x" #\) #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space "if" #\Space "type" #\( "x" #\) #\Space "=" "=" #\Space "bool" #\: #\Space #\Space #\Space #\Space "return" #\Space "BoolSort" #\( #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space "elif" #\Space "type" #\( "x" #\) #\Space "=" "=" #\Space "int" #\: #\Space #\Space #\Space "return" #\Space "IntSort" #\( #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space "elif" #\Space "type" #\( "x" #\) #\Space "=" "=" #\Space "float" #\: #\Space "return" #\Space "RealSort" #\( #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space "elif" #\Space "hasattr" #\( "x" #\, #\Space #\' "sort" #\' #\) #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "if" #\Space "x" #\. "sort" #\( #\) #\Space "=" "=" #\Space "BoolSort" #\( #\) #\: #\Space "return" #\Space "BoolSort" #\( #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "if" #\Space "x" #\. "sort" #\( #\) #\Space "=" "=" #\Space "IntSort" #\( #\) #\: #\Space #\Space "return" #\Space "IntSort" #\( #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "if" #\Space "x" #\. "sort" #\( #\) #\Space "=" "=" #\Space "RealSort" #\( #\) #\: #\Space "return" #\Space "RealSort" #\( #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "else" #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "raise" #\Space "Exception" #\( #\' "unknown" #\Space "sort" #\Space "for" #\Space "expression" #\' #\)  #\Newline )
    (list  #\Newline )
    (list "class" #\Space "ACL22SMT" #\( "object" #\) #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space "class" #\Space "status" #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "def" #\Space "__init__" #\( "self" #\, #\Space "value" #\) #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "self" #\. "value" #\Space "=" #\Space "value"  #\Newline )
    (list  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "def" #\Space "__str__" #\( "self" #\) #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "if" #\( "self" #\. "value" #\Space "is" #\Space "True" #\) #\: #\Space "return" #\Space #\' "QED" #\'  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "elif" #\( "self" #\. "value" #\. "__class__" #\Space "=" "=" #\Space #\' "msg" #\' #\. "__class__" #\) #\: #\Space "return" #\Space "self" #\. "value"  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "else" #\: #\Space "raise" #\Space "Exception" #\( #\' "unknown" #\Space "status" "?" #\' #\)  #\Newline )
    (list  #\Newline )
    (list "	" "	" "def" #\Space "isThm" #\( "self" #\) #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "return" #\( "self" #\. "value" #\Space "is" #\Space "True" #\)  #\Newline )
    (list  #\Newline )
    (list #\Space #\Space #\Space #\Space "class" #\Space "atom" #\: #\Space #\Space #\# #\Space "added" #\Space "my" #\Space "mrg" #\, #\Space "21" #\Space "May" #\Space "2015"  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space "def" #\Space "__init__" #\( "self" #\, #\Space "string" #\) #\:  #\Newline )
    (list "	" "self" #\. "who_am_i" #\Space "=" #\Space "string" #\. "lower" #\( #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space "def" #\Space "__eq__" #\( "self" #\, #\Space "other" #\) #\:  #\Newline )
    (list "	" "return" #\( "self" #\. "who_am_i" #\Space "=" "=" #\Space "other" #\. "who_am_i" #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space "def" #\Space "__ne__" #\( "self" #\, #\Space "other" #\) #\:  #\Newline )
    (list "	" "return" #\( "self" #\. "who_am_i" #\Space "!" "=" #\Space "other" #\. "who_am_i" #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space "def" #\Space "__str__" #\( "self" #\) #\:  #\Newline )
    (list "	" "return" #\( "self" #\. "who_am_i" #\)  #\Newline )
    (list  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "__init__" #\( "self" #\, #\Space "solver" "=" "0" #\) #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "if" #\( "solver" #\Space "!" "=" #\Space "0" #\) #\: #\Space "self" #\. "solver" #\Space "=" #\Space "solver"  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "else" #\: #\Space "self" #\. "solver" #\Space "=" #\Space "Solver" #\( #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "self" #\. "nameNumber" #\Space "=" #\Space "0"  #\Newline )
    (list  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "newVar" #\( "self" #\) #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "varName" #\Space "=" #\Space #\' "$" #\' #\Space "+" #\Space "str" #\( "self" #\. "nameNumber" #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "self" #\. "nameNumber" #\Space "=" #\Space "self" #\. "nameNumber" "+" "1"  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "return" #\Space "varName"  #\Newline )
    (list  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "isBool" #\( "self" #\, #\Space "who" #\) #\: #\Space "return" #\Space "Bool" #\( "who" #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "isInt" #\( "self" #\, #\Space "who" #\) #\: #\Space "return" #\Space "Int" #\( "who" #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "isReal" #\( "self" #\, #\Space "who" #\) #\: #\Space "return" #\Space "Real" #\( "who" #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "plus" #\( "self" #\, #\Space "*" "args" #\) #\: #\Space "return" #\Space "reduce" #\( "lambda" #\Space "x" #\, #\Space "y" #\: #\Space "x" "+" "y" #\, #\Space "args" #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "times" #\( "self" #\, #\Space "*" "args" #\) #\: #\Space "return" #\Space "reduce" #\( "lambda" #\Space "x" #\, #\Space "y" #\: #\Space "x" "*" "y" #\, #\Space "args" #\)  #\Newline )
    (list  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "reciprocal" #\( "self" #\, #\Space "x" #\) #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "if" #\( "type" #\( "x" #\) #\Space "is" #\Space "int" #\) #\: #\Space "return" #\( "Q" #\( "1" #\, "x" #\) #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "elif" #\( "type" #\( "x" #\) #\Space "is" #\Space "float" #\) #\: #\Space "return" #\Space "1" #\. "0" "/" "x"  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "else" #\: #\Space "return" #\Space "1" #\. "0" "/" "x"  #\Newline )
    (list  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "negate" #\( "self" #\, #\Space "x" #\) #\: #\Space "return" #\Space "-" "x"  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "lt" #\( "self" #\, #\Space "x" #\, "y" #\) #\: #\Space "return" #\Space "x" "<" "y"  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "equal" #\( "self" #\, #\Space "x" #\, "y" #\) #\: #\Space "return" #\Space "x" "=" "=" "y"  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "notx" #\( "self" #\, #\Space "x" #\) #\: #\Space "return" #\Space "Not" #\( "x" #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "implies" #\( "self" #\, #\Space "x" #\, #\Space "y" #\) #\: #\Space "return" #\Space "Implies" #\( "x" #\, "y" #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "Qx" #\( "self" #\, #\Space "x" #\, #\Space "y" #\) #\: #\Space "return" #\Space "Q" #\( "x" #\, "y" #\)  #\Newline )
    (list  #\Newline )
    (list #\Space #\Space #\Space #\Space #\# #\Space "type" #\Space "related" #\Space "functions"  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "integerp" #\( "self" #\, #\Space "x" #\) #\: #\Space "return" #\Space "sort" #\( "x" #\) #\Space "=" "=" #\Space "IntSort" #\( #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "rationalp" #\( "self" #\, #\Space "x" #\) #\: #\Space "return" #\Space "sort" #\( "x" #\) #\Space "=" "=" #\Space "RealSort" #\( #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "booleanp" #\( "self" #\, #\Space "x" #\) #\: #\Space "return" #\Space "sort" #\( "x" #\) #\Space "=" "=" #\Space "BoolSort" #\( #\)  #\Newline )
    (list  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "ifx" #\( "self" #\, #\Space "condx" #\, #\Space "thenx" #\, #\Space "elsex" #\) #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "return" #\Space "If" #\( "condx" #\, #\Space "thenx" #\, #\Space "elsex" #\)  #\Newline )
    (list  #\Newline )
    (list #\Space #\Space #\Space #\Space #\# #\Space "usage" #\Space "prove" #\( "claim" #\) #\Space "or" #\Space "prove" #\( "hypotheses" #\, #\Space "conclusion" #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space "def" #\Space "prove" #\( "self" #\, #\Space "hypotheses" #\, #\Space "conclusion" "=" "0" #\) #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "if" #\( "conclusion" #\Space "is" #\Space "0" #\) #\: #\Space "claim" #\Space "=" #\Space "hypotheses"  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "else" #\: #\Space "claim" #\Space "=" #\Space "Implies" #\( "hypotheses" #\, #\Space "conclusion" #\)  #\Newline )
    (list  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "self" #\. "solver" #\. "push" #\( #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "self" #\. "solver" #\. "add" #\( "Not" #\( "claim" #\) #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "res" #\Space "=" #\Space "self" #\. "solver" #\. "check" #\( #\)  #\Newline )
    (list  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "if" #\Space "res" #\Space "=" "=" #\Space "unsat" #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "print" #\Space #\" "proved" #\"  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "return" #\Space "self" #\. "status" #\( "True" #\) #\Space #\Space #\# #\Space "It" #\' "s" #\Space "a" #\Space "theorem"  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "elif" #\Space "res" #\Space "=" "=" #\Space "sat" #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "print" #\Space #\" "counterexample" #\"  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "m" #\Space "=" #\Space "self" #\. "solver" #\. "model" #\( #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "print" #\Space "m"  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\# #\Space "return" #\Space "an" #\Space "counterexample" "?" "?"  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "return" #\Space "self" #\. "status" #\( "False" #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "else" #\:  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "print" #\Space #\" "failed" #\Space "to" #\Space "prove" #\"  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "r" #\Space "=" #\Space "self" #\. "status" #\( "False" #\)  #\Newline )
    (list  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "self" #\. "solver" #\. "pop" #\( #\)  #\Newline )
    (list #\Space #\Space #\Space #\Space #\Space #\Space #\Space #\Space "return" #\( "r" #\)  #\Newline )
))