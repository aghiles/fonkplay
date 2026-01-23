; Main .asm module.
; warning, badly commented code :)

        .386
        .Model flat
        Jumps

.Code

; Public Functions
Public  LoadModule,StartP,HaltP,InitGus
Public  GetPointers,GetInfos,SetInfos,GetChanNum

; Public Variables

; Constants

PlayNote        = 2
StopNote        = 1
DoNothing       = 0             ; just relax and wait a note.

; Structures
include STRUCS.ASM

; Macros
include MACROS.ASM

; Data
include         GUS.INC
include         TABLES
;
align 16
NumChans                dd      4       ; (1..16)
Timer2Speed             dw      20
Speed                   dw      0       ; should do a structure for all this crap.
Tempo                   db      0
TempoWait               db      0
PlayerSpeed             db      0
SkipFactor              db      0
CurrentFactor           db      0
NumVoices               db      14      ; Active GUS voices (14,15 or 16)
Limits                  dw      2 dup (0)
;
Row_In_Pattern          dw      0
CurrentOrder            dw      0
BreakToRow              db      -1
PatternOffset           dd      0
EmptyPattern            db      FALSE  ; if TRUE then playing an empty pattern
;
MainVolume              dw      8
;
SampChans               ChanInfo 16 dup (<>)
;
getting_notes           db FALSE        ; TRUE when getting a note.
s3mPlaying              db FALSE        ; TRUE when playing
;
PatternDelayCounter     db      0       ; Q: what is that?
PatternDelayed          db      0       ; A: beuh, i don't know.
;
; I hate stacks...
align 16
eaxSave                 dd      0
ebxSave                 dd      0
edxSave                 dd      0
ecxSave                 dd      0
esiSave                 dd      0
ediSave                 dd      0
ebpSave                 dd      0
;
;----------------------------------------
PlaySamples     Proc    Near
;----------------------------------------
        _SaveRegs                       ; this is a MACRO (see MACROS.ASM)
        ;                               ; not recomanded to use PUSHAD here
        mov     al,2
        call    StopGusTimer            ; Stop Timer #2
even
PlayNotes:                              ; or stop them.. heh
        mov     [getting_notes],FALSE
        mov     edi,offset SampChans     ; Start with the first Channel
        mov     ecx,[NumChans]
        movzx   edx,[CommandPort]
UpdateChannels:
        test    [edi.ChanFlag],128
        jnz     Ahem2                   ; Chanel disabled
ChannelOn:
        ;
        dec     edx                      ; Active Voice Port
        mov     eax,[NumChans]
        sub     eax,ecx
        out     dx,al                   ; Set the active voice
        inc     edx                      ; dx = command port again.
        ;
        cmp     [edi.SampleOperation],DoNothing
        je      SetChannelFrequency     ; and volume
        ;
PlaySample:
        call    StopVoice               ; Stop Current Voice.Already faded down
        cmp     [edi.SampleOperation],StopNote
        je      Ahem2                   ; AHEM!
        ;
        ; dx = command port
        mov     al,VoiceBalance
        out     dx,al
        mov     al,[edi.Chan_Side]
        add     dl,2                    ; dx = data high port
        out     dx,al
        sub     dl,2                    ; dx = command port
        ;
        test    [edi.ChanFlag],64       ; must we output some shit to the GUS?
        jz      psNoMerde
        ;-----------------------------------------------
        ; Set sample Start&End offsets + Loop Start&End offsets
        Call    SetVoiceParams
        ;-----------------------------------------------
psNoMerde:
        mov     [edi.SampleOperation],DoNothing  ; played..
        mov     [edi.OffsetAdd],0                ; no more offsetadd effect
        ; dx = command port
        mov     al,WriteVoiceMode
        out     dx,al
        add     dl,2                    ; dx = data high port
        mov     al,[edi.LoopBOOL]        ; Looped?
        out     dx,al
        call    UDelay
        out     dx,al
        sub     dl,2                    ; dx = command port
        ;
SetChannelFrequency:
        push    edx
        call    GetGusVolume
        ; bx = [edi.Gus_Volume] = Gus Volume
        push    ecx                      ; save voices counter
        mov     ecx,03FH                 ; rate (very fast)
        call    RampVolume               ; Set Voice volume by ramping.
        pop     ecx
        pop     edx
        ;
        mov     al,SetVoiceFreq
        out     dx,al
        inc     edx
        cmp     [edi.Effect],0           ; do we have an effect? (no please)
        jne     Ahem1                    ; yes.
        mov     bp,[edi.NotePeriod]      ; no.
        call    GetGusFreq
Ahem1:  mov     ax,[edi.FreqVal]
        out     dx,ax
        dec     edx
        ; dx = command port
Ahem2:  add     edi,size ChanInfo        ; Next channel
        dec     ecx
        jnz     UpdateChannels          ; if any ...
        ;
psExit: _RestoreRegs
        ret
        ENDP

;------------------------------------------------
UpdateEffects   Proc    Near
;------------------------------------------------
        _SaveRegs                       ; this is a macro...;^)
        ;                               ; see "macros.asm"
        mov     al,[SkipFactor]         ; for Speeds under 030H
        add     [CurrentFactor],al
        jc      psExit
        ;
        mov     al,1                    ; Timer #1
        mov     cx,[Speed]              ; and it's speed.
        call    StartGustimer           ; Update Timer #1 stuff
        ;
        dec     [TempoWait]             ; wait another blouche? (tick)
        jle     GetNewNotes             ; Nah.
DoEffects:
        cmp     [EmptyPattern],TRUE
        je      psExit
        mov     edi,offset SampChans
        mov     ecx,[NumChans]
EffectLoop:
        push    cx
        test    [edi.ChanFlag],128       ; Check if this channel is on
        jnz     NoEffect
        inc     [edi.EffectTime]
        movzx   ebx,[edi.Effect]          ; for real coders only.
        dec     bx
        jl      NoEffect
        mov     al,[edi.EfxParam]
        call    dword ptr EffectJumps[ebx*4]     ; blouche again.
NoEffect:
        pop     cx
        add     edi,Size ChanInfo
        dec     cx
        jnz     EffectLoop              ; Loop until done with all channels
        jmp     EndPattern              ; jump somewhere.
;----------------------------------------
GetNewNotes:
        mov     [getting_notes],TRUE    ; what is true?
        mov     al,[Tempo]
        mov     [TempoWait],al
        ;
        ; Here I check if the current pattern is empty.
        cmp     [EmptyPattern],TRUE     ; is he?
        jne     gnnOkPattern            ; Nah
        inc     [Row_In_Pattern]        ; yes.
        cmp     [Row_In_Pattern],64
        jne     gnnExit
        mov     [EmptyPattern],FALSE
        jmp     gnnOkPattern
gnnExit:jmp     psExit
gnnOkPattern:
        ; And here, I check if there is a PatternDelay
        mov     [PatternDelayed],0
        cmp     [PatternDelayCounter],0
        je      NoPatternDelay
        mov     [PatternDelayed],1
        dec     [PatternDelayCounter]
        jmp     ProcessVoices
NoPatternDelay:
        ;
        ; Check if we must go to next pattern
        cmp     [Row_In_Pattern],64
        jb      NoPatternWrap           ; everything is ok.
        ;
        ; If so, we reset the row to 0 and get the next pattern
        mov     [Row_In_Pattern],0
        inc     [CurrentOrder]
NoOrderWrap:
        movzx   ebx,[CurrentOrder]
        mov     dl,[PattOrder+ebx]
        cmp     dl,-1                   ; 255? end of tune
        jne     NotEndOfTune            ; phew.
        mov     [CurrentOrder],0        ; nooo.
        jmp     NoOrderWrap
NotEndOftune:
        cmp     dl,-2                   ; 254? skip marker.
        jne     GoodOrder
        inc     [CurrentOrder]
        jmp     NoOrderWrap
GoodOrder:
        ;
        cmp     dl,byte ptr [s3mHeader.s3mPatNum]
        jb      GoodPatternNum
        mov     [EmptyPattern],TRUE
GoodPatternNum:
        ; if the played pattern is empty we set EmptyPattern to TRUE
        movzx   edx,dl
        mov     eax,PatternPointer[edx*4]
        cmp     eax,PatternPointer[edx*4+4]
        jne     GoodPatternLength
        mov     [EmptyPattern],TRUE     ; EMPTY pattern
GoodPatternLength:
        mov     [PatternOffset],eax     ; Offset Of the Pattern
NoPatternWrap:
        ; Reset all channels.
        mov     edi,offset SampChans
        mov     ecx,[NumChans]
        xor     edx,edx                   ; saves some bytes ltr..
ResetChannels:
        mov     al,[edi.Effect]
        mov     [edi.LastEfx],al
        mov     [edi.Effect],dl
        mov     [edi.EfxParam],dl
        mov     [edi.OffsetAdd],dx
        mov     [edi.EffectTime],dl
        mov     [edi.NoteBool],DoNothing
        mov     [edi.SampleOperation],DoNothing
        add     edi,size ChanInfo
        dec     ecx
        jnz     ResetChannels
        ;
        ; Make esi point to packed pattern data and process Cxx effect if
        ; needed
        mov     esi,[PatternsSeg]
        add     esi,[PatternOffset]
        ;
        cmp     [BreakToRow],-1         ; fot effect B00
        je      PattLoop
        ; we must skip some rows because a Cxx effect was specified.
        movzx   cx,byte ptr [BreakToRow]
        mov     [Row_In_Pattern],cx
        mov     [BreakToRow],-1
        or      cx,cx
        je      PattLoop
SkipRowsLoop:
        mov     al,[esi]
        inc     esi
        or      al,al
        je      RowSkipped
        test    al,32
        jz      bNoNote
        inc     esi                      ; skip NOTE
        inc     esi                      ; skip INSTRUMENT
        bNoNote:
        test    al,64
        jz      bNoVolume
        inc     esi                      ; skip volume
        bNoVolume:
        test    al,128
        jz      SkipRowsLoop
        inc     esi                      ; skip COMMAND
        inc     esi                      ; skip INFO
        jmp     SkipRowsLoop
RowSkipped:
        dec     cx
        jnz     SkipRowsLoop            ; that's all.

        ; This loop will read notes/volumes/effects from the packed pattern
        ; data
PattLoop:
        mov     ah,[esi]                ; Load 1s byte
        mov     ch,ah                   ; save it for ltr.
        or      ah,ah                   ; end of row?
        je      EndTracks
        ;
        and     eax,01F00H              ; Get channel number
        shr     ax,8
        imul    eax,size ChanInfo
        lea     edi,[SampChans+eax]     ; fonky 386. i like you.
        and     [edi.ChanFlag],not 64
        ;
        mov     ah,ch
        and     ah,011100000b
        jnz     GoodInfo
        mov     [edi.SampleOperation],DoNothing
        jmp     NextTrack
GoodInfo:
        ; reset channel infos
        test    ch,32                   ; test for NOTE bit
        jz      GetVolume
        or      [edi.ChanFlag],64
        inc     esi
        mov     al,[esi]
        cmp     al,254
        jae     GetInstrument
GoodNote:
        mov     [edi.s3mNote],al                 ; Save Note
        mov     ax,PlayNote
        mov     [edi.SampleOperation],al         ; There is a note..so Play it
        mov     [edi.NoteBool],al
        mov     [edi.VolumeBar],al               ; Kick the volume bar
        mov     [edi.VibratoIndex],ah            ; Reset Vibrato Index (ah=0)
        mov     [edi.ArpIndex],ah                ; Reset Arpeggio Index
        ;
GetInstrument:
        inc     esi                              ; next byte (instrument)
        mov     bl,[esi]                         ; bl = instrument
        or      bl,bl
        je      GetVolume                        ; if (bl=0) then there is no instrument
        mov     [edi.CurrSamp],bl
        dec     bx
        movzx   eax,bl
        imul    eax,smpSize                      ; Get instrument header offset
        mov     ebx,eax
        add     ebx,[SampHeadersSeg]
        mov     [edi.SampHeader],ebx
        mov     al,[ebx.smpVol]                  ; load the volume of this sample
        mov     [edi.Volume],al
        mov     ax,word ptr [ebx.smpC2Spd]
        mov     [edi.BasePeriod],ax
        mov     [edi.LoopBOOL],8         ; enable looping
        cmp     [ebx.smpFlag],0
        jne     GetVolume
        mov     [edi.LoopBOOL],0         ; disable looping
        ;
GetVolume:
        test    ch,64                    ; Test for VOLUME bit
        jz      ReadEfx
        inc     esi
        mov     al,[esi]
        mov     [edi.Volume],al
        ;
ReadEfx:cmp     [edi.SampleOperation],PlayNote   ; do we have a new note
        jne     NoCalc
        push    cx
        ;
        mov     al,[edi.s3mNote]        ; if yes, then calc.the periode
        movzx   ebp,[edi.BasePeriod]
        call    CalcS3Mnote             ; we can't do it before because
        call    ClipPeriod              ; amiga limits..etc.
        mov     ax,[edi.NotePeriod]     ; we don't have the base Period
        mov     [edi.OldNotePeriod],ax
        mov     [edi.NotePeriod],bp
        call    GetGusFreq
        pop     cx
NoCalc: test    ch,128                ; Test for EFFECT bit
        jz      NextTrack
        inc     esi
        mov     al,[esi]              ; Get Effect
        mov     [edi.Effect],al
        cmp     al,[edi.LastEfx]
        je      NoFreqRestart
        mov     bp,[edi.NotePeriod]
        call    GetGusFreq
NoFreqrestart:
        inc     esi
        mov     al,[esi]              ; Get Effect Parameter
        mov     [edi.EfxParam],al
        or      al,al
        jnz     BadBad
        mov     al,[edi.LastEfxParam]
BadBad: mov     [edi.LastEfxParam],al
NextTrack:
        inc     esi                      ; next byte in packed pattern.
        jmp     PattLoop
EndTracks:
        inc     [Row_In_Pattern]        ; Next row in this pattern
        inc     esi
        sub     esi,[PatternsSeg]
        mov     [PatternOffset],esi     ; Next entry.
ProcessVoices:

        mov     edi,offset SampChans
        mov     ecx,[NumChans]
FadeVoicesForMoreClicks:
        push    cx
        test    [edi.ChanFlag],128
        jnz     NoRowEffect
        movzx   ebx,[edi.Effect]
        dec     bx
        jl      NoRowEffect
        mov     al,[edi.EfxParam]
        call    dword ptr PattJumps[ebx*4]               ; Call the effect
NoRowEffect:
        cmp     [edi.SampleOperation],PlayNote
        jne     DoNotRamp
        mov     dx,[CommandPort]
        dec     dx                     ; Active Voice Port
        xor     eax,edx
        mov     eax,[NumChans]
        sub     eax,ecx
        out     dx,al                   ; Set the active voice
        xor     bx,bx
        mov     cl,02Fh
        call    RampVolume              ; Ramp -> 0
        DoNotRamp:
        pop     cx
        add     edi,ChannelSize
        dec     cx
        jnz     FadeVoicesForMoreClicks
        ;
        mov     [getting_notes],FALSE
EndPattern:
        ;
        cmp     [PatternDelayed],1
        je      upExit                  ; Do not trigger the notes if we
        mov     ax,2                    ; are in a pattern delay
        mov     cx,[Timer2Speed]
        call    StartGusTimer
upExit: jmp     psExit                  ; Go up.
        ENDP

;----------------------------------
StartP  Proc    Near
;----------------------------------
        cli
        mov     [TempoWait],1
        mov     [Row_In_Pattern],64
        mov     [CurrentOrder],-1
        ;
        mov     ax,[GUSIrq]             ; GF1 IRQ
        mov     cx,[GUSMIDIIrq]         ; MIDI IRQ (not used currently)
        call    SetIrqs
        call    SetVector
        ;
        mov     al,1                    ; Timer #1
        mov     cx,[Speed]
        call    StartGusTimer
        ;
        mov     dx,[BasePort]           ; Output ON.
        mov     al,00001001b
        out     dx,al
        ;
        mov     [s3mPlaying],TRUE
        sti
        ret
        StartP  EndP
;----------------------------------------
HaltP   Proc    Near                    ;
;----------------------------------------
        cmp     [s3mPlaying],TRUE
        jne     hpExit
        cli
        mov     [s3mPlaying],FALSE
        mov     dx,[BasePort]        ; Speakers Off.
        mov     al,00000011b
        out     dx,al
        ;
        call    ResetIrqs
        call    ResetVector
        ;
        mov     dx,[ActiveVoicePort]
        movzx   ecx,[NumVoices]
        VoiceClearL:
        mov     al,cl
        dec     al
        out     dx,al
        inc     dx
        sub     al,al
        out     dx,al
        add     dx,2
        mov     al,3            ; Voice Off
        out     dx,al
        sub     dx,2
        mov     al,VolumeControl
        out     dx,al
        add     dx,2
        mov     al,3            ; Ramp Off
        out     dx,al
        sub     dx,3
        loop    VoiceClearL
        ;
        call    DeAlloc         ; free used memory
        ;
        sti
hpExit: ret
        ENDP
        ;
include SERVER.ASM              ; useful interfacing functions
include JUMPS.ASM               ; offsets table
include EFX.ASM                 ; Effects processing
include INIT.ASM                ; GUS init functions.
include MISC.ASM                ; Various functions (volume,freq,autodetect..)
include TIMER.ASM               ; GUS timer functions.
include S3MLOAD.ASM             ; S3M loading functions.
        ENDS
                End
