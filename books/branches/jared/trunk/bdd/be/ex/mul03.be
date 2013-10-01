@BE1

@invar
 (X1 Y1 X2 Y2 X3 Y3)

@sub
P$00.00 = 
(AND X1 Y1)
P$00.01 = 
(AND X1 Y2)
P$00.02 = 
(AND X1 Y3)
P$01.00 = 
(AND X2 Y1)
P$01.01 = 
(AND X2 Y2)
P$01.02 = 
(AND X2 Y3)
P$02.00 = 
(AND X3 Y1)
P$02.01 = 
(AND X3 Y2)
P$02.02 = 
(AND X3 Y3)
S$01.01 = 
(EXOR P$01.02 P$02.01)
C$01.01 = 
(AND P$01.02 P$02.01)
S$01.02 = 
(EXOR P$00.02 P$02.00)
C$01.02 = 
(AND P$00.02 P$02.00)
S$02.01 = 
(EXOR C$01.01 S$01.02 P$01.01)
S$02.02 = 
(EXOR C$01.02 P$01.00 P$00.01)
C$02.01 = 
(OR (AND C$01.01 S$01.02) (AND C$01.01 P$01.01) (AND S$01.02 P$01.01))
C$02.02 = 
(OR (AND C$01.02 P$01.00) (AND C$01.02 P$00.01) (AND P$01.00 P$00.01))
S$03.01 = 
(EXOR C$02.01 S$02.02)
C$03.01 = 
(AND C$02.01 S$02.02)
S$03.02 = 
(EXOR C$02.02 P$00.00 C$03.01)
C$03.02 = 
(OR (AND C$02.02 P$00.00) (AND C$02.02 C$03.01) (AND P$00.00 C$03.01))

@out
Z00 = 
(C$03.02) 
Z01 = 
(S$03.02) 
Z02 = 
(S$03.01) 
Z03 = 
(S$02.01) 
Z04 = 
(S$01.01) 
Z05 = 
(P$02.02) 
@end
@BE2

@invar
 (X1 X2 X3 Y1 Y2 Y3)

@sub
P&00.00 = 
(AND Y1 X1)
P&00.01 = 
(AND Y1 X2)
P&00.02 = 
(AND Y1 X3)
P&01.00 = 
(AND Y2 X1)
P&01.01 = 
(AND Y2 X2)
P&01.02 = 
(AND Y2 X3)
P&02.00 = 
(AND Y3 X1)
P&02.01 = 
(AND Y3 X2)
P&02.02 = 
(AND Y3 X3)
S&01.01 = 
(EXOR P&01.02 P&02.01)
C&01.01 = 
(AND P&01.02 P&02.01)
S&01.02 = 
(EXOR P&00.02 P&02.00)
C&01.02 = 
(AND P&00.02 P&02.00)
S&02.01 = 
(EXOR C&01.01 S&01.02 P&01.01)
S&02.02 = 
(EXOR C&01.02 P&01.00 P&00.01)
C&02.01 = 
(OR (AND C&01.01 S&01.02) (AND C&01.01 P&01.01) (AND S&01.02 P&01.01))
C&02.02 = 
(OR (AND C&01.02 P&01.00) (AND C&01.02 P&00.01) (AND P&01.00 P&00.01))
S&03.01 = 
(EXOR C&02.01 S&02.02)
C&03.01 = 
(AND C&02.01 S&02.02)
S&03.02 = 
(EXOR C&02.02 P&00.00 C&03.01)
C&03.02 = 
(OR (AND C&02.02 P&00.00) (AND C&02.02 C&03.01) (AND P&00.00 C&03.01))

@out
Z00 = 
(C&03.02)
Z01 = 
(S&03.02)
Z02 = 
(S&03.01)
Z03 = 
(S&02.01)
Z04 = 
(S&01.01)
Z05 = 
(P&02.02)
@end