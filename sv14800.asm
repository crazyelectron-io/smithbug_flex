                TITL  "Smithbug V1.0"
; HRJ reconstructed from imaged JPEG source listing  July 30 2019
; source listing SMITHBUG V1.0 from Mike Lee April 2019
; also provided V2.0 ASM, this ASM edited back to V1.0
; in original listing, SREG and PCTR defined as FCC not FCB was error
; listing also replaced ACIA code with jumps to F000 ROM monitor
;
;May 16 2022 HRJ assembled at 4800H to compare to FLEX smithbug binary
; changed this source to match FLEX disassmbly

;M      MOVE MEMORY
;E      CHANGE MEMORY
;G      GO TO PROGRAM
;R      PRINT
;T      TRACE PROGRAM
;@      ASCII CONVERSION
;H      PRINTER ON
;V      VIEW MEMORY
;I      FILL MEMORY
;J      JUMP TO TARGET PROGRAM
;F      FIND 
;Q      HARDWARE LOCATION
;D      DISASSEMBLE CODE
;K      CONTINUE AFTER BREAK
;1      BREAKPOINT ONE
;2      BREAKPOINT TWO
;&      S1 LOAD PROGRAMME (V2.0 addition, V1 loaded seperately)
;*      HARDWARE LOCATION (TBA), just restarts this code
;O      ECHO ON
;N      ECHO OFF
; 

ACIAS           EQU     $8004		;change in FLEX
ACIAD           EQU     $8005		;change in FLEX

;
;OPT    MEMORY
;
                ORG     $4800		;FLEX library binary
;
;ENTER POWER ON SEQUENCE
;
START           LDS     #STACK
                STS     SP
                CLR     ECHO
                LDX     #SFE
                STX     SWIPTR
                STX     NIO
;
;ACIA INITIALISE
;
                LDAA    #$03             ;RESET CODE
                STAA    ACIAS
                LDAA    #$15             ;8N1 NON-INTERRUPT
                STAA    ACIAT
;
;COMMAND CONTROL
;
CONTRL          LDA A   ACIAT
                STA A   ACIAS
                LDS     #TSTACK          ;SET CONTRL STACK POINTER
                CLR     TFLAG
                CLR     BKFLG
                CLR     BKFLG2
                LDX     #MCL
                BSR     PDATA1
                BSR     INCH
                TAB
                JSR     OUTS
;
; CHECK IF COMMAND IS VALID AND JUMP TO APPLICATION
;
                LDX     #FUTABL
NXTCHR          CMP B   0,X
                BEQ     GOODCH
                INX
                INX
                INX
                CPX     #TBLEND
                BNE     NXTCHR
                JMP     CKCBA
GOODCH          LDX     1,X
                JMP     0,X
;
;  IRQ INTERUPT SEQUENCE
;
IO              LDX     IOV
                JMP     0,X
;
;  NMI SEQUENCE
;
POWDWN          LDX     NIO
                JMP     0,X
;
;  SWI SEQUENCE
;
SWI             LDX     SWIPTR
                JMP     0,X
LOAD19          LDA A   #$3F
                BSR     OUTCH
C1              BRA     CONTRL
;
;  BUILD ADDRESS
;
BADDR           BSR     BYTE
                STA A   XHI
                BSR     BYTE
                STA A   XLOW
                LDX     XHI
                RTS
;
;  INPUT ONE BYTE
;
BYTE            BSR     INHEX
                ASL A
                ASL A
                ASL A
                ASL A
                TAB
                BSR     INHEX
                ABA
                RTS
;
;  OUTPUT LEFT HEX NUMBER
;
OUTHL           LSR A
                LSR A
                LSR A
                LSR A
;
;  OUTPUT RIGHT HEX NUMBER
;
OUTHR           AND A   #$F
                ADD A   #$30
                CMP A   #$39
                BLS     OUTCH
                ADD A   #$7
OUTCH           JMP     OUTEEE
INCH            JMP     INEEE
;
PDATA2          BSR     OUTCH	;FLEX binary patched this code to nop nop nop (01 01 01)
                INX
PDATA1          LDA A   0,X	;FLEX binary patched this code to JMP $E07E (7E e0 7e)
                CMP A   #$4	;FLEX binary patched this code to nop nop nop nop (01 0101 01)
                BNE     PDATA2
                RTS	
                                ;End of FLEX patch		 
;
; CHANGE MEMORY
;
CHANGE          BSR     BADDR
CHA51           LDX     #MCL

                                ;FLEX binary patched this code, appears non-executable
                                ; FCB   A7 B4 FD FE D3 97 CB 93 
                                ; FCB   ED 3E B6 FD 11 BF 03 93 5E 
                BSR     PDATA1
                BSR     OUTXHI
                BSR     OUT2HS
                STX     XHI
                BSR     INCH
                CMP A   #$20
                BEQ     CHA51
                CMP A   #$5E

                               ;end of FLEX patching, following code matches V1 source 
                BNE     CHM1	
                DEX
                DEX
                STX     XHI
                BRA     CHA51
CHM1            BSR     INHEX+2
                BSR     BYTE+2
                DEX
                STA A   0,X
                CMP A   0,X
                BEQ     CHA51
;
XBK             BRA     LOAD19
;
INHEX           BSR     INCH
                SUB A   #$30
                BMI     C1
                CMP A   #$9
                BLE     IN1HG
                CMP A   #$11
                BMI     C1
                CMP A   #$16
                BGT     C1
                SUB A   #$7
IN1HG           RTS
;
;
OUT2H           LDA A   0,X
                BSR     OUTHL
                LDA A   0,X
                INX
                BRA     OUTHR
;
OUT4HS          BSR     OUT2H
OUT2HS          BSR     OUT2H
OUTS            LDA A   #$20
                BRA     OUTCH
;
; SET BREAK POINTS
;
BKPNT2          JSR     ADDR
                STX     PC1
                LDA A   0,X
                STA A   BKFLG2
                BEQ     XBK
                LDA A   #$3F
                STA A   0,X
BKPNT           JSR     ADDR
                STX     PB2
                LDA A   0,X
                STA A   BKFLG
                BEQ     XBK
                LDA A   #$3F
                STA A   0,X
                JSR     CRLF
;
; FALL INTO GO COMMAND
;
CONTG           LDS     SP
                RTI
;
; PRINT XHI ADDRESS SUB
;
OUTXHI          LDX     #XHI
                BSR     OUT4HS
                LDX     XHI
                RTS
;
; VECTORED SWI ROUTINE
;
SFE             STS     SP
                TSX
                TST     6,X
                BNE     *+4
                DEC     5,X
                DEC     6,X
                LDS     #TSTACK
                TST     TFLAG
                BEQ     PRINT
                LDX     PC1
                LDA A   OPSAVE
                STA A   0,X
                TST     BFLAG
                BEQ     DISPLY
                LDX     BPOINT
                LDA A   BPOINT+2
                STA A   0,X
DISPLY          JMP     RETURN
;
; PRINT REGISTERS
;
PRINT           LDX     SP
                LDA A   #6
                STA A   MCONT
                LDA B   1,X
                ASL B
                ASL B
                LDX     #CSET
;
DSOOP           LDA A   #$2D
                ASL B
                BCC     DSOOP1
                LDA A   0,X
DSOOP1          JSR     OUTEEE
                INX
                DEC     MCONT
                BNE     DSOOP
                LDX     #BREG
                BSR     PDAT
                LDX     SP
                INX
                INX
                JSR     OUT2HS
                STX     TEMP
                LDX     #AREG
                BSR     PDAT
                LDX     TEMP
                JSR     OUT2HS
                STX     TEMP
                LDX     #XREG
                BSR     PDAT
                LDX     TEMP
                BSR     PRTS
                STX     TEMP
                TST     TFLAG
                BNE     PNTS
                LDX     #PCTR
                BSR     PDAT
                LDX     TEMP
                BSR     PRTS
PNTS            LDX     #SREG
                BSR     PDAT
                LDX     #SP
                TST     TFLAG
                BNE     PRINTS
                BSR     PRTS
;
; CHECK IF ANY BREAK POINTS ARE SET
;
                LDA A   BKFLG
                BEQ     C2		;BNE in V1 code, BEQ in FLEX code!!
                LDX     PB2
                STA A   0,X
                LDA A   BKFLG2
                BEQ     C2
                LDX     PC1
                STA A   0,X
C2              BRA     CR8
PDAT            JMP     PDATA1
;
; SET ECHO FUNCTION
;
ECHON           CLR B
PRNTON          NEG B
ECHOFF          STA B   ECHO
                BRA     CR8
;
;  PRINT STACK POINTER
;
PRINTS          LDA B   0,X
                LDA A   1,X
                ADD A   #7
                ADC B   #0
                STA B   TEMP
                STA A   TEMP+1
                LDX     #TEMP
PRTS            JMP     OUT4HS
;
;INPUT ONE CHAR INTO A-REGISTER
;
INEEE           LDAA    ACIAS
                ASRA
                BCC     INEEE            ;RECEIVE NOT READY
                LDAA    ACIAD            ;INPUT CHARACTER
                ANDA    #$7F             ;RESET PARITY BIT
                CMPA    #$7F
                BEQ     INEEE            ;IF RUBOUT, GET NEXT CHAR
                TST     ECHO
                BLE     OUTEEE
                RTS
;
CR8             BRA     IFILL1
;
;
;OUTPUT ONE CHAR 
;
OUTEEE          TST     ECHO
                BGE     OTST2
                JMP     PRINTR
OTST2           PSH B
OT3             LDA B   ACIAS
                ASR B
                ASR B
                BCC     OT3
                STA A   ACIAD
                PUL B
                RTS
;
;  HERE ON JUMP COMMAND
;
JUMP            LDX     #TOADD
                BSR     ENDADD+3
                LDS     #STACK
                JMP     0,X
;
;  ASCII IN "@" COMMAND
;
ASCII           BSR     BAD2
                INX
ASC01           DEX
ASC02           BSR     INEEE
                CMP A   #$8
                BEQ     ASC01
                STA A   0,X
                CMP A   #$4
                BEQ     CR9
                INX
                BRA     ASC02
;
;  FILL MEMORY "I" COMMAND
;
IFILL           BSR     LIMITS
                BSR     VALUE
                LDX     BEGA
                DEX
IFILL2          INX
                STA A   0,X
                CPX     ENDA
                BNE     IFILL2
IFILL1          BRA     CR9
;
;  INPUT DATA SUB ROUTINE
;
BAD2            LDX     #FROMAD
                BRA     *+5
ENDADD          LDX     #THRUAD
                JSR     PDATA1
                JMP     BADDR
LIMITS          BSR     BAD2
                STX     BEGA
                BSR     ENDADD
                STX     ENDA
                JMP     CRLF
ADDR            LDX     #ADASC	;FLEX code has LDX #ADASC, V1 code has LDX ADASC
                BRA     ENDADD+3
VALUE           LDX     #VALASC
                JSR     PDATA1
                JMP     BYTE
;
; BLOCK MOVE "M" COMMAND
;
MOVE            BSR     LIMITS
                LDX     #TOADD
                BSR     ENDADD+3
                LDX     BEGA
                DEX
BMC1            INX
                LDA A   0,X
                STX     BEGA
                LDX     XHI
                STA A   0,X
                INX
                STX     XHI
                LDX     BEGA
                CPX     ENDA
                BNE     BMC1
CR9             JMP     CONTRL
;
;  SEARCH MEMORY "S" COMMAND
;
FIND            BSR     LIMITS
                BSR     VALUE
                TAB
                LDX     BEGA
                DEX
SMC1            INX
                LDA A   0,X
                CBA
                BNE     SMC2
                STX     XHI
                BSR     CRLF
                JSR     OUTXHI
SMC2            CPX     ENDA
                BNE     SMC1
                BRA     CR9
;
;  SUB ROUTINE TO ADD SPACE
;
SKIP            LDA A   #$20
                JSR     OUTEEE
                DEC B
                BNE     SKIP
                RTS
;
;  PRINT BYTE IN A REGISTER
;
PNTBYT          STA A   BYTECT
                LDX     #BYTECT
                JMP     OUT2H
;
;  CARRIAGE RETURN NON PROMPT
;
CRLF            LDX     #CRLFAS
                JMP     PDATA1
;
;  DISASSEMBLE "D" COMMAND
;
DISSA           JSR     BAD2
                BRA     DISS
;
;  TRACE COMMAND "T"
;
TRACE           JSR     BAD2
                BSR     CRLF
                LDX     SP
                LDA B   XHI
                STA B   6,X
                LDA A   XLOW
                STA A   7,X
KONTIN          INC     TFLAG
RETURN          JSR     PRINT
                LDX     SP
                LDX     6,X
DISS            STX     PC1
DISIN           BSR     CRLF
                LDX     #PC1
                JSR     OUT4HS
                LDX     #BFLAG
                LDA A   #5
CLEAR           CLR     0,X
                INX
                DEC A
                BNE     CLEAR
                LDX     PC1
                LDA B   0,X
                JSR     OUT2HS
                STX     PC1
                LDA A   0,X
                STA A   PB2
                LDA A   1,X
                STA A   PB3
                STA B   PB1
                TBA
                JSR     TBLKUP
                LDA A   TEMP
                CMP A   #$2A
                BNE     OKOP
                JMP     NOTBB
OKOP            LDA A   PB1
                CMP A   #$8D
                BNE     NEXT
                INC     BFLAG
                BRA     PUT1
NEXT            AND A   #$F0
                CMP A   #$60
                BEQ     ISX
                CMP A   #$A0		;code not in V1 HRJ
                BEQ     ISX
                CMP A   #$E0
                BEQ     ISX
                CMP A   #$80		;code in V1 listing HRJ
                BEQ     IMM
                CMP A   #$C0
                BNE     PUT1
IMM             INC     MFLAG
                LDX     #SPLBD0
                BRA     PUT
ISX             INC     XFLAG
                LDA A   PB2
                JSR     PNTBYT
                LDX     #COMMX
PUT             JSR     PDATA1
PUT1            LDX     PC1
                LDA A   PB1
                CMP A   #$8C
                BEQ     BYT3
                CMP A   #$8E
                BEQ     BYT3
                CMP A   #$CE
                BEQ     BYT3
                AND A   #$F0
                CMP A   #$20
                BNE     NOTB
                INC     BFLAG
                BRA     BYT2
NOTB            CMP A   #$60
                BCS     BYT1
                AND A   #$30
                CMP A   #$30
                BNE     BYT2
BYT3            INC     BITE3
                TST     MFLAG
                BNE     BYT31
                LDA A   #$24
                JSR     OUTEEE
BYT31           LDA A   0,X
                INX
                STX     PC1
                JSR     PNTBYT
                LDX     PC1
                BRA     BYT21
BYT2            INC     BITE2
BYT21           LDA A   0,X
                INX
                STX     PC1
                TST     XFLAG
                BNE     BYT1
                TST     BITE3
                BNE     BYT22
                TST     MFLAG
                BNE     BYT22
                TAB
                LDA A   #$24
                JSR     OUTEEE
                TBA
BYT22           JSR     PNTBYT
BYT1            TST     BFLAG
                BEQ     NOTBB
                LDA B   #3
                JSR     SKIP
                CLR A
                LDA B   PB2
                BGE     DPOS
                LDA A   #$FF
DPOS            ADD B   PC2
                ADC A   PC1
                STA A   BPOINT
                STA B   BPOINT+1
                LDX     #BPOINT
                JSR     OUT4HS
;
; PRINT ASCII VALUE OF INST
;
NOTBB           LDA B   #$D
                LDA A   #1
                TST     BITE2
                BEQ     PAVOI3
                LDA B   #1
                TST     BFLAG
                BNE     PAVOI2
                LDA B   #8
                TST     MFLAG	;FLEX code has A04E, V1 source has A04E = MFLAG
                BNE     PAVOI2
                TST     XFLAG	;FLEX code has A04F = XFLAG, V1 source has A04E
                BNE     PAVOI2
                LDA B   #9
PAVOI2          LDA A   #2
                BRA     PAVOI8
;
PAVOI3          TST     BITE3
                BEQ     PAVOI8
                LDA A   #3
                LDA B   #6
                TST     MFLAG
                BEQ     PAVOI8
                LDA B   #8		;FLEX code has #8, V1 source has #5
PAVOI8          PSH A
                JSR     SKIP
                PUL B
                LDX     #PB1
PAVOI4          LDA A   0,X
                CMP A   #$20
                BLE     PAVOI5
                CMP A   #$60
                BLE     PAVOI9
PAVOI5          LDA A   #$2E
PAVOI9          INX
                JSR     OUTEEE
                DEC B
                BNE     PAVOI4
NOT1            JSR     INEEE
                TAB
                JSR     OUTS
                CMP B   #$20
                BEQ     DOT
;
;  CHECK INPUT COMMAND
;  A, B, C, X, OR S
;
CKCBA           LDX     SP
                INX
                CMP B   #$43
                BEQ     RDC
                INX
                CMP B   #$42
                BEQ     RDC
                INX
                CMP B   #$41
                BEQ     RDC
                INX
                CMP B   #$58
                BEQ     RDX
                LDX     #SP
                CMP B   #$53
                BNE     RETNOT
RDX             JSR     BYTE
                STA A   0,X
                INX
RDC             JSR     BYTE
                STA A   0,X
                JSR     CRLF
                JSR     PRINT
;
;  WILL RETURN HERE IN TRACE
;
                BRA     NOT1
RETNOT          JMP     CONTRL
DOT             TST     TFLAG
                BNE     DOT1
                JMP     DISIN
;
DOT1            LDA B   #$3F
                LDA A   PB1
                CMP A   #$8D
                BNE     TSTB
                LDX     BPOINT
                STX     PC1
                CLR     BFLAG
TSTB            TST     BFLAG
                BEQ     TSTJ
                LDX     BPOINT
                LDA A   0,X
                STA A   BPOINT+2
                STA B   0,X
                BRA     EXEC
;
TSTJ            CMP A   #$6E
                BEQ     ISXD
                CMP A   #$AD
                BEQ     ISXD
                CMP A   #$7E
                BEQ     ISJ
                CMP A   #$BD
                BNE     NOTJ
ISJ             LDX     PB2
                STX     PC1
                BRA     EXEC
ISXD            LDX     SP
                LDA A   5,X
                ADD A   PB2
                STA A   PC2
                LDA A   4,X
                ADC A   #0
                STA A   PC1
                BRA     EXEC
;
NOTJ            LDX     SP
                CMP A   #$39
                BNE     NOTRTS
NOTJ1           LDX     8,X
                BRA     EXR
;
NOTRTS          CMP A   #$38
                BNE     NOTRTI
                LDX     13,X
EXR             STX     PC1
NOTRTI          CMP A   #$3F
                BEQ     NONO
                CMP A   #$3E
                BEQ     NONO
;
EXEC            LDX     PC1
                LDA A   0,X
                STA A   OPSAVE
                STA B   0,X
                CMP B   0,X
                BNE     CKROM
                JMP     CONTG
;
NONO            JMP     LOAD19
;
CKROM           LDA A   PC1
                CMP A   #$E0
                BCS     NONO
;
;  GET JSR OR JMP
;
                LDX     SP
                LDA A   PB1
                CMP A   #$7E
                BEQ     NOTJ1
                CMP A   #$BD
                BNE     NONO
                LDX     6,X
                INX
                INX
                INX
                BRA     ISJ+3
;
;  OP CODES LOOKUP 
;
TBLKUP          CMP A   #$40
                BCC     IMLR6
IMLR1           JSR     PNT3C
                LDA A   PB1
                CMP A   #$32
                BEQ     IMLR3
                CMP A	   #$36  ;had � instead of #
                BEQ     IMLR3
                CMP A   #$33
                BEQ     IMLR4
                CMP A   #$37
                BEQ     IMLR4
IMLR2           LDX     #BLANK
                BRA     IMLR5
;
IMLR3           LDX     #PNTA
                BRA     IMLR5
;
IMLR4           LDX     #PNTB
IMLR5           JMP     PDATA1
IMLR6           CMP A   #$4E
                BEQ     IMLR7
                CMP A   #$5E
                BNE     IMLR8
;
IMLR7           CLR A
                BRA     IMLR1
;
IMLR8           CMP A   #$80
                BCC     IMLR9
                AND A   #$4F
                JSR     PNT3C
                LDA A   TEMP
                CMP A   #$2A
                BEQ     IMLR2
                LDA A   PB1
                CMP A   #$60
                BCC     IMLR2
                AND A   #$10
                BEQ     IMLR3
                BRA     IMLR4
;
IMLR9           AND A   #$3F
                CMP A   #$F
                BEQ     IMLR7
                CMP A   #$7
                BEQ     IMLR7
                AND A   #$F
                CMP A   #$3
                BEQ     IMLR7
                CMP A   #$C
                BGE     IMLR10
                ADD A   #$50
                JSR     PNT3C
                LDA A   PB1
                AND A   #$40
                BEQ     IMLR3
                BRA     IMLR4
;
IMLR10          LDA A   PB1
                CMP A   #$8D
                BNE     IMLR11
                LDA A   #$53
                BRA     IMLR1
;
IMLR11          CMP A   #$C0
                BCC     IMLR12
                CMP A   #$9D
                BEQ     IMLR7
                AND A   #$F
                ADD A   #$50
                BRA     IMLR13
;
IMLR12          AND A   #$F
                ADD A   #$52
                CMP A   #$60
                BLT     IMLR7
;
IMLR13          JMP     IMLR1
;
PNT3C           CLR B
                STA A   TEMP
                ASL A
                ADD A   TEMP
                ADC B   #$0
                LDX     #TBL
                STX     XTEMP
                ADD A   XTEMP+1
                ADC B   XTEMP
                STA B   XTEMP
                STA A   XTEMP+1
                LDX     XTEMP
                LDA A   0,X
                STA A   TEMP
                BSR     OUTA
                LDA A   1,X
                BSR     OUTA
                LDA A   2,X
;
OUTA            JMP     OUTEEE
;
;  "V" COMMAND
;
VIEW            JSR     BAD2
VCOM1           LDA A   #8
                STA A   MCONT
VCOM5           JSR     CRLF
                JSR     OUTXHI
                LDA B   #$10
VCOM9           JSR     OUT2HS
                DEC B
                BIT B   #3
                BNE     VCOM10
                JSR     OUTS
                CMP B   #$0
VCOM10          BNE     VCOM9
                JSR     CRLF
                LDA B   #$5
                JSR     SKIP
                LDX     XHI
                LDA B   #$10
VCOM2           LDA A   0,X
                CMP A   #$20
                BCS     VCOM3
                CMP A   #$5F
                BCS     VCOM4
VCOM3           LDA A   #$2E
VCOM4           BSR     OUTA
                INX
                DEC B
                BNE     VCOM2
                STX     XHI
                DEC     MCONT
                BNE     VCOM5
                JSR     INEEE
                CMP A   #$20
                BEQ     VCOM1
                CMP A   #$56
                BEQ     VIEW
                JMP     CONTRL
;
; MNKEMONIC TABLE
;
TBL             FCC     "***NOPNOP***"
                FCC     "******TAPTPA"
                FCC     "INXDEXCLVSEV"
                FCC     "CLCSECCLISEI"
                FCC     "SBACBA******"
                FCC     "******TABTBA"
                FCC     "***DAA***ABA"
                FCC     "************"
                FCC     "BRA***BHIBLS"
                FCC     "BCCBCSBNEBEQ"
                FCC     "BVCBVSBPLBMI"
                FCC     "BGEBLTBGTBLE"
                FCC     "TSXINSPULPUL"
                FCC     "DESTXSPSHPSH"
                FCC     "***RTS***RTI"
                FCC     "******WAISWI"
                FCC     "NEG******COM"
                FCC     "LSR***RORASR"
                FCC     "ASLROLDEC***"
                FCC     "INCTSTJMPCLR"
                FCC     "SUBCMPSBCBSR"
                FCC     "ANDBITLDASTA"
                FCC     "EORADCORAADD"
                FCC     "CPXJSRLDSSTS"
                FCC     "LDXSTX"
SPLBD0          FCC     "#$"
                FCB     $4
COMMX           FCB     $2C,$58,$04
BLANK           FCB     $20,$20,$20
                FCB     $04
PNTA            FCC     " A "
                FCB     $04
PNTB            FCC     " B "
                FCB     $04
MCL             FCB     $D,$A,$15,$13,$3E,$04
BREG            FCB     $20,$42,$3D,$04
AREG            FCB     $41,$3D,$04
XREG            FCB     $58,$3D,$04
; HRJ misalignment, errors due to FCC vs FCB, wrong bytes and count
SREG            FCB     $53,$3D,$04      ;<-- was FCC
PCTR            FCB     $50,$43,$3D,$04  ;<-- was FCC
CSET            FCB     $48,$49,$4E,$5A,$56,$43
CRLFAS          FCB     $0D,$0A,$15,$04
ADASC           FCB     $0D,$0A
                FCB     $42,$4B,$41,$44,$44,$52,$20,$04
FROMAD          FCB     $0D,$0A,$46,$52,$4F,$4D,$20
                FCB     $41,$44,$44,$52,$20,$04
THRUAD          FCB     $0D,$0A,$54,$48,$52,$55,$20,$41
                FCB     $44,$44,$52,$20,$04
TOADD           FCB     $54,$4F,$20,$41,$44,$44,$52,$20,$04
VALASC          FCB     $56,$41,$4C,$55,$45,$20,$04
;
;   CONNAND JUMP TABLE
;
FUTABL          FCC     "M"
                FDB     MOVE
                FCC     "E"
                FDB     CHANGE
                FCC     "G"
                FDB     CONTG
                FCC     "R"
                FDB     PRINT
                FCC     "T"
                FDB     TRACE
                FCC     "@"
                FDB     ASCII
                FCC     "H"
                FDB     PRNTON
                FCC     "V"
                FDB     VIEW
                FCC     "I"
                FDB     IFILL
                FCC     "J"
                FDB     JUMP
                FCC     "F"
                FDB     FIND
                FCC     "Q"
                FDB     $8020
                FCC     "D"
                FDB     DISSA
                FCC     "K"
                FDB     KONTIN
                FCC     "1"
                FDB     BKPNT
                FCC     "2"
                FDB     BKPNT2
                FCC     "&"
                FDB     $7283		;apparently SLOAD program
                FCC     "*"
                FDB     $E0E3		;FLEX hass $E0E3, V1 source has $F800
                FCC     "O"
                FDB     ECHON
                FCC     "N"
                FDB     ECHOFF
TBLEND          EQU     *
; 
;   STARTUP VECTORS $FFF8 -$FFFF
;
                FDB     IO
                FDB     SWI
                FDB     POWDWN
                FDB     START
;
                ORG     $A000            ; TOP OF USER MEMORY
;
;ADDRESS
;
;                              addr remarks are where FLEX binary addresses are
;BUFFER         RMB     2                ; V2 had Buffer to protect system scratch
IOV             RMB     2		;addr OK
BEGA            RMB     2		;addr OK
ENDA            RMB     2		;addr OK
NIO             RMB     2		;addr OK
SP              RMB     2		; addr OK
                RMB     2
ECHO            RMB     1		; OK
XHI             RMB     1		; OK
XLOW            RMB     1		; OK
;TW              RMB     2		;not used in  code!
TFLAG           RMB     1		; OK
XTEMP           RMB     2		; OK 

SWIPTR		RMB     2		; OK
TEMP            RMB     1		; OK
                RMB     1
ACIAT           RMB     1		;addr A016 OK;
                RMB     43		;adjusted to fit FLEX code
STACK           RMB     8		;addr OK
PRINTR          RMB     3
BFLAG           RMB     1		;addr OK
MFLAG           RMB     1
XFLAG           RMB     1
BITE2           RMB     1
BITE3           RMB     15
TSTACK          RMB     1		;addr OK
OPSAVE          RMB     1		;addr OK
PB1             RMB     1
PB2             RMB     1		;addr OK
PB3             RMB     1
BYTECT          RMB     1
PC1             RMB     1
PC2             RMB     1
BPOINT          RMB     3		;addr OK 
BKFLG           RMB     1		;addr OK
BKFLG2          RMB     1		;addr OK
MCONT           RMB     1
;
                END
;
