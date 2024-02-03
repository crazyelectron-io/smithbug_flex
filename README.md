https://www.simonwynn.com/flex
Web page that explains the FLEX disk archive

https://s3.us-west-1.amazonaws.com/assets.simonwynn.com/flex_archive.zip
A zip file of all 1,379 FLEX DSK images is available here.

https://s3.us-west-1.amazonaws.com/assets.simonwynn.com/catalog.txt
A consolidated file listing for each disk image is available here.

Two disk images in the archive have "smithbug" as a file. They appear
to be duplicates. I unzipped one of the DSK files and use a hex editor
to extract "smithbug" as a series of sequential sectors. 

6800sb_old.bin

is a binary snatched from the disk image from the Flex library,
that corresponses to the "smithbug" file in that disk image

6800sb.bin

is that binary with all the FLEX sector-links removed, as I 
disassembled the binary and found those links at every 128 bytes
or so

6800_sb.lst

is the disassembled listing, thanks to an old MS-DOS/C disassembler
I found. My disassembly of this smithbug binary, *generally* matches
instruction-for-instruction with the Smithbug V1.0 source.

I edited the Smithbug V1.0 source, to 1) change the ORG to 4800H like
the FLEX binary. Then I had to 2) change some of the variable locations
at $A000H (edited in the source) to match the FLEX disassembly's variable addresses. 

Then 3) I found differences in a few instructions, either old typos or new typos.
I annotated these differences in the edited source. 

Then 4) I found some evidence of a) patched code in the FLEX binary, for changed
I/O calls, and b) either a broken patch or corruption in the FLEX binary which
did not disassemble to reasonable code. These are also annotated in the edited source.
I did not include an assembly change for the "corrupted" code. You can look at the 
disassembly and try your luck to reconstruct something from the corrupted area.

So I've included in this FLEX ZIP file:

sv14800.asm	the edited V1 source to match the FLEX binary when assembled
sv14800.lst	the listing of the assembled code
sv14800.hex, bin binary and hex for the assembled listing

When the binaries are compared, the only differences are in that "corrupted" areas.

-----------------------

Here's the differences between the FLEX binary (as disassembled too), that amount
to actual changes in instructions. Again, there's other changes from relocation and
modifications to the order of the variable table. Read the source for those, namely
the sv14800.lst file, modified for best-match to the FLEX binary.

1) Again, ignore the differences around $4891 to $48a0. It's a mix of a jump-patch
for outputting at PDATA1 & PDATA2 ; and some kind of corruption inside the CHANGE
routine. 

2) at $49b3, there's a "break point" check. A difference in branching:

   49b3   b6 a0 6b                      LDA A   BKFLG
   49b6   27 0f                         BEQ     C2		;BNE in V1 code, BEQ in FLEX code!!

3) at $4a5d there's a "input data" read. Which variation is correct? You decide.

   4a5d   ce 4f 88      ADDR            LDX     #ADASC	;FLEX code has LDX #ADASC, V1 code has LDX ADASC
   4a60   20 e8                         BRA     ENDADD+3

4) at $4b30 there's repeated checks for ISX. Three in the FLEX code, two in the V1 code.

   4b30   84 f0         NEXT            AND A   #$F0
   4b32   81 60                         CMP A   #$60
   4b34   27 18                         BEQ     ISX
   4b36   81 a0                         CMP A   #$A0		;code not in V1 HRJ
   4b38   27 14                         BEQ     ISX
   4b3a   81 e0                         CMP A   #$E0
   4b3c   27 10                         BEQ     ISX
   4b3e   81 80                         CMP A   #$80		;code in V1 listing HRJ

5) in the "print ASCII value of inst", the TST intruction looks at MFLAG and XFLAG (Flex code)
   or MFLAG and MFLAG (V1 source)

   4bf7   7d a0 4e                      TST     MFLAG	;FLEX code has A04E, V1 source has A04E = MFLAG
   4bfa   26 07                         BNE     PAVOI2
   4bfc   7d a0 4f                      TST     XFLAG	;FLEX code has A04F = XFLAG, V1 source has A04E
   4bff   26 02                         BNE     PAVOI2

6) later along at $4c15, there's an immediate LDA B with different values:

   4c15   c6 08                         LDA B   #8		;FLEX code has #8, V1 source has #5


7) in the "op codes lookup" there was an old error in one of the compares:

   4d1e   81 32                         CMP A   #$32
   4d20   27 11                         BEQ     IMLR3
   4d22   81 36                         CMP A	   #$36  ;had £ instead of #
   4d24   27 0d                         BEQ     IMLR3
   4d26   81 33                         CMP A   #$33
   4d28   27 0e                         BEQ     IMLR4

8) in the table of addresses at the end, there's two address differences between the FLEX binary
   and the V1 binary which are probably patched for purpose.

9) I had to futz with the V1 table of addresses, to get everything lined up with the FLEX binary
disassembly. The source assembles to properly represent all the addresses in the FLEX disassembly.

HErb Johnson, May 16 2022
