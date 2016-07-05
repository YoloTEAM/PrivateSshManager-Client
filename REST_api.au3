#include-once
#include <WinHttp.au3>
OnAutoItExitRegister("_closeWinHTTP")

#cs
	; Config-section
	Global $sServer = "localhost"
	Global $sPort = 8080
#ce

Global $hOpen = _WinHttpOpen(), $hConnect
If $sPort < 1 Then
	$sPort = 80
	$hConnect = _WinHttpConnect($hOpen, $sServer)
Else
	$hConnect = _WinHttpConnect($hOpen, $sServer, $sPort)
EndIf

#cs
	; Test
	ConsoleWrite(REST_login("james", "here") & @CRLF)
	ConsoleWrite(REST_signUp("james", "here") & @CRLF)
	ConsoleWrite(REST_memberInfo("JWT eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJfaWQiOiI1Nzc5NDUwYjI5ZGJkMTAzMDAyMTc0YzUiLCJ1c2VybmFtZSI6ImphbWVzIiwicGFzc3dvcmQiOiIkMmEkMTAkZTNjYktrSVdSRlpnTjZvaDRZNUYudVJNQXJwUlN0WFY5Li4yRllza25aVTBUZ3ZYWWVWZzYiLCJfX3YiOjB9.EzWjUusISf0wCrnILl5EsBxmGcJBTwy7Npg5w4Ol9PM") & @CRLF)
	ConsoleWrite(REST_getSocks("us", 10, "JWT eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJfaWQiOiI1Nzc5NDUwYjI5ZGJkMTAzMDAyMTc0YzUiLCJ1c2VybmFtZSI6ImphbWVzIiwicGFzc3dvcmQiOiIkMmEkMTAkZTNjYktrSVdSRlpnTjZvaDRZNUYudVJNQXJwUlN0WFY5Li4yRllza25aVTBUZ3ZYWWVWZzYiLCJfX3YiOjB9.EzWjUusISf0wCrnILl5EsBxmGcJBTwy7Npg5w4Ol9PM") & @CRLF)
	ConsoleWrite(REST_getTotalSocksUnUsed("af", "JWT eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJfaWQiOiI1Nzc5NDUwYjI5ZGJkMTAzMDAyMTc0YzUiLCJ1c2VybmFtZSI6ImphbWVzIiwicGFzc3dvcmQiOiIkMmEkMTAkZTNjYktrSVdSRlpnTjZvaDRZNUYudVJNQXJwUlN0WFY5Li4yRllza25aVTBUZ3ZYWWVWZzYiLCJfX3YiOjB9.EzWjUusISf0wCrnILl5EsBxmGcJBTwy7Npg5w4Ol9PM") & @CRLF)
#ce

Func REST_login($username, $password)
	Return _WinHttpSimpleRequest($hConnect, "POST", "/api/login", Default, "username=" & $username & "&password=" & $password)
EndFunc   ;==>REST_login

Func REST_signUp($username, $password)
	Return _WinHttpSimpleRequest($hConnect, "POST", "/api/signup", Default, "username=" & $username & "&password=" & $password)
EndFunc   ;==>REST_signUp

Func REST_memberInfo($token)
	Return _WinHttpSimpleRequest($hConnect, "GET", "/api/memberinfo", Default, Default, "authorization: " & $token)
EndFunc   ;==>REST_memberInfo

Func REST_getSocks($country, $number, $token)
	Local $getSocks = _WinHttpSimpleRequest($hConnect, "POST", "/api/getsocks", Default, "country=" & $country & "&number=" & $number, "Authorization: " & $token & @CRLF & "Content-type: application/x-www-form-urlencoded")
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

Func REST_getTotalSocksUnUsed($country, $token)
	Return _WinHttpSimpleRequest($hConnect, "GET", "/api/getsocks?country=" & $country, Default, Default, "Authorization: " & $token)
EndFunc   ;==>REST_getSocks

Func _closeWinHTTP()
	_WinHttpCloseHandle($hConnect)
	_WinHttpCloseHandle($hOpen)
EndFunc   ;==>_closeWinHTTP
