program ocrimage;
(*
    1.  Setzen der Startwerte und Einlesen der Parameter, Öffnen der Log-Datei
    2.  Erstellen der Liste mit den zu überprüfenden und anzpassenden
        Image-Dateien.
    3.
    4.
*)

{$mode OBJFPC}

uses
    //crt, classes, strings, SysUtils, objects;
    classes, SysUtils, strutils;

(* Deklaration der Konstanten, Typen und Variablen *)
const
    knlogfile           = 'ocrimage.log';
    knfilelist          = 'ocrimage.lst';
    (* Aufruf von tesseract
       tesseract -l deu EINGABEBILD AUSGABENAME pdf *)
    ktess               = '/usr/bin/tesseract';
    (* Aufruf von empty-page
       empty-page -i EINGABEBILD -p 10%
       Rückgabewert bei überweigend weiss ist 0, sonst 1 *)
    kempty              = '/usr/bin/empty-page';
    (* Aufruf von pdftk
       pdftk 1.pdf 2.pdf cat output 12.pdf *)
    kpdftk              = '/usr/bin/pdftk';

//type


var
    logfile             : text;
    filelist            : text;
    z                   : integer;
    inpfad, savepfad    : string;
    pfad                : string;
    //datei               : string;
    listname            : string;
    filename            : string;
    zeile               : string;
    //ok                  : boolean;
    strlist             : TStringList;
    duplex              : boolean;

(* Deklaration der Funktionen und Prozeduren *)

function datwr( var datei : text; zeile : string ) : boolean;
(*   Es wird eine Zeile in eine als Parameter uebergebene Datei geschrieben.
    Das IOResult der jeweils aufgerufenen Funktion wird ausgewertet. Ist der
    Schreibvorgang (und Oeffnen sowie Schliessen) erfolgreich, wird true
    zurueckgegeben, ansonsten false *)

var
    wresult  : word;

begin
    datwr := true;
    {$i-}
    append( datei );
    {$i+}
    wresult := ioresult;
    if wresult = 0 then
    begin
        {$i-}
        writeln( datei, zeile );
        {$i+}
        wresult := ioresult;
        if wresult <> 0 then
        begin
            writeln( 'Schreiben in Datei fehlgeschlagen - IOResult = ', wresult );
            datwr := false;
        end;
    end
    else
    begin
        writeln( 'Datei konnte nicht geöffnet werden - IOResult = ', wresult );
        datwr := false;
    end;
    {$i-}
    close( datei );
    {$i+}
    wresult := ioresult;
    if wresult <> 0 then
    begin
        writeln( 'Datei konnte nicht geschlossen werden - IOResult = ', wresult );
        datwr := false;
    end;
end;



function makedir( pfad : string ) : byte;
{   Erstellen eine Verzeichnisses mit Ueberpruefen vorher, ob das Verzeichnis
    schon existiert. Rueckgabewert ist:
    0 : Verzeichnis wurde neu angelegt
    1 : Verzeichnis existiert bereits
    2 : Verzeichnis existiert nicht und konnte nicht angelegt werden }

var
    makepfad        : string;

begin
    makepfad := expandfilename( pfad );
    if fileexists( makepfad ) then
    begin
        makedir := 1;
    end
    else
    begin
        if createdir( makepfad ) then
        begin
            makedir := 0;
        end
        else
        begin
            makedir := 2;
        end;
    end;
end;



procedure writelog( zeile : string; info : string; var dat : text );
{   Genau 1 Zeile wird in die angegebene Log-Datei geschrieben. Der mitgegebene
    Text (Var zeile) wird um einen Timestamp (Datum und Zeit) und einen Info-
    text (Var info) erweitert. }

var
    stamp       : ansistring;
    zeit        : ansistring;
    gesamt      : string;

begin
    DateTimetoString( stamp, 'yyyymmdd', date );
    DateTimetoString( zeit, 'hh:nn:ss', time );
    gesamt := stamp + '-' + zeit + ' - ' + info + ' - ' + zeile;
    //writeln( gesamt );
    if not datwr( dat, gesamt ) then
    begin
        writeln( 'Fehler beim Schreiben in Datei. Inhalt : ');
        writeln( gesamt );
    end;
end;


procedure dateisuchen( (*hpfad : UnicodeString;*) lstname : string; var liste : text );
{   Unterprogramm für Prozedur dateiliste() - Wird rukursiv aufgerufen
    Aufbau einer Liste mit gefundenen Dateinamen
}
var
    //i, y            : integer;
    info            : TSearchRec;
    suchpfad        : UnicodeString;
    dateiname       : UnicodeString;
    hilf	        : UnicodeString;
    //wechsel         : boolean;
    dat		    : text;

begin
    //writeln( 'Pfad dateisuchen : ', getcurrentdir( ) );
    suchpfad := '*';
    if FindFirst( suchpfad, faAnyFile and faDirectory, info ) = 0 then
    begin
        //writelog( 'DateiSuchen - Suchpfad : ' + lstname +
        //          ' akt. Pfad : ' + hpfad, 'INFO', logfile );
        repeat
            with info do
            begin
                if( name <> '.' ) and ( name <> '..' ) then
                begin
                    if( ( attr and faDirectory ) = faDirectory ) then
                    begin
                        if setcurrentdir( name ) then
                        begin
                            //writeln( 'Pfad2 -> ', getcurrentdir( ) );
			                hilf := lstname + '_' + name;
			                datwr( liste, hilf + '|' + pfad + hilf + '.lst' );
                            dateisuchen( hilf, liste );
                            setcurrentdir( '..' );
                        end
                        else
                        begin
                            writelog( 'Kann nicht in Verzeichnis ' + name +
                                'wechseln.', 'ERR', logfile );
                        end;
                    end
                    else
                    begin
						assign( dat, pfad + lstname + '.lst' );
                        //writelog( 'Pfad : ' + hpfad + ' Name : ' +
                        //          lstname, 'INFO', logfile );
						if( not fileexists( pfad + lstname + '.lst' ) ) then
						begin
							rewrite( dat );
							close( dat );
						end;
                        dateiname := expandfilename( name );
                        //writeln( 'Datei2 -> ', name );
                        if not datwr( dat, dateiname ) then
                        begin
                            writeln( 'Fehler beim Erstellen der Dateiliste.' +
                                     ' Inhalt : ' );
                            writeln( dateiname );
                        end;
                    end;
                end;
            end;
        until findnext( info ) <> 0;
    end;
    findclose( info );
end;


procedure dateiliste( hpfad : UnicodeString; var dat : text );

var
    //i, y            : integer;
    info            : TSearchRec;
    suchpfad        : UnicodeString;
    dateiname       : UnicodeString;
    //wechsel         : boolean;

begin
    rewrite( dat );
    close( dat );
    suchpfad := hpfad;
    //writelog( 'Eingang Dateiliste - Suchpfad : ' + suchpfad, 'INFO', logfile );
    //writeln( 'Suchpfad -> ', suchpfad );
    if setcurrentdir( suchpfad ) then
    begin
        suchpfad := suchpfad + '/*';
        //writeln( 'Pfad -> ', getcurrentdir( ) );
        //writeln( 'Suchpfad -> ' + suchpfad );
        if findfirst( suchpfad, faAnyFile and faDirectory, info ) = 0 then
        begin
            //writeln( 'Etwas gefunden... (dateiliste)' );
            repeat
                with info do
                begin
                    //writeln( 'Innen - Name -> ', name );
                    if( name <> '.' ) and ( name <> '..' ) then
                    begin
                        if( ( attr and faDirectory ) = faDirectory ) then
                        begin
                            if setcurrentdir( name ) then
                            begin
                                //writeln( 'Pfad1 -> ', getcurrentdir( ) );
                                dateisuchen( name, dat );
                                setcurrentdir( '..' );
                            end;
                        end
                        else
                        begin
                            dateiname := expandfilename( name );
                            //writeln( 'gef. Dateiname : ' + dateiname );
                            if not datwr( dat, dateiname ) then
                            begin
                                writeln( 'Fehler beim Schreiben in Dateiliste.' );
                                writeln( dateiname );
                            end;
                        end;
                    end;
                end;
            until findnext( info ) <> 0;
        end;
        findclose( info );
    end
    else
        writelog( 'In das Verzeichnis ' + suchpfad + ' konnte nicht ' +
                  'gewechselt werden.', 'ERR', logfile );
end;



function CreateList( dateiname, dateiliste : string ) : boolean;

var
   zeile, filen, hilf,
   zeileneu, bildnrn,
   bildnr, scannr               : string;
   zahl                         : integer;
   listfile                     : text;

begin
   CreateList := true;
   assign( listfile, dateiliste );
   reset( listfile );
   while not eof( listfile ) do
   begin
       readln( listfile, zeile );
       filen := ExtractFileName( zeile );
       zahl := pos( '_', filen );
       hilf := copy( filen, zahl + 1, length( filen ) - zahl - 4 );
       zahl := pos( '_', hilf );
       if zahl = 0 then
       begin
           bildnr := '1';
           scannr := hilf;
       end
       else
       begin
           bildnr := copy( hilf, zahl + 1, length( hilf ) - zahl );
           scannr := copy( hilf, 1, zahl - 1 );
       end;
       bildnrn := StringofChar( '0', 4 - length( bildnr ) ) + bildnr;
       // so, aufgetrennt ist der Dateiname, jetzt fehlt nur noch das
       // Zusammensetzen als String zum Sortieren in der TStringList
       zeileneu := ( scannr + bildnrn + '|' + zeile + '|' +  dateiname + '|' +
                scannr + '|' + bildnr );
       //writelog( 'Zeile neu -> ' + zeileneu, 'INFO', logfile );
       strlist.Add( zeileneu );
   end;
   // Liste sortieren, nachdem alle Files eingelesen sind
   strlist.Sort;
end;


function workonstrlist( dateiname : string ) : boolean;

var
   i, z            : integer;
   index, hstr,
   fullfile, path,
   newname, suffix,
   newpath,
   scannr, imagenr : string;
   hilf1, hilf2    : string;
   nummerneu, nnr  : integer;
   code            : word;
   backside        : boolean;

begin
   workonstrlist := true;
   hstr := '';
   path := extractfilepath( extractword( 2, strlist[ 0 ], ['|'] ) );
   newpath := ReplaceStr( path, inpfad, savepfad );
   (* Hier sollte der "neue" Pfad angelegt werden, damit später der
      Kopiervorgang reibungslos funktioniert! *)
   if not ForceDirectories( newpath ) then
   begin
      writelog( 'Fehler Verzeichnis erstellen ' + newpath, 'ERR', logfile );
      exit;
   end;
   i := 0;
   repeat
      backside := false;
      hilf1 := strlist[ i ];
      // Aufteilen des Strings
      index := extractword( 1, hilf1, ['|'] );
      fullfile := extractword( 2, hilf1, ['|'] );
      newname := extractword( 3, hilf1, ['|'] );
      scannr := extractword( 4, hilf1, ['|'] );
      imagenr := extractword( 5, hilf1, ['|'] );
      suffix := extractfileext( fullfile );
      path := extractfilepath( fullfile );
      str( i, hilf2 );
      // Festlegen des neuen Bildnamens (Rückseite z.B.)
      if duplex then // für später... (ohne Rückseite gescannt)
      begin
          //writelog( 'Work - nach IF - Zähler -> ' + hilf2, 'INFO', logfile );
          val( imagenr, nnr, code );
          if ( hstr = scannr ) or ( i = 0 ) then
          begin
             //writelog( 'Name ist gleich Vorgänger, oder i = 0', 'INFO', logfile );
             if ( nnr mod 2 = 0 ) then
             begin
                //writelog( 'G Bildnummer ' + index, 'INFO', logfile );
                nummerneu := nnr div 2;
                str( nummerneu, hilf1 );
                hilf1 := StringofChar( '0', 4 - length( hilf1 ) ) + hilf1;
                newname := newname + '_' + scannr + hilf1 + 'R';
                //newname := path + newname;
                backside := true;
                //writelog( 'Dateiname neu -> ' + newname, 'INFO', logfile );
             end
             else
             begin
                //writelog( 'U Bildnummer ' + index, 'INFO', logfile );
                nummerneu := ( nnr + 1 ) div 2;
                str( nummerneu, hilf1 );
                hilf1 := StringofChar( '0', 4 - length( hilf1 ) ) + hilf1;
                newname := newname + '_' + scannr + hilf1;
                //newname := path + newname;
                //writelog( 'Dateiname neu -> ' + newname, 'INFO', logfile );
             end;
          end
          else
          begin
             //writelog( 'Name ist ungleich Vorgänger', 'INFO', logfile );
             if ( nnr mod 2 = 0 ) then
             begin
                //writelog( 'G Bildnummer ' + index, 'INFO', logfile );
                nummerneu := nnr div 2;
                str( nummerneu, hilf1 );
                hilf1 := StringofChar( '0', 4 - length( hilf1 ) ) + hilf1;
                newname := newname + '_' + scannr + hilf1 + 'R';
                //newname := path + newname;
                backside := true;
                //writelog( 'Dateiname neu -> ' + newname, 'INFO', logfile );
             end
             else
             begin
                //writelog( 'U Bildnummer ' + index, 'INFO', logfile );
                nummerneu := ( nnr + 1 ) div 2;
                str( nummerneu, hilf1 );
                hilf1 := StringofChar( '0', 4 - length( hilf1 ) ) + hilf1;
                newname := newname + '_' + scannr + hilf1;
                //newname := path + newname;
                //writelog( 'Dateiname neu -> ' + newname, 'INFO', logfile );
             end;
          end;
          if backside then
          begin
             // Überprüfen auf leere Rückseiten
             if Sysutils.ExecuteProcess( kempty, '-i ' +
                fullfile + ' -p 5' ) = 0 then
             begin
                writelog( 'Leere Rückseite -> ' + fullfile, 'INFO', logfile );
                strlist.delete( i );
                //dec( i );
                continue;
             end
             else
             begin
                //writelog( 'Rückseite -> ' + zeile, 'INFO', logfile );
                (* Neue Zeile wird erstellt mit folgendem Inhalt:
                   Scannnummer, Bildnummer, Dateiname alt, Dateiname neu ohne
                   Suffix und Pfad, Pfad neu *)
                strlist[ i ] := scannr + copy( hilf1, 0, 4 ) + '|' + fullfile +
                         '|' + newname + '|' + newpath;
                //writelog( 'Neue Zeile -> ' + strlist[ i ], 'INFO', logfile );
             end;
          end    // Ende von backside...
          else
          begin
             //writelog( 'Vorderseite -> ' + zeile, 'INFO', logfile );
             (* Neue Zeile wird erstellt mit folgendem Inhalt:
                Scannnummer, Bildnummer, Dateiname alt, Dateiname neu ohne
                Suffix und Pfad, Pfad neu *)
             strlist[ i ] := scannr + copy( hilf1, 0, 4 ) + '|' + fullfile +
                      '|' + newname + '|' + newpath;
             //writelog( 'Neue Zeile -> ' + strlist[ i ], 'INFO', logfile );
          end;
      end
      else
      begin
        // hier käme dann der ELSE-Zweig für einseitige Scans...
        // duplex = false
      end;
      // OCR über die Images mit Einbettung von Text in PDFs
      // Vorder- und Rückseite zusammenfügen
      if Sysutils.ExecuteProcess( ktess, '-l deu -psm 1 ' + fullfile +
                  ' ' + newpath + newname + ' pdf' ) = 0 then
      begin
         //writelog( 'Bild ' + extractfilename( fullfile ) + ' fehlerfrei zu ' +
         //         newname + ' umgewandelt.', 'INFO', logfile );
      end
      else
      begin
         writelog( 'Bild ' + extractfilename( fullfile ) + ' nicht zu ' +
                  newname + ' umgewandelt.', 'ERR', logfile );
      end;
      // Zusammenfügen von Vorder- und Rückseite per pdftk
      if ( backside ) and ( i > 0 ) then
      begin
         //hilf1 := extractword( 4, strlist[ i - 1 ], ['|'] );
         hilf2 := extractword( 3, strlist[ i - 1 ], ['|'] );
         if Sysutils.ExecuteProcess( kpdftk, newpath + hilf2 + '.pdf ' + newpath +
               newname + '.pdf cat output ' + newpath + 'foo.pdf' ) = 0 then
         begin
            if DeleteFile( newpath + hilf2 + '.pdf' ) then
               if RenameFile( newpath + 'foo.pdf', newpath +
                              hilf2 + '.pdf' ) then
                  if DeleteFile( newpath + newname + '.pdf' ) then
                     writelog( 'Image ' + hilf2 + ' mit Vorder- und Rückseite ' +
                               'verbunden.', 'INFO', logfile )
                  else
                     writelog( 'Datei ' + newname + '.pdf konnte nicht ' +
                               'gelöscht werden.', 'ERR', logfile )
               else
                  writelog( 'Datei foo.pdf konnte nicht nach ' + hilf2 +
                            ' umbenannt werden', 'ERR', logfile )
            else
               writelog( 'Datei ' + hilf2 + '.pdf konnte nicht gelöscht ' +
                         'werden.', 'ERR', logfile );
         end
         else
         begin
            writelog( 'Image ' + hilf1 + ' konnte nicht mit Rückseite ' +
                      'verbunden werden.', 'ERR', logfile );
         end;
      end;
      hstr := scannr;
      inc( i );
   until i > strlist.count - 1;
   //strlist.SaveToFile( pfad + filename + '.txt' );
   // Ende von repeat until - alle Elemente der TStringList sind
   // komplett verarbeitet worden.
end;

(* das eigentliche Hauptprogramm *)

begin
    (*  ermitteln der zu verändernden Dateien und in Liste speichern
        jede Datei checken, ob ein Vorlaufbeleg vorkommt und an
        welcher Position. Ist die Position am Ende der Datei, ist die
        Datei entsprechend anzupassen und zu speichern *)
    // Parameter einlesen
    duplex := true;
    pfad := getcurrentdir( ) + '/work/';
	if makedir( pfad ) = 2 then
	begin
        writeln( 'Alles Mist - irgendwas ist kaputt... ' );
	end;
    assign( logfile, pfad + knlogfile );
    if( not fileexists( pfad + knlogfile ) ) then
        rewrite( logfile )
    else
        append( logfile );
    writelog( 'LogDatei korrekt geoeffnet', 'INFO', logfile );
    if( paramcount < 2 ) then
    begin
        writeln( 'Programm muss mit Parametern aufgerufen werden. ');
        writeln( '1. Par : Verzeichnis mit den Imagedateien ');
        writeln( '2. Par : Verzeichnis fuer die Sicherungskopien' );
        writelog( 'Falsche Parameter übergeben!', 'ERROR', logfile );
        exit;
    end;
    inpfad := paramstr( 1 );
    inpfad := expandfilename( inpfad );
    if not DirectoryExists( inpfad ) then
    begin
       writelog( 'Verzeichnis ' + inpfad + ' existiert nicht.', 'ERR',
                 logfile );
       writeln( 'Verzeichnis ' + inpfad + ' existiert nicht. Abbruch.' );
       exit;
    end;
    savepfad := paramstr( 2 );
    savepfad := expandfilename( savepfad );
    if not ForceDirectories( savepfad ) then
    begin
       writelog( 'Ausgabeverzeichnis ' + savepfad + ' konnte nicht angelegt' +
                 ' werden.', 'ERR', logfile );
       writeln( 'Ausgabeverzeichnis ' + savepfad + ' konnte nicht angelegt' +
                 ' werden. Abbruch.' );
       exit;
    end;
    writelog( 'Eingabeverzeichnis -> ' + inpfad, 'INFO', logfile );
    writelog( 'Ausgabeverzeichnis -> ' + savepfad, 'INFO', logfile );
    // Text-Dateien ermitteln
    assign( filelist, pfad + knfilelist );
    if( not fileexists( pfad + knfilelist ) ) then
    begin
        rewrite( filelist );
        close( filelist );
    end;
    dateiliste( inpfad, filelist );
    //writelog( 'Liste mit den Dateinamen aufgebaut.', 'INFO', logfile );
    // Liste mit den umzubenennenden Dateien ist jetzt erzeugt und muss
	// verarbeitet werden.
    assign( filelist, pfad + knfilelist );
    reset( filelist );
    strlist := TStringList.Create;
    try
        while not eof( filelist ) do
        begin
           // lesen einer Zeile mit Dateinamenspräfix und Name der Listendatei
           //writelog( '', '----', logfile );
           readln( filelist, zeile );
           z := pos( '|', zeile );
           filename := copy( zeile, 1, ( z - 1 ) );
           listname := copy( zeile, ( z + 1 ), length( zeile ) );
           //writelog( 'Datei -> ' + filename + ' Liste -> ' + listname,
           //       'INFO', logfile );
           // Füllen der TStringList
           if CreateList( filename, listname ) then
           begin
               strlist.SaveToFile( pfad + filename + '.txt' );
               // bearbeiten der Listen
               //writelog( 'StringListe soll bearbeitet werden.', 'INFO', logfile );
               if workonstrlist( filename ) then
               begin
                  strlist.SaveToFile( pfad + filename + '1.txt' );
               end;
               strlist.Clear;
           end
           else
               writeln( 'Fehler beim Füllen der TStringList!' );
        end;
    finally
       if Assigned(  strlist ) then
          FreeAndNil( strlist );
    end;
end.
