10000 constant MAX-SOURCE
create source MAX-SOURCE allot
create tmp 50 allot
variable input
variable copy
variable copy-len
variable fileid

\ Words to implement Meta II words
: advance 1 input +! ;
: save input @ copy ! ;
: restore copy @ input ! ;
: end-save  input @ copy @ - copy-len ! ;
: delete-blanks begin input @ c@ 1 33 within while advance repeat ;
: digit? ( -- ) input @ c@ [char] 0 [char] 9 1+ within ;
: letter? ( -- ) input @ c@ [char] A [char] z 1+ within ;
: @quote? ( -- ) @ c@ [char] ' = ;
: quote? ( -- ) input @quote? ;
: letters/digits begin advance letter? digit? or not until ;
: match? ( addr count -- count flag ) true swap 0 do over i + c@ input @ c@ advance = and loop nip ;
: copy>tmp copy @ tmp 2 + copy-len @ cmove tmp 2 + copy ! ;
: '>s" [char] s copy @ 2 - c! 34 copy @ 1 - c! 32 copy @ c! ;
: '>"  34 copy @ copy-len @ 1- + c! ;
: ''len>s""len copy @ 2 - copy ! copy-len @ 2 + copy-len ! ;
: ''>s"" ( -- ) '>s" '>" ''len>s""len ;
\ Meta II words. All expect a flag to be on the stack
: BGN 0 cr ; \ added by me
: SET drop true ;
: RST false and ;
: TST ( str -- ) delete-blanks save match? if end-save SET else restore RST then ; 
: NUM delete-blanks digit? if SET save begin advance digit? not until end-save else RST then ;
: ID delete-blanks letter? if SET save letters/digits end-save else RST then ;
: SR delete-blanks quote? if SET save advance begin quote? not while advance repeat advance end-save else RST then ;
: BE dup not ABORT" Error" ;
: CL ( str -- ) type space ;
: CI copy @quote? if  copy>tmp ''>s"" then copy @ copy-len @ type space ;
: OUT cr ;
: END cr if ." COMPILATION COMPLETE" else ." ERRORS IN COMPILATION" then ;

\ Input
: reset-input ( -- ) source input ! ;
: open-source ( fname -- ) r/o open-file ABORT" open file failed" fileid ! ;
: read-source ( -- ) source MAX-SOURCE fileid @ read-file ABORT" Read failed" drop ;
: close-source ( -- ) fileid @ close-file ABORT" close file failed" ;
: load ( fname -- )   open-source read-source close-source reset-input ;

\ Meta II Meta Compiler Bootstrap
: OUT1 
s" *" TST dup IF 
	s" CI" CL OUT 
THEN 
dup not IF 
	SR dup IF CI s" CL" CL OUT THEN 
THEN ;

: OUTPUT 
s" .OUT" TST dup IF 
	s" (" TST BE BEGIN OUT1 dup not UNTIL SET BE s" )" TST BE s" OUT" CL OUT
THEN ;
DEFER EX1
: EX3
ID dup IF CI OUT THEN
dup not IF 
	SR dup IF CI s" TST" CL OUT  THEN
THEN
dup not IF 
	s" .ID" TST dup IF s" ID" CL OUT  THEN
THEN
dup not IF 
	s" .NUMBER" TST dup IF s" NUM" CL OUT  THEN
THEN
dup not IF 
	s" .STRING" TST dup IF s" SR" CL OUT  THEN
THEN
dup not IF 
	s" (" TST dup IF EX1 BE s" )" TST BE THEN
THEN
dup not IF 
	s" .EMPTY" TST dup IF s" SET" CL THEN
THEN 
dup not IF 
	s" $" TST dup IF s" BEGIN" CL OUT RECURSE s" dup not UNTIL" CL OUT s" SET" CL OUT THEN
THEN ;
: EX2
EX3 dup IF 
	s" dup IF" CL OUT 
	BEGIN 
		EX3 dup IF s" BE" CL OUT THEN dup not IF OUTPUT THEN dup not 
	UNTIL 
	SET	
	s" THEN" CL OUT 
THEN 
dup not IF 
	OUTPUT dup IF 
		BEGIN 
			EX3 dup IF s" BE" CL OUT THEN dup not IF OUTPUT THEN dup not
		UNTIL
		SET
	THEN
THEN ;
:NONAME
EX2
BEGIN 
	s" /" TST dup IF s" dup not IF" CL OUT EX2 BE s" THEN" CL OUT THEN dup not 
UNTIL SET ; IS EX1
DEFER RULE
:NONAME 
s" .RULE" TST dup IF 
	ID BE s" DEFER" CL CI OUT BEGIN RULE dup not UNTIL SET
	s" .BEGIN" TST BE s" :NONAME" CL OUT EX1 BE s" .END" TST BE ID BE s" ; IS" CL CI OUT 
THEN ; IS RULE
: PROGRAM
s" .SYNTAX" TST
dup IF ID BE s" DEFER" CL CI OUT 
	BEGIN RULE dup not
	UNTIL SET
	s" .BEGIN" TST BE s" :NONAME" CL OUT EX1 BE s" .END" TST BE ID s" ; IS" CL CI OUT
THEN ;

