#include-once
#include <WinHttp.au3>
OnAutoItExitRegister("_closeWinHTTP")

#cs
	; Config-section
	Global $ServerHost = "localhost"
	Global $ServerPort = 8080
#ce

Global $hOpen = _WinHttpOpen()
Global $hConnect = _WinHttpConnect($hOpen, $ServerHost, $ServerPort)

#cs
	; Test
	ConsoleWrite(REST_login("james", "here") & @CRLF)
	ConsoleWrite(REST_signUp("james", "here") & @CRLF)
	ConsoleWrite(REST_memberInfo("JWT eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJfaWQiOiI1Nzc1YTdjNDI0YzdjMGQwMGI2NDc2ZjEiLCJ1c2VybmFtZSI6ImphbWVzIiwicGFzc3dvcmQiOiIkMmEkMTAka25KRmIvaXdDRGt6S0t3VC4zelp0TzBWUHVsbE8vaWVaMHlnakY1bXo1M3R3NjJ3dzFldkciLCJfX3YiOjB9._HSI7lmFLA-xzVy0PGHB5D5Y-a2VUX4orrsHjx-azq8") & @CRLF)
	ConsoleWrite(REST_getSocks("us", 10, "JWT eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJfaWQiOiI1Nzc1YTdjNDI0YzdjMGQwMGI2NDc2ZjEiLCJ1c2VybmFtZSI6ImphbWVzIiwicGFzc3dvcmQiOiIkMmEkMTAka25KRmIvaXdDRGt6S0t3VC4zelp0TzBWUHVsbE8vaWVaMHlnakY1bXo1M3R3NjJ3dzFldkciLCJfX3YiOjB9._HSI7lmFLA-xzVy0PGHB5D5Y-a2VUX4orrsHjx-azq8") & @CRLF)
#ce

Func REST_login($username, $password)
	Return _WinHttpSimpleRequest($hConnect, "GET", "/api/login?username=" & $username & "&password=" & $password)
EndFunc   ;==>REST_login

Func REST_signUp($username, $password)
	Return _WinHttpSimpleRequest($hConnect, "GET", "/api/signup?username=" & $username & "&password=" & $password)
EndFunc   ;==>REST_signUp

Func REST_memberInfo($token)
	Return _WinHttpSimpleRequest($hConnect, "GET", "/api/memberinfo", Default, Default, "authorization: " & $token)
EndFunc   ;==>REST_memberInfo

Func REST_getSocks($country, $number, $token)
	Local $getSocks = _WinHttpSimpleRequest($hConnect, "GET", "/api/getsocks?country=" & $country & "&number=" & $number, Default, Default, "authorization: " & $token)
	Local $getSocksEx = StringRegExp($getSocks, '"ip":"(.*?)","user":"(.*?)","pass":"(.*?)"', 3)
	If IsArray($getSocksEx) Then
		If UBound($getSocksEx) == 3 Then Return $getSocksEx[0] & "|" & $getSocksEx[1] & "|" & $getSocksEx[2]

		$getSocks = ""
		For $i = 0 To UBound($getSocksEx) - 1 Step 3
			$getSocks &= $getSocksEx[$i] & "|" & $getSocksEx[$i + 1] & "|" & $getSocksEx[$i + 2] & @CRLF
		Next

		Return StringTrimRight($getSocks, 2)
	Else
		Return $getSocks
	EndIf
EndFunc   ;==>REST_getSocks

Func _closeWinHTTP()
	_WinHttpCloseHandle($hConnect)
	_WinHttpCloseHandle($hOpen)
EndFunc   ;==>_closeWinHTTP
