;----------------------------------------
; Call with al = s3m note Byte
;          ebp =  base period.
;-----------------------------------------
CalcS3Mnote Proc Near
        push    ebx cx
        push    ebp                     ; save base period
        mov     ah,al                   ; save it
        and     al,0FH                  ; mask low nibble.
        movzx   ebx,al
        mov     bx,word ptr [s3mPeriodTable+ebx*2]
        mov     cl,ah                   ; cl = octave
        shr     cl,4
        shl     ebx,4
        shr     ebx,cl
        mov     eax,ebx
        mov     ebp,8363
        imul    ebp
        pop     ebp                     ; restore base period
        div     ebp
        mov     bp,ax                   ; bp = note period
        pop     cx ebx
        ret
        ENDP

;----------------------------------------
RampVolume      Proc    Near
;----------------------------------------
        ; bx : EndVolume
        ; cl : speed (Msecs)
        ;
        push    edi
        mov     dx,[CommandPort]
        mov     al,GetVolumeControl
        out     dx,al
        add     dl,2
        in      al,dx
        or      al,3            ; volume stopped | stop volume
        mov     ah,al
        ;
        sub     dl,2
        mov     al,VolumeControl
        out     dx,al
        add     dl,2
        mov     al,ah
        out     dx,al
        call    UDelay
        out     dx,al           ; STOP VOLUME
        ;
        mov     dx,[CommandPort]
        mov     al,ReadVolume
        out     dx,al
        inc     dx
        in      ax,dx           ; get current voice Volume
        mov     si,ax           ; save start volume
        shr     ax,4
        ;
        mov     ch,0            ; ramp direction = increasing
        ;
        cmp     ax,bx
        jne     rvContinue
        pop     edi
        ret
rvContinue:
        cmp     ax,bx
        jb      rvNoFlip
        xchg    ax,bx
        mov     ch,040H         ; ramp direction = decreasing
rvNoFlip:
        ;
        cmp     ax,64
        jg      rvNoLowClip
        mov     ax,64
rvNoLowClip:
        cmp     bx,4032
        jl      rvNoHighClip
        mov     bx,4032
rvNoHighClip:
        ;
        mov     di,ax
        mov     dx,[CommandPort]
        mov     al,VolumeRampRate
        out     dx,al
        mov     al,cl           ; al = rate
        add     dl,2
        out     dx,al
        ;
        sub     dl,2
        mov     al,VolumeRampStart
        out     dx,al
        mov     ax,di
        shr     ax,4
        add     dl,2
        out     dx,al
        ;
        sub     dl,2
        mov     al,VolumeRampEnd
        out     dx,al
        mov     ax,bx
        shr     ax,4
        add     dl,2
        out     dx,al
        ;
        sub     dl,2
        mov     al,GetVolumeControl
        out     dx,al
        add     dl,2
        in      al,dx
        and     al,04H                  ; ROLLOVER mask
        jz      rvContinue2
        or      ch,04H
rvContinue2:
        ;
        sub     dl,2
        mov     al,VolumeControl
        out     dx,al
        add     dl,2
        mov     al,ch
        out     dx,al
        call    UDelay
        out     dx,al
        ;
        pop     edi
        ret
        ENDP

;--------------------------------
ClipPeriod      Proc    Near
;--------------------------------
        push    bx dx
        mov     dx,[Limits]
        mov     bx,[Limits+2]
        cmp     bp,bx
        jae     cpUpOk
        mov     bp,bx
        jmp     cpExit
cpUpOk: cmp     bp,dx
        jbe     cpExit
        mov     bp,dx
cpExit: pop     dx bx
        ret
        ENDP
;--------------------------------
GetGusFreq      Proc    Near
;--------------------------------
; Input bp = Note Period
; Output [edi.FreqVal] = gus frequency.
        or      bp,bp
        jnz     ggfGoodPeriod
        mov     [edi.FreqVal],0
        ret
ggfGoodPeriod:
        push    dx
        and     ebp,0000FFFFh
        xor     edx,edx
        mov     eax,14317056
        div     ebp
        shl     eax,9
        mov     ebp,[CurrDivisor]
        shr     ebp,1
        add     eax,ebp
        xor     edx,edx
        div     [CurrDivisor]
        add     ax,ax
        mov     [edi.FreqVal],ax
        pop     dx
        ret
        ENDP
;--------------------------------
GetGusVolume Proc Near
;--------------------------------
        movzx   eax,[edi.Volume]
        imul    ax,[MainVolume]
        shr     ax,6
        mov     bx,[GusVolume+eax*2]
        mov     [edi.Gus_Volume],bx
        ret
        ENDP
;--------------------------------
UDelay  Proc    Near
;--------------------------------
        push    dx ax
        mov     dx,300h
        in      al,dx
        in      al,dx           ; 2 ins should be enough.
        pop     ax dx
        ret
        ENDP

;--------------------------------
SetVoiceParams  Proc Near
;--------------------------------
; In : di = ChanInfo structure.
        push    ebx ebp dx
        ;
        mov     ebx,[edi.SampHeader]             ; offset of Sample header
        mov     dx,[CommandPort]

Comment &
        Sending Low part of Sample adress
        &
        mov     al,SampleStartLo
        out     dx,al
        inc     dx
        movzx   eax,word ptr [edi.OffsetAdd]
        add     eax,dword ptr [ebx.smpGUSAdress]
        mov     ebp,eax                         ; save it for LTR
        shr     eax,7
        out     dx,ax
        dec     dx
        ;-----------------------------------------------
Comment &
        Sending Hi part of sample adress
        &
        mov     al,SampleStartHi
        out     dx,al
        inc     dx
        mov     eax,ebp
        shl     ax,9
        out     dx,ax
        dec     dx
        ;-----------------------------------------------
Comment &
        Sending Low Part of Sample Start Loop adress
        &
        mov     al,LoopStartLo
        out     dx,al
        inc     dx
        movzx   eax,word ptr [ebx.smpLoopBeg]
        add     eax,dword ptr [ebx.smpGUSAdress]
        ;cmp    [edi.LoopBOOL],0
        ;jne    AdressOk
        dec     eax
        jge     AdressOk
        inc     eax
AdressOk:
        mov     ebp,eax
        shr     eax,7
        out     dx,ax
        dec     dx
        ;-----------------------------------------------
Comment &
        Sending Hi Part of Sample Start Loop adress
        &
        mov     al,LoopStartHi
        out     dx,al
        inc     dx
        mov     eax,ebp
        shl     ax,9
        out     dx,ax
        dec     dx
        ;-----------------------------------------------
Comment &
        Sending Low Part of sample End Loop adress
        &
        xor     eax,eax
        mov     al,LoopEndLo
        out     dx,al
        inc     dx
        mov     ax,word ptr [ebx.smpLength]
        cmp     [edi.LoopBOOL],0
        je      NoLoop1
        mov     ax,word ptr [ebx.smpLoopEnd]
NoLoop1:add     eax,dword ptr [ebx.smpGUSAdress]
        dec     eax
        jge     AdressOk2
        inc     eax
AdressOk2:
        mov     ebp,eax                 ; save it
        shr     eax,7
        out     dx,ax
        dec     dx
        ;-----------------------------------------------
Comment &
        Sending Hi Part of Sample End Loop adress
        &
        mov     al,LoopEndHi
        out     dx,al
        inc     dx
        mov     eax,ebp
        shl     ax,9
        out     dx,ax
        ;
        pop     dx ebp ebx
        ret
        ENDP

comment %
;-------------------------------------------
PlayOneSample   Proc    Near
;-------------------------------------------
; Params : cl = voice number
;          al = note. (st3 format)
;          ah = volume
;          bl = sample number
        push    di ds
        push    cs
        pop     ds
        ;
        push    ax
        mov     dx,cs:[CommandPort]
        dec     dx              ; dx = active voice port
        mov     al,cl
        out     dx,al           ; sets active voice.
        ;
        mov     ah,0
        imul    ax,size ChanInfo
        add     ax,offset SampChans
        mov     di,ax
        pop     ax
        mov     [edi.Volume],ah
        ;
        push    ax
        mov     bh,0
        mov     ax,bx
        imul    ax,smpSize
        mov     [edi.SampHeader],ax              ; bx = offset of the sample header
        pop     ax
        ;
        movzx   ebp,[di.BasePeriod]
        call    CalcS3Mnote
        ;
        mov     [di.OffsetAdd],0
        mov     [di.ChanFlag],1         ; sound effect voice
        ;
        pop     ds di
        ret
        ENDP
        %
;-------------------------------
StopVoice       Proc    Near
;-------------------------------
        push    ax dx
        mov     dx,[CommandPort]
        mov     al,GetVolumeControl
        out     dx,al
        add     dl,2
        in      al,dx
        and     al,0FBH         ; not(ROLLOVER)
        mov     ah,al
        ;
        sub     dl,2
        mov     al,VolumeControl
        out     dx,al
        add     dl,2
        mov     al,ah
        out     dx,al
        call    UDelay
        out     dx,al
        ;
        ; Now, we can stop this voice
        ;
        sub     dl,2
        mov     al,GetControl
        out     dx,al
        add     dl,2
        in      al,dx
        mov     ah,al
        and     ah,0DFH         ; not(WAVE_IRQ) , WAVE_IRQ = 20h
        or      ah,3            ; 3 = VOICE_STOP | VOICE_STOPPED
        sub     dl,2
        mov     al,SetControl
        out     dx,al
        add     dl,2
        mov     al,ah
        out     dx,al
        call    UDelay
        out     dx,al
        pop     dx ax
        ret
        ENDP

;--------------------------------
DetectGus       Proc    Near
;--------------------------------
; returns GUS base port in AX
        mov     edi,edx         ; edx = environnement offset
        mov     cx,1024
        mov     eax,'=DNS'      ; search for SND= (ultrasnd u)
        ;
SearchLoop:
        cmp     [edi],eax
        je      dgGusFound
        inc     edi
        dec     cx
        jnz     SearchLoop
dgGusFound:
        add     edi,5
        xor     ax,ax
        mov     al,[edi]
        sub     al,'0'
        shl     ax,4
        add     ax,0200H        ; ax = port
        push    eax              ; save port
        add     di,7
        xor     ax,ax
        mov     al,[edi]
        cmp     al,'1'
        jne     Not10Bigger
        inc     di
        mov     al,[edi]
        add     al,10
Not10Bigger:
        sub     al,'0'
        mov     si,ax           ; si = GF1 irq
        inc     di
        inc     di
        mov     al,[edi]
        sub     al,'0'
        mov     di,ax           ; di = MIDI irq (cannot be higher than 7..)
        pop     eax
        ret
        ENDP
