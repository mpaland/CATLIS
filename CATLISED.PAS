UNIT CatlisED;    { CATLIS Editor }

INTERFACE

USES Crt, Dos, CatlisUI, CatlisFD, CatlisBO;

PROCEDURE EDIT(var stimmung : setting;      { Stimmung wird editiert }
               var actual   : setting );    { Actual Stimmung in Steurung }

IMPLEMENTATION

TYPE  Talpha250 = string[250];

(*TYPE Setting = RECORD
                 Scene   : STRING[9];      { Szene }
                 Number  : STRING[9];      { Nummer der Stimmung }
                 Time    : STRING[7];      { Zeit, in der die St. kommt }
                 Channel : ARRAY[1..128] OF BYTE; { 128 Kanaleinst. 0-100% }
                 Tone    : STRING[180];           { Tonanw.  der Stimmung }
                 Text    : STRING[240];           { Textanw. der Stimmung }
               END;

       Channeltype : ARRAY[1..128] OF BYTE; {Fr Show_Channels und Fader}

*)
VAR  N,M       : INTEGER;     {Schleifenvariablen}
     savetext  : byte;        {speichert die textattribute zwischen}
     dummy     : char;        {Wenn ein Rckgabewert in die Tonne soll}
     ebuffer   : Talpha250;   {Der Eingabebuffer fr ein Feld}
     edtype    : byte;        {Flag; sagt an, was gerade ediert wird}
     buflen    : integer;     {L„nge des gerade zu edierenden Feldes}
     return    : byte;        {Mein Returnstatus vom Editor}
     channelp  : channeltype; {Kanalinformationen fr SHOW_CHANNELS}
     offset2   : byte;        {Fr SHOW_CHANNELS}
     showed    : boolean;     { zeigt, ob Kanal„nderung sofort }
     relchan   : byte;
     xchan     : byte;
     ychan     : byte;
     insflag   : boolean;     { Autoinsert Ein / Aus }


(* ------------------ Editor fr alphanumerische Eingaben ---------------- *)

PROCEDURE EDIT;

procedure editor(lox,loy,rux,ruy,edlen:integer;var edbuf:talpha250;var status:byte;etype:byte);

var x,y,cin:byte;             {Cursorkoordinaten und Hilfsvariable}
    input  :char;             {Die aktuelle Schaubude, „h, Taste  }
    onechar:string[1];        {Einzeichen, frs INSERT im Editor}
    edxyabs:byte;             {Position des Cursors im Eingabefeld}

begin
  onechar:=' ';               {Leerzeichen fr Insert}
  window(lox,loy,rux,ruy);    {Fenster aufmachen}
  textcolor(white);
  clrscr;                     {und putzen}
  write(copy(edbuf,0,length(edbuf))); {Das gilt es zu edieren}
  y:=1;                               {erstmal den Cursor auf (1,1) setzen}
  x:=1;
  gotoxy(x,y);
  repeat
    repeat                                 {we're waiting for a key}
    until keypressed;
    input:=readkey;                        {was haben wir denn gedrckt??}
    if (input=#0) and (keypressed) then begin {eine Sondertaste!}
      input:=readkey;                      {welche Sondertaste?}
      cin:=ord(input);
      input:=chr(1);                       {Sonderzeichen ausblenden}
      case cin of

      71: x:=1;                            {Home}


      79: x:=rux-lox+1;                    {End}


      77: begin                            {Cursor rechts}
            x:=x+1;                        {erstmal nach rechts}
            if x>(rux-lox+1) then begin    {schon aus dem Window raus?}
              x:=1;                        {ja->Cursor zum linken Rand}
              y:=y+1;                      {und einen Linefeed.}
              if y>(ruy-loy+1) then y:=y-1; {wars die letzte Zeile?}
            end;                            {wenn ja, bleiben wir dort.}
          end;

      75: begin                            {Cursor links}
            x:=x-1;                        {erstmal nach links}
            if x<1 then begin              {schon aus dem Window raus?}
              x:=rux-lox+1;                {ja->Cursor an den rechten Rand}
              y:=y-1;                      {und eine Zeile h”her}
              if y<1 then y:=1;            {wars die oberste Zeile?}
            end;                           {wenn ja, bleiben wir dort}
          end;

      72: if y>1 then y:=y-1;              {Cursor hoch, wenn nicht oben}

      73: begin                            {PgUp}
            input:=#0;
            if offset2>0 then
              offset2:=offset2-32;
            window(1,1,80,25);
            textcolor(lightblue);
            show_channels(stimmung.channel,offset2);
            textcolor(White);
            if etype=4 then
              textbackground(brown);
            if (etype>=1) and (etype<=3) then
              textbackground(green);
            window(lox,loy,rux,ruy);
          end;

      81: begin                            {PgDwn}
            input:=#0;
            if offset2<96 then
              offset2:=offset2+32;
            window(1,1,80,25);
            textcolor(lightblue);
            show_channels(stimmung.channel,offset2);
            textcolor(white);
            if etype=4 then
              textbackground(brown);
            if (etype>=1) and (etype<=3) then
              textbackground(green);
            window(lox,loy,rux,ruy);
          end;

      80: if y<(ruy-loy+1) then y:=y+1;    {Cursor runter, wenn nicht unten}

      82: begin                            {Insert}
            insflag:=not(insflag);
            window(1,1,80,25);
            gotoxy(59,25);
            savetext:=textattr;
            textbackground(cyan);
            textcolor(black);
            if insflag=true then
               write('Insert')
             else
               write('      ');
            textattr:=savetext;
            window(lox,loy,rux,ruy);
            gotoxy(x,y);
          end;

      83: begin                            {Delete}
            edxyabs:=(y-1)*(rux-lox+1)+x;  {Cursorposition berechnen}
            if edxyabs<edlen then begin    {Wenn wir nicht am Ende sind,}
              delete(edbuf,edxyabs,1);     {nehmen wir ein Zeichen raus}
              insert(onechar,edbuf,y*(rux-lox+1)); {setzen am Ende ein Space}
              cursor_off;
              gotoxy(1,1);                 {und schreiben den ganzen Ramsch}
              write(copy(edbuf,0,edlen));  {neu hin.}
              gotoxy(x,y);                 {Cursor auf alte Position setzen}
              cursor_on;
            end;
          end;
    end;
  end;

  if (ord(input)=8) and (x>1) then begin  {Backspace, wenn nicht in Spalte 1}
    x:=x-1;                               {einmal Cursor links}
    edxyabs:=(y-1)*(rux-lox+1)+x;         {Cursorposition berechnen}
    delete(edbuf,edxyabs,1);              {ein Zeichen wegl”schen}
    insert(onechar,edbuf,y*(rux-lox+1));  {setzen am Ende ein Space}
    cursor_off;                           {Cursor abschalten}
    gotoxy(1,1);
    write(copy(edbuf,0,edlen));           {und neu ausgeben}
    gotoxy(x,y);                          {Cursor auf alte Position setzen}
    cursor_on;                            {und Cursor wieder an}
  end;

  cin:=ord(input);
  if cin=13 then begin
               {Ein Return!}
    x:=1;                                 {Cursor zum Anfang}
    cin:=1; {etwas schummeln, damit man mit Return in die letzte Zeile kommt}
    if y<(ruy-loy+1) then y:=y+1 else cin:=13; {und ein Linefeed, ggf. raus }
  end;

  edxyabs:=(y-1)*(rux-lox+1)+x;           {Cursorposition berechnen}
  if (cin>31) and (cin<256) and (edxyabs<edlen) then begin
    if insflag=true then begin
       delete(edbuf,y*(rux-lox+1),1);
       if y=(ruy-loy+1) then
          delete(edbuf,edlen-1,1);
       insert(input,edbuf,edxyabs);   {Das Zeichen einfgen}
       cursor_off;
       gotoxy(1,1);
       write(copy(edbuf,0,edlen));    {Alles nochmal neu hinschreiben}
       gotoxy(x,y);                   {Cursor auf alte Position setzen}
       cursor_on;
     end;

    edbuf[edxyabs]:=input;
    if insflag=false then
       write(input);
    x:=x+1;                               {erstmal nach rechts}
    if x>(rux-lox+1) then begin           {schon aus dem Window raus?}
      x:=1;                               {ja->Cursor zum linken Rand}
      y:=y+1;                             {und einen Linefeed.}
      if y>(ruy-loy+1) then y:=y-1;       {wars die letzte Zeile?}
    end;                                  {wenn ja, bleiben wir dort.}
  end;

  gotoxy(x,y);
  until (cin=27) or (cin=9) or ((cin=13) and (y=(ruy-loy+1)));
  clrscr;
  textcolor(yellow);
  write(edbuf);
  window(1,1,80,25);
  if ord(input)=27 then status:=1 else status:=0;


end;

(* -------------------- Ende alphanumerischer Editor --------------------- *)

(* -------------------- Hilfsprozedur ------------------------------------ *)

procedure chan_norm;
begin
  textcolor(yellow);
  gotoxy(xchan,ychan);
  write(stimmung.channel[relchan+offset2]:3);
  textbackground(brown);
  textcolor(white);
  gotoxy(xchan,ychan-1);
  write(relchan+offset2:3);
  textbackground(black);
end;

(* ------------------------ Ende Hilfsprozedur --------------------------- *)

(* --------- Eingabe von einem Prozentwert im Kanaleditor ---------------- *)

procedure ed_percent(key:char;var percent:byte);
var counter : byte;
    pbuffer : string[3];
    xpro    : integer;
    error   : integer;
    xbuffer : string[4];

begin
  cursor_on;
  counter:=1;
  pbuffer:=key+'  ';
  repeat
    gotoxy(xchan,ychan);
    write(pbuffer);
    gotoxy(xchan+counter,ychan);
    repeat
    until keypressed;
    key:=readkey;
    if (key=#0) and (keypressed) then
      dummy:=readkey;
    if (key=#8) and (counter>0) then
      begin
        pbuffer[counter]:=' ';
        dec(counter);
      end;
    if (key>='0') and (key<='9') and (counter<3) then
      begin
        inc(counter);
        pbuffer[counter]:=key;
      end;
    if (key=#13) and (counter>0) then begin
      xbuffer:='';
      for n:=1 to counter do
        xbuffer:=xbuffer+pbuffer[n];
      pbuffer:=xbuffer;
    end;
    val(pbuffer,xpro,error);
    if (key=#13) and ((error<>0) or (xpro>100)) then
      begin
        cursor_off;
        gotoxy(40,21);
        textbackground(red);
        write('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
        gotoxy(40,22);
        write('³ Number not in range 0..100. Press ESC ³');
        gotoxy(40,23);
        write('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
        repeat
          if keypressed then dummy:=readkey else dummy:=#32;
        until dummy=#27;
        textbackground(black);
        gotoxy(40,21);
        WRITE('ÄÄÄÄÄÄÄ¿                                 ');
        gotoxy(40,22);
        WRITE('     % ³                                 ');
        gotoxy(40,23);
        WRITE('ÄÄÄÄÄÄÄÙ                                 ');
        cursor_on;
      end;
  until (key=#13) and (xpro<=100) and (error=0);
  cursor_off;
  percent:=xpro;
end;

(* --------------------- Ende Prozenteingabe ----------------------------- *)

(* --------------------- Anfang Kanaleditor ------------------------------ *)

Procedure Chan_edit(var status:byte);
var taste   : char;

begin
  window(1,1,80,25);
  relchan:=1;
  show_channels(stimmung.channel,offset2);
  repeat
    xchan:=17+4*((relchan-1) mod 16);
    ychan:=4+3*((relchan-1) div 16);
    gotoxy(xchan,ychan);
    textcolor(white);
    write(stimmung.channel[relchan+offset2]:3);
    gotoxy(xchan,ychan-1);
    textbackground(brown);
    textcolor(black);
    write(relchan+offset2:3);
    textcolor(white);
    repeat
      show_time;
      textbackground(black);
    until keypressed;
    taste:=readkey;
    if (taste=#0) and (keypressed) then
    begin
      taste:=readkey;
      case ord(taste) of

        72: if stimmung.channel[relchan+offset2]<96 then   {CursorUp}
                inc(stimmung.channel[relchan+offset2],5)   {Channel +5%}
                else stimmung.channel[relchan+offset2]:=100;

        80: if stimmung.channel[relchan+offset2]>4 then    {CursorDown}
                dec(stimmung.channel[relchan+offset2],5)   {Channel -5%}
                else stimmung.channel[relchan+offset2]:=0;

        71: begin                                          {Home}
              gotoxy(40,21);
              textbackground(red);
              write('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
              gotoxy(40,22);
              write('³ Set complete setting to   0% ?  (Y/N) ³');
              gotoxy(40,23);
              write('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
              repeat
              if keypressed then dummy:=readkey else dummy:=#32;
              until ((upcase(dummy)='Y') or (upcase(dummy)='N') or (dummy=#27));
              textbackground(black);
              gotoxy(40,21);
              WRITE('ÄÄÄÄÄÄÄ¿                                 ');
              gotoxy(40,22);
              WRITE('     % ³                                 ');
              gotoxy(40,23);
              WRITE('ÄÄÄÄÄÄÄÙ                                 ');
              if upcase(dummy)='Y' then begin
                 for n:=1 to 128 do
                    stimmung.channel[n]:=0;
                 if showed = true then begin
                    SHOW_DATA(actual,stimmung);
                    SHOW_ACTUAL(actual.number);
                 end;
              end;
              show_channels(stimmung.channel,offset2);
            end;

        79: begin                                          {End}
              gotoxy(40,21);
              textbackground(red);
              write('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
              gotoxy(40,22);
              write('³ Set complete setting to 100% ?  (Y/N) ³');
              gotoxy(40,23);
              write('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
              repeat
              if keypressed then dummy:=readkey else dummy:=#32;
              until ((upcase(dummy)='Y') or (upcase(dummy)='N') or (dummy=#27));
              textbackground(black);
              gotoxy(40,21);
              WRITE('ÄÄÄÄÄÄÄ¿                                 ');
              gotoxy(40,22);
              WRITE('     % ³                                 ');
              gotoxy(40,23);
              WRITE('ÄÄÄÄÄÄÄÙ                                 ');
              if upcase(dummy)='Y' then begin
                 for n:=1 to 128 do
                    stimmung.channel[n]:=100;
                 if showed = true then begin
                    SHOW_DATA(actual,stimmung);
                    SHOW_ACTUAL(actual.number);
                 end;
              end;
              show_channels(stimmung.channel,offset2);
            end;

        75: begin                                          {CursorLeft}
              chan_norm;                                   {Previous Channel}
              if relchan>1 then dec(relchan) else relchan:=32;
            end;

        77: begin                                          {CursorRight}
              chan_norm;                                   {Next Channel}
              if relchan<32 then inc(relchan) else relchan:=1;
            end;

        73: begin                                          {PageUp}
              if offset2>0 then dec(offset2,32);           {Show Previous}
              show_channels(stimmung.channel,offset2);     {32 Channels}
            end;

        81: begin                                          {PageDown}
              if offset2<96 then inc(offset2,32);          {Show Next 32}
              show_channels(stimmung.channel,offset2);     {Channels}
            end;

        116: begin                                         {CtrlCursorRight}
               for n:=1 to 128 do                          {Setting +5%}
                 if stimmung.channel[n] <> 0 then
                    if (stimmung.channel[n]<96) then
                      inc(stimmung.channel[n],5)
                    else
                      stimmung.channel[n]:=100;
               show_channels(stimmung.channel,offset2);
             end;

        115: begin                                         {CtrlCursorLeft}
               for n:=1 to 128 do                          {Setting -5%}
                 if stimmung.channel[n]>4 then
                   dec(stimmung.channel[n],5)
                 else
                   stimmung.channel[n]:=0;
               show_channels(stimmung.channel,offset2);
             end;
         63: begin                                         { F5 }
                showed:= true;
                SHOW_DATA(actual,stimmung);
                board(stimmung);
                SHOW_Setting(stimmung,offset);
                SHOW_Actual(actual.number);
                textbackground(black);
             end;
         67: begin                                         { F9 }
                showed:= NOT showed;
                if showed = true then begin
                   textcolor(red);
                   gotoxy(57,22);
                   write('DYNAMIC SHOW MODE ON');
                   SHOW_DATA(actual,stimmung);
                   SHOW_Actual(actual.number);
                   textbackground(black);
                end
                else begin
                   gotoxy(57,22);
                   write('                    ');
                end;
             end;
         68: begin                                         { F10 }
               SHOW_DATA(actual,stimmung);
               SHOW_Actual(actual.number);
               textbackground(black);
             end;
      end;
      if showed = true then begin
         textcolor(red);
         gotoxy(57,22);
         write('DYNAMIC SHOW MODE ON');
         DATA_OUT(stimmung.channel);
         for n:= 1 to 128 do
            actual.channel[n]:= stimmung.channel[n];
         actual.scene := stimmung.scene;
         actual.number:= stimmung.number;
      end;
      taste:=#0;
    end;
    if (taste>='0') and (taste<='9') then                  {0...9}
      begin                                                {Handeingabe}
        ed_percent(taste,stimmung.channel[relchan+offset2]);
        chan_norm;
        if relchan<32 then inc(relchan) else relchan:=1;
        if showed = true then begin
           textcolor(red);
           gotoxy(57,22);
           write('DYNAMIC SHOW MODE ON');
           SHOW_DATA(actual,stimmung);
           SHOW_Actual(actual.number);
           textbackground(black);
        end;
      end;
    until (taste=#9) or (taste=#27);
  show_channels(stimmung.channel,offset2);
  gotoxy(57,22);
  write('                    ');
  status:=0;
  showed:= false;
  if taste=#27 then status:=1;
end;

(* ------------------------ Ende Kanaleditor ----------------------------- *)

(* -------------------- Statuszeile fr Alpha-Editor --------------------- *)
procedure show_status;
begin
  textcolor(black);
  textbackground(cyan);
  gotoxy(1,24);
  writeln('  Use cursorkeys, insert, delete,                                        Swap  ');
    write('  backspace and return to edit                                           Swap  ');
  gotoxy(59,25);
  if insflag=true then write('Insert');
  textcolor(red);
  gotoxy(68,24);
  write('PgUp');
  gotoxy(68,25);
  write('PgDwn');
  textcolor(black);
end;
(* -------------------- Ende Statuszeile --------------------------------- *)


BEGIN                     { Hier geht das MAIN los }
  offset2:=  Offset;
  edtype:=2;
  showed:= false;
  insflag := true;
  show_setting(Stimmung,offset2);
  show_channels(stimmung.channel,offset2);
  textcolor(yellow);
  (* Hier f„ngt der Editor an *)
  repeat
  case edtype of
  1: begin
       show_status;
       gotoxy(32,25);
       write('PLAY  ');
       textbackground(green);
       ebuffer:=play;
       cursor_on;
       editor(24,1,32,1,9,ebuffer,return,edtype);
       cursor_off;
       play:=copy(ebuffer,0,8);
     end;
  2: begin
       show_status;
       gotoxy(32,25);
       write('SCENE ');
       textbackground(green);
       ebuffer:=stimmung.scene;
       cursor_on;
       editor(41,1,49,1,9,ebuffer,return,edtype);
       cursor_off;
       stimmung.scene:=copy(ebuffer,0,8);
     end;
  3: begin
       show_status;
       gotoxy(32,25);
       write('NUMBER');
       textbackground(green);
       ebuffer:=stimmung.number;
       cursor_on;
       editor(58,1,66,1,9,ebuffer,return,edtype);
       cursor_off;
       stimmung.number:=copy(ebuffer,0,8);
     end;
  4: begin
       show_status;
       gotoxy(32,25);
       write('TIME and (L,P,B,C)');
       textbackground(blue);
       ebuffer:=stimmung.time;
       cursor_on;
       editor(74,1,80,1,7,ebuffer,return,edtype);
       cursor_off;
       stimmung.time:=copy(ebuffer,0,6);
     end;
  5: begin
       textcolor(black);
       textbackground(cyan);
       gotoxy(1,24);
       write(' ',chr(26),',',chr(27),' : select       Set 100%          Set+5%   Up  +5%  F9  DMode        Swap  ');
       gotoxy(1,25);
       write                    (' BS, CR: edit       Set   0%          Set-5%   Dwn -5%  F10 SHOW         Swap  ');
       textcolor(red);
       gotoxy(17,24);
       write('End');
       gotoxy(17,25);
       write('Home');
       gotoxy(32,24);
       write('Ctrl+',chr(26));
       gotoxy(32,25);
       write('Ctrl+',chr(27));
       gotoxy(48,24);
       write('Up');
       gotoxy(48,25);
       write('Dwn');
       gotoxy(57,24);
       write('F9');
       gotoxy(57,25);
       write('F10');
       gotoxy(68,24);
       write('PgUp');
       gotoxy(68,25);
       write('PgDwn');
       chan_edit(return);                    {Procedur Chan_edit aufrufen}
     end;
  6: begin
       show_status;
       gotoxy(32,25);
       write('F/X   ');
       textbackground(black);
       ebuffer:=stimmung.tone;
       cursor_on;
       editor(19,10,78,12,180,ebuffer,return,edtype);
       cursor_off;
       stimmung.tone:=copy(ebuffer,0,180);
     end;
  7: begin
       show_status;
       gotoxy(32,25);
       write('TEXT  ');
       textbackground(black);
       ebuffer:=stimmung.text;
       cursor_on;
       editor(19,16,78,19,240,ebuffer,return,edtype);
       cursor_off;
       stimmung.text:=copy(ebuffer,0,240);
     end;
  end;
  if (return=0) then
    if edtype<7 then edtype:= edtype+1 else edtype:=1;
  until return=1;
  window(1,1,80,25);
  show_setting(stimmung,Offset2);
  Offset:= Offset2;
  gotoxy(80,25);
end;

END.