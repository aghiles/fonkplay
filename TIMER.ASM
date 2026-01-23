; IRQ related structures
irq_struc       STRUC
                latch   db      ?
                maskx   db      ?
                spec_eoi db     ?
                ocr     db      ?       ; operation control register
                imr     db      ?       ; interrupt maskx register
                ENDS

; IRQ related constants
OCR1    = 020h  ; 8259-1 operation contro register
IMR1    = 021h  ; mask register 1
OCR2    = 0A0h  ; 8259-2 operation contro register
IMR2    = 0A1H  ; mask register 2

; IRQ related varibales.
TimerVar1       db      0
TimerVar2       db      0
TimerByte       db      0

IrqTable        = this word
        irq_struc       <0,0FEH,060H,OCR1,IMR1> ; Irq 0
        irq_struc       <0,0FDH,061H,OCR1,IMR1> ; Irq 1
        irq_struc       <1,0FBH,062H,OCR1,IMR1> ; Irq 2
        irq_struc       <3,0F7H,063H,OCR1,IMR1> ; Irq 3
        irq_struc       <0,0EFH,064H,OCR1,IMR1> ; Irq 4
        irq_struc       <2,0DFH,065H,OCR1,IMR1> ; Irq 5
        irq_struc       <0,0BFH,066H,OCR1,IMR1> ; Irq 6
        irq_struc       <4,07FH,067H,OCR1,IMR1> ; Irq 6
        ;
        irq_struc       <0,0FEH,060H,OCR2,IMR2> ; Irq 8
        irq_struc       <0,0FDH,061H,OCR2,IMR2> ; Irq 9
        irq_struc       <0,0FBH,062H,OCR2,IMR2> ; Irq 10
        irq_struc       <5,0F7H,063H,OCR2,IMR2> ; Irq 11
        irq_struc       <6,0EFH,064H,OCR2,IMR2> ; Irq 12
        irq_struc       <0,0DFH,065H,OCR2,IMR2> ; Irq 13
        irq_struc       <0,0BFH,066H,OCR2,IMR2> ; Irq 14
        irq_struc       <7,07FH,067H,OCR2,IMR2> ; Irq 15

;---------------------------------------;
StartGusTimer   Proc    Near
;---------------------------------------;
        ; AL : Timer 1 or 2
        ; CX : Hz
        dec     al                              ; Timer 1 ?
        jnz     sgtTimer2                       ; no
        or      [TimerVar1],4       ; yes
        or      [TimerVar2],1
        mov     [TimerByte],TIMER1
        jmp     sgtSetTimer
sgtTimer2:
        or      [TimerVar1],8
        or      [TimerVar2],2
        mov     [TimerByte],TIMER2
sgtSetTimer:
        ;
        mov     dx,[CommandPort]
        mov     al,[TimerByte]               ; TimerByte = temp. (see sdk)
        out     dx,al
        add     dl,2                            ; dx = Data Hi port
        mov     ax,256
        sub     ax,cx                           ; ax = count
        out     dx,al                           ;
        ;
        sub     dl,2                            ; dx = Command Port
        mov     al,Timer_Control
        out     dx,al
        add     dl,2                            ; dx = Data Hi port
        mov     al,byte ptr [TimerVar1]
        out     dx,al
        ; MUST
        mov     dx,[TimerPort]               ; 2x8
        mov     al,04h
        out     dx,al
        inc     dx                              ; dx = Timer Data Port (2x9)
        mov     al,byte ptr [TimerVar2]
        out     dx,al
        ;
sgtExit:ret
        ENDP
;---------------------------------------
StopGusTimer    Proc    Near
;---------------------------------------
        ; AL : Timer 1 or 2
        ; CX : Hz
        dec     al                              ; Timer 1 ?
        jnz     sgt2Timer2                      ; no
        or      [TimerVar1],NOT 4               ; 0FBH
        or      [TimerVar2],NOT 1               ; 0FEH
        mov     [TimerByte],TIMER1
        jmp     sgtSetTimer
sgt2Timer2:
        and     [TimerVar1],NOT 8               ;0F7H
        and     [TimerVar2],NOT 2               ;0FDH
        mov     [TimerByte],TIMER2
        jmp     sgtSetTimer
        ENDP
;---------------------------------------
SetVector       Proc    Near
;---------------------------------------
        ; ax = IRQ number (7,11...)
        mov     [RealIRQNumber],al
        cmp     ax,7
        jle     igi8
        add     ax,068h
        jmp     igiSetVector
igi8:   add     ax,008h
igiSetVector:
        ; Get current adress of the IRQ
        mov     [INTNum],al
        mov     bl,al
        push    bx
        mov     ax,0204H
        int     031H
        mov     [OldIRQVector],edx
        mov     [OldIRQSelector],cx
        ; Set the adress of our IRQ handler
        pop     bx
        mov     edx,offset IrqHandler   ; offset in edx
        mov     cx,cs                   ; code selector in cx
        mov     ax,0205H
        int     031H
        ;
        ret

OldIRQVector    DD      0
OldIRqSelector  DW      0

INTNum          db      0
RealIRQNumber   db      0
        ENDP
;---------------------------------------
ResetVector     Proc    Near            ; DOS32 version
;---------------------------------------
        mov     edx,[OldIRQVector]
        mov     cx,[OldIRQSelector]
        mov     ax,0205H                ; set protected mode vector
        mov     bl,[IntNum]
        int     031H
        ret
        ENDP
;---------------------------------------
SetIrqs Proc    near
;---------------------------------------
        ; ax = GF1 IRQ number
        ; si = MIDI IRQ number
        push    ax
        mov     bx,ax
        imul    ax,5                    ; sizeof one Irq table entry
        xchg    bx,ax
        or      ax,ax                   ; GF1 irq = 0??
        je      si0Irq
        ; Unmask GF1 interrupt
        call    UnmaskIrq

si0Irq: ; Now, Unmask IRQ2 from 1st controller if using 2nd controller
        pop     ax              ; pop interrupt number
        push    ax
        cmp     ax,7
        jbe     siNoUnmask
        mov     bx,2*5          ; (IRQ number+1)*(sizeof[entry in irqtable])
        call    UnmaskIrq
siNoUnmask:
        pop     ax

        ; Now, Unmask MIDI IRQ
        push    ax
        mov     ax,si
        mov     bx,ax
        imul    ax,5                    ; sizeof one Irq table entry
        xchg    bx,ax
        or      ax,ax                   ; GF1 irq = 0??
        je      siExit2
        ; Unmask GF1 MIDI interrupt
        call    UnmaskIrq
siExit2:pop     ax
        ret

UnmaskIrq:
        ; bx = Irq number * 5
        xor     dx,dx
        mov     dl,[IrqTable.imr+bx]
        in      al,dx
        and     al,[IrqTable.maskx+bx]
        out     dx,al
        ; Send a specific EOI in case of pending interrupt
        mov     dl,[IrqTable.ocr+bx]
        mov     al,[IrqTable.spec_eoi+bx]
        out     dx,al
        ret
        ENDP
;---------------------------------------;
ResetIrqs       Proc    Near
;---------------------------------------;
        ; ax = IRQ number
        mov     bx,ax
        imul    ax,5                    ; no need of speed here.:)
        xchg    ax,bx
        cmp     ax,2
        je      riExit
        or      ax,ax
        je      riExit
        xor     dx,dx
        mov     dl,[IrqTable.imr+bx]
        in      al,dx
        mov     cl,[IrqTable.maskx+bx]
        not     cl
        or      al,cl
        out     dx,al            ; mask irq
riExit: ret
        ENDP
;---------------------------------------;
IrqHandler      Proc    Near
;---------------------------------------;
        cli
        push    ax edx ebx ecx ds
        ;
        mov     ax,@code
        mov     ds,ax           ; it's important to use the right selector!!
        ;
        cld
        movzx   ebx,[RealIrqNumber]
        mov     ecx,ebx
        mov     dl,[IrqTable.ocr        +ebx*4 +ecx]
        mov     al,[IrqTable.spec_eoi   +ebx*4 +ecx]
        mov     dh,0
        out     dx,al
        ;
ihAhem: mov     dx,[StatusPort]
        in      al,dx
        or      al,al
        jz      ihExit
        ;
        mov     bx,ax                   ; save ax
        mov     dx,[CommandPort]
        mov     al,Timer_Control
        out     dx,al
        add     dx,2                    ; dx = Data Hi
        mov     al,0
        out     dx,al
        mov     al,[TimerVar1]
        out     dx,al
        mov     ax,bx                   ; restore ax
        test    al,4
        jz      NoTimer1
        call    UpdateEffects
NoTimer1:
        test    al,8
        jz      ihExit
        call    PlaySamples
        ;
ihExit: mov     al,020h
        out     0A0h,al                 ; send signal to Slave PIC
        mov     al,020h
        out     020H,al                 ; send signal to Master PIC
        pop     ds ecx ebx edx ax
        sti
        IRETD
        ENDP

;Timer1Function  UpdateEffects
;Timer2Function  PlaySamples
