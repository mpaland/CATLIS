PROGRAM CatlisMP;    { CATLIS MAIN PROGRAM }

USES Crt, Dos, CatlisUI, CatlisED, CatlisFD, CatlisBO;

(*   SettingPtr = ^SettingType;         { Liste anlegen }

     SettingType = RECORD
                     Data : Setting;
                     Prev : SettingPtr;
                     Next : SettingPtr;
                   END;

     RootPtr   : SettingPtr;  { Wurzelzeiger }
     Set1Ptr   : SettingPtr;  { Allgemeiner Zeiger }
     Set2Ptr   : SettingPtr;  { Allgemeiner Zeiger }
     DisplaySet: SettingPtr;  { Stimmung, die im Display gezeigt wird      }
     ActualSet : SettingPtr;  { Stimmung, die gerade laeuft (in Steuerung )}
     NextSet   : SettingPtr;  { Stimmung, die auf NEXT ausgegben wird, und }
                              { im Display sichtbar sein sollte            }
     EmtyPtr   : SettingPtr;  { Fester Zeiger auf leere Stimmung (Anfang)  }
*)


VAR  N,M       : INTEGER;
     Filename  : STRING[80];   { Filename }
     Files     : FILE OF Setting;
     KeyIn     : CHAR;


PROCEDURE INIT_VARS;
BEGIN
  Output:= TRUE;                       { Interface Output freigeben }
  Play:= '  ----  ';
  Offset:= 0;
  NEW(EmtyPtr);                        { Leeren Eintrag anlegen }
  EmtyPtr^.Data.Scene  := '-----';
  EmtyPtr^.Data.Number := '-----';
  EmtyPtr^.Data.Time   := '000';
  EmtyPtr^.Data.Tone   := '';
  EmtyPtr^.Data.Text   := '';
  FOR N:= 1 TO 179 DO
     EmtyPtr^.Data.Tone:= EmtyPtr^.Data.Tone + ' ';
  EmtyPtr^.Data.Text   := '                                                            ' +
                          '                -----  N O  E N T R Y  -----                ' +
                          '                                                            ' +
                          '                                                            ';
  EmtyPtr^.Prev:= NIL;
  EmtyPtr^.Next:= NIL;
  FOR N:= 1 TO 128 DO
     EmtyPtr^.Data.Channel[N]:= 0;
  RootPtr:= NIL;
  DisplaySet:= NIL;
  NextSet   := NIL;
  NEW(ActualSet);
  ActualSet^.Data:= EmtyPtr^.Data;
  ActualSet^.Data.Time:='      ';
  ActualSet^.Data.Number:= '* * *';
  ActualSet^.Data.Text := '                                                            ' +
                          '           ---  A C T U A L   S E T T I N G  ---            ' +
                          '                                                            ' +
                          '                                     ... press a key        ';
END;


PROCEDURE LOAD_CMDLine(Datei : STRING);
{ Diese Procedure zieht die Datei aus der CMDLine rein, wie LOAD }

BEGIN
  Filename:= Datei;
  IF Filename <> '' THEN BEGIN
   ASSIGN(Files,Filename + '.CAT');
   {$I-}
   RESET(Files);
   {$I+}
   IF IOResult = 0 THEN BEGIN

      { Destroy old List }
      Set1Ptr:= RootPtr;
      WHILE Set1Ptr <> NIL DO BEGIN
         Set2Ptr:= Set1Ptr^.Next;
         DISPOSE(Set1Ptr);
         Set1Ptr:= Set2Ptr;
      END;

      NEW(Set1Ptr);
      READ(Files,Set1Ptr^.Data);
      Play:= Set1Ptr^.Data.Scene;    { Stuecknamen rausprokeln }
      DISPOSE(Set1Ptr);

      RootPtr:= NIL;                 { Und laden }
      Set2Ptr:= NIL;
      WHILE EOF(Files) = FALSE DO BEGIN
         NEW(Set1Ptr);
         IF RootPtr = NIL THEN
            RootPtr:= Set1Ptr;
         READ(Files,Set1Ptr^.Data);
         Set1Ptr^.Prev:= Set2Ptr;
         IF Set1Ptr^.Prev <> NIL THEN
            Set1Ptr^.Prev^.Next:= Set1Ptr;
         Set1Ptr^.Next:=NIL;
         Set2Ptr:= Set1Ptr;
      END;
      CLOSE(Files);
      DisplaySet:= RootPtr;
      NextSet   := RootPtr;
   END;
  END;
END;


PROCEDURE  Parse_CMDLine;
BEGIN
  for n:=1 to paramcount do begin
    if ((paramstr(n)='/i') or (paramstr(n)='-i')) then
      output:=false;
    if ((copy(paramstr(n),1,3)='-f:') or (copy(paramstr(n),1,3)='/f:')) then
      load_cmdline(copy(paramstr(n),4,length(paramstr(n))-3));
  end;
end;


FUNCTION NEW_RECORD : SettingPtr;

{Diese Function legt ein neues Record an und uebergibt den Zeiger }

BEGIN
  NEW(Set1Ptr);                             { Neuen Eintrag anlegen }
  Set1Ptr^.Data.Scene  := '        ';
  Set1Ptr^.Data.Number := '        ';
  Set1Ptr^.Data.Time   := '      ';
  Set1Ptr^.Data.Tone:= '';
  Set1Ptr^.Data.Text:= '';
  FOR N:= 1 to 179 do
     Set1Ptr^.Data.Tone:= Set1Ptr^.Data.Tone + ' ';
  FOR N:= 1 to 239 do
     Set1Ptr^.Data.Text:= Set1Ptr^.Data.Text + ' ';
  Set1Ptr^.Prev:= NIL;
  Set1Ptr^.Next:= NIL;
  FOR N:= 1 TO 128 DO
     Set1Ptr^.Data.Channel[N]:= 0;
  NEW_RECORD:= Set1Ptr;
END;


PROCEDURE SET_RECORD(PutInPtr : SettingPtr);

VAR PutIn   : BOOLEAN;  { Schon reingepackt ??? VAR }
BEGIN
   Set1Ptr:= RootPtr;
   PutIn:= FALSE;

   IF Set1Ptr = NIL THEN BEGIN      { Der erste Eintrag }
      PutInPtr^.Prev:= NIL;
      PutInPtr^.Next:= NIL;
      RootPtr:= PutInPtr;
      Set1Ptr:= PutInPtr;
      PutIn:= TRUE;
   END;

   IF PutInPtr^.Data.Number < Set1Ptr^.Data.Number THEN BEGIN
      PutInPtr^.Prev:= NIL;
      PutInPtr^.Next:= Set1Ptr;     { Eintrag vor erstes Element }
      Set1Ptr^.Prev:= PutInPtr;
      RootPtr      := PutInPtr;
      PutIn:= TRUE
   END;

   WHILE (Set1Ptr <> NIL) AND (PutIn = FALSE) DO BEGIN
      IF (PutInPtr^.Data.Number >= Set1Ptr^.Data.Number)  AND
         (PutInPtr^.Data.Number < Set1Ptr^.Next^.Data.Number) OR
         (Set1Ptr^.Next = NIL) AND (PutIn = FALSE) THEN BEGIN

         PutInPtr^.Prev:= Set1Ptr;  { PutInPtr nach Set1Ptr einfuegen }
         PutInPtr^.Next:= Set1Ptr^.Next;
         IF Set1Ptr^.Next <> NIL THEN
            Set1Ptr^.Next^.Prev:= PutinPtr;
         Set1Ptr^.Next := PutInPtr;
         PutIn:= TRUE;
      END;
      Set1Ptr:=Set1Ptr^.Next;   { Naechstes ELement }
   END;
END;


FUNCTION DEL_BUTTON(DelPtr : SettingPtr): BOOLEAN;
BEGIN
  TEXTBACKGROUND(12);
  TEXTCOLOR(15);
  GOTOXY(29,8);
  WRITE('ษออออออออออออออออออออออออออออป');
  GOTOXY(29,9);
  WRITE('บ                            บ');
  GOTOXY(29,10);
  WRITE('บ  DELETE  THIS  RECORD  ??  บ');
  GOTOXY(29,11);
  WRITE('บ                            บ');
  GOTOXY(29,12);
  WRITE('บ                            บ');
  GOTOXY(29,13);
  WRITE('บ                            บ');
  GOTOXY(29,14);
  WRITE('บ                 ( Y / N )  บ');
  GOTOXY(29,15);
  WRITE('ศออออออออออออออออออออออออออออผ');
  GOTOXY(39,12);
  WRITE(DelPtr^.Data.Number);
  REPEAT
    SHOW_TIME;
  UNTIL KEYPRESSED;
  KeyIn:= READKEY;
  IF (KeyIn = 'y') OR (KeyIn = 'Y') THEN
     DEL_BUTTON:= TRUE
  ELSE
     DEL_BUTTON:= FALSE;
  WHILE KEYPRESSED DO
     KeyIn:= READKEY;                     { Buffer leer machen   }
  SHOW_MAINSCREEN;                        { Bild wieder aufbauen }
  EDIT_HELP;
  IF DisplaySet <> NIL THEN
     SHOW_SETTING(DisplaySet^.Data,Offset)
  ELSE
     SHOW_SETTING(EmtyPtr^.Data,Offset);
  IF NextSet <> NIL THEN
     SHOW_NEXT(NextSet^.Data.Number)
  ELSE
     SHOW_NEXT(EmtyPtr^.Data.Number);
  SHOW_ACTUAL(ActualSet^.Data.Number);
END;


PROCEDURE DEL_RECORD(DelPtr : SettingPtr);
BEGIN

  IF DelPtr^.Prev <> NIL THEN          { Nicht das Erste Element }
     DelPtr^.Prev^.Next:= DelPtr^.Next
  ELSE
     RootPtr:= DelPtr^.Next;           { Es ist das Erste }

  IF DelPtr^.Next <> NIL THEN          { Nicht das Letzte }
     DelPtr^.Next^.Prev:= DelPtr^.Prev;

  DISPOSE(DelPtr);      { Und Tschuess }

END;


PROCEDURE SAVE_DATA;
BEGIN
   TEXTBACKGROUND(12);
   TEXTCOLOR(15);
   GOTOXY(17,8);
   WRITE('ษออออออออออออออออออออออออออออออออออออออออออออออป');
   GOTOXY(17,9);
   WRITE('บ                                              บ');
   GOTOXY(17,10);
   WRITE('บ            S A V E    F I L E  ??            บ');
   GOTOXY(17,11);
   WRITE('บ                                              บ');
   GOTOXY(17,12);
   WRITE('บ                                              บ');
   GOTOXY(17,13);
   WRITE('บ                                              บ');
   GOTOXY(17,14);
   WRITE('บ                                              บ');
   GOTOXY(17,15);
   WRITE('ศออออออออออออออออออออออออออออออออออออออออออออออผ');
   GOTOXY(24,12);
   CURSOR_ON;
   READLN(Filename);
   CURSOR_OFF;
   IF Filename <> '' THEN BEGIN
      ASSIGN(Files,Filename + '.CAT');
      {$I-}
      REWRITE(Files);
      {$I+}
      IF IOResult = 0 THEN BEGIN
         EmtyPtr^.Data.Scene:= Play;     { Stueckname speichern }
         WRITE(Files,EmtyPtr^.Data);
         EmtyPtr^.Data.Scene:= '-----';  { Und wieder herstellen }

         Set1Ptr:= RootPtr;
         WHILE Set1Ptr <> NIL DO BEGIN
            WRITE(Files,Set1Ptr^.Data);
            Set1Ptr:= Set1Ptr^.Next;
         END;
         CLOSE(Files);
      END
      ELSE BEGIN
         GOTOXY(32,12);
         WRITE('   --- E R R O R ---      ');
         GOTOXY(32,14);
         WRITE('            Press ESC ...');
         REPEAT
            SHOW_TIME;
            IF KEYPRESSED THEN
               KeyIn:= READKEY
            ELSE
               KeyIn:= ' ';
         UNTIL KeyIn = CHR(27);
         WHILE KEYPRESSED DO
            KeyIn:= READKEY;                { Buffer leer machen   }
      END;
   END;
   SHOW_MAINSCREEN;                         { Bild wieder aufbauen }
   EDIT_HELP;
   IF DisplaySet <> NIL THEN
      SHOW_SETTING(DisplaySet^.Data,Offset)
   ELSE
      SHOW_SETTING(EmtyPtr^.Data,Offset);
   IF NextSet <> NIL THEN
      SHOW_NEXT(NextSet^.Data.Number)
   ELSE
      SHOW_NEXT(EmtyPtr^.Data.Number);
   SHOW_ACTUAL(ActualSet^.Data.Number);
END;


PROCEDURE LOAD_DATA;
BEGIN
   TEXTBACKGROUND(12);
   TEXTCOLOR(15);
   GOTOXY(17,8);
   WRITE('ษออออออออออออออออออออออออออออออออออออออออออออออป');
   GOTOXY(17,9);
   WRITE('บ                                              บ');
   GOTOXY(17,10);
   WRITE('บ            L O A D    F I L E  ??            บ');
   GOTOXY(17,11);
   WRITE('บ                                              บ');
   GOTOXY(17,12);
   WRITE('บ                                              บ');
   GOTOXY(17,13);
   WRITE('บ                                              บ');
   GOTOXY(17,14);
   WRITE('บ                                              บ');
   GOTOXY(17,15);
   WRITE('ศออออออออออออออออออออออออออออออออออออออออออออออผ');
   GOTOXY(24,12);
   CURSOR_ON;
   READLN(Filename);
   CURSOR_OFF;
   IF Filename <> '' THEN BEGIN
      ASSIGN(Files,Filename + '.CAT');
      {$I-}
      RESET(Files);
      {$I+}
      IF IOResult = 0 THEN BEGIN

         { Destroy old List }
         Set1Ptr:= RootPtr;
         WHILE Set1Ptr <> NIL DO BEGIN
            Set2Ptr:= Set1Ptr^.Next;
            DISPOSE(Set1Ptr);
            Set1Ptr:= Set2Ptr;
         END;

         NEW(Set1Ptr);
         READ(Files,Set1Ptr^.Data);
         Play:= Set1Ptr^.Data.Scene;    { Stuecknamen rausprokeln }
         DISPOSE(Set1Ptr);

         RootPtr:= NIL;                 { Und laden }
         Set2Ptr:= NIL;
         WHILE EOF(Files) = FALSE DO BEGIN
            NEW(Set1Ptr);
            IF RootPtr = NIL THEN
               RootPtr:= Set1Ptr;
            READ(Files,Set1Ptr^.Data);
            Set1Ptr^.Prev:= Set2Ptr;
            IF Set1Ptr^.Prev <> NIL THEN
               Set1Ptr^.Prev^.Next:= Set1Ptr;
            Set1Ptr^.Next:=NIL;
            Set2Ptr:= Set1Ptr;
         END;
         CLOSE(Files);
         DisplaySet:= RootPtr;
         NextSet   := RootPtr;
      END
      ELSE BEGIN                                { Fehler aufgetreten }
         GOTOXY(32,12);
         WRITE('   --- E R R O R ---      ');
         GOTOXY(32,14);
         WRITE('            Press ESC ...');
         REPEAT
            SHOW_TIME;
            IF KEYPRESSED THEN
               KeyIn:= READKEY
            ELSE
               KeyIn:= ' ';
         UNTIL KeyIn = CHR(27);
         WHILE KEYPRESSED DO
            KeyIn:= READKEY;                    { Buffer leer machen   }
      END;
   END;
   SHOW_MAINSCREEN;                             { Bild wieder aufbauen }
   EDIT_HELP;
   IF DisplaySet <> NIL THEN
      SHOW_SETTING(DisplaySet^.Data,Offset)
   ELSE
      SHOW_SETTING(EmtyPtr^.Data,Offset);
   IF NextSet <> NIL THEN
      SHOW_NEXT(NextSet^.Data.Number)
   ELSE
      SHOW_NEXT(EmtyPtr^.Data.Number);
   SHOW_ACTUAL(ActualSet^.Data.Number);
END;



PROCEDURE MAIN_LOOP;

VAR   Input     : CHAR;
      Cin       : BYTE;
      Cont      : BOOLEAN;

LABEL Next_Loop;

PROCEDURE EDIT_MENUE;
{ Erst mal die neuen HELP OPTIONS }
BEGIN
   EDIT_HELP;
   REPEAT                        { Auf Abbruch warten }
      REPEAT                     { Auf Taste warten }
         SHOW_TIME;              { Und Zeit zeigen  }
      UNTIL KEYPRESSED;
      Input:= READKEY;
      IF (Input = CHR(0)) AND KEYPRESSED THEN BEGIN  { Sonderzeichen !!! }
         Input:= READKEY;
         Cin:= ORD(Input);
         CASE Cin OF
           75 : BEGIN                   { Cursor links }
                  IF (DisplaySet^.Prev <> NIL) AND (DisplaySet <> NIL) THEN
                     DisplaySet:= DisplaySet^.Prev;
                  IF DisplaySet <> NIL THEN
                     SHOW_SETTING(DisplaySet^.Data,Offset)
                  ELSE
                     SHOW_SETTING(EmtyPtr^.Data,Offset);
                END;
           77 : BEGIN                   { Cursor rechts }
                  IF (DisplaySet^.Next <> NIL) AND (DisplaySet <> NIL) THEN
                     DisplaySet:= DisplaySet^.Next;
                  IF DisplaySet <> NIL THEN
                     SHOW_SETTING(DisplaySet^.Data,Offset)
                  ELSE
                     SHOW_SETTING(EmtyPtr^.Data,Offset);
                END;
           73 : BEGIN                   { PgUp, Offset wechseln }
                  IF Offset > 0 THEN
                     Offset:= Offset - 32;
                  IF DisplaySet <> NIL THEN
                     SHOW_CHANNELS(DisplaySet^.Data.Channel,Offset)
                  ELSE
                     SHOW_CHANNELS(EmtyPtr^.Data.Channel,Offset);
                END;
           81 : BEGIN                   { PgDwn, Offset wechseln }
                  IF Offset < 96 THEN
                     Offset:= Offset + 32;
                  IF DisplaySet <> NIL THEN
                     SHOW_CHANNELS(DisplaySet^.Data.Channel,Offset)
                  ELSE
                     SHOW_CHANNELS(EmtyPtr^.Data.Channel,Offset);
                END;

           68 : BEGIN                   { F10 }
                  IF DisplaySet <> NIL THEN
                     SHOW_DATA(ActualSet^.Data,DisplaySet^.Data)
                  ELSE
                     SHOW_DATA(ActualSet^.Data,EmtyPtr^.Data);
                  SHOW_ACTUAL(ActualSet^.Data.Number);
                END;
         END;
      END
      ELSE
         CASE Input OF
            'e','E' : BEGIN
                        IF DisplaySet <> NIL THEN BEGIN

                           GOTOXY(3,23);
                           TEXTBACKGROUND(0);
                           TEXTCOLOR(12);
                           WRITE('EDIT MODE');
                           EDIT(DisplaySet^.Data,ActualSet^.Data);
                           EDIT_HELP;

                           { Nun ausklinken, wie DEL_RECORD }
                           IF DisplaySet^.Prev <> NIL THEN  { N. das Erste }
                              DisplaySet^.Prev^.Next:= DisplaySet^.Next
                           ELSE
                              RootPtr:= DisplaySet^.Next;   { das Erste }
                           IF DisplaySet^.Next <> NIL THEN  { N. das Letzte }
                              DisplaySet^.Next^.Prev:= DisplaySet^.Prev;

                           SET_RECORD(DisplaySet);    { Einfuegen und zeigen }
                           SHOW_SETTING(DisplaySet^.Data,Offset);
                           IF NextSet <> NIL THEN
                              SHOW_NEXT(NextSet^.Data.Number)
                           ELSE
                              SHOW_NEXT(EmtyPtr^.Data.Number);
                        END;
                      END;
            's','S' : BEGIN
                         SAVE_DATA;
                         Input:= CHR(27);  { Zurueck zum HM }
                      END;
            'l','L' : BEGIN
                         LOAD_DATA;
                         Input:= CHR(27);
                      END;

            'n','N' : BEGIN
                         Set2Ptr:= NEW_RECORD;

                         GOTOXY(3,23);
                         TEXTBACKGROUND(0);
                         TEXTCOLOR(12);
                         WRITE('EDIT MODE');

                         EDIT(Set2Ptr^.Data,ActualSet^.Data);
                         EDIT_HELP;

                         SET_RECORD(Set2Ptr);
                         DisplaySet:= Set2Ptr; { Wird ja gerade gezeigt }
                         SHOW_SETTING(DisplaySet^.Data,Offset);
                      END;
            'd','D' : IF DisplaySet <> NIL THEN BEGIN
                         IF DEL_BUTTON(DisplaySet) = TRUE THEN BEGIN

                            IF DisplaySet^.Next <> NIL THEN
                               Set2Ptr:= DisplaySet^.Next
                            ELSE
                               IF DisplaySet^.Prev <> NIL THEN
                                  Set2Ptr:= DisplaySet^.Prev
                               ELSE
                                  Set2Ptr:= NIL;
                            IF NextSet = DisplaySet THEN
                               NextSet:= Set2Ptr;

                            DEL_RECORD(DisplaySet);
                            DisplaySet:= Set2Ptr;

                            IF DisplaySet <> NIL THEN
                               SHOW_SETTING(DisplaySet^.Data,Offset)
                            ELSE
                               SHOW_SETTING(EmtyPtr^.Data,Offset);
                            IF NextSet <> NIL THEN
                               SHOW_NEXT(NextSet^.Data.Number)
                            ELSE
                               SHOW_NEXT(EmtyPtr^.Data.Number);
                         END;
                      END;
            'c','C' : IF DisplaySet <> NIL THEN BEGIN   { COPY FUNCTION }
                         Set2Ptr:= NEW_RECORD;
                         Set2Ptr^.Data.Channel:= DisplaySet^.Data.Channel;

                         GOTOXY(3,23);
                         TEXTBACKGROUND(0);
                         TEXTCOLOR(12);
                         WRITE('EDIT MODE');

                         EDIT(Set2Ptr^.Data,ActualSet^.Data);
                         EDIT_HELP;

                         SET_RECORD(Set2Ptr);
                         DisplaySet:= Set2Ptr; { Wird ja gerade gezeigt }
                         SHOW_SETTING(DisplaySet^.Data,Offset);
                      END;
         END;
   UNTIL Input = CHR(27);  { Esc gedrueckt }
   Input:= ' ';
   MAIN_HELP;              { wieder die Haupt Hilfe zeigen };
END;


{ Das ist das Haupt-Menue }
BEGIN
  REPEAT
     REPEAT                            { Auf Taste warten }
        SHOW_TIME;                     { Und Zeit zeigen  }
     UNTIL KEYPRESSED;
     Input:= READKEY;

     IF (Input = CHR(0)) AND KEYPRESSED THEN BEGIN { Sonderzeichen gedrueckt }
        Input:= READKEY;
        Cin:= ORD(Input);
        CASE Cin OF
           75 : BEGIN                   { Cursor links }
                  IF (DisplaySet^.Prev <> NIL) AND (DisplaySet <> NIL) THEN
                     DisplaySet:= DisplaySet^.Prev;
                  IF DisplaySet <> NIL THEN
                     SHOW_SETTING(DisplaySet^.Data,Offset)
                  ELSE
                     SHOW_SETTING(EmtyPtr^.Data,Offset);
                END;
           77 : BEGIN                   { Cursor rechts }
                  IF (DisplaySet^.Next <> NIL) AND (DisplaySet <> NIL) THEN
                     DisplaySet:= DisplaySet^.Next;
                  IF DisplaySet <> NIL THEN
                     SHOW_SETTING(DisplaySet^.Data,Offset)
                  ELSE
                     SHOW_SETTING(EmtyPtr^.Data,Offset);
                END;
           59 : BEGIN                   { F1 }
                  IF NextSet <> NIL THEN BEGIN
                     IF NextSet^.Prev <> NIL THEN    { Ptr auf vorherige }
                        NextSet:= NextSet^.Prev;     { Stimmung setzen   }
                  END
                  ELSE
                     NextSet:= RootPtr;
                  DisplaySet:= NextSet;
                  IF DisplaySet <> NIL THEN
                     SHOW_SETTING(DisplaySet^.Data,Offset)
                  ELSE
                     SHOW_SETTING(EmtyPtr^.Data,Offset);
                  IF NextSet <> NIL THEN
                     SHOW_NEXT(NextSet^.Data.Number)
                  ELSE
                     SHOW_NEXT(EmtyPtr^.Data.Number);
                END;
           60 : BEGIN                   { F2 }
                  IF NextSet <> NIL THEN BEGIN
                     IF NextSet^.Next <> NIL THEN    { Ptr auf naechste }
                        NextSet:= NextSet^.Next;     { Stimmung setzen  }
                  END
                  ELSE
                     NextSet:= RootPtr;
                  DisplaySet:= NextSet;
                  IF DisplaySet <> NIL THEN
                     SHOW_SETTING(DisplaySet^.Data,Offset)
                  ELSE
                     SHOW_SETTING(EmtyPtr^.Data,Offset);
                  IF NextSet <> NIL THEN
                     SHOW_NEXT(NextSet^.Data.Number)
                  ELSE
                     SHOW_NEXT(EmtyPtr^.Data.Number);
                END;
           63 : BEGIN                   { F5 }
                  BOARD(ActualSet^.Data);            { Control Board }
                  SHOW_MAINSCREEN;
                  MAIN_HELP;
                  IF DisplaySet <> NIL THEN
                     SHOW_SETTING(DisplaySet^.Data,Offset)
                  ELSE
                     SHOW_SETTING(EmtyPtr^.Data,Offset);
                  IF NextSet <> NIL THEN
                     SHOW_NEXT(NextSet^.Data.Number)
                  ELSE
                     SHOW_NEXT(EmtyPtr^.Data.Number);
                  SHOW_ACTUAL(ActualSet^.Data.Number);
                END;
           73 : BEGIN                   { PgUp, Offset wechseln }
                  IF Offset > 0 THEN
                     Offset:= Offset - 32;
                  IF DisplaySet <> NIL THEN
                     SHOW_CHANNELS(DisplaySet^.Data.Channel,Offset)
                  ELSE
                     SHOW_CHANNELS(EmtyPtr^.Data.Channel,Offset);
                  END;
           81 : BEGIN                   { PgDwn, Offset wechseln }
                  IF Offset < 96 THEN
                     Offset:= Offset + 32;
                  IF DisplaySet <> NIL THEN
                     SHOW_CHANNELS(DisplaySet^.Data.Channel,Offset)
                  ELSE
                     SHOW_CHANNELS(EmtyPtr^.Data.Channel,Offset);
                END;
        END;
     END
     ELSE BEGIN                        { Normale Taste gedrueckt }
        CASE Input OF
           'e','E' : BEGIN                  { Editor aufrufen }
                        EDIT_MENUE;
                     END;
           'a','A' : BEGIN                  { Actual zeigen }
                        SHOW_SETTING(ActualSet^.Data,Offset);
                        REPEAT
                        UNTIL KEYPRESSED;
                        KeyIn:= READKEY;
                        IF DisplaySet <> NIL THEN
                           SHOW_SETTING(DisplaySet^.Data,Offset)
                        ELSE
                           SHOW_SETTING(EmtyPtr^.Data,Offset);
                        END;
               ' ' : BEGIN                  { Show Next }
                        DisplaySet:= NextSet;
                        IF DisplaySet <> NIL THEN
                           SHOW_SETTING(DisplaySet^.Data,Offset)
                        ELSE
                           SHOW_SETTING(EmtyPtr^.Data,Offset);
                     END;
           'n','N' : BEGIN                  { NEXT OUT }
                        Next_Loop:

                        IF NextSet <> NIL THEN
                           Set1Ptr:= NextSet
                        ELSE
                           Set1Ptr:= EmtyPtr;
                        SHOW_SETTING(Set1Ptr^.Data,Offset);

                        FADE(ActualSet^.Data,Set1Ptr^.Data,Cin);

                        IF Cin = 0 THEN BEGIN      { FADING complete }
                           Cont:= FALSE;
                           IF (NextSet <> NIL) AND (NextSet^.Next <> NIL) THEN BEGIN
                              NextSet:= NextSet^.Next;
                              DisplaySet:= NextSet;
                              FOR N:= 1 TO LENGTH(NextSet^.Data.Time) DO
                              IF (COPY(NextSet^.Data.Time,N,1) = 'c') OR
                                 (COPY(NextSet^.Data.Time,N,1) = 'C') THEN
                                 Cont:= TRUE
                           END
                           ELSE
                              DisplaySet:= NextSet;

                           IF DisplaySet <> NIL THEN
                              SHOW_SETTING(DisplaySet^.Data,Offset)
                           ELSE
                              SHOW_SETTING(EmtyPtr^.Data,Offset);
                           IF NextSet <> NIL THEN
                              SHOW_NEXT(NextSet^.Data.Number)
                           ELSE
                              SHOW_NEXT(EmtyPtr^.Data.Number);
                           SHOW_ACTUAL(ActualSet^.Data.Number);
                           IF Cont = TRUE THEN
                              GOTO Next_Loop;
                        END;
                        IF Cin = 2 THEN BEGIN     { Fading abgebrochen }
                           SHOW_SETTING(ActualSet^.Data,Offset);
                           SHOW_ACTUAL(ActualSet^.Data.Number);
                        END;
                     END;

           'q','Q' : BEGIN                  { Program verlassen }
                        GOTOXY(40,21);
                        TEXTBACKGROUND(Red);
                        WRITE('ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ');
                        GOTOXY(40,22);
                        WRITE('ณ  *** QUIT ***   Exit to DOS ?  (Y/N)  ณ');
                        GOTOXY(40,23);
                        WRITE('ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู');
                        REPEAT
                          IF KeyPressed THEN
                             KeyIn:= READKEY
                          ELSE
                             KeyIn:=#32;
                        UNTIL ((UPCASE(KeyIn)='Y') OR (UPCASE(KeyIn)='N') OR (KeyIn=#27));
                        TEXTBACKGROUND(Black);
                        GOTOXY(40,21);
                        WRITE('ฤฤฤฤฤฤฤฟ                                 ');
                        GOTOXY(40,22);
                        WRITE('     % ณ                                 ');
                        GOTOXY(40,23);
                        WRITE('ฤฤฤฤฤฤฤู                                 ');
                        IF UPCASE(KeyIn)='Y' THEN BEGIN
                           CLRSCR;
                           LOWVIDEO;
                           WRITELN('Exiting CATLIS...');
                           WRITELN('Have a nice DOS!');
                           CURSOR_ON;
                           HALT;
                        END;
                     END;
        END;
     END;
  UNTIL FALSE;
END;



BEGIN
  INIT_VARS;
  IF PARAMCOUNT > 0 THEN Parse_CMDLine;      {Commandline auseinanderprokeln}
  TEXTMODE(3);                               { CGA 80 * 25 }
  SHOW_MAINSCREEN;                           { Bild wieder aufbauen }
  MAIN_HELP;
  IF DisplaySet <> NIL THEN
     SHOW_SETTING(DisplaySet^.Data,Offset)
  ELSE
     SHOW_SETTING(EmtyPtr^.Data,Offset);
  IF NextSet <> NIL THEN
     SHOW_NEXT(NextSet^.Data.Number)
  ELSE
     SHOW_NEXT(EmtyPtr^.Data.Number);
  SHOW_ACTUAL(ActualSet^.Data.Number);
  CURSOR_OFF;
  REPEAT
     MAIN_LOOP;                         { Haupt Schleife aufrufen }
  UNTIL FALSE;

END.