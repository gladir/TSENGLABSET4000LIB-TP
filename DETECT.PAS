{ @author: Sylvain Maltais (support@gladir.com)
  @created: 1993
  @website(https://www.gladir.com/CODER/TSENGLABSET4000LIB-TP)
  @abstract(Target: Turbo Pascal 7)
}

Unit DETECT;

INTERFACE

Function  ITVGA2Detect:Boolean;
Function  TsengLabsET3000Detect:Boolean;
Function  TsengLabsET4000Detect:Boolean;
Procedure TsengLabsET4000ExtendedSetLock(X:Boolean);

IMPLEMENTATION

Function RtnChn(Seg,Ofs:Word;Nombre:Byte):String;
Var
 Temp:String;
 I:Byte;
Begin
 Temp:='';
 For I:=0 to Nombre do Temp:=Temp+Chr(Mem[Seg:Ofs+I]);
 RtnChn:=Temp;
End;

Function ITVGA2Detect:Boolean;Begin
 ITVGA2Detect:=(RtnChn($C000,$0181,8) = 'IT - VGA2');
End;

Function TsengLabsET3000Detect:Boolean;
Var
 Old,Val:Byte;
 Base:Integer;
Begin
 Old:=Port[$3CD];
 Port[$3CD]:=Old xor $3F;
 Val:=Port[$3CD];
 Port[$3CD]:=Old;
 If(Val<>(Old xor $3F))Then Begin
  TsengLabsET3000Detect:=False;
  Exit;
 End;
 If(Port[$3CC] and 1<>0)Then Base:=$3D4
	                Else Base:=$3B4;
 Port[Base]:=$1B;
 Old:=Port[Base+1];
 Port[Base+1]:=Old xor $FF;
 Val:=Port[Base+1];
 Port[Base+1]:=Old;
 If(Val<>(Old xor $FF))Then TsengLabsET3000Detect:=False
                       Else TsengLabsET3000Detect:=True;
End;

Procedure TsengLabsET4000ExtendedSetLock(X:Boolean);Begin
 If(X)Then Begin
  If(Port[$3CC] and 1<>0)Then Port[$3D8]:=$29
		         Else Port[$3B8]:=$29;
  Port[$3BF]:=$01;
 End
  Else
 Begin
  Port[$3BF]:=$03;
  If(Port[$3CC] and 1<>0)Then Port[$3D8]:=$A0
		         Else Port[$3B8]:=$A0;
 End;
End;

Function TsengLabsET4000Detect:Boolean;
Var
 New,Old,Val:Byte;
 Base:Integer;
Begin
 TsengLabsET4000Detect:=False;
  (* Active les registres ‚tendues *)
 TsengLabsEt4000ExtendedSetLock(False);
 Old:=Port[$3CD];
 Port[$3CD]:=$55;
 Val:=Port[$3CD];
 Port[$3CD]:=Old;
 If(Val<>$55)Then Exit;
 If(Port[$3CC]and 1<>0)Then Base:=$3D4
	               Else Base:=$3B4;
 Port[Base]:=$33;
 Old:=Port[Base+1];
 New:=Old xor $0F;
 Port[Base+1]:=New;
 Val:=Port[Base+1];
 Port[base+1]:=Old;
 If(Val<>New)Then Exit;
  (* Verrouille les registres ‚tendues *)
 TsengLabsEt4000ExtendedSetLock(True);
  (* ET4000 d‚tect‚ *)
 TsengLabsET4000Detect:=True;
End;

END.