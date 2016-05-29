; AutoHotkey Version: 1.x
; Language:       English
; Platform:       Win9x/NT
; Author:         Gene <gene.hwung@gmail.com>
;
; Script Function:
;   Provides an Emacs-like keybinding emulation mode that can be toggled on and off using
;   the CapsLock key.

;==========================
;Initialise
;==========================

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#InstallKeybdHook  ;Only use the keyboard response for A_TimeIdlePhysical
#KeyHistory 100 ; Setup a key history for debugging purposes

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

enabledIcon := "EmacsEverywhere_on.ico"
disabledIcon := "EmacsEverywhere_off.ico"
IsInEmacsMode := true

is_pre_x := false ; turns to be true when ctrl-x is pressed
is_pre_spc := false ; turns to be true when ctrl-space is pressed

key_lst := ""
key_grp := 0 ; 0: normal 1: pre_space 2: pre_x
timeStamp_GL := 0 ; Used for calculate time between events

;==========================
;Functions
;==========================
; Check application, 0 means disable the key binding all together
is_target() {
  IfWinActive,ahk_class PuTTY ; PuTTY
    ;TrayTip, Emacs Everywhere, PuTTY mode, 10, 1
    Return 0
  IfWinActive,ahk_class Emacs ; NTEmacs 
    Return 0
  IfWinActive,ahk_class mintty ; Cygwin
    Return 0
  IfWinActive,ahk_class ConsoleWindowClass ; Cygwin
    Return 0
  IfWinActive,ahk_class MEADOW ; Meadow
    Return 1 
  IfWinActive,ahk_class cygwin/x X rl-xterm-XTerm-0
    Return 1
  IfWinActive,ahk_class MozillaUIWindowClass ; keysnail on Firefox
    Return 1
  ; Avoid VMwareUnity with AutoHotkey
  IfWinActive,ahk_class VMwareUnityHostWndClass
    Return 1
  IfWinActive,ahk_class Vim ; GVIM
    Return 1
   IfWinActive,ahk_class XEmacs ; XEmacs on Cygwin
     Return 1
  IfWinActive,ahk_class OpusApp ; Word
	;TrayTip, Emacs Everywhere, Word mode, 10, 1
    Return 2
  IfWinActive,ahk_class ENMainFrame ; Evernote
    Return 3
  IfWinActive,ahk_class SunAwtFrame ; MATLAB	
	Return 4	 ;TrayTip, Emacs Everywhere, Emacs mode is %state%, 10, 1
  IfWinActive,ahk_class SWT_Window0 ; Eclipse
    Return 5
  IfWinActive,ahk_class Chrome_WidgetWin_1 ; Chrome
	Return 6
  else
	Return 1
	
;   IfWinActive,ahk_class Xming X
;     Return 1
}

global INTERVAL := 100

loop{
	global is_pre_spc 
	global is_pre_x
	
	; reset the flag if too long
	global timeStamp_GL	
	global INTERVAL
	global key_grp
	
	sleep INTERVAL
	if (is_pre_spc || is_pre_x) {
		ts := A_TickCount
		diffTs := ts - timeStamp_GL
		; Msgbox, %ts% or %diffTs% or %timeStamp_GL% milliseconds!	
		if (diffTs > 3000 ) { ; after # seconds, reset to normal 	
			setPrefix_x("", false)
			setPrefix_space("", false) 
		}
		
		; any key will cancel the ^x , this will however, turn it off when releasing control (shich seems too strict but fine for now)
		if (is_pre_x) {		
			; the last keystroke has to be something else (diffTs > INTERVAL)
			if (A_TimeIdlePhysical < INTERVAL && diffTs > INTERVAL && (A_Thishotkey <> "$^x" || !GetKeyState("Ctrl","P")) ){ 
				;Msgbox, %A_Thishotkey% . %A_Priorkey% .GetKeyState("Ctrl","P")
				setPrefix_x("", false)
			}
		}
		
		; any key will cancel the ^space, this will however, turn it off when releasing control (shich seems too strict but fine for now)
		if (is_pre_spc) {
			; the last keystroke has to be something else (diffTs > INTERVAL)			
			; other hotkeys are pressed, or just some random keys being pressed (commenting: control is released)
			if (A_TimeIdlePhysical < INTERVAL && diffTs > INTERVAL && (key_grp <> 1 ) ){  ; || !GetKeyState("Ctrl","P")
				;Msgbox, %A_Thishotkey% . %A_Priorkey%
				setPrefix_space("", false)
			}
		}		
	}
}

SetEmacsMode(toActive) {
  ;local iconFile := toActive ? enabledIcon : disabledIcon
  ;local state := toActive ? "ON" : "OFF"
  
  if (IsInEmacsMode != toActive) {
	  IsInEmacsMode := toActive
	  ;TrayTip, Emacs Everywhere, Emacs mode is %state%, 10, 1
	  ;Menu, Tray, Icon, %iconFile%,	  

	  Send {Shift Up}
  }
}

; Disable emacs mode whenever at right positions
SendCommand(emacsKey, translationToWindowsKeystrokes, secondWindowsKeystroke="") {
	global timeStamp_GL := A_TickCount ; record when the key is pressed
	; if prefix x, disable it once anything has been clicked
	if (is_pre_x  && is_target() <> 0) {
		setPrefix_x("", false)
	}
	
  if (is_target() == 0) 
	SetEmacsMode(false)
   else	
	SetEmacsMode(true)   
	
  if (is_target() <> 0 && translationToWindowsKeystrokes <>"") {
    Send, %translationToWindowsKeystrokes%
	sleep, 40
    if (secondWindowsKeystroke<>"") {
      Send, %secondWindowsKeystroke%
	  sleep, 40
    }
	global key_lst = translationToWindowsKeystrokes . secondWindowsKeystroke 
  } else {
    Send, %emacsKey% ;passthrough original keystroke 
  }
  
  ; Attempt to fix the modifier stuck situation, check whether they are stuck, then 
  ;While GetKeyState("Ctrl","P") || GetKeyState("LWin","P") || GetKeyState("RWin","P") || GetKeyState("Shift","P") || GetKeyState("Alt","P"){	
	;Sleep 50
  ;}
  
  return
}

SendCommand_norm(emacsKey, translationToWindowsKeystrokes, secondWindowsKeystroke="") {
	SendCommand(emacsKey, translationToWindowsKeystrokes, secondWindowsKeystroke)
	global key_grp := 0
	setPrefix_space("", false)
	setPrefix_x("", false)
	return
}

SendCommand_spc(emacsKey, translationToWindowsKeystrokes) {
	global is_pre_spc
	global key_grp := 1
	
	if (is_pre_spc && is_target() <> 0) {
		
		SendCommand(emacsKey, "+" . translationToWindowsKeystrokes) ; Concatenate string
	}
	else {
		SendCommand(emacsKey, translationToWindowsKeystrokes)
	}	
	setPrefix_x("", false)
	return
}

; compute the command when space is on
GetCommand_spc(emacsKey, translationToWindowsKeystrokes) {
;	global is_pre_spc
	local result
  
	if (is_pre_spc && is_target() <> 0) {
		result = +%translationToWindowsKeystrokes% ; Concatenate string
	}
	else {
		result = %translationToWindowsKeystrokes%
	}	
	return result
}

SendCommand_PreX(emacsKey, translationToWindowsKeystrokes, alternativeKeystrokes) {
	
	global is_pre_x	  
	global key_grp := 2	
	if (is_pre_x  && is_target() <> 0) {				
		SendCommand(emacsKey, translationToWindowsKeystrokes)
	}
	else {
		SendCommand(emacsKey, alternativeKeystrokes)
	}	
	setPrefix_space("", false)
	return
}

setPrefix_x(emacsKey,toActive) {
	global disabledIcon
	global enabledIcon
	if (is_target() <> 0) {
		iconFile := toActive ? disabledIcon : enabledIcon
		is_pre_x := toActive
		Menu, Tray, Icon, %iconFile%,
		timeStamp_GL := A_TickCount
		return
	}
	else {
		Send, %emacsKey% ;passthrough original keystroke 
	}
}
  
setPrefix_space(emacsKey,toActive) {
	global disabledIcon
	global enabledIcon
	if (is_target() <> 0) {
		iconFile := toActive ? disabledIcon : enabledIcon
		is_pre_spc := toActive
		Menu, Tray, Icon, %iconFile%,
		timeStamp_GL := A_TickCount
		return
	}
	else {
		Send, %emacsKey% ;passthrough original keystroke
	}
}
  
;==============================
;Things starting with ^X or Space
;==============================
$^x::setPrefix_x("^x", true) ;Ctrl X is just typed

$h::SendCommand_PreX("h", "^a", "h") ;Select all

$^f::SendCommand_PreX("^f", "^o", GetCommand_spc("^f","{Right}"))  ; Open a file or move right
	
$^s:: ; Save or search
	if (is_target() == 4)        ; Matlab incremental search
		SendCommand_PreX("^s", "^s", "^s") ;Save or searching (because ^f is forward now)
	else if (is_target() == 3)    ;Evernote
		SendCommand_PreX("^s", "{F9}", "^f") 
	else if (is_target() == 5)          ; Eclipse incremental search Not working
		SendCommand_PreX("^s", "^s", "^j") ;Save or searching (because ^f is forward now)
	else if (is_target() == 6)    ;Chrome
		SendCommand_PreX("^s", "^s", "^g") 
	else
		SendCommand_PreX("^s", "^s", "^f") ;Save or searching (because ^f is forward now)
	return
	
$^w:: ;Save as or cut (because ^f is forward now)
	if (is_target() == 2) ;Word
		SendCommand_PreX("^w", "{F12}", "^x")
	else
		SendCommand_PreX("^w", "^!s", "^x") ;
	setPrefix_space("", false)  ; Disable the marker
	return

$^space:: ;Marker begins	
	global is_pre_spc
	if !is_pre_spc ; Just enable marker when it is not enabled
		setPrefix_space("^{space}", true) 
	else {
		SendCommand("^{space}", "{Up}{Down}") ; Cancel the selection, and then go to the right 
		setPrefix_space("", true) 
	}
	return

$^g:: ;Reset the marker
	setPrefix_x("", false) ; Disable the Ctrl_x 
	setPrefix_space("", false)	; Disable the marker	
	SendCommand("^g", "{Up}{Down}") ; Clear the selection (sometimes the cursor goes to a different place)
	return

;==========================
;Search "incremental in c_x"
;==========================
$^r:: 
	if (is_target() == 5) ; Eclipse reverse search reverse
		SendCommand_norm("^r", "^+j")
	else if (is_target() == 6)    ;Chrome reverse search
		SendCommand_norm("^r", "^+g") 	
	else
		SendCommand_norm("^r", "^r")
	return
	
;==========================
;Character navigation
;==========================

$^p::SendCommand_spc("^p","{Up}")

$^n::SendCommand_spc("^n","{Down}")

;$^f::SendCommand_spc("^f","{Right}")

$^b::SendCommand_spc("^b","{Left}")

;==========================
;Word Navigation
;==========================

$!{::SendCommand_spc("!p","^{Up}")

$!}::SendCommand_spc("!n","^{Down}")

$!f::SendCommand_spc("!f","^{Right}")

$!b::SendCommand_spc("!b","^{Left}")

;==========================
;Line Navigation
;==========================

$^a::SendCommand_spc("^a","{Home}")

$^e::SendCommand_spc("^e","{End}")

;==========================
;Page Navigation
;==========================

$^v::SendCommand_spc("^v","{PgDn}")

$!v::SendCommand_spc("!v","{PgUp}")

$!<::SendCommand_spc("!<","^{Home}")

$!>::SendCommand_spc("!>","^{End}")

;==========================
;Undo and Redo
;==========================

$^_::SendCommand_norm("^_","^z") ;Undo

$^+::SendCommand_norm("^_","^y") ;Redo, this is a silly helper as Emacs behaves very different for Redo

$^q::
	SendCommand_norm("","^z")
	SendCommand_norm("^q","^y")
	return
	
;==========================
;Copy, cut, paste, delete
;==========================

$^d::SendCommand_norm("^d","{Delete}") ;Delete

$!d::SendCommand_norm("!d","^+{Right}","{Delete}") ;Delete a word

$!Backspace::SendCommand_norm("!{Backspace}","^+{left}","{Delete}") ;Delete a word from the right side

$!Delete::SendCommand_norm("!{Del}","^+{Left}","{Del}") ;Delete from the right side

$^k:: ;Take the whole line and cut it
	if (is_target() == 2) {    ;Word
		SendCommand_norm("^k","+{End}+{Left}","^c") ; Copy the line minus one 
		SendCommand_norm("","+{End}+{Left}","{Delete}") ; Cut the line minus one
	}
	else {
		SendCommand_norm("^k","+{End}","^c") ; Copy the line
		SendCommand_norm("","+{End}","{Delete}") ; Cut the line
	}
	return
	
;OnClipboardChange: 
	;send, "%A_EventInfo%" ;ToolTip Clipboard data type: %A_EventInfo%"1"

$!w:: ;copy region, and reset the marker
	SendCommand_norm("!w","^c") 
	setPrefix_space("", false)
	return

$^y::SendCommand_norm("^y","^v") ;paste

;==========================
;Hot string
;==========================

;==========================
;Use x as shift
;==========================
x::Sendcommand_norm("x", "x")

x & 9::SendCommand_norm("(", "(")
x & 0::SendCommand_norm(")", ")")
x & [::SendCommand_norm("{{}}", "{{}}")
x & ]::SendCommand_norm("{}}", "{}}")
x & =::SendCommand_norm("{+}", "{+}")
x & 6::SendCommand_norm("{^}", "{^}")
x & 7::SendCommand_norm("&", "&")
x & 8::SendCommand_norm("*", "*")

x & y::SendCommand_norm("Y", "Y")
x & u::SendCommand_norm("U", "U")
x & i::SendCommand_norm("I", "I")
x & o::SendCommand_norm("O", "O")
x & p::SendCommand_norm("P", "P")
x & h::SendCommand_norm("H", "H")
x & j::SendCommand_norm("J", "J")
x & k::SendCommand_norm("K", "K")
x & l::SendCommand_norm("L", "L")
x & m::SendCommand_norm("M", "M")
x & n::SendCommand_norm("N", "N")

x & a::SendCommand_norm("A", "A")
x & s::SendCommand_norm("S", "S")
x & d::SendCommand_norm("D", "D")
x & f::SendCommand_norm("F", "F")
x & g::SendCommand_norm("G", "G")
x & q::SendCommand_norm("Q", "Q")
x & w::SendCommand_norm("W", "W")
x & e::SendCommand_norm("E", "E")
x & r::SendCommand_norm("R", "R")
x & t::SendCommand_norm("T", "T")
x & z::SendCommand_norm("Z", "Z")
x & x::SendCommand_norm("X", "X")
x & c::SendCommand_norm("C", "C")
x & b::SendCommand_norm("B", "B")

x & `::SendCommand_norm("~", "~")
x & 1::SendCommand_norm("{!}", "{!}")
x & 2::SendCommand_norm("@", "@")
x & 3::SendCommand_norm("{#}", "{#}")
x & 4::SendCommand_norm("$", "$")
x & 5::SendCommand_norm("%", "%")

; prevent the thumb to click on the wrong keys.
z::Sendcommand_norm("z", "z")
z & `::SendCommand_norm("~", "~")
z & 1::SendCommand_norm("{!}", "{!}")
z & 2::SendCommand_norm("@", "@")
z & 3::SendCommand_norm("{#}", "{#}")
z & 4::SendCommand_norm("$", "$")
z & 5::SendCommand_norm("%", "%")


x & `;::SendCommand_norm("{:}", "{:}")
x & '::SendCommand_norm("""", """")
x & ,::SendCommand_norm("{<}", "{<}")
x & .::SendCommand_norm("{>}", "{>}")
x & /::SendCommand_norm("{?}", "{?}")
x & -::SendCommand_norm("{_}", "{_}")
x & \::SendCommand_norm("{|}", "{|}")

;==========================
;Conflicting shortcuts
;==========================
$^+p:: SendCommand_norm("^+p", "^p") ; Print
$^+k:: SendCommand_norm("^+k", "^k") ; Insert a link
$^+b:: SendCommand_norm("^+b", "^b") ; Bold face
$^+i:: SendCommand_norm("^+i", "^i") ; Italicize
$^+u:: SendCommand_norm("^+u", "^u") ; Underline
$^+w:: SendCommand_norm("^+w", "^w") ; Close tab
$^+n:: SendCommand_norm("^+n", "^n") ; Open a new tab/file
$^+d:: SendCommand_norm("^+d", "^d") ; just control + d
$^+r:: SendCommand_norm("^+r", "^r") ; just control + r
$^+f:: SendCommand_norm("^+f", "^f") ; just control + f
$^+e:: 
	if (is_target() == 6)        ; Google Chrome
		SendCommand_norm("^+e", "^+e") ; Same ^+e
	else 
		SendCommand_norm("^+e", "^e") ; just control + e
	return

;==========================
;Extra keys
;==========================
$!a:: SendCommand_norm("!a", "{AppsKey}") ; Right click

$+!d::  ; ;Send date and time
FormatTime, CurrentDateTime,, M/d/yyyy h:mm tt  ; It will look like 9/1/2005 3:53 PM
SendInput %CurrentDateTime%
return
