; #INDEX# =======================================================================================================================
; Title .........: PrivateSSHServer - Client
; AutoIt Version : 3.3.14.2
; Description ...: Connect to PrivateSSHServer, pull SSH list via REST_API to use with BitviseSSH
; Author(s) .....: WormIt, KienNguyen
; Power by ......: YoloTEAM
; Github ........: http://YoloTEAM.github.io/PrivateSsHManager-Server
; ===============================================================================================================================

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_Outfile=PrivateSshManager-ClientChanger.exe
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_Description=PrivateSshManager-ClientChanger
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=YoloTEAM @ 2016
#AutoIt3Wrapper_Res_Field=ProductName|PrivateSshManager-ClientChanger
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; Global Config-section
Global $sServer, $sPort, $Username, $Password, $countryISO, $SocksPerRq
Global $BvSsh_pID, $BvSsh_path, $BvSsh_forwardPort, $BvSsh_timeOut, $BvSsh_hideAll
Global $configFile = @ScriptDir & '\config.ini', $GlobalJWT
Global $tempSsh, $stop_wait = False

_loadingConfig()

#include <WindowsConstants.au3>
#include <Misc.au3>
#include <Array.au3>
#include <File.au3>

_Singleton(@ScriptName)

Opt("TrayMenuMode", 1)

SplashTextOn("", "Loading...", 100, 40, -1, -1, 1, "Tahoma", 10)

Run(@ScriptDir & '\autoBvSsh.exe')
OnAutoItExitRegister("_indexExit")

DirCreate(@ScriptDir & "\SaveSsh")
DirCreate(@ScriptDir & "\SaveSsh\unUSED")

#Region #MainGUI
Global $hMemberAreaGUI = GUICreate("PrivateSshManager - Member Area", 315, 135, -1, -1)
GUISetBkColor(0x008080)
Global $hLCountry = GUICtrlCreateLabel("Country:    " & $countryISO, 25, 20, 170, 15)
GUICtrlSetFont(-1, 8.5, 800, 0, "Tahoma", 5)
GUICtrlSetColor(-1, 0xFFFFFF)
Global $hLStatus = GUICtrlCreateLabel(">> READY .", 10, 118, 295, 15)
GUICtrlSetFont(-1, 8.5, 400, 0, "Tahoma", 5)
GUICtrlSetColor(-1, 0xFFFFFF)
Global $hBChane = GUICtrlCreateButton("Change", 170, 72, 80, 26)
GUICtrlSetFont(-1, 8.5, 400, 0, "Tahoma", 5)
Global $hBStop = GUICtrlCreateButton("STOP", 255, 70, 45, 30)
GUICtrlSetFont(-1, 8.5, 800, 0, "Tahoma", 5)
GUICtrlSetState(-1, 128)
Global $hBSelect = GUICtrlCreateButton("Select", 200, 15, 70, 25)
GUICtrlSetFont(-1, 8.5, 400, 0, "Tahoma", 5)
GUICtrlCreateGroup("", -3, 107, 325, 30)
GUICtrlCreateLabel("Port: ", 25, 44, 40, 15)
GUICtrlSetColor(-1, 0xFFFFFF)
GUICtrlSetFont(-1, 8.5, 800, 0, "Tahoma", 5)
Global $hIPort = GUICtrlCreateInput($BvSsh_forwardPort, 84, 40, 40, 20)
GUICtrlSetFont(-1, 8.5, 400, 0, "Tahoma", 5)
GUICtrlCreateLabel("Timeout:", 25, 68, 50, 15)
GUICtrlSetFont(-1, 8.5, 800, 0, "Tahoma", 5)
GUICtrlSetColor(-1, 0xFFFFFF)
Global $hITimeout = GUICtrlCreateInput($BvSsh_timeOut, 84, 65, 40, 20)
GUICtrlSetFont(-1, 8.5, 400, 0, "Tahoma", 5)
Global $hCHideAll = GUICtrlCreateCheckbox("", 193, 48, 15, 15)
GUICtrlSetFont(-1, 8.5, 400, 0)
GUICtrlSetColor(-1, 0xFFFFFF)
GUICtrlSetBkColor(-1, 0x008080)
If $BvSsh_hideAll == 'true' Then GUICtrlSetState(-1, 1)
Global $hLHideAll = GUICtrlCreateLabel("Hide BvSsh", 215, 49, 65, 15)
GUICtrlSetColor(-1, 0xFFFFFF)
GUICtrlSetFont(-1, 8.5, 800, 0, "Tahoma", 5)
#EndRegion #MainGUI

#include "GUI-and-other-function.au3"
#include "Bitvise_autoLogin.au3"
#include "REST_api.au3"

While ProcessExists("BvSsh.exe")
	ProcessClose("BvSsh.exe")
	Sleep(35)
WEnd

If _getJWT() <> 1 Then _loginArea()

GUISetState(@SW_SHOW, $hMemberAreaGUI)

TrayTip("", "Welcome in the member area, " & StringUpper($Username), 5)
_FileReadToArray(@ScriptDir & '\SaveSsh\get.txt', $tempSsh, 1, "|")

GUIRegisterMsg($WM_COMMAND, "_WM_COMMAND")

While 1
	Switch GUIGetMsg()
		Case -3
			Exit
		Case $hLHideAll
			ControlClick($hMemberAreaGUI, '', $hCHideAll)
		Case $hBSelect
			_selectCountry()
		Case $hBChane
			GUICtrlSetState($hBChane, 128)

			$BvSsh_forwardPort = GUICtrlRead($hIPort)
			$BvSsh_timeOut = GUICtrlRead($hITimeout)

			If $BvSsh_forwardPort < 1000 Or $BvSsh_timeOut < 1 Then ContinueCase
			GUICtrlSetData($hLStatus, ">> Change SSH ...")

			If _IsChecked($hCHideAll) Then
				IniWrite($configFile, "BvSshConfig", "BvSshHideAll", True)
			Else
				IniWrite($configFile, "BvSshConfig", "BvSshHideAll", False)
			EndIf

			IniWrite($configFile, "BvSshConfig", "BvSshPort", $BvSsh_forwardPort)
			IniWrite($configFile, "BvSshConfig", "BvSshTimeout", $BvSsh_timeOut)

			If UBound($tempSsh) < 2 Then _SshToArray()

			GUICtrlSetState($hBStop, 64)

			_changeSsh()

			GUICtrlSetState($hBChane, 64)
			GUICtrlSetState($hBStop, 128)
	EndSwitch
WEnd

Func _loadingConfig()
	$sServer = IniRead($configFile, "SshPrivateServer", "Server", "localhost")
	$sPort = IniRead($configFile, "SshPrivateServer", "Port", 8080)
	$Username = IniRead($configFile, "SshPrivateServer", "Username", "")
	$Password = IniRead($configFile, "SshPrivateServer", "Password", "")
	$countryISO = IniRead($configFile, "SshPrivateServer", "CountryISO", "")
	$SocksPerRq = IniRead($configFile, "SshPrivateServer", "SocksPerRequest", 20)

	$BvSsh_path = IniRead($configFile, "BvSshConfig", "BvSshPath", @ScriptDir & "\Bitvise")
	If StringLeft($BvSsh_path, 1) == '\' Then $BvSsh_path = @ScriptDir & $BvSsh_path
	If Not FileExists($BvSsh_path & '\BvSsh.exe') Then
		MsgBox(48, 'Exit', 'Not found ???!!!' & @CRLF & $BvSsh_path & '\BvSsh.exe')
		Exit
	EndIf

	$BvSsh_forwardPort = IniRead($configFile, "BvSshConfig", "BvSshPort", 1080)
	$BvSsh_timeOut = IniRead($configFile, "BvSshConfig", "BvSshTimeout", 10)
	$BvSsh_hideAll = StringLower(IniRead($configFile, "BvSshConfig", "BvSshHideAll", 'true'))
EndFunc   ;==>_loadingConfig

Func _getJWT()
	ConsoleWrite('--> Login to ' & $sServer & ":" & $sPort & @CRLF)
	Local $dataLogin = REST_login($Username, $Password)
	If Not StringInStr($dataLogin, "success") Then
		SplashOff()
		MsgBox(48, "Server is Offline", "(" & $sServer & ":" & $sPort & ")" & @CRLF& "Can't connect.")
		Exit
	EndIf

	SplashOff()

	Local $regJWT = StringRegExp($dataLogin, '"success":(.*?),".*":"(.*?)"', 3)

	If $regJWT[0] == 'true' Then
		ConsoleWrite("+> Login successfully!" & @CRLF)
		$GlobalJWT = $regJWT[1]
		Return 1
	Else
		Return $regJWT[1]
		ConsoleWrite("! " & $regJWT[1] & @CRLF)
	EndIf
EndFunc   ;==>_getJWT

Func _WM_COMMAND($hWnd, $Msg, $wparam, $lparam)
	If BitAND($wparam, 0x0000FFFF) = $hBStop Then
		GUICtrlSetData($hLStatus, ">> Stopping ...")
		$stop_wait = True
		GUICtrlSetState($hBStop, 128)
	EndIf

	Return $GUI_RUNDEFMSG
EndFunc   ;==>_WM_COMMAND

Func _indexExit()
	ProcessClose("autoBvSsh.exe")
	ProcessClose($BvSsh_pID)
	FileDelete(@ScriptDir & '\SaveSsh\get.txt')
	If IsArray($tempSsh) Then
		For $i = 1 To UBound($tempSsh) - 1
			FileWrite(@ScriptDir & '\SaveSsh\get.txt', $tempSsh[$i][0] & "|" & $tempSsh[$i][1] & "|" & $tempSsh[$i][2] & @CRLF)
		Next
	EndIf
EndFunc   ;==>_indexExit
