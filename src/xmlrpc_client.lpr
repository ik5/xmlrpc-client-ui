{ XMLRPC client program, that helps debug xmlrpc requests

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

Program xmlrpc_client;

{$mode objfpc}{$H+}

Uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
cthreads,
  {$ENDIF}{$ENDIF}
Interfaces, // this includes the LCL widgetset
Forms
  { you can add units after this }, untXMLRPC_Client, lnetvisual, lnetbase;

{$IFDEF WINDOWS}{$R xmlrpc_client.rc}{$ENDIF}

{$R *.res}

Begin
  Application.Title:= 'xmlrpc-client';
  Application.Initialize;
  Application.CreateForm ( TfrmXMLRPCForm,frmXMLRPCForm ) ;
  Application.Run;
End.

