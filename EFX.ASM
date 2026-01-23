; This is not an EFFECT!!
even
ClipVolume:
        cmp     [edi.Volume],0
        jge     cvNotLow
        mov     [edi.Volume],0
cvNotLow:
        cmp     [edi.Volume],64
        jle     cvNotHigh
        mov     [edi.Volume],64
cvNotHigh:
        ret

;((((((((((((((((((((((((( One call effect ))))))))))))))))))))))))))))
;-------------------------------------- Effect A
even
SetTempo:
        or      al,al
        jz      stExit
        mov     [Tempo],al
        mov     [TempoWait],al
stExit: ret
even
;-------------------------------------- Effect B
PosJump:xor     ah,ah
pj1:    cmp     ax,[s3mHeader.s3mOrdNum]
        jbe     pjNoClip
        mov     ax,[s3mHeader.s3mOrdNum]
pjNoClip:
        dec     ax
        mov     [CurrentOrder],ax
        mov     [Row_In_Pattern],64
        ret
;-------------------------------------- Effect C
even
BreakPatt:
        mov     ah,al
        and     al,0FH
        shr     ah,4
        aad
        cmp     al,63
        ja      Dummy                   ; no effect if > 63
        mov     [BreakToRow],al         ; will be handled in FPLAY.ASM
        mov     [Row_In_Pattern],64
Dummy:  ret
;-------------------------------------- Effect D
even
VolumeComs:
        or      al,al
        jnz     vcGoodParam
        mov     al,[edi.OldVolSlide]
vcGoodParam:
        mov     [edi.OldVolSlide],al
VolumeComs2:
        ;
        cmp     al,0FH
        je      VSD
        cmp     al,0F0H
        je      VSU
        ;
vcNoException:
        cmp     [getting_notes],FALSE
        je      vcNoFine
        mov     dl,al
        rol     dl,4
        or      dl,al           ; if DL = 0FFH then it's a fine volume up/down
        inc     dl
        jnz     vcNotFine       ; go try SLIDE volume effect if not.
        ; if you can't understend the following code, i understend you.
vcSuperCode:
        mov     dl,al
        and     dl,0FH
        cmp     dl,0FH
        je      VSU
        jmp     VSD
vcNotFine:
        test    [s3mHeader.s3mFlags],64 ; Volume slides on first row?
        jz      vcExit                  ; No, exit.
vcNoFine:
        mov     dl,al
        rol     dl,4
        and     dl,al           ; if DL = 0 then volume slide up/down
        jnz     vcExit
        ;
        mov     dl,al
        and     dl,0F0H
        jnz     VSU
VSD:    and     al,0FH
        sub     [edi.Volume],al          ; Volume Slide Down
        jmp     ClipVolume
VSU:    shr     al,4
        add     [edi.Volume],al
        jmp     ClipVolume
vcExit: ret
;---------------------------------------- Effect E
even
SlideComs:
Comment &
        This function uncludes:
                Slide Down
                Fine Slide Down
                Extra Fine Slide Down (4 times slower)
                Slide Up
                Fine Slide Up
                Extra Fine Slide Up (4 times slower)
        Fonkuh, this function is a moton of conditional jumps..
        &
        or      al,al
        jnz     scGoodParam
        mov     al,[edi.OldSlide]
scGoodParam:
        mov     [edi.OldSlide],al
        mov     bp,[edi.NotePeriod]
        mov     dl,al
        shr     dl,4
        cmp     [getting_notes],0
        je      scNoFineSlide
        cmp     dl,0FH
        je      FSDU
        cmp     dl,0EH
        je      EFSDU
        jmp     scExit
scNoFineSlide:
        cmp     al,0DFH
        ja      scExit
SDU:    and     ax,000FFH
        shl     ax,2
SDU2:   cmp     [edi.Effect],'F'-'A'+1
        jne     seNotUp
        neg     ax                      ; do a  Slide UP!
seNotUp:add     bp,ax
        jmp     scExit
FSDU:   and     al,0FH
        jmp     SDU
EFSDU:  and     ax,0FH
        jmp     SDU2                    ; do not multiply by 4
scExit: call    ClipPeriod
        mov     [edi.NotePeriod],bp
        jmp     GetGusFreq
;---------------------------------------- Effect G init
even
PortToInit:
        or      al,al
        jnz     ptiGoodPar
        mov     al,[edi.OldPortTo]
ptiGoodPar:
        mov     [edi.OldPortTo],al
        cmp     [edi.SampleOperation],PlayNote
        jne     viExit                  ; just a "ret" instruction
        mov     [edi.SampleOperation],DoNothing  ; Do not play the note.
        mov     bp,[edi.NotePeriod]
        mov     [edi.PortEnd],bp
        mov     bp,[edi.OldNotePeriod]
        mov     [edi.PortStart],bp
        jmp     GetGusFreq
;-------------------------------------- Effect H init
even
VibratoInit:
        mov     dl,[edi.LastEfx]
        cmp     dl,'H'-'A'+1            ; Vibrato?
        je      viExit                  ; do not reset
        cmp     dl,'K'-'A'+1            ; Vibrato + VolumeSlide
        je      viExit                  ; do not reset
        cmp     dl,'U'-'A'+1            ; Fine Vibrato?
        je      viExit                  ; Continue on vibrato!
        mov     [edi.VibratoIndex],0     ; Reset wave index
viExit: ret
;-------------------------------------- Effect I init
even
TremorInit:
        mov     [TremorOnOff],0
        or      al,al
        jnz     tiiExit
        mov     al,[edi.OldTremor]
tiiExit:mov     [edi.OldTremor],AL
        ret
;--------------------------------------- Effect J init
even
ArpeggioInit:
        or      al,al
        jnz     aiNewArpeggio
        mov     al,[edi.OldArpeggio]     ; ST3 Bug! (see FPLAY.TXT)
aiNewArpeggio:
        mov     [edi.OldArpeggio],al
        ;
        push    cx                      ; save CX, because we'll kill it ltr
        xor     cx,cx
        sub     ah,ah
        mov     cl,al                   ; al = param
        mov     bl,al                   ; save it twice.
        mov     al,[edi.s3mNote]        ; Get note number
        mov     dl,al
        and     dl,0F0H                 ; dl = Octave (mask octave)
        and     al,00FH                 ; ax = Note (mask note)
        push    ax dx
        shr     cl,4                    ; Get First param.(cl = al = arp param)
        add     al,cl                   ; add
aiOL:   cmp     al,12                   ; maximum number of notes = 12
        jb      aiNoOctaveFix
        sub     al,12                   ; save note but
        add     dl,010H                 ; Next Octave
        jmp     aiOL                    ; in case
aiNoOctaveFix:
        or      al,dl                   ; NOTE || OCTAVE
        movzx   ebp,[edi.BasePeriod]
        call    CalcS3Mnote             ; returns frequency in BP.
        call    ClipPeriod
        mov     [edi.Arp+2],bp
        pop     dx ax
        and     bl,0FH                  ; Get Second param.
        add     al,bl
aiOL2:  cmp     al,12                   ; Octave loop
        jb      aiNoOctaveFix2
        sub     al,12
        add     dl,010H                 ; Next Octave
        jmp     aiOL2                   ; in case
aiNoOctaveFix2:
        or      al,dl                   ; NOTE || OCTAVE
        movzx   ebp,[edi.BasePeriod]
        call    CalcS3Mnote
        call    ClipPeriod
        mov     [edi.Arp+4],bp
        mov     bp,[edi.NotePeriod]
        mov     [edi.Arp],bp            ; First arp frequence = current frequence
        mov     [edi.ArpIndex],0        ; 0 , 2 or 4 (3 freqs).
        pop     cx
aiExit: ret
;-------------------------------------- Effect L init
even
PVSlideInit:
        push    ax
        xor     ax,ax
        call    PortToInit
        pop     ax
        cmp     al,0F0H
        je      psiExit
        cmp     al,0FH
        jne     VolumeComs2
psiExit:ret
;--------------------------------------- Effect O
even
SampleOff:
        or      al,al
        jnz     soGoodParam
        mov     al,[edi.LastEfxParam]
soGoodParam:
        shl     ax,8                    ; (param) * 256
        mov     [edi.OffsetAdd],ax
        or      [edi.ChanFlag],64
soExit: ret
;-------------------------------------- Effect Q init
even
Retriginit:
        or      al,al
        jnz     riiGoodParam                    ; riExit already exists...:)
        mov     al,[edi.OldRetrig]
riiGoodParam:
        mov     [edi.OldRetrig],al
        cmp     [edi.LastEfx],'Q'-'A'+1  ; is ther a note on this row?
        jne     riiExit
        mov     dh,al
        and     dh,0FH
        mov     [edi.EffectTime],dh
riiExit:jmp     Retrig
;--------------------------------------- Effect R init
even
TremoloInit:
        cmp     [edi.LastEfx],'R'-'A'+1  ; Tremolo? (#12H, effect R)
        je      tiExit                  ; do not reset
        mov     [edi.VibratoIndex],0     ; reset wave index.
tiExit: ret
;--------------------------------------- Effect T
SpeedSet:
        cmp     al,020H
        jbe     EffectEnd       ; range = [021H..0FFH]
        mov     [SkipFactor],0
        mov     [CurrentFactor],0
        push    bx
        mov     [PlayerSpeed],al
        cmp     al,125
        jae     ssGoodForGus
        add     al,al
        mov     [SkipFactor],080H
ssGoodForGus:
        xor     bx,bx
        mov     bl,al
        mov     ax,125*125
        cwd                     ;
        div     bx              ; Gus Timer Count = (125*125 / BPM )
        add     ax,ax
        mov     [Speed],ax
        pop     bx
EffectEnd:
        ret
;----------------------------------------
even
SetGlobalVol:
        cmp     al,64
        ja      sgvExit                         ; clip
        mov     byte ptr [MainVolume],al        ; Set Volume
sgvExit:ret
;((((((((((((((((( "Multi-Call" EFFECTS )))))))))))))))))))
even
Arpeggio:                                       ; Effect J
        push    ebx
        movzx   ebx,[edi.ArpIndex]
        mov     bp,word ptr [edi.Arp+ebx*2]
        call    GetGusFreq
        inc     bx
        cmp     bl,2
        jbe     aNoArpClip
        xor     bx,bx
aNoArpClip:
        mov     [edi.ArpIndex],bl        ; 0,1 or 2.
        pop     ebx
        ret
;---------------------------------------- PortToTone + Volume Slide (L)
even
TonePortVSlide:
        or      al,al
        jnz     tpvsGoodParam
        mov     al,[edi.OldPortTo_L]
tpvsGoodParam:
        mov     [edi.OldPortTo_L],al
        call    VolumeComs2
;---------------------------------------- PortToTone    (G)
even
PortToTone:
        mov     al,[edi.OldPortTo]       ; set in PortToInit
        mov     ah,0
        shl     ax,2                    ; x4 wow.
        mov     dx,[edi.PortEnd]
        mov     bx,dx
        mov     bp,[edi.PortStart]
        ;
        sub     bx,bp           ; difference between the 2 periods
        jge     pttNotNeg
        neg     bx
pttNotNeg:
        cmp     ax,bx           ; Check if (DeltaPeriod < PortSpeed)
        jae     pttCompleted
        ;
        cmp     bp,dx
        jne     pttContinuePort
pttCompleted:
        mov     bp,dx
        jmp     pttSetPort
pttContinuePort:
        ja      pttPortToUp
        add     bp,ax
        cmp     bp,dx
        jb      pttSetPort
        jmp     pttCompleted
pttClipPort:
        mov     bp,dx
        jmp     pttCompleted
pttPortToUp:
        sub     bp,ax
        cmp     bp,dx
        jbe     pttCompleted
pttSetPort:
        call    ClipPeriod
        mov     [edi.PortStart],bp
        mov     [edi.OldNotePeriod],bp
        mov     [edi.NotePeriod],bp
        jmp     GetGusFreq
;---------------------------------------- Vibrato + Volume Slide
even
VibratoVSlide:
        or      al,al
        jnz     vvsGoodParam
        mov     al,[edi.OldVibrato_K]
vvsGoodParam:
        mov     [edi.OldVibrato_K],al
        call    VolumeComs2
        mov     al,[edi.OldVibrato]
;---------------------------------------- Vibrat + Fine Vibrato. 2 in 1. :)
even
Vibrato:xor     ebx,ebx
        cmp     [edi.Effect],'U'-'A'+1   ; Fine Vibrato ?
        sete    bl                      ; bx = 1 if so
        mov     dl,al
        or      al,al
        jnz     vNewVibrato
        mov     al,[edi.OldVibrato+ebx]   ; vibrato or fine vibrato (H/U)
        mov     dl,al
vNewVibrato:
        shr     dl,4
        or      dl,dl                   ; Speed == 0 ???
        jnz     GoodSpeed
        mov     dh,[edi.OldVibrato+ebx]   ; vibrato or fine vibrato (H/U)
        and     dh,0F0H                 ; get old speed
        or      dl,dh
        mov     al,dl
GoodSpeed:
        mov     [edi.OldVibrato+ebx],al
        push    cx
        mov     cl,5
        dec     bx
        jnz     EffectH                 ; Not fine vibrato.
        mov     cl,7
EffectH:call    ForVibratoAndTremolo
        pop     cx
        add     ax,[edi.NotePeriod]      ; Do not modifie Note period
        mov     bp,ax
        call    ClipPeriod
        jmp     GetGusFreq
;----------------------------------------
even
ForVibratoAndTremolo:                   ; THIS IS NOT AN EFFECT!
        mov     dl,al                   ; al = param
        shr     al,4                    ; mask speed
        and     dl,0Fh                  ; mask depth
        mov     bl,[edi.VibratoIndex]    ; Index in the sine table
        add     bl,al                   ; Increment index (+Speed)
        mov     [edi.VibratoIndex],bl
        and     ebx,31
        mov     al,[SinTab+ebx]
        mul     dl
        shr     ax,cl                   ; cl = 5 or 7 (Vibrato or tremolo)
        and     [edi.VibratoIndex],63
        cmp     [edi.VibratoIndex],31
        jle     fvatUp1
        neg     ax
fvatUp1:ret
;---------------------------------------- Effect I
; PS: ST3's tremor is very strange, this is not
; an exact copy of it.. will do better in the next
; version..:P
; so prepare yourself, this one is tricky. :> :>
even
Tremor: cmp     [edi.NoteBool],PlayNote
        jne     tExit1                  ; if no note, no tremor!
        push    cx
        xor     cx,cx
        mov     al,[edi.OldTremor]       ; Ixy (x=ontime, y=offtime)
        cmp     [TremorOnOff],0         ; Switch ON/OFF
        setne   cl
        shl     cx,2
        shr     al,cl                   ; cl = 0/4
        and     al,0FH                  ; only needed when cl = 0.
        mov     dh,cl
        pop     cx
        cmp     al,[edi.EffectTime]
        jne     tExit1
        xor     [TremorOnOff],1
        jz      cnCutIt
        mov     [edi.SampleOperation],PlayNote
tExit1: ret
TremorOnOff     db      0                       ; 0 = off, 1 = on
;----------------------------------------
even
Tremolo:or      al,al
        jnz     tGoodParam
        mov     al,[edi.LastEfxParam]
tGoodParam:
        push    cx
        mov     cl,7
        call    ForVibratoAndTremolo            ; saves some bytes.
        pop     cx
        add     [edi.Volume],al
        jmp     ClipVolume                      ; and returns to caller
;---------------------------------------------  Effect Q
even
Retrig: mov     al,[edi.OldRetrig]
        mov     ah,al
        shr     ah,4                    ; get high nibble. (volume slide)
        and     al,0FH
        cmp     al,[edi.EffectTime]
        jne     rExit
        mov     [edi.EffectTime],0
        mov     [edi.SampleOperation],PlayNote           ; Play it again
        ; Now, update the volume
rProcessVolume:
        or      ah,ah
        je      rExit
        cmp     ah,6
        je      r2_3            ; * (2/3)
        cmp     ah,7
        je      r1_2            ; * (1/2)
        cmp     ah,0EH
        je      r3_2            ; * (3/2)
        cmp     ah,0FH
        je      r2_1            ; * (2/1)
        jmp     rAddVolume
        ;
r2_3:   xor     ax,ax
        mov     al,[edi.Volume]
        shl     al,1
        mov     dl,3
        idiv    dl
        mov     [edi.Volume],al
        ret
r1_2:   shr     [edi.Volume],1
        ret
r3_2:   xor     ax,ax
        mov     al,[edi.Volume]
        mov     bl,al
        add     al,al
        add     al,bl
        shr     al,1
        mov     [edi.Volume],al
        jmp     ClipVolume      ; check if higher than 64
r2_1:   shl     [edi.Volume],1
        jmp     ClipVolume      ; check if higher than 64
rAddVolume:
        push    ebx
        movzx   ebx,ah
        mov     al,[RetrigVolumeTable+ebx]
        pop     ebx
        add     [edi.Volume],al
rClipVolume:
        jmp     ClipVolume
rExit:  ret
;---------------------------------------------
even
ExtraEffects:
        mov     dl,al
        and     dl,0FH
        or      dl,dl
        jnz     eeGoodParam
        mov     al,[edi.LastEfxParam]
eeGoodParam:
        mov     dl,al
        shr     dl,4
        or      dl,dl
        cmp     dl,0FH
        ja      eeExit
        movzx   edx,dl
        jmp     dword ptr [ExtraEffectsTable+edx*4]     ; don't bother with
eeExit: ret                                             ; conditional jmps...
;---------------------------------------------
even
SetFineTune:
        cmp     [getting_notes],1
        jne     sftExit
        and     eax,0FH
        mov     ax,[FineTunesTable+eax*2]
        mov     [edi.BasePeriod],ax
sftExit:ret
;--------------------------------;
even
SetVibratoWave:
        and     al,0FH
        and     [edi.WaveForm],0F0H      ; look at strucs.asm for more details
        jmp     stwExit                 ; ^^
;--------------------------------;
even
SetTremoloWave:
        shl     al,4
        and     [edi.WaveForm],00FH      ; look in strucs.asm for more details
stwExit:or      [edi.WaveForm],al
        ret
;--------------------------------;
even
StereoControl:
        ; I don't have enough informations to code this effect ..sorry.
        ; Panic.s3m only.
        ret
;--------------------------------;
PLoopCounter    db      0       ; loop count
PLoopRow        dw      0       ; Row Number.
PLoopPattern    dw      0       ; Pattern Number
PLoopOffset     dd      0       ; Offset in patterns
PLoopInLoop     db      0       ; a Flag
FirstTime       db      0
PatternLoop:
        cmp     [getting_notes],1
        jne     plExit
        mov     dl,al           ; al = param
        and     al,0FH          ; Mask low nibble
        je      plSavePos       ; Set Position if al == 0
        cmp     byte ptr [FirstTime],0
        je      plNoCounterSet
        mov     byte ptr [FirstTime],0
        mov     byte ptr [PLoopCounter],al
plNoCounterSet:
        dec     [PLoopCounter]
        jle     plExit
        mov     ax,[PLoopPattern]
        mov     [CurrentOrder],ax
        mov     ax,[PLoopRow]
        mov     [Row_In_Pattern],ax
        mov     eax,[PLoopOffset]
        mov     [PatternOffset],eax
        ret
plSavePos:
        mov     ax,[CurrentOrder]
        mov     [PLoopPattern],ax
        mov     ax,[Row_In_Pattern]
        mov     [PLoopRow],ax
        mov     eax,[PatternOffset]
        mov     [PLoopOffset],eax
plExit: ret
;--------------------------------;
even
CutNote:and     al,0FH                  ; mask low nibble
        jz      cnExit                  ; SC0 = no effect
        cmp     al,[edi.EffectTime]
        jne     cnExit
cnCutIt:mov     [edi.Sampleoperation],StopNote
cnExit: ret
;--------------------------------;
DelayNote:
        cmp     [edi.NoteBool],DoNothing
        je      dnExit                  ; no note!
        cmp     [getting_notes],0
        je      dnContinue
        mov     [edi.SampleOperation],DoNothing  ; do not play this note
        jmp     dnExit
dnContinue:
        and     al,0FH
        cmp     al,[edi.EffectTime]
        jne     dnExit
        mov     [edi.SampleOperation],PlayNote
        mov     [edi.VibratoIndex],0
dnExit: ret
;--------------------------------;
even
PatternDelay:
        cmp     [getting_notes],1
        jne     pdExit
        cmp     [PatternDelayed],1
        je      pdExit
        and     al,0FH                  ; Get Low nibble
        mov     [PatternDelayCounter],al
pdExit: ret
;--------------------------------;      Effect E8x
SetPanPos2:
        shr     al,4
        ret
even
SetPanPos:
        and     al,0FH
        mov     [edi.Chan_Side],al
        ret
