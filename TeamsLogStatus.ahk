#NoEnv
#Warn ; Enable warnings to assist with detecting common errors.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

#SingleInstance force
#Persistent

; Config
TeamsLogFile := "C:\Users\venaasj\AppData\Roaming\Microsoft\Teams\logs.txt"
WebhookURI = http://172.17.13.240:8000/api/webhook/
Username := "joachim"


;Set a default Status
CurrentStatus = "Offline"

; Send a heartbeat webhook anyway every 1 mins
SetTimer, SendWebhook, 60000

; Set initial status on start
loop, Read, %TeamsLogFile%
{
	if A_LoopReadLine
	{
		if (instr(A_LoopReadLine, "StatusIndicatorStateService: Added"))
		    Last_Line := A_LoopReadLine
	}

}
NewLine(Last_Line)


lt := new CLogTailer(TeamsLogFile, Func("NewLine"))
return


NewLine(text)
{
global CurrentStatus
#ReadStatus := RegExMatch(text, "Setting the taskbar overlay icon - (?!New)([A-Za-z ]*) ", StatusText)
ReadStatus := RegExMatch(text, "StatusIndicatorStateService: Added (?!NewActivity)(\w+)", StatusText)
if (ReadStatus != 0)
 {
 CurrentStatus := RegExReplace(StatusText1, "[^A-Z\s]\K([A-Z])", " $1")
 SendWebhook()
 }
}


class CLogTailer {
	__New(logfile, callback){
		this.file := FileOpen(logfile, "r-d")
		this.callback := callback
		; Move seek to end of file
		this.file.Seek(0, 2)
		fn := this.WatchLog.Bind(this)
		SetTimer, % fn, 100
	}
	
	WatchLog(){
		Loop {
			p := this.file.Tell()
			l := this.file.Length
			line := this.file.ReadLine(), "`r`n"
			len := StrLen(line)
			if (len){
				RegExMatch(line, "[\r\n]+", matches)
				if (line == matches)
					continue
				this.callback.Call(Trim(line, "`r`n"))
			}
		} until (p == l)
	}
}

; ----------------------
; Function to POST a JSON payload to the Webhook URI defined
; ----------------------
SendWebhook()
{

  global
	try {
	WinHTTP := ComObjCreate("WinHTTP.WinHttpRequest.5.1")
	WinHTTP.Open("POST", WebhookURI, 0)
	WinHTTP.SetRequestHeader("Content-Type", "application/json")
	Body = { "uid": "%UserName%", "status":"%CurrentStatus%" }
	WinHTTP.Send(Body)
	Result := WinHTTP.ResponseText
	Status := WinHTTP.Status
  }
}


