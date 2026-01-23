;--------------------------------
InitGus Proc    Near
;--------------------------------
        ; call with si = GUS IRQ
        ;           di = GUS MIDI IRQ
        ;           cx = Global Volume  (0..64)
        ;           ax = PortNumber
        or      ax,ax
        jne     igNoAutoDetect
        push    ecx
        call    DetectGus
        pop     ecx
igNoAutoDetect:
        cmp     cx,64
        jle     igVolumeOk
        mov     cx,64
        or      cx,cx
        jge     igVolumeOk
        xor     cx,cx
igVolumeOk:
        mov     [GusIRQ],si
        mov     [GusMIDIIrq],di
        mov     [MainVolume],cx
        sub     ax,0220H
        add     [BasePort],ax
        add     [StatusPort],ax
        add     [ActiveVoicePort],ax
        add     [CommandPort],ax
        add     [DataLowPort],ax
        add     [DataHighPort],ax
        add     [DRAMIOPort],ax
        add     [TimerPort],ax
        add     [TimerDataPort],ax
        ;
        xor     ax,ax
        mov     [NumVoices],14
        mov     [NumChans],4
        mov     [Tempo],al
        mov     [TempoWait],al
        mov     [Speed],ax
        mov     [PlayerSpeed],al
        mov     [Timer2Speed],20
        mov     [SkipFactor],al
        mov     [CurrentFactor],al
        mov     [getting_notes],false
        mov     [s3mPlaying],false
        mov     [BreakToRow],-1
        ret
        EndP
;------------------------------------------
InitDevice      Proc    Near
;------------------------------------------
;Init the UltraSound
        mov     bx,[Commandport]
        mov     cx,[DatahighPort]
        mov     dx,bx
        mov     al,Initialize
        out     dx,al
        mov     dx,cx
        xor     al,al
        out     dx,al
        ;
        mov     dx,bx
        mov     al,4Ch
        out     dx,al
        mov     dx,cx
        mov     al,1
        out     dx,al
        ;
        mov     dx,bx
        mov     al,DMACtrl
        out     dx,al
        mov     dx,cx
        xor     al,al
        out     dx,al
        ;
        mov     dx,bx
        mov     al,45h
        out     dx,al
        mov     dx,cx
        xor     al,al
        out     dx,al
        ;
        mov     dx,bx
        mov     al,49h
        out     dx,al
        mov     dx,cx
        sub     al,al
        out     dx,al
        ;
        mov     dx,bx
        mov     al,VoicesActive
        out     dx,al
        mov     dx,cx
        mov     al,[NumVoices]
        dec     al
        or      al,0C0h
        out     dx,al

        mov     dx,[StatusPort]
        in      al,dx
        mov     dx,bx
        mov     al,DMACtrl
        out     dx,al
        mov     dx,cx
        in      al,dx
        mov     dx,bx
        mov     al,49h
        out     dx,al
        mov     dx,cx
        in      al,dx
        mov     dx,bx
        mov     al,8Fh
        out     dx,al
        mov     dx,cx
        in      al,dx

        push    cx
        mov     cx,32
VoiceClearLoop:
        mov     dx,[ActiveVoicePort]
        mov     al,cl
        dec     al
        out     dx,al
        inc     dx
        mov     al,0
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
        loop    VoiceClearLoop
        pop     cx

        mov     dx,bx
        mov     al,DMACtrl
        out     dx,al
        mov     dx,cx
        in      al,dx
        mov     dx,bx
        mov     al,49h
        out     dx,al
        mov     dx,cx
        in      al,dx
        mov     dx,bx
        mov     al,8Fh
        out     dx,al
        mov     dx,cx
        in      al,dx

        mov     dx,bx
        mov     al,Initialize
        out     dx,al
        mov     dx,cx
        mov     al,7
        out     dx,al
        ;
        mov     dx,[CommandPort]
        mov     al,Timer_Control
        out     dx,al
        xor     ax,ax
        inc     dx
        inc     dx
        out     dx,al                   ; reset timer interrupt
        ;
idExit: ret
InitDevice EndP
