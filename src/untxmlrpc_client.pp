Unit untXMLRPC_Client;
{ The window that handles XMLRPC requests

  Copyright (C) 2010 LINESIP idok at@at linesip.com

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}


{$mode objfpc}{$H+}

Interface

Uses
Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
lNetComponents, StdCtrls, XMLCfg, ExtCtrls, SynEdit,
SynHighlighterXML, SynMemo, Menus, Buttons, lNet, lhttp;

Const
  Version = '0.2';

Type

  { TfrmXMLRPCForm }

  TfrmXMLRPCForm = Class( TForm )
    btnConnect           : TBitBtn;
    cmbxURI              : TComboBox;
    ImageList2           : TImageList;
    lblXMLToSend         : TLabel;
    Label2               : TLabel;
    lblURI               : TLabel;
    lblLog               : TLabel;
    LHTTPClient          : TLHTTPClientComponent;
    mnuRespondeClearAll  : TMenuItem;
    mnuXMLToSendClear    : TMenuItem;
    mnuRespondeSave      : TMenuItem;
    MenuItem2            : TMenuItem;
    mnuXMLToSendSave     : TMenuItem;
    mnuXMLToSendOpenFile : TMenuItem;
    mnuXMLToSendCut      : TMenuItem;
    mnuXMLToSendPaste    : TMenuItem;
    mnuXMLToSendCopy     : TMenuItem;
    mmoLog               : TMemo;
    OpenDialogXML        : TOpenDialog;
    mnuXMLToSend         : TPopupMenu;
    mnuResponde          : TPopupMenu;
    Responde             : TSynMemo;
    SaveXMLDialog        : TSaveDialog;
    XMLToSend            : TSynEdit;
    SynXMLSyn1           : TSynXMLSyn;
    XMLConfig            : TXMLConfig;
    Procedure FormClose( Sender : TObject; Var CloseAction : TCloseAction );
    Procedure FormCreate( Sender : TObject );
    Procedure LHTTPClientCanWrite( ASocket : TLHTTPClientSocket;
                                   Var OutputEof : TWriteBlockStatus );
    Procedure LHTTPClientDisconnect( aSocket : TLSocket );
    Procedure LHTTPClientError( Const msg : String; aSocket : TLSocket );
    Function LHTTPClientInput( ASocket : TLHTTPClientSocket;
                               ABuffer : PChar; ASize : integer ) : integer;
    Procedure btnConnectClick( Sender : TObject );
    Procedure mnuRespondeSaveClick( Sender : TObject );
    Procedure mnuXMLToSendCutClick( Sender : TObject );
    Private
    { private declarations }
    Procedure AddToLog( Const S : String );
    Procedure AppendLogFile;
    Procedure LoadURL;
    Procedure SaveURL;
    Public
    { public declarations }
    LogFileName : string;
    XMLFileName : string;
  End;

Var
  frmXMLRPCForm : TfrmXMLRPCForm;

Function AppConfigFile : string;

Implementation
Uses {lHTTPUtil,} FileUtil, URIParser;

Function AppConfigFile : string;
Begin
{$IFDEF UNIX}
  Result := GetEnvironmentVariable('HOME');
  Result := IncludeTrailingPathDelimiter(Result) + '.config' +
            DirectorySeparator + 'xmlrpc_client';
{$ELSE}
  {$IFDEF WINODWS}
  Result := GetEnvironmentVariable('USERPROFILE');
  Result := IncludeTrailingPathDelimiter(Result) + 'xmlrpc_client';
  {$ELSE}
    {$FATAL Unsupported OS}
  {$ENDIF}
{$ENDIF}
End;

{ TfrmXMLRPCForm }

Procedure TfrmXMLRPCForm.mnuXMLToSendCutClick(Sender : TObject);
Begin
  Case TMenuItem(Sender).Tag Of
    0 :
        Begin
          XMLToSend.Lines.BeginUpdate;
          XMLToSend.Lines.Clear;
          XMLToSend.Lines.EndUpdate;
        End;
    1 : XMLToSend.CutToClipboard;
    2 : XMLToSend.CopyToClipboard;
    3 : XMLToSend.PasteFromClipboard;
    4 :
        Begin
          If OpenDialogXML.Execute Then
            Begin
              If FileIsReadable(OpenDialogXML.FileName) Then
                Begin
                  XMLToSend.Lines.BeginUpdate;
                  XMLToSend.Lines.Clear;
                  XMLToSend.Lines.LoadFromFile(OpenDialogXML.FileName);
                  XMLToSend.Lines.EndUpdate;
                  XMLFileName := OpenDialogXML.FileName;
                End
              Else
                Begin
                  MessageDlg('No read permission to read the requested file.',
                             mtError, [mbOK], 0);
                End;
            End;
        End;

    5 :
        Begin
          If SaveXMLDialog.Execute Then
            Begin
              If DirectoryIsWritable(ExtractFilePath(SaveXMLDialog.FileName)) Then
                XMLToSend.Lines.SaveToFile(SaveXMLDialog.FileName)
              Else
                MessageDlg('No write permission to save the requested file.',
                           mtError, [mbOK], 0);
            End;
        End;
  End;
End;

Procedure TfrmXMLRPCForm.mnuRespondeSaveClick(Sender : TObject);
Begin
  Case TMenuItem(Sender).Tag Of
    1 :
        Begin
          If SaveXMLDialog.Execute Then
            Begin
              If DirectoryIsWritable(ExtractFilePath(SaveXMLDialog.FileName)) Then
                Responde.Lines.SaveToFile(SaveXMLDialog.FileName)
              Else
                MessageDlg('No write permission to save the requested file.',
                           mtError, [mbOK], 0);
            End;
        End;
    2 :
        Begin
          Responde.Lines.BeginUpdate;
          Responde.Lines.Clear;
          Responde.Lines.EndUpdate;
        End;
  End;
End;

Procedure TfrmXMLRPCForm.AddToLog(Const S : String);
Begin
  mmoLog.Lines.BeginUpdate;
  mmoLog.Lines.Add(FormatDateTime('[yyyy"/"mm"/"dd hh:nn:ss] ', Now) + S);
  mmoLog.Lines.EndUpdate;
End;

Procedure TfrmXMLRPCForm.AppendLogFile;
Var path : string;
Begin
  path := Self.LogFileName;
  If Not FileExistsUTF8(path) Then path := ExtractFilePath(Path);
  If Not FileIsWritable(path) Then
    Begin
      MessageDlg('No write permission to save the log file.', mtError, [mbOK], 0);
      Exit;
    End;

  If mmoLog.Lines.Count > 0 Then
    mmoLog.Lines.SaveToFile(Self.LogFileName);
End;

Procedure TfrmXMLRPCForm.btnConnectClick(Sender : TObject);
Var
  aHost, aURI  : string;
  aPort: word;
  XMLContent   : string;
  URL          : string;
  uri          : TURI;
Begin
  XMLContent := XMLToSend.Lines.Text;
  If Trim(XMLContent) = '' Then
    Begin
      MessageDlg('Nothing to send', mtError, [mbOK], 0);
      exit;
    End;

  //XMLToSend.Enabled := False;
  btnConnect.Enabled := False;
  URL := cmbxURI.Text;
  If cmbxURI.Items.IndexOf(URL) = -1 Then
    cmbxURI.Items.Add(URL);
  //DecomposeURL(URL, aHost, aURI, aPort);

  uri   := ParseURI(URL);
  aHost := uri.Host;
  aPort := uri.Port;
  aURI  := uri.Path;

  if Trim(aURI) = '' then aURI := '/';
  if aPort=0 then
    if UpperCase(uri.Protocol) = 'HTTP' then
      aPort :=  80
    else
      aPort := 443;

  LHTTPClient.URI  := aURI;
  LHTTPClient.Host := aHost;
  LHTTPClient.Port := aPort;
  LHTTPClient.ContentLength := Length(XMLContent);
  AddToLog('About to send a request to ' + aHost + ' Port ' +
           IntToStr(aPort) + ' with the URI of ' + aURI);
  LHTTPClient.SendRequest;
  AddToLog('Sent the request');
End;

Procedure TfrmXMLRPCForm.FormClose(Sender : TObject; Var CloseAction : TCloseAction);
Begin
  AppendLogFile;
  SaveURL;
  If trim(XMLFileName) <> '' Then
    Begin
      XMLConfig.SetValue('XMLLoad/Name', XMLFileName);
    End;
End;

Procedure TfrmXMLRPCForm.LHTTPClientDisconnect(aSocket : TLSocket);
Begin
  aSocket.Disconnect;
  XMLToSend.Enabled  := True;
  btnConnect.Enabled := True;
  AddToLog('Disconnected');
End;

Procedure TfrmXMLRPCForm.LHTTPClientError(Const msg : String; aSocket : TLSocket);
Begin
  MessageDlg(msg, mtError, [mbOK], 0);
  XMLToSend.Enabled  := True;
  btnConnect.Enabled := True;
  AddToLog('An error was found: ' + msg);
End;

Function TfrmXMLRPCForm.LHTTPClientInput(ASocket : TLHTTPClientSocket;
                                         ABuffer : PChar; ASize : integer) : integer;
Begin
  Responde.Lines.BeginUpdate;
  Responde.Lines.Append(StrPas(ABuffer));
  Responde.Lines.EndUpdate;
  AddToLog('An answer was returned from the server: ' + StrPas(ABuffer));
End;

Procedure TfrmXMLRPCForm.LoadURL;
Var
  MaxItems: integer;
  i: integer;
  S: string;
Begin
  MaxItems := XMLConfig.GetValue('URL/Count', 0);

  If MaxItems <= 0 Then
    exit;

  cmbxURI.Items.BeginUpdate;
  For i := 0 To MaxItems - 1 Do
    Begin
      S := XMLConfig.GetValue('URL/Items/Item_' + IntToStr(i) + '/url/address', '');
      If trim(S) <> '' Then
        cmbxURI.Items.Add(S);
    End;

  cmbxURI.Items.EndUpdate;
End;

Procedure TfrmXMLRPCForm.SaveURL;
Var
  i, MaxItems: integer;
  S: string;
Begin
  MaxItems := cmbxURI.Items.Count;
  XMLConfig.SetValue('URL/Count', MaxItems);
  If MaxItems > 0 Then
    Begin
      For i := 0 To MaxItems - 1 Do
        Begin
          S := cmbxURI.Items.Strings[i];
          XMLConfig.SetValue('URL/Items/Item_' + IntToStr(i) + '/url/address', S);
        End;
    End;

  XMLConfig.Flush;
End;

Procedure TfrmXMLRPCForm.LHTTPClientCanWrite(ASocket : TLHTTPClientSocket;
                                             Var OutputEof : TWriteBlockStatus);
Var S : string;
Begin
  S := XMLToSend.Lines.Text;
  If Trim(S) <> '' Then
    Begin
      ASocket.SendMessage(S);
      AddToLog('Sent the text: ' + XMLToSend.Lines.Text);
    End
  Else
    Begin
      MessageDlg('Nothing to send', mtError, [mbOK], 0);
    End;
End;

Procedure TfrmXMLRPCForm.FormCreate(Sender : TObject);
Var
  ConfigDir  :  string;
  ConfigFile : string;
Begin
  LHTTPClient.AddExtraHeader('User-Agent: LINESIP(r) XMLRPC client tester (version ' +
                             Version + ')');
  LHTTPClient.AddExtraHeader('Accept: text/xml');
  LHTTPClient.AddExtraHeader( // HTTP 1.1
                     'Cookie: SESSf528764d624db129b32c21fbca0cb8d6=08f26afaee1b160e84857d69c6c22100'
  );
  LHTTPClient.AddExtraHeader('Accept-Language: en');
  LHTTPClient.AddExtraHeader('Accept-Charset: us-ascii');
  LHTTPClient.AddExtraHeader('Content-type: text/xml');

  ConfigDir := AppConfigFile;
  If Not DirectoryExists(ConfigDir) Then
    ForceDirectories(ConfigDir);

  ConfigFile  := ConfigDir + DirectorySeparator + 'xmlrpc_client.cfg';
  XMLConfig.Filename := ConfigFile;
  XMLFileName := XMLConfig.GetValue('XMLLoad/Name', '');
  LoadURL;

  Self.LogFileName := ConfigDir + DirectorySeparator + 'xmlrpc.log';

  If FileExistsUTF8(Self.LogFileName) Then
    mmoLog.Lines.LoadFromFile(Self.LogFileName);

  If trim(XMLFileName) <> '' Then
    Begin
      If FileIsReadable(XMLFileName) Then
        XMLToSend.Lines.LoadFromFile(XMLFileName)
      Else
        XMLFileName := '';
    End;
End;

initialization
  {$I untxmlrpc_client.lrs}

End.

