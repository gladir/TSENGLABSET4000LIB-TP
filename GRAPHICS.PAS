{ @author: Sylvain Maltais (support@gladir.com)
  @created: 1993
  @website(https://www.gladir.com/CODER/TSENGLABSET4000LIB-TP)
  @abstract(Target: Turbo Pascal 7)
}

Unit Graphics;

INTERFACE

Const
 _VideoMode640x480c256=$2E;
 _VideoMode640x400c256=$2F;
 _VideoMode800x600c256=$30;
 _VideoMode1024x768c256=$38;

Procedure ClearScreen(Color:Byte);
Procedure Copy8Bin(X,Y:Word;Value,Background,Foreground:Byte);
Procedure CopyLine(X1,Y,X2:Word;Var Buffer);
Procedure GetLine(X1,Y,X2:Word;Var Buffer);
Function  GetPixel(X,Y:Word):Byte;
Function  GetSizeMemory:LongInt;
Procedure PutBox(X1,Y1,X2,Y2:Word;Color:Byte);
Procedure PutLine(X1,Y,X2:Word;Color:Byte);
Procedure PutLineV(X,Y1,Y2:Word;Color:Byte);
Procedure SelectPage(PageNumber:Byte);
Procedure SelectReadPage(PageNumber:Byte);
Procedure SelectWritePage(PageNumber:Byte);
Procedure SelectText;
Procedure SetPixel(X,Y:Word;Color:Byte);
Procedure SetVideoMode(Mode:Byte);

IMPLEMENTATION

Const
 Page_Sel_Port=$3CD;

 _Tseng=17;
 _Tseng4000=18;

 LongIntMax= 2147483647;
 LongIntMin=-2147483647;
 LongMax=LongIntMax;
 LongMin=LongIntMin;
 WordMax=65535;
 WordMin=0;
 IntegerMax=32767;
 IntegerMin=-32768;
 IntMax=IntegerMax;
 IntMin=IntegerMin;
 ShortIntMin=-128;
 ShortIntMax=127;
 ByteMax=255;
 ByteMin=0;

Type
 TByte=Array[0..32000]of Byte;

Var
 GBuffer:^TByte;
 VG:Record
   {PUBLIC:}
  NumXPixels:Word;
  NumYPixels:Word;
  MaxXPixels:Word;
  MaxYPixels:Word;
  NumColors:LongInt;
  BitsPerPixel:Word;
  NumVideoPages:Byte;
  Mode:Integer;
  Adaptor:Byte;
  Monitor:Byte;
  Memory:LongInt;
   {PRIVATE:}
  BytesPerScanLine:Word;
  AddrSegment:Word;
  MaxPage:Byte;
  R_Page:Byte;
  W_Page:Byte;
  RW_Page:Byte;
 End;

Procedure Tseng4000ClearScreen(Color:Byte);Forward;
Procedure Tseng4000Copy8Bin(X,Y:Word;Value,Background,Foreground:Byte);Forward;
Procedure Tseng4000CopyLine(X1,Y,X2:Word;Var Buffer);Forward;
Procedure Tseng4000GetLine(X1,Y,X2:Word;Var Buffer);Forward;
Procedure Tseng4000Line(X1,Y1,X2,Y2:Word;Color:Byte);Forward;
Procedure Tseng4000LineNot(X1,Y1,X2,Y2:Word);Forward;
Procedure Tseng4000PutBox(X1,Y1,X2,Y2:Word;Color:Byte);Forward;
Procedure Tseng4000PutLine(X1,Y,X2:Word;Color:Byte);Forward;
Procedure Tseng4000PutLineV(X,Y1,Y2:Word;Color:Byte);Forward;
Procedure Tseng4000SelectPage(Page:Byte);Forward;
Procedure Tseng4000WritePixel(X,Y:Word;Color:Byte);Forward;
Function  Tseng4000ReadPixel(X,Y:Word):Byte;Forward;
Procedure Tseng4000SelectReadPage(Page:Byte);Forward;
Procedure Tseng4000SelectWritePage(Page:Byte);Forward;

Function Get8BitAddress(X,Y:Word):LongInt;Assembler;ASM
 MOV AX,Y
 MUL VG.NumXPixels
 ADD AX,X
 ADC DX,0
 MOV BX,DX
End;

Function GetBytesPerScanLine:Word;Begin
 Case VG.NumColors of
  256: GetBytesPerScanLine:=VG.NumXPixels;
  Else GetBytesPerScanLine:=VG.NumXPixels shr 3;
 End;
End;

Function GetMaxPage:Byte;Begin
 VG.MaxPage:=Byte((LongInt(VG.NumXPixels)*LongInt(VG.NumYPixels))shr 18);
End;

Procedure ClearScreen(Color:Byte);
Var
 J:Byte;
Begin
 For J:=0 to VG.MaxPage do Begin
  SelectWritePage(J);
  FillChar(Mem[VG.AddrSegment:0],$FFFF,0);
 End;
End;

Procedure SetVideoMode(Mode:Byte);Begin
 ASM
  MOV AL,Mode
  XOR AH,AH
  INT $10
 END;
 Case Mode of
  $2E:Begin
   VG.NumXPixels:=640;
   VG.NumYPixels:=480;
   VG.NumColors:=256;
  End;
  $2F:Begin
   VG.NumXPixels:=640;
   VG.NumYPixels:=400;
   VG.NumColors:=256;
  End;
  $30:Begin
   VG.NumXPixels:=800;
   VG.NumYPixels:=600;
   VG.NumColors:=256;
  End;
  $38:Begin
   VG.NumXPixels:=1024;
   VG.NumYPixels:=768;
   VG.NumColors:=256;
  End;
 End;
 VG.MaxXPixels:=VG.NumXPixels-1;
 VG.MaxYPixels:=VG.NumYPixels-1;
 VG.MaxPage:=GetMaxPage;
 VG.BytesPerScanLine:=GetBytesPerScanLine;
End;

Procedure SelectPage(PageNumber:Byte);Assembler;ASM
 MOV AL,PageNumber;
 CMP AL,VG.RW_Page;
 JE  @@2;
 MOV DX,Page_Sel_Port;
 AND AL,7;
 MOV VG.RW_Page,AL;
 MOV VG.R_Page,$FF;
 MOV VG.W_Page,$FF;
 MOV AH,AL;
 {$IFOPT G+}
  SHL AH,3;
 {$ELSE}
  SHL AH,1;
  SHL AH,1;
  SHL AH,1;
 {$ENDIF}
 OR  AL,AH;
 OR  AL,$40;
 OUT DX,AL;
@@2:
END;

Procedure SelectReadPage(PageNumber:Byte);Assembler;ASM
 MOV AL,PageNumber;
 CMP AL,VG.R_Page;
 JE  @@2;
 AND AL,7;
 MOV AH,AL;
 MOV VG.R_Page,AH;
 {$IFOPT G+}
  SHL AH,3;
 {$ELSE}
  SHL AH,1;
  SHL AH,1;
  SHL AH,1;
 {$ENDIF}
 MOV DX,Page_Sel_Port;
 IN  AL,DX;
 AND AL,$07;
 OR  AL,$40;
 OR  AL,AH;
 OUT DX,AL;
 MOV VG.RW_Page,$FF;
@@2:
END;

Procedure SelectWritePage(PageNumber:Byte);Assembler;ASM
 MOV AL,PageNumber;
 CMP AL,VG.W_Page;
 JE  @@2;
 AND AL,7;
 MOV AH,AL;
 MOV VG.W_Page,AH;
 MOV DX,Page_Sel_Port;
 IN  AL,DX;
 AND AL,$38;
 OR  AL,$40;
 OR  AL,AH;
 OUT DX,AL;
 MOV VG.RW_Page,$FF;
@@2:
END;

Procedure SelectText;Assembler;ASM
 MOV AL,$03;
 XOR AH,AH;
 INT $10;
END;

Procedure SetPixel(X,Y:Word;Color:Byte);
Var
 Address:LongInt;
Begin
 Address:=Get8BitAddress(X,Y);
 SelectWritePage(Address shr 16);
 Mem[VG.AddrSegment:Word(Address)]:=Color;
End;

Function GetPixel(X,Y:Word):Byte;
Var
 Address:LongInt;
Begin
 Address:=Get8BitAddress(X,Y);
 SelectReadPage(Address shr 16);
 GetPixel:=Mem[VG.AddrSegment:Word(Address)];
End;

Procedure PutLine(X1,Y,X2:Word;Color:Byte);
Var
 AddressY,Address1,Address2:LongInt;
 L1,L:Word;
Begin
 L:=(X2-X1)+1;
 AddressY:=(LongInt(Y)*LongInt(VG.BytesPerScanLine));
 Address1:=LongInt(X1)+AddressY;
 Address2:=LongInt(X2)+AddressY;
 SelectWritePage(Address1 shr 16);
 If(Byte(Address1 shr 16)=Byte(Address2 shr 16))Then Begin
  FillChar(Mem[VG.AddrSegment:Address1],L,Color);
 End
  Else
 Begin
  L1:=(WordMax-Word(AddressY))+1;
  FillChar(Mem[VG.AddrSegment:Word(Address1)],L1,Color);
  SelectWritePage(Address2 shr 16);
  FillChar(Mem[VG.AddrSegment:0],L-L1,Color);
 End;
End;

Procedure CopyLine(X1,Y,X2:Word;Var Buffer);
Var
 AddressY,Address1,Address2:LongInt;
 TBuffer:^TByte;
 L1,L:Word;
Begin
 L:=(X2-X1)+1;
 AddressY:=(LongInt(Y)*LongInt(VG.BytesPerScanLine));
 Address1:=LongInt(X1)+AddressY;
 Address2:=LongInt(X2)+AddressY;
 SelectWritePage(Address1 shr 16);
 If(Byte(Address1 shr 16) = Byte(Address2 shr 16))Then Begin
  Move(Buffer,Mem[VG.AddrSegment:Word(Address1)],L);
 End
  Else
 Begin
  L1:=(WordMax-Word(AddressY))+1;
  Move(Mem[VG.AddrSegment:Word(Address1)],Buffer,L1);
  SelectWritePage(Byte(Address2 shr 16));
  TBuffer:=@Buffer;
  Move(Mem[VG.AddrSegment:0],TBuffer^[L1],L-L1);
 End;
End;

Procedure GetLine(X1,Y,X2:Word;Var Buffer);
Var
 AddressY,Address1,Address2:LongInt;
 TBuffer:^TByte;
 L1,L:Word;
Begin
 L:=(X2-X1)+1;
 AddressY:=(LongInt(Y)*LongInt(VG.BytesPerScanLine));
 Address1:=LongInt(X1)+AddressY;
 Address2:=LongInt(X2)+AddressY;
 SelectReadPage(Address1 shr 16);
 If(Byte(Address1 shr 16) = Byte(Address2 shr 16))Then Begin
  Move(Mem[VG.AddrSegment:Word(Address1)],Buffer,(X2-X1+1));
 End
  Else
 Begin
  L1:=(WordMax-Word(AddressY));
  Move(Mem[VG.AddrSegment:Word(Address1)],Buffer,L1);
  SelectReadPage(Address2 shr 16);
  TBuffer:=@Buffer;
  Move(Mem[VG.AddrSegment:0],TBuffer^[L1],L-L1);
 End;
End;

Procedure PutBox(X1,Y1,X2,Y2:Word;Color:Byte);
Var
 J:Word;
Begin
 For J:=Y1 to Y2 do PutLine(X1,J,X2,Color);
End;

Procedure Copy8Bin(X,Y:Word;Value,Background,Foreground:Byte);
Var
 Address1,Address2:LongInt;
 I:Word;
Begin
 Address1:=LongInt(X)+(LongInt(Y)*LongInt(VG.BytesPerScanLine));
 Address2:=Address1+7;
 SelectWritePage(Byte(Address1 shr 16));
 If(Byte(Address1 shr 16) = Byte(Address2 shr 16))Then Begin
  ASM
   CLD
   MOV ES,VG.AddrSegment
   MOV DI,Word(Address1);
   MOV BH,Value;
   CMP BH,$0;
   JE  @@1;
   MOV AL,Foreground;
   CMP BH,$FF;
   JNE @@2;
   MOV AH,AL;
   MOV CX,4;
   REP STOSW;
   JMP @@6;
@@1:
   MOV CX,4;
   MOV AL,Background;
   MOV AH,AL;
   REP STOSW;
   JMP @@6;
@@2:
   MOV DL,Background;
   MOV DH,AL;
   MOV CX,8;
@@3:
   MOV BL,BH;
   ROR BL,CL;
   JC  @@4;
   MOV AL,DL;
   STOSB;
   LOOP @@3;
   JMP @@6;
@@4:
   MOV AL,DH;
   STOSB;
   LOOP @@3;
@@6:
  END;
 End
  else
 Begin
  For I:=7 downto 0 do Begin
   If(((Value shr I) and 1)=1)Then Mem[VG.AddrSegment:Word(Address1)]:=Background
                              Else Mem[VG.AddrSegment:Word(Address1)]:=Foreground;
   Inc(Address1);
   SelectWritePage(Byte(Address1 shr 16));
  End;
 End;
End;

Procedure PutLineV(X,Y1,Y2:Word;Color:Byte);
Var
 Address:LongInt;
 J:Word;
Begin
 Address:=Get8BitAddress(X,Y1);
 For J:=Y1 to Y2 do Begin
  SelectWritePage(Byte(Address shr 16));
  Mem[VG.AddrSegment:Word(Address)]:=Color;
  Inc(Address,VG.BytesPerScanLine);
 End;
End;

Function GetSizeMemory:LongInt;
Var
 Mode:Byte;
Begin
 ASM
  MOV AX,$0038;
  INT $10;
  MOV AH,$0F;
  INT $10;
  MOV Mode,AL;
 END;
 If(Mode=$38)Then GetSizeMemory:=1048576
             Else GetSizeMemory:=262144;
End;

Procedure Tseng4000ClearScreen(Color:Byte);
Var
 J:Byte;
Begin
 For J:=0 to VG.MaxPage do Begin
  Tseng4000SelectWritePage(J);
  ASM
   {$IFOPT G+}
    PUSH VG.AddrSegment;
    POP  ES;
   {$ELSE}
    MOV  ES,VG.AddrSegment;
   {$ENDIF}
   XOR DI,DI;
   CLD;
   {$IFOPT G+}
    MOV CX,($FFFF) shr 1;
    MOV AL,Color;
    MOV AH,AL;
    REP STOSW;
   {$ELSE}
    MOV CX,$FFFF;
    REP STOSB;
   {$ENDIF}
  END;
 End;
End;

Procedure Tseng4000Copy8Bin(X,Y:Word;Value,Background,Foreground:Byte);
Var
 Address1,Address2:LongInt;
 I:Word;
Begin
 Address1:=LongInt(X)+(LongInt(Y)*LongInt(VG.BytesPerScanLine));
 Address2:=Address1+7;
 {$IFDEF __SWITCHPAGERW__}
  Tseng4000SelectWritePage(Byte(Address1 shr 16));
 {$ELSE}
  Tseng4000SelectPage(Byte(Address1 shr 16));
 {$ENDIF}
 If(Byte(Address1 shr 16) = Byte(Address2 shr 16))Then
 Begin
  ASM
   CLD
   MOV ES,VG.AddrSegment;
   MOV DI,Word Ptr Address1[0];
   MOV BH,Value;
   CMP BH,$0;
   JE  @@1;
   MOV AL,Foreground;
   CMP BH,$FF;
   JNE @@2;
   {$IFOPT G+}
    MOV AH,AL;
    MOV CX,4;
    REP STOSW;
   {$ELSE}
    MOV CX,8;
    REP STOSB;
   {$ENDIF}
   JMP @@6;
@@1:
   MOV AL,Background;
   {$IFOPT G+}
    MOV CX,4;
    MOV AH,AL;
    REP STOSW;
   {$ELSE}
    MOV CX,8;
    REP STOSB;
   {$ENDIF}
   JMP @@6;
@@2:
   MOV DL,Background;
   MOV DH,AL;
   MOV CX,8;
@@3:
   MOV BL,BH;
   ROR BL,CL;
   JC  @@4;
   MOV AL,DL;
   STOSB;
   LOOP @@3;
   JMP @@6;
@@4:
   MOV AL,DH;
   STOSB;
   LOOP @@3;
@@6:
  END;
 End
  else
 Begin
  For I:=7 downto 0 do Begin
   If(((Value shr I) and 1) = 1)Then Mem[VG.AddrSegment:Word(Address1)]:=Background
                                Else Mem[VG.AddrSegment:Word(Address1)]:=Foreground;
   Inc(Address1);
   Tseng4000SelectWritePage(Byte(Address1 shr 16));
  End;
 End;
End;

Procedure Tseng4000CopyLine(X1,Y,X2:Word;Var Buffer);
Var
 AddressY,Address1,Address2:LongInt;
 TBuffer:^TByte;
 L1,L:Word;
Begin
 If(X1>X2)Then Exit;
 L:=(X2-X1)+1;
 AddressY:=(LongInt(Y)*LongInt(VG.BytesPerScanLine));
 Address1:=LongInt(X1)+AddressY;
 Address2:=LongInt(X2)+AddressY;
 Tseng4000SelectWritePage(Byte(Address1 shr 16));
 If(Byte(Address1 shr 16) = Byte(Address2 shr 16))Then Begin
  Move(Buffer,Mem[$A000:Word(Address1)],L);
 End
  Else
 Begin
  L1 := (WordMax - Word(Address1))+1;
  Move(Buffer,Mem[$A000:Word(Address1)],L1);
  Tseng4000SelectWritePage(Byte(Address2 shr 16));
  TBuffer := @Buffer;
  Move(TBuffer^[L1],Mem[$A000:0],L-L1);
 End;
End;

Procedure Tseng4000GetLine(X1,Y,X2:Word;Var Buffer);
Var
 AddressY,Address1,Address2:LongInt;
 TBuffer:^TByte;
 L1,L:Word;
Begin
 If(X1 > X2)Then Exit;
 L:=(X2-X1)+1;
 AddressY:=(LongInt(Y)*LongInt(VG.BytesPerScanLine));
 Address1:=LongInt(X1)+AddressY;
 Address2:=LongInt(X2)+AddressY;
 Tseng4000SelectReadPage(Byte(Address1 shr 16));
 If(Byte(Address1 shr 16) = Byte(Address2 shr 16))Then Begin
  Move(Mem[VG.AddrSegment:Word(Address1)],Buffer,L);
 End
  Else
 Begin
  L1 := (WordMax - Word(Address1)) + 1;
  Move(Mem[VG.AddrSegment:Word(Address1)],Buffer,L1);
  Tseng4000SelectReadPage(Address2 shr 16);
  TBuffer := @Buffer;
  Move(Mem[VG.AddrSegment:0],TBuffer^[L1],L-L1);
 End;
End;

Procedure Tseng4000Line(X1,Y1,X2,Y2:Word;Color:Byte);
Var
 PageNo,First_Mask:Byte;
 D1,D2,Pitch,Delta_X:Word;
Begin
 ASM
   { Calcul l'adresse (X1,Y1) en DX:AX }
  MOV  AX,Y1;
  MUL  VG.BytesPerScanLine;
  ADD  AX,X1;
  ADC  DX,0;
   { Selecte la page (Write Mode) }
  PUSH AX;
   MOV PageNo,DL;
   MOV AL,DL;
   CMP VG.W_Page,AL;
   JE  @@1;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
@@1:
   MOV  ES,VG.AddrSegment
   { Calcul le delta de X }
   MOV AX,VG.BytesPerScanLine;
   MOV Pitch,AX;
   MOV SI,X2;
   SUB SI,X1;
   MOV Delta_X,SI;
   JGE @@2;
   NEG SI;
@@2:
   { Calcul le delta de Y }
   MOV DI,Y2;
   SUB DI,Y1;
   JGE @@3;
   NEG Pitch;
   NEG DI;
@@3:
   { (Delta X > Delta Y) ? }
   CMP SI,DI;
   JGE @@5;
   JMP @@33;
@@5:
   MOV CX,SI;
   INC CX;
   SAL DI,1;
   MOV DX,DI;
   SUB DX,SI;
   NEG SI;
   ADD SI,DX;
   MOV D1,DI;
   MOV D2,SI;
  POP DI;
  TEST Pitch,$8000;
  JZ   @@7;
  NEG  Pitch;
  TEST Delta_X,$8000;
  JNZ  @@6;
  JMP  @@20;
@@6:
  JMP  @@26;
@@7:
  TEST Delta_X,$8000;
  JZ   @@8;
  JMP  @@14;
   { Ligne Delta X > 0 et Delta Y > 0 et X majeur }
@@8:
  MOV  AL,Color;
@@9:
  MOV  ES:[DI],AL;
  ADD  DI,1;
  JC   @@12;
@@10:
  TEST DX,$8000;
  JNZ  @@11;
  ADD  DX,D2;
  ADD  DI,Pitch;
  JC   @@13;
  LOOP @@9;
  JMP  @@60;
@@11:
  ADD  DX,D1;
  LOOP @@9;
  JMP  @@60;
@@12:
  XCHG AL,PageNo;
  INC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP DX;
  XCHG AL,PageNo;
  JMP  @@10;
@@13:
  XCHG AL,PageNo;
  INC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP DX;
  XCHG AL,PageNo;
  LOOP @@9;
  JMP  @@60;
   { Ligne Delta X < 0 et Delta Y > 0 et X majeur }
@@14:
  MOV  AL,Color;
@@15:
  MOV  ES:[DI],AL;
  SUB  DI,1;
  JC   @@18;
@@16:
  TEST DX,$8000;
  JNZ  @@17;
  ADD  DX,D2;
  ADD  DI,Pitch;
  JC   @@19;
  LOOP @@15;
  JMP  @@60;
@@17:
  ADD  DX,D1;
  LOOP @@15;
  JMP  @@60;
@@18:
  XCHG AL,PageNo;
  DEC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP DX;
  XCHG AL,PageNo;
  JMP  @@16;
@@19:
  XCHG AL,PageNo;
  INC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP DX;
  XCHG AL,PageNo;
  LOOP @@15;
  JMP  @@60;
   { Ligne Delta X > 0 et Delta Y < 0 et X majeur }
@@20:
  MOV  AL,Color;
@@21:
  MOV  ES:[DI],AL;
  ADD  DI,1;
  JC   @@24;
@@22:
  TEST DX,$8000;
  JNZ  @@23;
  ADD  DX,D2;
  SUB  DI,Pitch;
  JC   @@25;
  LOOP @@21;
  JMP  @@60;
@@23:
  ADD  DX,D1;
  LOOP @@21;
  JMP  @@60;
@@24:
  XCHG AL,PageNo;
  INC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP DX;
  XCHG AL,PageNo;
  JMP  @@22;
@@25:
  XCHG AL,PageNo;
  DEC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP  DX;
  XCHG AL,PageNo;
  LOOP @@21;
  JMP  @@60;
   { Ligne Delta X < 0 et Delta Y < 0 et X majeur }
@@26:
  MOV AL,Color;
@@27:
  MOV ES:[DI],AL;
  SUB DI,1;
  JC  @@30;
@@28:
  TEST DX,$8000;
  JNZ  @@29;
  ADD  DX,D2;
  SUB  DI,Pitch;
  JC   @@31;
  LOOP @@27;
  JMP  @@60;
@@29:
  ADD  DX,D1;
  LOOP @@27;
  JMP  @@60;
@@30:
  XCHG AL,PageNo;
  DEC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP DX;
  XCHG AL,PageNo;
  JMP  @@28;
@@31:
  XCHG AL,PageNo;
  DEC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP DX;
  XCHG AL,PageNo;
  LOOP @@27;
  JMP  @@60;
   { Ligne diagonal Y majeur }
@@32:
   JMP @@60;
@@33:
   MOV CX,DI;
   INC CX;
   SAL SI,1;
   MOV DX,SI;
   SUB DX,DI;
   NEG DI;
   ADD DI,DX;
   MOV D2,DI;
   MOV D1,SI;
   POP DI;
   TEST Pitch,$8000;
   JZ   @@35;
   NEG  Pitch;
   TEST Delta_X,$8000;
   JNZ  @@34;
   JMP  @@48;
@@34:
   JMP  @@54;
@@35:
   TEST Delta_X,$8000;
   JZ   @@36;
   JMP  @@42;
    { Ligne Delta X > 0 et Delta Y > 0 et Y majeur }
@@36:
   MOV AL,Color;
@@37:
   MOV ES:[DI],AL;
   ADD DI,Pitch;
   JC  @@40;
@@38:
   TEST DX,$8000;
   JNZ  @@39;
   ADD  DX,D2;
   ADD  DI,1;
   JC   @@41;
   LOOP @@37;
   JMP  @@60;
@@39:
   ADD  DX,D1;
   LOOP @@37;
   JMP  @@60;
@@40:
   XCHG AL,PageNo;
   INC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND  AL,$0F;
   MOV  AH,AL;
   MOV  DX,$3CD;
   IN   AL,DX;
   AND  AL,$F0;
   OR   AL,AH;
   OUT  DX,AL;
  POP  DX;
  XCHG AL,PageNo;
  JMP  @@38;
@@41:
  XCHG AL,PageNo;
  INC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP  DX;
  XCHG AL,PageNo;
  LOOP @@37;
  JMP  @@60;
   { Ligne Delta X < 0 et Delta Y > 0 et Y majeur }
@@42:
  MOV AL,Color;
@@43:
  MOV ES:[DI],AL;
  ADD DI,Pitch;
  JC  @@46;
@@44:
  TEST DX,$8000;
  JNZ  @@45;
  ADD  DX,D2;
  SUB  DI,1;
  JC   @@47;
  LOOP @@43;
  JMP  @@60;
@@45:
  ADD  DX,D1;
  LOOP @@43;
  JMP  @@60;
@@46:
  XCHG AL,PageNo;
  INC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP  DX;
  XCHG AL,PageNo;
  JMP  @@44;
@@47:
  XCHG AL,PageNo;
  DEC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP  DX;
  XCHG AL,PageNo;
  LOOP @@43;
  JMP  @@60;
   { Ligne Delta X > 0 et Delta Y < 0 et Y majeur }
@@48:
  MOV  AL,Color;
@@49:
  MOV  ES:[DI],AL;
  SUB  DI,Pitch;
  JC   @@52;
@@50:
  TEST DX,$8000;
  JNZ  @@51;
  ADD  DX,D2;
  ADD  DI,1;
  JC   @@53;
  LOOP @@49;
  JMP  @@60;
@@51:
  ADD  DX,D1;
  LOOP @@49;
  JMP  @@60;
@@52:
  XCHG AL,PageNo;
  DEC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP  DX;
  XCHG AL,PageNo;
  JMP  @@50;
@@53:
  XCHG AL,PageNo;
  INC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP  DX;
  XCHG AL,PageNo;
  LOOP @@49;
  JMP  @@60;
   { Ligne Delta X < 0 et Delta Y < 0 et Y majeure }
@@54:
  MOV  AL,Color;
@@55:
  MOV  ES:[DI],AL;
  SUB  DI,Pitch;
  JC   @@58;
@@56:
  TEST DX,$8000;
  JNZ  @@57;
  ADD  DX,D2;
  SUB  DI,1;
  JC   @@59;
  LOOP @@55;
  JMP  @@60;
@@57:
  ADD  DX,D1;
  LOOP @@55;
  JMP  @@60;
@@58:
  XCHG AL,PageNo;
  DEC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP  DX;

  XCHG AL,PageNo;
  JMP  @@56;
@@59:
  XCHG AL,PageNo;
  DEC  AL;
   { Select Page (Write Mode) }
  PUSH DX;
   AND AL,$0F;
   MOV AH,AL;
   MOV DX,$3CD;
   IN  AL,DX;
   AND AL,$F0;
   OR  AL,AH;
   OUT DX,AL;
  POP  DX;
  XCHG AL,PageNo;
  LOOP @@55;
  JMP  @@60;
@@60:
  MOV VG.W_Page,$FF;
  MOV VG.R_Page,$FF;
  MOV VG.RW_Page,$FF;
 END;
End;

Procedure Tseng4000LineNot(X1,Y1,X2,Y2:Word);
Var
 PageNo,First_Mask:Byte;
 D1,D2,Pitch,Delta_X:Word;
Begin
 ASM
   { Calcul l'adresse (X1,Y1) en DX:AX }
  MOV  AX,Y1;
  MUL  VG.BytesPerScanLine;
  ADD  AX,X1;
  ADC  DX,0;
   { Selecte la page }
  PUSH AX;
   MOV PageNo,DL;
   MOV AL,DL;
   CMP VG.RW_Page,AL;
   JE  @@1;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
@@1:
   {$IFOPT G+}
    PUSH SegmentVideo;
    POP  ES;
   {$ELSE}
    MOV  ES,VG.AddrSegment;
   {$ENDIF}
    { Calcul le delta de X }
   MOV AX,VG.BytesPerScanLine;
   MOV Pitch,AX;
   MOV SI,X2;
   SUB SI,X1;
   MOV Delta_X,SI;
   JGE @@2;
   NEG SI;
@@2:
   { Calcul le delta de Y }
   MOV DI,Y2;
   SUB DI,Y1;
   JGE @@3;
   NEG Pitch;
   NEG DI;
@@3:
   CMP  SI,DI;
   JNGE @@33;  { (Delta X > Delta Y) ? }
@@5:
   MOV CX,SI;
   INC CX;
   SAL DI,1;
   MOV DX,DI;
   SUB DX,SI;
   NEG SI;
   ADD SI,DX;
   MOV D1,DI;
   MOV D2,SI;
  POP DI;

  TEST Pitch,$8000;
  JZ   @@7;
  NEG  Pitch;
  TEST Delta_X,$8000;
  JNZ  @@26;
  JMP  @@20;
@@7:
  TEST Delta_X,$8000;
  JNZ @@14;
   { Ligne Delta X > 0 et Delta Y > 0 et X majeur }
@@9:
  MOV AL,ES:[DI];
  NOT AL;
  MOV ES:[DI],AL;
  ADD DI,1;
  JC  @@12;
@@10:
  TEST DX,$8000;
  JNZ  @@11;
  ADD  DX,D2;
  ADD  DI,Pitch;
  JC   @@13;
  LOOP @@9;
  JMP  @@60;
@@11:
  ADD  DX,D1;
  LOOP @@9;
  JMP  @@60;
@@12:
  XCHG AL,PageNo;
  INC  AL;
   { Select Page }
  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP  DX;
  XCHG AL,PageNo;
  JMP  @@10;
@@13:
  XCHG AL,PageNo;
  INC  AL;
   { Select Page }
  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP DX;
  XCHG AL,PageNo;
  LOOP @@9;
  JMP  @@60;
   { Ligne Delta X < 0 et Delta Y > 0 et X majeur }
@@14:
@@15:
  MOV  AL,ES:[DI];
  NOT  AL;
  MOV  ES:[DI],AL;
  SUB  DI,1;
  JC   @@18;
@@16:
  TEST DX,$8000;
  JNZ  @@17;
  ADD  DX,D2;
  ADD  DI,Pitch;
  JC   @@19;
  LOOP @@15;
  JMP  @@60;
@@17:
  ADD  DX,D1;
  LOOP @@15;
  JMP  @@60;
@@18:
  XCHG AL,PageNo;
  DEC  AL;
   { Select Page }
  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP  DX;
  XCHG AL,PageNo;
  JMP  @@16;
@@19:
  XCHG AL,PageNo;
  INC  AL;
   { Select Page }
  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP DX;
  XCHG AL,PageNo;
  LOOP @@15;
  JMP  @@60;
   { Ligne Delta X > 0 et Delta Y < 0 et X majeur }
@@20:
@@21:
  MOV  AL,ES:[DI];
  NOT  AL;
  MOV  ES:[DI],AL;
  ADD  DI,1;
  JC   @@24;
@@22:
  TEST DX,$8000;
  JNZ  @@23;
  ADD  DX,D2;
  SUB  DI,Pitch;
  JC   @@25;
  LOOP @@21;
  JMP  @@60;
@@23:
  ADD  DX,D1;
  LOOP @@21;
  JMP  @@60;
@@24:
  XCHG AL,PageNo;
  INC  AL;
   { Select Page }
  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP DX;
  XCHG AL,PageNo;
  JMP  @@22;
@@25:
  XCHG AL,PageNo;
  DEC  AL;
   { Select Page }
  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP DX;
  XCHG AL,PageNo;
  LOOP @@21;
  JMP  @@60;
   { Ligne Delta X < 0 et Delta Y < 0 et X majeur }
@@26:
@@27:
  MOV  AL,ES:[DI];
  NOT  AL;
  MOV  ES:[DI],AL;
  SUB  DI,1;
  JC   @@30;
@@28:
  TEST DX,$8000;
  JNZ  @@29;
  ADD  DX,D2;
  SUB  DI,Pitch;
  JC   @@31;
  LOOP @@27;
  JMP  @@60;
@@29:
  ADD  DX,D1;
  LOOP @@27;
  JMP  @@60;
@@30:
  XCHG AL,PageNo;
  DEC  AL;

   { Select Page }

  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP DX;

  XCHG AL,PageNo;
  JMP  @@28;
@@31:
  XCHG AL,PageNo;
  DEC  AL;

   { Select Page }

  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP DX;

  XCHG AL,PageNo;
  LOOP @@27;
  JMP  @@60;

   { Ligne diagonal Y majeur }

@@32:
   JMP @@60;
@@33:
   MOV CX,DI;
   INC CX;
   SAL SI,1;
   MOV DX,SI;
   SUB DX,DI;
   NEG DI;
   ADD DI,DX;
   MOV D2,DI;
   MOV D1,SI;
   POP DI;

   TEST Pitch,$8000;
   JZ   @@35;
   NEG  Pitch;
   TEST Delta_X,$8000;
   JNZ  @@34;
   JMP  @@48;
@@34:
   JMP  @@54;
@@35:
   TEST Delta_X,$8000;
   JZ   @@36;
   JMP  @@42;

    { Ligne Delta X > 0 et Delta Y > 0 et Y majeur }

@@36:
@@37:
   MOV AL,ES:[DI];
   NOT AL;
   MOV ES:[DI],AL;
   ADD DI,Pitch;
   JC  @@40;
@@38:
   TEST DX,$8000;
   JNZ  @@39;
   ADD  DX,D2;
   ADD  DI,1;
   JC   @@41;
   LOOP @@37;
   JMP  @@60;
@@39:
   ADD  DX,D1;
   LOOP @@37;
   JMP  @@60;
@@40:
   XCHG AL,PageNo;
   INC  AL;

   { Select Page }

  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP DX;

  XCHG AL,PageNo;
  JMP  @@38;
@@41:
  XCHG AL,PageNo;
  INC  AL;

   { Select Page }

  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP DX;

  XCHG AL,PageNo;
  LOOP @@37;
  JMP  @@60;

   { Ligne Delta X < 0 et Delta Y > 0 et Y majeur }
@@42:
@@43:
  MOV  AL,ES:[DI];
  NOT  AL;
  MOV  ES:[DI],AL;
  ADD  DI,Pitch;
  JC   @@46;
@@44:
  TEST DX,$8000;
  JNZ  @@45;
  ADD  DX,D2;
  SUB  DI,1;
  JC   @@47;
  LOOP @@43;
  JMP  @@60;
@@45:
  ADD  DX,D1;
  LOOP @@43;
  JMP  @@60;
@@46:
  XCHG AL,PageNo;
  INC  AL;

   { Select Page }

  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP DX;

  XCHG AL,PageNo;
  JMP  @@44;
@@47:
  XCHG AL,PageNo;
  DEC  AL;

   { Select Page }
  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP DX;

  XCHG AL,PageNo;
  LOOP @@43;
  JMP  @@60;

   { Ligne Delta X > 0 et Delta Y < 0 et Y majeur }
@@48:
@@49:
  MOV  AL,ES:[DI];
  NOT  AL;
  MOV  ES:[DI],AL;
  SUB  DI,Pitch;
  JC   @@52;
@@50:
  TEST DX,$8000;
  JNZ  @@51;
  ADD  DX,D2;
  ADD  DI,1;
  JC   @@53;
  LOOP @@49;
  JMP  @@60;
@@51:
  ADD  DX,D1;
  LOOP @@49;
  JMP  @@60;
@@52:
  XCHG AL,PageNo;
  DEC  AL;

   { Select Page }
  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP DX;

  XCHG AL,PageNo;
  JMP  @@50;
@@53:
  XCHG AL,PageNo;
  INC  AL;

   { Select Page }

  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP DX;

  XCHG AL,PageNo;
  LOOP @@49;
  JMP  @@60;

   { Ligne Delta X < 0 et Delta Y < 0 et Y majeur }
@@54:
@@55:
  MOV  AL,ES:[DI];
  NOT  AL;
  MOV  ES:[DI],AL;
  SUB  DI,Pitch;
  JC   @@58;
@@56:
  TEST DX,$8000;
  JNZ  @@57;
  ADD  DX,D2;
  SUB  DI,1;
  JC   @@59;
  LOOP @@55;
  JMP  @@60;
@@57:
  ADD  DX,D1;
  LOOP @@55;
  JMP  @@60;
@@58:
  XCHG AL,PageNo;
  DEC  AL;

   { Select Page }

  PUSH DX;
   MOV DX,$3CD;
   MOV AH,AL;
   AND AH,$0F;
   MOV AL,AH;
   {$IFOPT G+}
    SHL AH,4;
   {$ELSE}
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
    SHL AH,1;
   {$ENDIF}
   OR  AL,AH;
   OUT DX,AL;
  POP DX;

  XCHG AL,PageNo;
  JMP  @@56;
@@59:
  XCHG AL,PageNo;
  DEC  AL;

   { Select Page }

  PUSH DX;
  MOV  DX,$3CD;
  MOV  AH,AL;
  AND  AH,$0F;
  MOV  AL,AH;
  {$IFOPT G+}
   SHL AH,4;
  {$ELSE}
   SHL AH,1;
   SHL AH,1;
   SHL AH,1;
   SHL AH,1;
  {$ENDIF}
  OR   AL,AH;
  OUT  DX,AL;
  POP  DX;

  XCHG AL,PageNo;
  LOOP @@55;
@@60:
  MOV VG.W_Page,$FF;
  MOV VG.R_Page,$FF;
  MOV VG.RW_Page,$FF;
 END;
End;

Procedure Tseng4000PutBox(X1,Y1,X2,Y2:Word;Color:Byte);
Var
 J:Word;
Begin
 If(X1>X2)Then Exit;
 For J:=Y1 to Y2 do Tseng4000PutLine(X1,J,X2,Color)
End;

Procedure Tseng4000PutLine(X1,Y,X2:Word;Color:Byte);
Var
 AddressY,Address1,Address2:LongInt;
 L1,L:Word;
Begin
 If(X1>X2)Then Exit;
 L:=(X2-X1)+1;
 AddressY:=(LongInt(Y)*LongInt(VG.BytesPerScanLine));
 Address1:=LongInt(X1)+AddressY;
 Address2:=LongInt(X2)+AddressY;
 Tseng4000SelectWritePage(Address1 shr 16);
 If(Byte(Address1 shr 16) = Byte(Address2 shr 16))Then
 Begin
  FillChar(Mem[VG.AddrSegment:Word(Address1)],L,Color);
 End
  Else
 Begin
  L1 := (WordMax - Word(Address1)) + 1;
  FillChar(Mem[VG.AddrSegment:Word(Address1)],L1,Color);
  Tseng4000SelectWritePage(Address2 shr 16);
  FillChar(Mem[VG.AddrSegment:0],L-L1,Color);
 End;
End;

Procedure Tseng4000PutLineV(X,Y1,Y2:Word;Color:Byte);
Var
 Address:LongInt;
 J:Word;
Begin
 Address:=Get8BitAddress(X,Y1);
 For J:=Y1 to Y2 do Begin
  Tseng4000SelectWritePage(Byte(Address shr 16));
  Mem[VG.AddrSegment:Word(Address)] := Color;
  Inc(Address,VG.BytesPerScanLine);
 End;
End;

Procedure Tseng4000SelectPage(Page:Byte);Assembler;ASM
 MOV DX,$3CD;
 MOV AH,Page;
 AND AH,$0F;
 MOV VG.RW_Page,AH;
 MOV VG.R_Page,$FF;
 MOV VG.W_Page,$FF;
 MOV AL,AH;
 {$IFOPT G+}
  SHL AH,4;
 {$ELSE}
  SHL AH,1;
  SHL AH,1;
  SHL AH,1;
  SHL AH,1;
 {$ENDIF}
 OR AL,AH;
 OUT DX,AL;
END;

Procedure Tseng4000SelectReadPage(Page:Byte);Assembler;ASM
 MOV AL,Page;
 CMP VG.R_Page,AL;
 JE  @@2;
 AND AL,$0F;
 MOV VG.R_Page,AL;
 MOV AH,AL;
 {$IFOPT G+}
  SHL AL,4;
 {$ELSE}
  SHL AL,1;
  SHL AL,1;
  SHL AL,1;
  SHL AL,1;
 {$ENDIF}
 MOV DX,$3CD;
 IN  AL,DX;
 AND AL,$0F;
 OR  AL,AH;
 OUT DX,AL;
 MOV VG.RW_Page,$FF;
 MOV VG.W_Page,$FF;
@@2:
END;

Procedure Tseng4000SelectWritePage(Page:Byte);Assembler;ASM
 MOV AL,Page;
 CMP VG.W_Page,AL;
 JE  @@2;
 AND AL,$0F;
 MOV VG.W_Page,AL;
 MOV AH,AL;
 MOV DX,$3CD;
 IN  AL,DX;
 AND AL,$F0;
 OR  AL,AH;
 OUT DX,AL;
 MOV VG.R_Page,$FF;
 MOV VG.RW_Page,$FF;
@@2:
END;

Procedure Tseng4000WritePixel(X,Y:Word;Color:Byte);
Var
 Address:LongInt;
Begin
 Address:=Get8BitAddress(X,Y);
 Tseng4000SelectWritePage(Byte(Address shr 16));
 Mem[VG.AddrSegment:Word(Address)]:=Color;
End;

Function Tseng4000ReadPixel(X,Y:Word):Byte;
Var
 Address:LongInt;
Begin
 Address:=Get8BitAddress(X,Y);
 Tseng4000SelectPage(Address shr 16);
 Tseng4000ReadPixel:=Mem[VG.AddrSegment:Word(Address)];
End;

BEGIN
 VG.MaxPage:=3;
 VG.Adaptor:=$FF;
 VG.Adaptor:=_Tseng4000;
 VG.MaxXPixels:=0;
 VG.MaxYPixels:=0;
 VG.NumXPixels:=0;
 VG.NumYPixels:=0;
 VG.BytesPerScanLine:=0;
 VG.AddrSegment:=$A000;
 VG.R_Page:=$FF;
 VG.W_Page:=$FF;
 VG.RW_Page:=$FF;
END.
