UNIT CatlisFD;

{ Die Fader Unit }

INTERFACE


USES Crt, Dos, CatlisUI;


PROCEDURE FADE(VAR Set1       : Setting;
                   Set2       : Setting;
               VAR Error      : BYTE    );  { Die Ueberblendroutine    }
                                            { Error : 0 -> Kein Fehler }
                                            { Error : 2 -> Fading vor- }
                                            { zeitig abgebrochen       }

PROCEDURE SHOW_DATA(VAR Set1  : Setting;
                        Set2  : Setting );

{ Diese Routine fadet Daten innerhalb 1 Sec von Set1 auf Set2 }



PROCEDURE DATA_OUT(DOut : Channeltype);     { Gibt die Channels aus }


IMPLEMENTATION


VAR     MTime    : INTEGER;        { Gesamte Zeit (aus Stimmung) }
        GStps    : INTEGER;        { Gesamte Schritte            }
        Stps     : INTEGER;        { Gemachte Schritte           }
        NormTime : INTEGER;
        CompTime : INTEGER;
        Check    : INTEGER;
        Data     : Channeltype;    { Kanalwerte }
        Delta    : REAL;
        Index    : REAL;
        N,M, TC  : BYTE;
        FMode    : char;
        Hand     : BOOLEAN;        { HAND FADING }
        FTerm    : BYTE;           { AF Abbruch  Code }
        Hour, Minute,
        Second, Sec100 : WORD;
        Input    : CHAR;



PROCEDURE DATA_OUT;
{ Diese Procedure gibt die Daten aus }

VAR   STATUS  : BYTE;

BEGIN
  M:= 0;
  PORT[$37A]:= 14;                        { STROBE reset  }


  IF Output = TRUE THEN
     FOR N:= 1 TO 16 DO BEGIN

     REPEAT
     UNTIL (PORT[$379] AND 128 = 128);    { BUSY inactive }
     PORT[$378]:= 170;                    { ADR code      }
     PORT[$37A]:= 15;                     { STROBE set    }
     M:= M AND M;                         { Delay         }
     PORT[$37A]:= 14;                     { STROBE reset  }

     M:= M AND M;                         { Delay         }

     REPEAT
     UNTIL (PORT[$379] AND 128 = 128);    { BUSY inactive }
     PORT[$378]:= N - 1;                  { Kanal waehlen }
     PORT[$37A]:= 15;                     { STROBE set    }
     M:= M AND M;
     PORT[$37A]:= 14;                     { STROBE reset  }

     M:= M AND M;

     REPEAT
     UNTIL (PORT[$379] AND 128 = 128);    { BUSY inactive }
     PORT[$378]:= 213;                    { DATA code     }
     PORT[$37A]:= 15;                     { STROBE set    }
     M:= M AND M;
     PORT[$37A]:= 14;                     { STROBE reset  }

     M:= M AND M;

     REPEAT
     UNTIL (PORT[$379] AND 128 = 128);    { BUSY inactive }
     PORT[$378]:= DOut[N];                { Daten raus    }
     PORT[$37A]:= 15;                     { STROBE set    }
     M:= M AND M;
     PORT[$37A]:= 14;                     { STROBE reset  }

  END;
END;


PROCEDURE SHOW_DATA;

VAR  Stps : INTEGER;
    GStps : INTEGER;

BEGIN
  Stps:= 0;

  GETTIME(Hour,Minute,Second,Sec100);       { Zeitnormal bilden }
  NormTime:= Sec100;

   REPEAT                                    { Haupt - Schleife }
      TC    := Stps MOD 5;
      Index := (Stps / 5);

      FOR N:= 1 TO 32 DO BEGIN
         Delta:= (Set2.Channel[N] - Set1.Channel[N]);
         Data[N]:= Set1.Channel[N] + ROUND(Delta * Index);
      END;

      { TimeNormal Check }

      GETTIME(Hour,Minute,Second,Sec100);
      CompTime:= Sec100;
      Check:= CompTime - NormTime;
      IF Check < 0 THEN
         Check:= (Check + 100);
      Check:= Check DIV 20;             { Normierter Zeitvergleich }

      IF Check <> TC THEN
         IF Check > TC THEN
            Stps:= Stps + (Check - TC)     { Daten der Zeit anpassen  }
         ELSE
            Stps:= Stps + (Check - TC) + 5
      ELSE                                 { Warten                   }
         REPEAT
            GETTIME(Hour,Minute,Second,Sec100);
            CompTime:= Sec100;
            Check:= CompTime - NormTime;
            IF Check < 0 THEN
               Check:= (Check + 100);
            Check:= Check DIV 20;       { Normierter Zeitvergleich }
         UNTIL (Check=TC+1) OR (Check=0) AND (TC=4);

      INC(Stps);
      DATA_OUT(Data);

   UNTIL Stps >= 6;

   { Actual updaten }
   Set1.Channel := Set2.Channel;
   Set1.Scene   := Set2.Scene;
   Set1.Number  := Set2.Number;
END;



PROCEDURE FADE;            { Hier beginnt die Hauptroutine }


PROCEDURE COMPUTE_DATA;      { Daten berechnen und ausgeben }
BEGIN

   Index:= (Stps / GStps);

   SHOW_FADER(ROUND(Index * 100));
   SHOW_TIME;

   CASE FMode OF
      'L' : FOR N:= 1 TO 32 DO BEGIN
               Delta:= (Set2.Channel[N] - Set1.Channel[N]);
               Data[N]:= Set1.Channel[N] + ROUND(Delta * Index);
            END;
      'P' : FOR N:= 1 TO 32 DO BEGIN
               Delta:= (Set2.Channel[N] - Set1.Channel[N]);
               Data[N]:= Set1.Channel[N] + ROUND(Delta * SQRT(Index));
            END;
      'B' : FOR N:= 1 TO 32 DO BEGIN
               Delta:= (Set2.Channel[N] - Set1.Channel[N]);
               IF Delta >= 0 THEN
                  Data[N]:= Set1.Channel[N] + ROUND(Delta * SQRT(Index))
               ELSE
                  Data[N]:= Set1.Channel[N] + ROUND(Delta * SQR(Index));
            END;
   END;
   DATA_OUT(Data);

   { Und Channels zeigen }
   TEXTBACKGROUND(0);
   TEXTCOLOR(14);
   HIGHVIDEO;
   FOR N:= (1+Offset) TO (16+Offset) DO BEGIN
      GOTOXY((N-Offset)*4+13,4);
      WRITE(Data[N]:3);
      GOTOXY((N-Offset)*4+13,7);
      WRITE(Data[N+16]:3);
   END;
END;


PROCEDURE FADE1_HELP;
BEGIN
  GOTOXY(1,24);
  TEXTBACKGROUND(3);
  TEXTCOLOR(15);
  WRITELN('                                                                               ');
  WRITE  ('                                                                               ');
  GOTOXY(2,24);
  TEXTCOLOR(0);
  WRITE('   Esc Interrupt     Faster     Hand FADING ');
  GOTOXY(2,25);
  WRITE('       Terminate     Slower                 ');
  TEXTCOLOR(4);
  IF DisplayDRV = 'MONO' THEN
     HIGHVIDEO
  ELSE
     LOWVIDEO;
  GOTOXY(5,24);
  WRITE('Esc');
  GOTOXY(9,25);
  WRITE('T');
  GOTOXY(23,24);
  WRITE('F');
  GOTOXY(23,25);
  WRITE('S');
  GOTOXY(34,24);
  WRITE('H');
END;


PROCEDURE FADE2_HELP;
BEGIN
  GOTOXY(1,24);
  TEXTBACKGROUND(3);
  TEXTCOLOR(15);
  WRITELN('                                                                               ');
  WRITE  ('                                                                               ');
  GOTOXY(2,24);
  TEXTCOLOR(0);
  WRITE('       Continue      eXit       Hand FADING ');
  GOTOXY(2,25);
  WRITE('       Terminate ');
  TEXTCOLOR(4);
  IF DisplayDRV = 'MONO' THEN
     HIGHVIDEO
  ELSE
     LOWVIDEO;
  GOTOXY(9,24);
  WRITE('C');
  GOTOXY(9,25);
  WRITE('T');
  GOTOXY(24,24);
  WRITE('X');
  GOTOXY(34,24);
  WRITE('H');
END;


PROCEDURE FADE3_HELP;
BEGIN
  GOTOXY(1,24);
  TEXTBACKGROUND(3);
  TEXTCOLOR(15);
  WRITELN('                                                                               ');
  WRITE  ('                                                                               ');
  GOTOXY(2,24);
  TEXTCOLOR(0);
  WRITE('        CONTROL      eXit      (Auto FADING) ');
  GOTOXY(2,25);
  WRITE('       Terminate ');
  TEXTCOLOR(4);
  IF DisplayDRV = 'MONO' THEN
     HIGHVIDEO
  ELSE
     LOWVIDEO;
  GOTOXY(9,25);
  WRITE('T');
  GOTOXY(24,24);
  WRITE('X');
  GOTOXY(34,24);
  WRITE('A');
  GOTOXY(8,24);
  WRITE(CHR(31));
  GOTOXY(18,24);
  WRITE(CHR(30));
END;



PROCEDURE AUTO_FADE;   { Die Autoblendroutine }
BEGIN

   FTerm:= 0;                                { AutoFade Abbruch }
   FADE1_HELP;

   GETTIME(Hour,Minute,Second,Sec100);       { Zeitnormal bilden }
   NormTime:= Sec100;

   REPEAT                                    { Haupt - Schleife }
      TC := Stps MOD 5;

      COMPUTE_DATA;

      { TimeNormal Check }

      GETTIME(Hour,Minute,Second,Sec100);
      CompTime:= Sec100;
      Check:= CompTime - NormTime;
      IF Check < 0 THEN
         Check:= (Check + 100);
      Check:= Check DIV 20;             { Normierter Zeitvergleich }

      IF Check <> TC THEN
         IF Check > TC THEN
            Stps:= Stps + (Check - TC)     { Daten der Zeit anpassen  }
         ELSE
            Stps:= Stps + (Check - TC) + 5
      ELSE                                 { Warten                   }
         REPEAT
            GETTIME(Hour,Minute,Second,Sec100);
            CompTime:= Sec100;
            Check:= CompTime - NormTime;
            IF Check < 0 THEN
               Check:= (Check + 100);
            Check:= Check DIV 20;       { Normierter Zeitvergleich }
         UNTIL (Check=TC+1) OR (Check=0) AND (TC=4);

      INC(Stps);

      IF KEYPRESSED THEN BEGIN
         Input:= READKEY;
         CASE Input OF
            CHR(27): BEGIN                     { Anhalten }
                        FADE2_HELP;
                        WHILE KEYPRESSED DO    { Buffer leermachen }
                           Input:= READKEY;
                        REPEAT
                           IF KEYPRESSED THEN
                              Input:= READKEY
                           ELSE
                              Input:= ' ';
                        UNTIL (Input = 'c') OR (Input = 'C') OR
                              (Input = 'x') OR (Input = 'X') OR
                              (Input = 't') OR (Input = 'T') OR
                              (Input = 'h') OR (Input = 'H');
                        CASE UPCASE(Input) OF
                           'X' : FTerm:= 2;             { EXIT Code   }
                           'T' : BEGIN
                                   Stps:= GStps;        { End Wert }
                                   Set1.Channel:= Data;
                                   SHOW_FADER(100);
                                   SHOW_DATA(Set1,Set2);
                                   INC(Stps);           { fuer ABBRUCH }
                                 END;
                           'H' : FTerm:= 1;             { HAND FADIND }
                        END;
                        FADE1_HELP;               { Alte Hilfe zeigen }

                        REPEAT         { Zeit wieder angleichen }
                           GETTIME(Hour,Minute,Second,Sec100);
                           CompTime:= Sec100;
                           Check:= CompTime - NormTime;
                           IF Check < 0 THEN
                              Check:= (Check + 100);
                           Check:= Check DIV 20;
                        UNTIL (Check=TC+1) OR (Check=0) AND (TC=4);

                     END;
           'h','H' : BEGIN
                       FTerm:= 1;               { HAND STEUERUNG }
                     END;
           't','T' : BEGIN
                       Stps:= GStps;
                       Set1.Channel:= Data;
                       SHOW_FADER(100);
                       SHOW_DATA(Set1,Set2);
                       INC(Stps);               { fuer ABBRUCH }
                     END;
           'f','F' : BEGIN                      { OK, schneller }
                        Stps:= Stps + 5;        { 1 Sec springen }
                        WHILE KEYPRESSED DO     { Buffer leermachen }
                           Input:= READKEY;
                     END;
           's','S' : BEGIN
                        DELAY(1000);            { 1 Sec verzoegern  }
                        WHILE KEYPRESSED DO     { Buffer leermachen }
                           Input:= READKEY;
                     END;
         END;
      END;

   UNTIL ((Stps-1) >= GStps) OR (FTerm <> 0);

   IF Stps-1 >= GStps THEN BEGIN
      Stps:= GStps;
      COMPUTE_DATA;                { Letzten Wert ausgeben }
   END
   ELSE
      DEC(Stps);                   { Hand Steuerung oder EXIT }

END;


PROCEDURE HAND_FADE;
BEGIN
  FTerm:= 0;
  FADE3_HELP;

  REPEAT

    SHOW_TIME;

    IF KEYPRESSED THEN BEGIN
      Input:= READKEY;
      IF (Input = CHR(0)) AND KEYPRESSED THEN BEGIN
        Input:= READKEY;
        CASE Input OF
          CHR(72) : BEGIN         { Cursor rauf }
                       Check:= Stps;
                       Stps:= Stps + (GStps * 5) DIV 200;  { 2.5% mehr }
                       IF Stps > GStps THEN
                          Stps:= GStps;
                       COMPUTE_DATA;
                       Stps:= Check;
                       Stps:= Stps + (GStps * 5) DIV 100;  { 5% mehr }
                       IF Stps = Check THEN
                          INC(Stps);          { Procente zu klein }
                       IF Stps > GStps THEN
                          Stps:= GStps;
                       COMPUTE_DATA;
                       IF KEYPRESSED THEN
                          Input:= READKEY;
                    END;
          CHR(80) : BEGIN         { Cursor runter }
                       Check:= Stps;
                       Stps:= Stps - (GStps * 5) DIV 200;
                       IF Stps < 0 THEN
                          Stps:= 0;
                       COMPUTE_DATA;
                       Stps:= Check;
                       Stps:= Stps - (GStps * 5) DIV 100;
                       IF Stps = Check THEN
                          DEC(Stps);          { Procente zu klein }
                       IF Stps < 0 THEN
                          Stps:= 0;
                       COMPUTE_DATA;
                       IF KEYPRESSED THEN
                          Input:= READKEY;
                    END;
        END;
      END
      ELSE
        CASE Input OF
          't','T' : BEGIN
                       Stps:= GStps;
                       Set1.Channel:= Data;
                       SHOW_FADER(100);
                       SHOW_DATA(Set1,Set2);
                    END;
          'a','A' : BEGIN
                       FTerm:= 1;            { Automatic einschalten }
                       Stps:= (Stps DIV 5) * 5 + 5;
                    END;
          'x','X' : BEGIN
                       FTerm:= 2;            { EXIT }
                    END;
        END;
    END;
  UNTIL (Stps = GStps) OR (Fterm <> 0);
END;



BEGIN       { PROCEDURE FADE }

   VAL(Set2.Time,MTime,Stps);   { Zeit in der die neue Stimmung kommt }
   VAL(COPY(Set2.Time,1,Stps-1),MTime,Stps);

   GStps:= MTime * 5;           { Gesamte Schritte  }
   Stps := 0;                   { Gemachte Schritte }

   IF GStps = 0 THEN            { Time = 0 oder HAND }
      INC(GStps);

   FMode:= 'L';                        { Modus bestimmen }
   FOR N:= 1 TO LENGTH(Set2.Time) DO BEGIN
      IF (COPY(Set2.Time,N,1) = 'l') OR (COPY(Set2.Time,N,1) = 'L') THEN
         FMode:= 'L';
      IF (COPY(Set2.Time,N,1) = 'p') OR (COPY(Set2.Time,N,1) = 'P') THEN
         FMode:= 'P';
      IF (COPY(Set2.Time,N,1) = 'b') OR (COPY(Set2.Time,N,1) = 'B') THEN
         FMode:= 'B';
   END;

   IF (COPY(Set2.Time,1,4) = 'hand') OR (COPY(Set2.Time,1,4) = 'Hand') OR
      (COPY(Set2.Time,1,4) = 'HAND') THEN BEGIN
      Hand:= TRUE;
      GStps:= 100;        { 100 Schritte }
   END
   ELSE
      Hand:= FALSE;

   TEXTBACKGROUND(0);
   TEXTCOLOR(13);
   GOTOXY(52,22);
   CASE FMode OF
      'L'  : WRITE('LINEAR Mode    ');
      'P'  : WRITE('PARABOLIC Mode ');
      'B'  : WRITE('BRIGHT Mode    ');
   END;

   REPEAT

   IF Hand = FALSE THEN BEGIN

      GOTOXY(3,23);
      TEXTBACKGROUND(0);
      TEXTCOLOR(12);
      WRITE('AUTO FADING');
      AUTO_FADE;

      IF FTerm = 1 THEN BEGIN
         GOTOXY(3,23);
         TEXTBACKGROUND(0);
         TEXTCOLOR(12);
         WRITE('HAND FADING');
         HAND_FADE;
      END;
   END
   ELSE BEGIN
      GOTOXY(3,23);
      TEXTBACKGROUND(0);
      TEXTCOLOR(12);
      WRITE('HAND FADING');                        { Per Hand faden }
      HAND_FADE;
   END;

   UNTIL (Stps >= GStps) OR (FTerm = 2);      { FTerm = 2 --> EXIT Code }

   { FADING ABGESCHLOSSEN }

   IF Stps >= GStps THEN BEGIN           { Actual Data uebergeben }
      Set1.Channel := Set2.Channel;
      Set1.Scene   := Set2.Scene;
      Set1.Number  := Set2.Number;
      Error:= 0
   END
   ELSE BEGIN
      Set1.Channel := Data;
      Set1.Scene   := Set2.Scene;
      Error:= 2;
      IF Stps <> 0 THEN
         Set1.Number  := '* * *';
   END;

   SHOW_FADER(0);                     { Fader wieder loeschen }
   GOTOXY(52,22);
   WRITE('               ');

   MAIN_HELP;                         { Haupt Hilfe zeigen }


END;



END.     { Hier endet die IMPLEMENTATION }