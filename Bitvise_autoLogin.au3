#include-once
#include <String.au3>

#cs
	; Config-section
	Global $BvSsh_path = @ScriptDir & "\Bitvise"
	Global $BvSsh_forwardPort = 1555
	Global $BvSsh_timeOut = 10
	Global $BvSsh_hideAll = True
	Global $BvSsh_pID
#ce

Func _BvSsh_Login($host, $user, $pass)
	ProcessClose($BvSsh_pID)
	Sleep(1000)

	Local $BvSsh_profile = _HexToString('0000000E54756E6E656C69657220342E3532000000000000001600000000000000000000000000000000000000000000000' & _
			'B627364617574682C70616D01010001020000000200000000000005787465726D010000FDE900000050000000190000012C07010000000000000000000D3132372E302' & _
			'E302E313A302E30000000000000000000000000000000093132372E302E302E3100000D3D000000000000000000000000000000000100000101010101010101010000010101' & _
			'01000001010101000000012C0100000000000000000000017F0000010000000431303830000000000000000000007F0000010000000232310000000001010100000000' & _
			'0000000000000000000000010100000001010000000000000000000000000000000000000200')
	RegWrite("HKEY_CURRENT_USER\Software\Bitvise" & $BvSsh_forwardPort & "\BvSshClient", 'DefaultProfile', 'REG_BINARY', $BvSsh_profile)

	Local $BvSsh_NewProfile = StringRegExpReplace(RegRead("HKEY_CURRENT_USER\Software\Bitvise" & $BvSsh_forwardPort & "\BvSshClient", "DefaultProfile"), '(7F00000100000004(?:.*?)000000000000000000007F)', '7F00000100000004' & _
			StringTrimLeft(StringToBinary($BvSsh_forwardPort), 2) & '000000000000000000007F', 1)

	RegWrite("HKEY_CURRENT_USER\Software\Bitvise" & $BvSsh_forwardPort & "\BvSshClient", "DefaultProfile", "REG_BINARY", $BvSsh_NewProfile)

	_BvSsh_runCmd($host, $user, $pass, $BvSsh_forwardPort)

	Return _BvSsh_waitConnected($BvSsh_forwardPort, $BvSsh_timeOut * 1000)
EndFunc   ;==>_BvSsh_Login

Func _BvSsh_runCmd($iHost, $iUser, $iPass, $iPort)
	Local $Cmd = $BvSsh_path & "\BvSsh.exe -host=" & $iHost & " -port=22 -user=" & $iUser & " -password=" & $iPass & _
			" -loginOnStartup -exitOnLogout -baseRegistry=HKEY_CURRENT_USER\Software\Bitvise" & $iPort

	If $BvSsh_hideAll Then
		$Cmd &= " -menu=small -hide=popups,trayLog,trayPopups,trayIcon"
	EndIf

	$BvSsh_pID = Run($Cmd)
	ProcessWait($BvSsh_pID)

	GUICtrlSetData($hLStatus, ">> Login Ssh: " & $iHost & "|" & $iUser & "|" & $iPass)

	Sleep(1500)
EndFunc   ;==>_BvSsh_runCmd

Func _BvSsh_waitConnected($port, $time_out = 10000, $delay = 80)
	Local $timer_int = TimerInit()
	While TimerDiff($timer_int) < $time_out
		GUICtrlSetData($hLStatus, ">> Waitting connection at 127.0.0.1:" & $BvSsh_forwardPort & " [" & $BvSsh_timeOut - Round(TimerDiff($timer_int) / 1000) & "]")
		If Not ProcessExists($BvSsh_pID) Then ExitLoop
		If $stop_wait Then Return -1
		If _BvSsh_checkConnection($port) Then Return TimerDiff($timer_int)
		Sleep($delay)
	WEnd

	Return 0
EndFunc   ;==>_BvSsh_waitConnected

Func _BvSsh_checkConnection($port)
	TCPStartup()
	Local $connection = TCPConnect("127.0.0.1", $port)
	If $connection <> -1 Then
		TCPCloseSocket($connection)
		TCPShutdown()
		Return 1
	Else
		TCPShutdown()
		Return 0
	EndIf
EndFunc   ;==>_BvSsh_checkConnection
