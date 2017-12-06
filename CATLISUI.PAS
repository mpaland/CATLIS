UNIT CatlisUI;   { CatlisUserInterface }

INTERFACE

USES Crt, Dos;

TYPE Channeltype = ARRAY[1..128] OF BYTE;

     Setting = RECORD
                 Scene   : STRING[9];      { Szene }
                 Number  : STRING[9];      { Nummer der Stimmung }
                 Time    : STRING[7];      { Zeit, in der die St. kommt }
                 Channel : Channeltype;    { 128 Kanaleinst. 0-100% }
                 Tone    : STRING[180];    { Tonanw.  der Stimmung }
                 Text    : STRING[240];    { Textanw. der Stimmung }
               END;

     SettingPtr = ^SettingType;         { Liste anlegen }

     SettingType = RECORD
                     Data : Setting;
                     Prev : SettingPtr;
                     Next : SettingPtr;
                   END;

{ GLOBALE VARS !!! }

VAR  RootPtr   : SettingPtr;  { Wurzelzeiger }
     Set1Ptr   : SettingPtr;  { Allgemeiner Zeiger }
     Set2Ptr   : SettingPtr;  { Allgemeiner Zeiger }
     DisplaySet: SettingPtr;  { Stimmung, die im Display gezeigt wird      }
     ActualSet : SettingPtr;  { Stimmung, die gerade laeuft (in Steuerung )}
     NextSet   : SettingPtr;  { Stimmung, die auf NEXT ausgegben wird, und }
                              { im Display sichtbar sein sollte            }
     EmtyPtr   : SettingPtr;  { Fester Zeiger auf leere Stimmung (Anfang)  }

     PLAY      : STRING[9];    { Name des Stuecks }
     Offset    : BYTE;         { Kanaloffset      }
     Output    : BOOLEAN;      { Interface Enable }
     DisplayDRV: STRING[5];    { Bildschirm Driver   }


{ So wird die Sache aufgerufen .... }

PROCEDURE SHOW_MAINSCREEN;
{ Zeigt und init den Hauptbildschirm zum Anfang des Programms }

PROCEDURE MAIN_HELP;
{ Gibt die Haupthilfe aus }

PROCEDURE EDIT_HELP;
{ Edit Hilfe }

PROCEDURE SHOW_TIME;
{ Zeigt die aktuelle Zeit aus }

PROCEDURE SHOW_ACTUAL(Actual : STRING);
{ Zeigt den STRING im Actual Fenster }

PROCEDURE SHOW_NEXT(Next : STRING);
{ Zeigt den STRING im Next Fenster }

PROCEDURE SHOW_CHANNELS(Chan   : Channeltype;
                        Offset : BYTE); { Offset = expliziter Kanaloffset }
                                        { z.B.:  0 : Kanal  1 -- 32       }
                                        {       32 : Kanal 33 -- 64 u.s.w.}
{ Zeigt die Kanaele xx bis yy je nach Offset (Routine fuer FADER ) }

PROCEDURE SHOW_SETTING(Actset : Setting;
                       Offset : BYTE   ); { OFFSET siehe SHOW_CHANNELS }
{ Gibt komplette Stimmung aus }

PROCEDURE SHOW_FADER(Percent : BYTE);
{ Erzeugt den FADER Balken }

PROCEDURE CURSOR_ON;
{ Schaltet den Cursor ein }

PROCEDURE CURSOR_OFF;
{ Schaltet den Cursor aus }


{ und jetzt die IMPLEMENTATION }

IMPLEMENTATION


VAR N,M         : INTEGER;       { ! Lokale ! Laufvars }
    Lasttime    : INTEGER;       { Zeitvar             }
    LastPer     : INTEGER;       { FADER Var           }
    Regs        : Registers;     { In DOS definiert    }



PROCEDURE SHOW_MAINSCREEN;
BEGIN
  DisplayDRV:= 'CGA';
  TEXTBACKGROUND(0);
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
  TEXTBACKGROUND(1);
  WRITE(' TIME:        ');
  { Und jetzt die Channels }
  TEXTBACKGROUND(6);
  GOTOXY(17,3);
  WRITELN('  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16 ');
  GOTOXY(17,6);
  WRITELN(' 17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32 ');
  TEXTBACKGROUND(0);
  GOTOXY(17,9);
  WRITELN('зддддддддддддддддддддддддддд  F  X  ддддддддддддддддддддддддддд©');
  GOTOXY(17,10);
  WRITELN('Ё                                                              Ё');
  GOTOXY(17,11);
  WRITELN('Ё                                                              Ё');
  GOTOXY(17,12);
  WRITELN('Ё                                                              Ё');
  GOTOXY(17,13);
  WRITELN('юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды');
  { Und das Textfenster }
  GOTOXY(17,15);
  WRITELN('здддддддддддддддддддддддд  T  E  X  T  дддддддддддддддддддддддд©');
  GOTOXY(17,16);
  WRITELN('Ё                                                              Ё');
  GOTOXY(17,17);
  WRITELN('Ё                                                              Ё');
  GOTOXY(17,18);
  WRITELN('Ё                                                              Ё');
  GOTOXY(17,19);
  WRITELN('Ё                                                              Ё');
  GOTOXY(17,20);
  WRITELN('юдддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды');
  { Jetzt die Zeit }
  TEXTBACKGROUND(1);
  GOTOXY(1,3);
  WRITELN('зддддддддддддд©');
  WRITELN('Ё   T I M E   Ё');
  WRITELN('Ё             Ё');
  WRITELN('юддддддддддддды');
  WRITELN;
  { USW ... }
  TEXTBACKGROUND(6);
  WRITELN('зддддддддддддд©');
  WRITELN('Ё   DISPLAY   Ё');
  WRITELN('Ё             Ё');
  WRITELN('юддддддддддддды');
  WRITELN;
  TEXTBACKGROUND(4);
  WRITELN('зддддддддддддд©');
  WRITELN('Ё   N E X T   Ё');
  WRITELN('Ё             Ё');
  WRITELN('юддддддддддддды');
  TEXTBACKGROUND(2);
  WRITELN;
  WRITELN('зддддддддддддд©');
  WRITELN('Ё   ACTUAL    Ё');
  WRITELN('Ё             Ё');
  WRITELN('юддддддддддддды');
  { Dann den FADER }
  TEXTBACKGROUND(0);
  GOTOXY(17,21);
  WRITE('зрдбдбдбдбдрдбдбдбдбдрбддддддд©');
  GOTOXY(17,22);
  WRITE('Ё0         ╚         NЁ     % Ё');
  GOTOXY(17,23);
  WRITE('юпдададададпдададададпаддддддды');
END;


PROCEDURE MAIN_HELP;
BEGIN
  GOTOXY(3,23);
  TEXTBACKGROUND(0);
  TEXTCOLOR(12);
  WRITE('STAND BY   ');
  GOTOXY(1,24);
  TEXTBACKGROUND(3);
  TEXTCOLOR(15);
  WRITELN('                                                                               ');
  WRITE  ('                                                                               ');
  GOTOXY(2,24);
  TEXTCOLOR(0);
  WRITE('   Next     F1 SET Prev    Show Prev    Actual  F5 Panel        Swap    Edit');
  GOTOXY(2,25);
  WRITE('            F2 SET Next    Show Next    SPACE Show NEXT         Swap    Quit');
  TEXTCOLOR(4);
  IF DisplayDRV = 'MONO' THEN
     HIGHVIDEO
  ELSE
     LOWVIDEO;
  GOTOXY(5,24);
  WRITE('N');
  GOTOXY(14,24);
  WRITE('F1');
  GOTOXY(14,25);
  WRITE('F2');
  GOTOXY(27,24);
  WRITE(CHR(27));
  GOTOXY(27,25);
  WRITE(CHR(26));
  GOTOXY(42,24);
  WRITE('A');
  GOTOXY(50,24);
  WRITE('F5');
  GOTOXY(42,25);
  WRITE('SPACE');
  GOTOXY(60,24);
  WRITE('PgUp');
  GOTOXY(60,25);
  WRITE('PgDwn');
  GOTOXY(74,24);
  WRITE('E');
  GOTOXY(74,25);
  WRITE('Q');
END;


PROCEDURE EDIT_HELP;
BEGIN
  GOTOXY(3,23);
  TEXTBACKGROUND(0);
  TEXTCOLOR(12);
  WRITE(' EDITOR   ');
  GOTOXY(1,24);
  TEXTBACKGROUND(3);
  TEXTCOLOR(15);
  WRITELN('                                                                               ');
  WRITE  ('                                                                               ');
  GOTOXY(2,24);
  TEXTCOLOR(0);
  WRITE('   Edit      Save      New Record      Show Prev                        Swap');
  GOTOXY(2,25);
  WRITE('   Copy      Load      Del Record      Show Next       F10 SHOW         Swap');
  TEXTCOLOR(4);
  IF DisplayDRV = 'MONO' THEN
     HIGHVIDEO
  ELSE
     LOWVIDEO;
  GOTOXY(5,24);
  WRITE('E');
  GOTOXY(5,25);
  WRITE('C');
  GOTOXY(15,24);
  WRITE('S');
  GOTOXY(15,25);
  WRITE('L');
  GOTOXY(25,24);
  WRITE('N');
  GOTOXY(25,25);
  WRITE('D');
  GOTOXY(68,24);
  WRITE('PgUp');
  GOTOXY(68,25);
  WRITE('PgDwn');
  gotoxy(39,24);
  write(chr(27));
  gotoxy(39,25);
  write(chr(26));
  GOTOXY(57,25);
  WRITE('F10');
END;


PROCEDURE SHOW_TIME;

VAR  Hour, Minute,
     Second, Sec100  : WORD;
     sminute, ssec   : string[2];

BEGIN
  GETTIME(Hour,Minute,Second,Sec100);
  IF Lasttime <> (Hour + Minute + Second) THEN BEGIN
     LastTime := Hour + Minute + Second;
     str(minute:2, sminute);
     str(second:2, ssec);
     if sminute[1]=' ' then sminute[1]:='0';
     if ssec[1]=' ' then ssec[1]:='0';
     GOTOXY(5,5);
     TEXTBACKGROUND(1);
     TEXTCOLOR(15);
     HIGHVIDEO;
     WRITE('        ');
     GOTOXY(5,5);
     WRITE(Hour:2,':',sminute,':',ssec);
  END;
END;


PROCEDURE SHOW_ACTUAL;
BEGIN
  GOTOXY(6,20);
  TEXTBACKGROUND(2);
  TEXTCOLOR(14);
  HIGHVIDEO;
  WRITE('         ');
  GOTOXY(6,20);
  WRITE(Actual);
END;


PROCEDURE SHOW_NEXT;
BEGIN
  GOTOXY(6,15);
  TEXTBACKGROUND(4);
  TEXTCOLOR(14);
  HIGHVIDEO;
  WRITE('         ');
  GOTOXY(6,15);
  WRITE(Next);
END;


PROCEDURE SHOW_SETTING;
BEGIN
  TEXTBACKGROUND(6);
  TEXTCOLOR(15);
  IF DisplayDRV = 'MONO' THEN
     LOWVIDEO
  ELSE
     HIGHVIDEO;
  GOTOXY(17,3);
  CASE Offset OF
  0  : BEGIN
         WRITELN('  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16 ');
         GOTOXY(17,6);
         WRITELN(' 17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32 ');
       END;
  32 : BEGIN
         WRITELN(' 33  34  35  36  37  38  39  40  41  42  43  44  45  46  47  48 ');
         GOTOXY(17,6);
         WRITELN(' 49  50  51  52  53  54  55  56  57  58  59  60  61  62  63  64 ');
       END;
  64 : BEGIN
         WRITELN(' 65  66  67  68  69  70  71  72  73  74  75  76  77  78  79  80 ');
         GOTOXY(17,6);
         WRITELN(' 81  82  83  84  85  86  87  88  89  90  91  92  93  94  95  96 ');
       END;
  96 : BEGIN
         WRITELN(' 97  98  99 100 101 102 103 104 105 106 107 108 109 110 111 112 ');
         GOTOXY(17,6);
         WRITELN('113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 ');
       END;
  END;
  TEXTBACKGROUND(2);
  TEXTCOLOR(14);
  HIGHVIDEO;
  GOTOXY(24,1);
  WRITE(PLAY);
  GOTOXY(41,1);
  WRITE(Actset.Scene);
  GOTOXY(58,1);
  WRITE('         ');
  GOTOXY(58,1);
  WRITE(Actset.Number);
  GOTOXY(74,1);
  TEXTBACKGROUND(1);
  WRITE(Actset.Time);
  TEXTBACKGROUND(6);
  GOTOXY(6,10);
  WRITE('         ');
  GOTOXY(6,10);
  WRITE(Actset.Number);
  TEXTCOLOR(14);
  TEXTBACKGROUND(0);
  FOR N:= (1+Offset) TO (16+Offset) DO BEGIN
     GOTOXY((N-Offset)*4+13,4);
     WRITE(Actset.Channel[N]:3);
     GOTOXY((N-Offset)*4+13,7);
     WRITE(Actset.Channel[N+16]:3);
  END;
  GOTOXY(19,10);
  WRITE(COPY(Actset.Tone,1,60));
  GOTOXY(19,11);
  WRITE(COPY(Actset.Tone,61,60));
  GOTOXY(19,12);
  WRITE(COPY(Actset.Tone,121,60));
  GOTOXY(19,16);
  WRITE(COPY(Actset.Text,1,60));
  GOTOXY(19,17);
  WRITE(COPY(Actset.Text,61,60));
  GOTOXY(19,18);
  WRITE(COPY(Actset.Text,121,60));
  GOTOXY(19,19);
  WRITE(COPY(Actset.Text,181,60));
END;


PROCEDURE SHOW_CHANNELS;        { Offset = expliziter Kanaloffset }
BEGIN                           { z.B.:  0 : Kanal  1 -- 32       }
  TEXTBACKGROUND(6);            {       32 : Kanal 33 -- 64 u.s.w.}
  TEXTCOLOR(15);
  IF DisplayDRV = 'MONO' THEN
     LOWVIDEO
  ELSE
     HIGHVIDEO;
  GOTOXY(17,3);
  CASE Offset OF
  0  : BEGIN
         WRITELN('  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16 ');
         GOTOXY(17,6);
         WRITELN(' 17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32 ');
       END;
  32 : BEGIN
         WRITELN(' 33  34  35  36  37  38  39  40  41  42  43  44  45  46  47  48 ');
         GOTOXY(17,6);
         WRITELN(' 49  50  51  52  53  54  55  56  57  58  59  60  61  62  63  64 ');
       END;
  64 : BEGIN
         WRITELN(' 65  66  67  68  69  70  71  72  73  74  75  76  77  78  79  80 ');
         GOTOXY(17,6);
         WRITELN(' 81  82  83  84  85  86  87  88  89  90  91  92  93  94  95  96 ');
       END;
  96 : BEGIN
         WRITELN(' 97  98  99 100 101 102 103 104 105 106 107 108 109 110 111 112 ');
         GOTOXY(17,6);
         WRITELN('113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 ');
       END;
  END;
  TEXTBACKGROUND(0);
  TEXTCOLOR(14);
  HIGHVIDEO;
  FOR N:= (1+Offset) TO (16+Offset) DO BEGIN
     GOTOXY((N-Offset)*4+13,4);
     WRITE(Chan[N]:3);
     GOTOXY((N-Offset)*4+13,7);
     WRITE(Chan[N+16]:3);
  END;
END;


PROCEDURE SHOW_FADER;
BEGIN
  TEXTBACKGROUND(0);
  TEXTCOLOR(14);
  IF DisplayDRV = 'MONO' THEN
     LOWVIDEO
  ELSE
     HIGHVIDEO;
  GOTOXY(18,22);
  IF (PerCent = 0) OR (LastPer > PerCent) THEN
     WRITE('0         ╚         N');
  LastPer:= PerCent;
  GOTOXY(19,22);
  TEXTCOLOR(12);
  HIGHVIDEO;
  IF PERCENT > 4 THEN
     FOR N:=1 TO (PERCENT DIV 5) DO
        WRITE('ш');
  IF (PERCENT MOD 5) > 2 THEN
     WRITE('щ');
  GOTOXY(41,22);
  WRITE(PerCent:3);
END;


PROCEDURE CURSOR_OFF;
BEGIN
  with regs do
    begin
      AH:=1;
      BH:=0;
      CX:=$1000;
      intr($10,regs)
    end;
END;


PROCEDURE CURSOR_ON;
BEGIN
  with regs do
    begin
      AH:=1;
      BH:=0;
      CX:=$0607;
      intr($10,regs)
    end;
END;


END.  { Hier endet die IMPLEMENTATION }

