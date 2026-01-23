; Number of voices to use
; UltraSound Commands
WriteVoiceMode	= 00h
SetControl	= 00H

SetVoiceFreq	= 01h           ; Value=Freq/Divisor
LoopStartLo	= 02h
LoopStartHi	= 03h
LoopEndLo	= 04h
LoopEndHi	= 05h
VolumeRampRate	= 06h
VolumeRampStart	= 07h
VolumeRampEnD	= 08h
SetVol		= 09h
SampleStartLo	= 0Ah
SampleStartHi	= 0Bh
VoiceBalance	= 0Ch
VolumeControl	= 0Dh
VoicesActive	= 0Eh
DMACtrl		= 41h
DRAMAddrLo	= 43h
DRAMAddrHi	= 44h
Timer_Control	= 45h
Timer1		= 46h
Timer2		= 47h
InitializE	= 4Ch
;
GetControl	= 80h
ReadVolume	= 89h
VoicePosLo	= 8Ah
VoicePosHi	= 8Bh
GetVolumeControl = 8DH
SetVolumeControl = 0Dh

CurrDivisor	DD 44100		; max freq (44100hz)
;
BasePort        dw 220h
StatusPort      dw 220h+6h
TimerPort	dw 220h+8h
TimerDataPort	dw 220h+9h
Gf1IRQcontrol	dw 220h+0Bh
ActiveVoicePort	dw 220h+102h
CommandPort	dw 220h+103h
DataLowPort	dw 220h+104h
DataHighPort	dw 220h+105h
DRAMIOPort	dw 220h+107h
;
GusIRQ		dw	11
GusMIDIIrq	dw	7		; same as SB IRQ
;
Divisors = this dword
dd	41160		; 15 voices
dd	38588		; 16 voices	.. this is the limit..:(
