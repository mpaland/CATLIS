UNIT CatlisBO;    { CATLIS BOard }

INTERFACE

USES Crt, Dos, CatlisUI, CatlisFD;

PROCEDURE BOARD(var actual : setting ); { Actual Stimmung in Steurung }

IMPLEMENTATION

(*TYPE Setting = RECORD
                 Scene   : STRING[9];      { Szene }
                 Number  : STRING[9];      { Nummer der Stimmung }
                 Time    : STRING[7];      { Zeit, in der die St. kommt }
                 Channel : ARRAY[1..128] OF BYTE; { 128 Kanaleinst. 0-100% }
                 Tone    : STRING[180];           { Tonanw.  der Stimmung }
                 Text    : STRING[240];           { Textanw. der Stimmung }
               END;

       Channeltype : ARRAY[1..128] OF BYTE; {FÅr Show_Channels und Fader}
*)

var n, m, o, x, y : integer;
    relchan       : integer;  (* Der derzeitige zu Edierende Kanal *)
    offset2       : integer;  (* Der Relativkanal *)
    taste         : char;
    change        : boolean;

procedure board;

procedure show_slider(n, offs, farbe : byte);

var xs,ys   : integer;

begin
  cursor_off;
  textcolor(farbe);
  textbackground(black);
  xs:=7+4*(n-1);
  if n>8 then xs:=xs+5;
  for m:=6 to 16 do begin
    gotoxy(xs,m);
    write('  ');
  end;
  ys:=16-(actual.channel[n+offs] div 10);
  gotoxy(xs,ys);
  if (actual.channel[n+offs] mod 10) > 4 then
    begin
      write('ﬂﬂ');
      gotoxy(xs,ys-1);
      write('‹‹');
    end
  else
    write('€€');
  gotoxy(xs-1,19);
  textcolor(lightblue);
  textbackground(7);
  write(actual.channel[n+offs]:3);
end;


PROCEDURE PRTBoard;
BEGIN
  textbackground(black);
  CLRSCR;               { Schirm loeschen }
  TEXTBACKGROUND(4);
  TEXTCOLOR(15);
  IF DisplayDRV = 'MONO' THEN
     LOWVIDEO
  ELSE
     HIGHVIDEO;
  WRITE(' C A T L I S ');
  TEXTBACKGROUND(2);
  GOTOXY(17,1);
  WRITE(' Play:           Scene:          Number:          ');
  TEXTBACKGROUND(2);
  TEXTCOLOR(14);
  HIGHVIDEO;
  GOTOXY(24,1);
  WRITE(Play);
  GOTOXY(41,1);
  IF DisplaySet <> NIL THEN
    WRITE(DisplaySet^.Data.Scene)
  ELSE
    WRITE(EmtyPtr^.Data.Scene);
  GOTOXY(58,1);
  WRITE('         ');
  GOTOXY(58,1);
  IF DisplaySet <> NIL THEN
    WRITE(DisplaySet^.Data.Number)
  ELSE
    WRITE(EmtyPtr^.Data.Number);
  GOTOXY(3,23);
  TEXTBACKGROUND(0);
  TEXTCOLOR(12);
  WRITE('  PANEL   ');
  textcolor(black);
  textbackground(cyan);
  gotoxy(1,24);
  write(' ',chr(26),',',chr(27),' : select                                  Up  +5%                   Swap  ');
  gotoxy(1,25);
  write                    ('     to end                                    Dwn -5%                   Swap  ');
  textcolor(red);
  gotoxy(2,25);
  write('ESC');
  gotoxy(48,24);
  write('Up');
  gotoxy(48,25);
  write('Dwn');
  gotoxy(68,24);
  write('PgUp');
  gotoxy(68,25);
  write('PgDwn');

  gotoxy(1,5);
  textbackground(7);
  textcolor(white);
  writeln('⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø');
  for n:=0 to 5 do begin
  textbackground(7);
  textcolor(white);
  write('√ƒ');
  for m:=0 to 1 do begin
   write(100-n*20:3,'ƒ');
   if m=1 then write('ƒ');
   for o:=0 to 7 do begin
     textbackground(black);
     write('  ');
     textbackground(7);
     write('ƒƒ');
     end;
   end;
  writeln(chr(8),100-n*20:3,'ƒ¥');
  if 5>n then begin
    textbackground(7);
    textcolor(white);
    write('≥    ');
    for o:=0 to 15 do begin
       textbackground(7);
       write('˙');
       textbackground(black);
       write('  ');
       textbackground(7);
       write('˙');
       if o=7 then write('     ');
       end;
     writeln('    ≥');
    end;
  end;
write('≥    ');
textcolor(black);
for n:=1 to 16 do begin
  write(n+offset:3,' ');
  if n=8 then write('     ');
end;
textcolor(white);
writeln('    ≥');
writeln('≥                                                                             ≥');
writeln('≥  %                                                                          ≥');
writeln('¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ');

END;

procedure show_number(rel, offs: byte);

var n, xs : byte;

begin
  textbackground(7);
  for n:=1 to 16 do begin
    xs:=7+4*(n-1);
    if n>8 then xs:=xs+5;
    textcolor(white);
    if n=rel then textcolor(black);
    gotoxy(xs-1,17);
    write(offs+n:3);
  end;
end;


begin
  cursor_off;
  change:= false;
  prtboard;
  for n:=1 to 16 do
    show_slider(n,offset,lightred);
  offset2:=offset;
  relchan:=1;
  show_number(relchan,offset2);
  show_slider(relchan,offset2,lightgreen);
  repeat
    repeat
    until keypressed;
    taste:=readkey;
    if (taste=#0) and (keypressed) then begin
      taste:=readkey;
      case ord(taste) of

        72: begin
              if actual.channel[relchan+offset2]<96 then        {CursorUp}
                inc(actual.channel[relchan+offset2],5)        {Channel +5%}
              else
                actual.channel[relchan+offset2]:=100;
              show_slider(relchan,offset2,lightgreen);
              data_out(actual.channel);
              change:= true;
            end;

        80: begin
              if actual.channel[relchan+offset2]>4 then         {CursorDown}
                dec(actual.channel[relchan+offset2],5)        {Channel -5%}
              else
                actual.channel[relchan+offset2]:=0;
              show_slider(relchan,offset2,lightgreen);
              data_out(actual.channel);
              change:= true;
            end;

        75: begin                                          {CursorLeft}
              show_slider(relchan,offset2,lightred);       {Previous Channel}
              if relchan>1 then begin
                dec(relchan);
                show_number(relchan,offset2);
                show_slider(relchan,offset2,lightgreen);
              end
              else begin
                relchan := 16;
                if offset2>0 then dec(offset2,16);         {Show Previous}
                for n:=1 to 16 do begin                    {16 Channels}
                  if n=relchan then
                    show_slider(n,offset2,lightgreen)
                  else
                    show_slider(n,offset2,lightred);
                end;
                show_number(relchan,offset2);
              end;
            end;

        77: begin                                          {CursorRight}
              show_slider(relchan,offset2,lightred);
              if relchan<16 then begin
                inc(relchan);
                show_number(relchan,offset2);
                show_slider(relchan,offset2,lightgreen);
              end
              else begin
                relchan := 1;
                if offset2<112 then inc(offset2,16);       {Show Next 16}
                for n:=1 to 16 do begin                    {Channels}
                  if n=relchan then
                    show_slider(n,offset2,lightgreen)
                  else
                    show_slider(n,offset2,lightred);
                end;
                show_number(relchan,offset2);
              end;
            end;

        73: begin                                          {PageUp}
              if offset2>0 then dec(offset2,16);           {Show Previous}
              for n:=1 to 16 do begin                      {16 Channels}
                if n=relchan then
                  show_slider(n,offset2,lightgreen)
                else
                  show_slider(n,offset2,lightred);
              end;
              show_number(relchan,offset2);
            end;

        81: begin                                          {PageDown}
              if offset2<112 then inc(offset2,16);         {Show Next 16}
              for n:=1 to 16 do begin                      {Channels}
                if n=relchan then
                  show_slider(n,offset2,lightgreen)
                else
                  show_slider(n,offset2,lightred);
              end;
              show_number(relchan,offset2);
            end;
      end;
    end;
  until taste = #27;
  if change=true then
    actual.number:= '* * *';
end;

END.