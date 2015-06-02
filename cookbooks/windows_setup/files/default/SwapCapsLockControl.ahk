#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.

; If we are running within a VMWare virtual machine, don't swap the keys.
; This is because we have them swapped in Mac OS X, and if we swap them again in Windows we double-swap and things become weird.

IsInVMware() {
	; TODO: Possibly use DllCall to run this instead of PowerShell.
	; Exit works, but Exit-PSSession does not. This command returns 1 if we are within VMware, 0 otherwise.
	; Compatible with PowerShell 4 only.
	RunWait, powershell -Command "Exit (Get-CimInstance -Query 'SELECT Model FROM win32_computersystem').Model -eq 'VMware Virtual Platform'", , Hide
	return ErrorLevel
}

if (IsInVMware()) {
	ExitApp
}

; Swap Caps Lock and Control
Capslock::Control
Control::Capslock