#include <String.au3>
#include <GUIConstantsEx.au3>
#include <GuiComboBox.au3>
#include <ProgressConstants.au3>
#include <WindowsConstants.au3>

Opt("GUIOnEventMode", 1)

Global $title = "VPS Status"
Global $sid, $key, $email
Global $name, $ip, $putty

If Not FileExists(@ScriptDir & "\config.ini") Then
	IniWrite(@ScriptDir & "\config.ini", "AUTH", "key", "")
	IniWrite(@ScriptDir & "\config.ini", "AUTH", "email", "")
	IniWrite(@ScriptDir & "\config.ini", "NAMES", "count", "1")
	IniWrite(@ScriptDir & "\config.ini", "NAMES", "1", "")
	MsgBox(64, "Information", "A confinguration file was missing, it has been created for you." & @CRLF & @ScriptDir & "\config.ini" & @CRLF & "Modify the configuration file to include: " & @CRLF & "- API Key" & @CRLF & "- Email" & @CRLF & "- A list of all your server names. " & @CRLF & "If you have more than one server you must modify the count to represent such.")
	Exit
EndIf

$key = IniRead(@ScriptDir & "\config.ini", "AUTH", "key", "")
$email = IniRead(@ScriptDir & "\config.ini", "AUTH", "email", "")
$putty = IniRead(@ScriptDir & "\config.ini", "AUTH", "putty", "")

If StringLen($key) <= 5 Or StringLen($email) < 4 Or Not StringInStr($email, "@") Then
	MsgBox(16, "Error", "Invalid Key/Email")
	Exit
EndIf

#Region ### START Koda GUI section ### Form=
$frmStatus = GUICreate($title, 355, 206, 526, 286)
GUISetOnEvent($GUI_EVENT_CLOSE, "frmStatusClose")
$Group1 = GUICtrlCreateGroup(" Usage ", 8, 56, 337, 121)
$Label1 = GUICtrlCreateLabel("CPU", 14, 88, 26, 17)
$Label2 = GUICtrlCreateLabel("RAM", 14, 120, 28, 17)
$Label3 = GUICtrlCreateLabel("HDD", 14, 152, 28, 17)
$progCPU = GUICtrlCreateProgress(45, 85, 206, 17, BitOR($PBS_SMOOTH, $WS_BORDER))
GUICtrlSetBkColor(-1, 0x99B4D1)
$progRAM = GUICtrlCreateProgress(45, 117, 206, 17, BitOR($PBS_SMOOTH, $WS_BORDER))
GUICtrlSetBkColor(-1, 0x99B4D1)
$progHDD = GUICtrlCreateProgress(45, 149, 206, 17, BitOR($PBS_SMOOTH, $WS_BORDER))
GUICtrlSetBkColor(-1, 0x99B4D1)
$lblcpu = GUICtrlCreateLabel("0%", 255, 88, 80, 17)
$lblram = GUICtrlCreateLabel("0MB / 0MB", 255, 120, 80, 17)
$lblhdd = GUICtrlCreateLabel("0GB / 0GB", 255, 152, 80, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$cboserver = GUICtrlCreateCombo("", 264, 8, 81, 25, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL, $CBS_UPPERCASE))

If FileExists(@ScriptDir & "\config.ini") Then
	Local $num = IniRead(@ScriptDir & "\config.ini", "NAMES", "COUNT", "0")
	Local $str = ""
	For $i = 1 To $num
		Local $d = IniRead(@ScriptDir & "\config.ini", "NAMES", $i, $i)
		$str = $str & $d & "|"
	Next
	$str = StringLeft($str, StringLen($str) - 1)
	GUICtrlSetData(-1, $str)
Else
	GUICtrlSetData(-1, "ONE|TWO|THREE|FOUR|FIVE|SIX|SEVEN|EIGHT|NINE|TEN")
EndIf

$cmdUpdate = GUICtrlCreateButton("Update", 264, 32, 81, 22)
GUICtrlSetOnEvent(-1, "cmdUpdateClick")
$Label4 = GUICtrlCreateLabel("Server: ", 8, 16, 41, 17)
$Label5 = GUICtrlCreateLabel("Status: ", 8, 32, 40, 17)
$lblname = GUICtrlCreateLabel("...", 56, 16, 206, 17)
GUICtrlSetOnEvent(-1, "lblnameClick")
$lblstatus = GUICtrlCreateLabel("...", 56, 32, 205, 17)
$cmdpwron = GUICtrlCreateButton("Power ON", 8, 176, 81, 22)
GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlSetOnEvent(-1, "cmdpwronClick")
$cmdpwroff = GUICtrlCreateButton("Power OFF", 100, 176, 81, 22)
GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlSetOnEvent(-1, "cmdpwroffClick")
$cmdreboot = GUICtrlCreateButton("Reboot", 264, 176, 81, 22)
GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlSetOnEvent(-1, "cmdrebootClick")
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

If _GUICtrlComboBox_GetCount($cboserver) < 1 Then GUICtrlSetState($cmdUpdate, $GUI_DISABLE)

While 1
	Sleep(100)
WEnd

Func cmdUpdateClick()
	retrieve(_GUICtrlComboBox_GetCurSel($cboserver))
EndFunc   ;==>cmdUpdateClickClick

Func frmStatusClose()
	Exit
EndFunc   ;==>frmStatusClose

Func lblnameClick()
	If StringInStr(GUICtrlRead($lblname), "(") Then
		GUICtrlSetData($lblname, "[SID] " & $sid)
	Else
		GUICtrlSetData($lblname, $name & " (" & $ip & ")")
	EndIf
EndFunc   ;==>lblnameClick

Func cmdpwroffClick()
	$rez = HttpPost('https://panel.cloudatcost.com/api/v1/powerop.php', "key=" & $key & '&login=' & $email & '&sid=' & $sid & '&action=poweroff')
	If verifysuccess($rez) Then
		GUICtrlSetData($lblstatus, "PowerOff Success!")
		GUICtrlSetState($cmdpwroff, $GUI_DISABLE)
		GUICtrlSetState($cmdpwron, $GUI_ENABLE)
		GUICtrlSetState($cmdreboot, $GUI_DISABLE)
	Else
		GUICtrlSetData($lblstatus, "PowerOff Failed...")
	EndIf
EndFunc   ;==>cmdpwroffClick

Func cmdpwronClick()
	$rez = HttpPost('https://panel.cloudatcost.com/api/v1/powerop.php', "key=" & $key & '&login=' & $email & '&sid=' & $sid & '&action=poweron')
	If verifysuccess($rez) Then
		GUICtrlSetData($lblstatus, "PowerOn Success!")
		GUICtrlSetState($cmdpwroff, $GUI_ENABLE)
		GUICtrlSetState($cmdpwron, $GUI_DISABLE)
		GUICtrlSetState($cmdreboot, $GUI_ENABLE)
	Else
		GUICtrlSetData($lblstatus, "PowerOn Failed...")
	EndIf
EndFunc   ;==>cmdpwronClick

Func cmdrebootClick()
	$rez = HttpPost('https://panel.cloudatcost.com/api/v1/powerop.php', "key=" & $key & '&login=' & $email & '&sid=' & $sid & '&action=reset')
	If verifysuccess($rez) Then
		GUICtrlSetData($lblstatus, "Reboot Success!")
		GUICtrlSetState($cmdpwroff, $GUI_ENABLE)
		GUICtrlSetState($cmdpwron, $GUI_DISABLE)
		GUICtrlSetState($cmdreboot, $GUI_ENABLE)
	Else
		GUICtrlSetData($lblstatus, "Reboot Failed...")
	EndIf
EndFunc   ;==>cmdrebootClick

Func verifysuccess($r)
	$out = _StringBetween($r, 'result": "', '"')
	If IsArray($out) Then
		$out = $out[0]
		If StringInStr($out, "success") Then
			Return True
		Else
			Return False
		EndIf
	Else
		Return False
	EndIf
EndFunc   ;==>verifysuccess

Func retrieve($i)
	If _GUICtrlComboBox_GetCurSel($cboserver) <= -1 Then Return False
	If $i < 0 And $i > 10 Then Return False
	$rez = HttpPost('https://panel.cloudatcost.com/api/v1/listservers.php?key=' & $key & '&login=' & $email & '')
	$rez = StringReplace($rez, '      ', '')
	$rez = StringReplace($rez, @CR, '')
	$rez = StringReplace($rez, @LF, '')
	$rez = StringReplace($rez, '"', "")
	$rez = StringRight($rez, StringLen($rez) - 1)
	$rez = StringLeft($rez, StringLen($rez) - 2)
	$batch = _StringBetween($rez, '{', '}')
	If IsArray($batch) And UBound($batch) >= $i Then
		$data = $batch[$i]
		$name = getBetween($data, 'lable:', ',')
		$ip = getBetween($data, 'ip:', ',')
		GUICtrlSetData($lblname, $name & " (" & $ip & ")")
		$cpu = getBetween($data, 'cpuusage:', ',')
		$ram = Round(getBetween($data, 'ram:', ','), 1)
		$ramused = Round(getBetween($data, 'ramusage:', ','), 1)
		$hdd = Round(getBetween($data, 'storage:', ','), 1)
		$hddused = Round(getBetween($data, 'hdusage:', ','), 1)
		$status = getBetween($data, ',status:', ',')
		$sid = getBetween($data, 'sid:', ',')
		GUICtrlSetData($lblstatus, $status)
		ControlSetText($title, "", $lblcpu, $cpu & "%", "0%")
		ControlSetText($title, "", $lblram, $ramused & "MB/" & $ram & "MB", "0/0")
		ControlSetText($title, "", $lblhdd, $hddused & "GB/" & $hdd & "GB", "0/0")
		GUICtrlSetData($progCPU, $cpu)
		GUICtrlSetData($progRAM, Int(Round(($ramused / $ram) * 100), 0))
		GUICtrlSetData($progHDD, Int(Round(($hddused / $hdd) * 100), 0))
		colorpb(0, $cpu)
		colorpb(1, Int(Round(($ramused / $ram) * 100), 0))
		colorpb(2, Int(Round(($hddused / $hdd) * 100), 0))
		ConsoleWrite($data & @CRLF)

		If $status == "PoweredOn" Then
			GUICtrlSetState($cmdpwroff, $GUI_ENABLE)
			GUICtrlSetState($cmdreboot, $GUI_ENABLE)
		ElseIf $status == "PoweredOff" Then
			GUICtrlSetState($cmdpwron, $GUI_ENABLE)
			GUICtrlSetState($cmdpwroff, $GUI_DISABLE)
			GUICtrlSetState($cmdreboot, $GUI_DISABLE)
			ControlSetText($title, "", $lblcpu, "0%")
			ControlSetText($title, "", $lblram, "0/0")
			ControlSetText($title, "", $lblhdd, "0/0")
			GUICtrlSetData($progCPU, 0)
			GUICtrlSetData($progRAM, 0)
			GUICtrlSetData($progHDD, 0)
		Else
			GUICtrlSetState($cmdpwron, $GUI_ENABLE)
			GUICtrlSetState($cmdpwroff, $GUI_ENABLE)
			GUICtrlSetState($cmdreboot, $GUI_ENABLE)
		EndIf

	Else
		GUICtrlSetData($lblname, "Invalid")
		GUICtrlSetData($lblstatus, "Invalid")
	EndIf

EndFunc   ;==>retrieve

Func colorpb($num, $val)
	If $val <= 25 Then ; green
		Switch $num
			Case 0
				_SendMessage(GUICtrlGetHandle($progCPU), $PBM_SETSTATE, 1)
			Case 1
				_SendMessage(GUICtrlGetHandle($progRAM), $PBM_SETSTATE, 1)
			Case 2
				_SendMessage(GUICtrlGetHandle($progHDD), $PBM_SETSTATE, 1)
		EndSwitch
	EndIf
	If $val >= 26 And $val < 74 Then ; yellow
		Switch $num
			Case 0
				_SendMessage(GUICtrlGetHandle($progCPU), $PBM_SETSTATE, 3)
			Case 1
				_SendMessage(GUICtrlGetHandle($progRAM), $PBM_SETSTATE, 3)
			Case 2
				_SendMessage(GUICtrlGetHandle($progHDD), $PBM_SETSTATE, 3)
		EndSwitch
	EndIf
	If $val >= 75 Then ; red
		Switch $num
			Case 0
				_SendMessage(GUICtrlGetHandle($progCPU), $PBM_SETSTATE, 2)
			Case 1
				_SendMessage(GUICtrlGetHandle($progRAM), $PBM_SETSTATE, 2)
			Case 2
				_SendMessage(GUICtrlGetHandle($progHDD), $PBM_SETSTATE, 2)
		EndSwitch
	EndIf
EndFunc   ;==>colorpb

Func getBetween($source, $left, $right)
	Local $temp = _StringBetween($source, $left, $right)
	If IsArray($temp) Then
		$temp[0] = StringReplace($temp[0], ' ', '')
		$temp[0] = StringReplace($temp[0], ':', '')
		Return $temp[0]
	Else
		Return "NULL"
	EndIf
EndFunc   ;==>getBetween

Func HttpPost($sURL, $sData = "")
	Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
	$oHTTP.Open("POST", $sURL, False)
	$oHTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
	$oHTTP.Send($sData)
	Return $oHTTP.ResponseText
EndFunc   ;==>HttpPost

Func HttpGet($sURL, $sData = "")
	Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
	$oHTTP.Open("GET", $sURL & "?" & $sData, False)
	$oHTTP.Send()
	Return $oHTTP.ResponseText
EndFunc   ;==>HttpGet
