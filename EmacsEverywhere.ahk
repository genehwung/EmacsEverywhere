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
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

enabledIcon := "EmacsEverywhere_on.ico"
disabledIcon := "EmacsEverywhere_off.ico"
IsInEmacsMode := false
SetEmacsMode(true)

is_pre_x := false ; turns to be true when ctrl-x is pressed
is_pre_spc := false ; turns to be true when ctrl-space is pressed

key_lst := ""

;==========================
;Functions
;==========================
is_target() {
  IfWinActive,ahk_class ConsoleWindowClass ; Cygwin
    Return 1 
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
   IfWinActive,ahk_class Emacs ; NTEmacs
     Return 1  
   IfWinActive,ahk_class XEmacs ; XEmacs on Cygwin
     Return 1
  IfWinActive,ahk_class OpusApp ; Word
    Return 2
  IfWinActive,ahk_class ENMainFrame ; Evernote
    Return 3
  IfWinActive,ahk_class SunAwtFrame ; MATLAB
	Return 4	 ;TrayTip, Emacs Everywhere, Emacs mode is %state%, 10, 1    
  IfWinActive,ahk_class SWT_Window0 ; Eclipse
    Return 5
  else
	Return 0
	
;   IfWinActive,ahk_class Xming X
;     Return 1
;   IfWinActive,ahk_class SunAwtFrame
;     Return 1
}

SetEmacsMode(toActive) {
  local iconFile := toActive ? enabledIcon : disabledIcon
  local state := toActive ? "ON" : "OFF"

  if (IsInEmacsMode != toActive) {
	  IsInEmacsMode := toActive
	  ; TrayTip, Emacs Everywhere, Emacs mode is %state%, 10, 1
	  Menu, Tray, Icon, %iconFile%,
	  ; Menu, Tray, Tip, Emacs Everywhere`nEmacs mode is %state%  

	  Send {Shift Up}
  }
}

SendCommand(emacsKey, translationToWindowsKeystrokes, secondWindowsKeystroke="") {
  global IsInEmacsMode
  ;if is_target() 
	;SetEmacsMode(false)
  ;else
	;SetEmacsMode(true)  
  if (IsInEmacsMode) {
    Send, %translationToWindowsKeystrokes%
    if (secondWindowsKeystroke<>"") {
      Send, %secondWindowsKeystroke%
    }
	global key_lst = translationToWindowsKeystrokes . secondWindowsKeystroke			
  } else {
    Send, %emacsKey% ;passthrough original keystroke
  }
  return
}

SendCommand_spc(emacsKey, translationToWindowsKeystrokes) {
	global is_pre_spc
  
	if (is_pre_spc) {
		SendCommand(emacsKey, "+" . translationToWindowsKeystrokes) ; Concatenate string
	}
	else {
		SendCommand(emacsKey, translationToWindowsKeystrokes)
	}	
	return
}

SendCommand_PreX(emacsKey, translationToWindowsKeystrokes, alternativeKeystrokes) {
	global is_pre_x	  
	if (is_pre_x) {
		SendCommand(emacsKey, translationToWindowsKeystrokes)
		setPrefix_x(emacsKey,false)
	}
	else {
		SendCommand(emacsKey, alternativeKeystrokes)
	}	
	return
}

setPrefix_x(emacsKey,toActive) {
	global is_pre_x := toActive
	SendCommand(emacsKey,"")
	return
}
  
setPrefix_space(emacsKey,toActive) {
	global is_pre_spc := toActive
	SendCommand(emacsKey,"")
	return
}
  
;==========================
;Emacs mode toggle
;==========================
CapsLock::
  SetEmacsMode(!IsInEmacsMode)
return

;==============================
;Things starting with ^X or Space
;==============================
$^x::setPrefix_x("^x", true) ;Ctrl X is just typed

$h::SendCommand_PreX("h", "^a", "h") ;Select all
	
$^s:: ; Save or search
	if (is_target() == 4)        ; Matlab incremental search
		SendCommand_PreX("^s", "^s", "^s") ;Save or searching (because ^f is forward now)
	else if (is_target() == 3)    ;Evernote
		SendCommand_PreX("^s", "{F9}", "^f") 
	else if (is_target() == 5)          ; Eclipse incremental search
		SendCommand_PreX("^s", "^s", "^j") ;Save or searching (because ^f is forward now)
	else
		SendCommand_PreX("^s", "^s", "^f") ;Save or searching (because ^f is forward now)
	return
	
$^w:: ;Save as or cut (because ^f is forward now)
	if (is_target() == 2) ;Word
		SendCommand_PreX("^w", "{F12}", "^x")
	else
		SendCommand_PreX("^w", "^!s", "^x") ;
	setPrefix_space("!space", false)  ; Disable the marker
	return

$^space:: ;Marker begins
	global is_pre_spc
	if !is_pre_spc ; Just enable marker when it is not enabled
		setPrefix_space("^space", true) 
	else {
		SendCommand("", "{Up}{Down}") ; Cancel the selection, and then go to the right 
		setPrefix_space("^space", true) 
	}
	return

$^g:: ;Reset the marker
	setPrefix_x("^g", false) ; Disable the Ctrl_x 
	setPrefix_space("", false)	; Disable the marker	
	SendCommand("", "{Up}{Down}") ; Clear the selection (sometimes the cursor goes to a different place)
	return

;==========================
;Search "incremental in c_x"
;==========================
$^r:: 
	if (is_target() == 5) ; Eclipse reverse search reverse
		SendCommand("^r", "^+j")
	else
		SendCommand("^r", "^r")
	
;==========================
;Character navigation
;==========================

$^p::SendCommand_spc("^p","{Up}")

$^n::SendCommand_spc("^n","{Down}")

$^f::SendCommand_spc("^f","{Right}")

$^b::SendCommand_spc("^b","{Left}")

;==========================
;Word Navigation
;==========================

$!p::SendCommand_spc("!p","^{Up}")

$!n::SendCommand_spc("!n","^{Down}")

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

$^_::SendCommand("^_","^z") ;Undo

$^+::SendCommand("^_","^y") ;Redo, this is a silly helper as Emacs behaves very different for Redo

;==========================
;Copy, cut, paste, delete
;==========================

$^d::SendCommand("^d","{Delete}") ;Delete

$!d::SendCommand("!d","^+{Right}","{Delete}") ;Delete a word

$!Delete::SendCommand("!{Del}","^+{Left}","{Del}") ;Delete from the right side

$^k:: ;Take the whole line and cut it
	SendCommand("^k","+{End}","^c") ; Copy the line	
	SendCommand("","+{End}","{Delete}") ; Cut the line
	return
	
;OnClipboardChange: 
	;send, "%A_EventInfo%" ;ToolTip Clipboard data type: %A_EventInfo%"1"

$!w:: ;copy region, and reset the marker
	SendCommand("!w","^c") 
	setPrefix_space("!space", false) 
	return

$^y::SendCommand("^y","^v") ;paste

;==========================
;Hot string
;==========================

;==========================
;Send date and time
;==========================
$+!d::  ; This hotstring replaces "shift+alt+d" with the current date and time via the commands below.
FormatTime, CurrentDateTime,, M/d/yyyy h:mm tt  ; It will look like 9/1/2005 3:53 PM
SendInput %CurrentDateTime%
return
