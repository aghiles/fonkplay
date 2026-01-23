Extrn   LoadModule: Near,StartP:Near,HaltP:Near,InitGus: Near
Extrn   FlushMem: Near
Extrn   PlayOneSample: Near
Extrn   GetPointers : Near
Extrn   GetInfos : Near
Extrn   _32BitInfo : Near
Extrn   Debug_Run : near

        .386
        .model flat
        STACK 256

        Jumps

        include strucs.asm

        SpeedLocation   = (160 * 2) + (1*2)
        RowLocation     = (160 * 2) + (16*2)
        OrderLocation   = (160 * 2) + (27*2)
        NoteY           = (2)  * 2
        VolumeY         = (8)  * 2
        InstrumentY     = (30) * 2
        EffectsY        = (61) * 2
        BarsY           = (13) * 2
        TestLocation    = 0
        ;
        .code

Start:  call    _32BitInfo
        mov     ax,0EE02H
        int     031H
        ;
        mov     [PspAdress],esi
        mov     eax,0B8000H
        sub     eax,ebx         ; - Base adress = Video adress
        mov     [VideoAdress],eax
        ;
        mov     [Real_Es],es
        mov     [Real_Ds],ds
        ;
        Call    Debug_Run
;--------------------------------------- Init Gus... AX = BASE ADRESS!
        mov     cx,16
        xor     ax,ax
        mov     edx,edi
        call    InitGus
        ;
        mov     edi,[PspAdress]
        add     edi,082H                ; command line param
        mov     edx,edi
        mov     ecx,0100h
        mov     al,0dh
        repnz   scasb
        dec     edi
        mov     byte ptr [edi],0
        xor     eax,eax
        Call    LoadModule
        jc      Error           ; If carry flag is set.. Then There is an Error.
        call    StartP
        ;
        ; Clear Screen
        ;
        mov     ecx,40*25
        xor     eax,eax
        mov     edi,[VideoAdress]
        repz    stosd
        ;
        ; Set Palette
        ;
        mov     esi,offset Palette
        xor     ax,ax
        mov     ecx,8*3
        call    SetPal
        ;
        call    GetPointers     ; Call the server (see server.asm)
        mov     [ChanPointer],ebx
        mov     [InstPointer],edi
        ;
        mov     edi,[VideoAdress]
        add     edi,(160*4)
        mov     ecx,79
        mov     ebx,18
        mov     ah,04H
        call    DrawBox
        ;
        mov     ax,'1' + (04H shl 8)
        mov     edi,[VideoAdress]
        add     edi,(160*5) + (78*2)
        mov     dx,16
        mov     esi,offset Channels
DrawAha:
        mov     ah,04H
        mov     ecx,2
        call    DisplayText
        add     edi,156
        dec     dx
        jnz     DrawAha
        ;
        mov     edi,SpeedLocation - (160*1) - (1*2)
        add     edi,[VideoAdress]
        mov     ecx,15
        mov     ebx,3
        mov     ah,04H
        call    DrawBox
        mov     edi,SpeedLocation
        add     edi,[VideoAdress]
        mov     esi,offset SpeedText
        mov     ecx,13
        mov     ah,07H
        call    DisplayText
        ;
        mov     edi,[VideoAdress]
        add     edi,RowLocation - (160*1) - (1*2)
        mov     ecx,11
        mov     ebx,3
        mov     ah,04H
        call    DrawBox
        mov     edi,[VideoAdress]
        add     edi,RowLocation
        mov     esi,offset RowText
        mov     ecx,9
        mov     ah,07H
        call    DisplayText
        ;
        mov     edi,[VideoAdress]
        add     edi,OrderLocation - (160*1) - (1*2)
        mov     ecx,15
        mov     ebx,3
        mov     ah,04H
        call    DrawBox
        mov     edi,[VideoAdress]
        add     edi,OrderLocation
        mov     esi,offset OrderText
        mov     ecx,13
        mov     ah,07H
        call    DisplayText
        call    GetInfos                ; just for OrderNum
        xor     bx,bx
        mov     bl,ah
        mov     edi,Offset TBuffer
        call    pBin2Dec

        ;
        mov     esi,offset TBuffer
        mov     edi,[VideoAdress]
        add     edi,OrderLocation + (10*2)
        mov     ecx,3
        mov     ah,07H
        call    DisplayText
        ;
        mov     edi,23*2
        add     edi,[VideoAdress]
        mov     esi,offset PlayerName
        mov     ecx,PlayerS
        mov     ah,05H
        call    DisplayText
repeatxx:
        call    WaitBorder
        call    ClearWorkArea
        call    UpdatePlayer
        in      al,060h
        dec     al
        jnz     repeatxx        ; Press ESCAPE to quit.
        ;
        call    HaltP           ; Stop!
        ;
        mov     ax,3
        push    010H
        call    DosInterrupt
        jmp     ExitFuck

Error:  mov     edx,offset NoFileError
        mov     ecx,ErrorStringLen
        inc     ax
        jz      ErrorFound      ; Error = -1 ?
        add     edx,ecx
        inc     ax
        jz      ErrorFound      ; Error = -2 ?
        add     edx,ecx
        ErrorFound:
        mov     ah,09h          ; EDX = error string offset
        int     021h            ; print string
ExitFuck:
        mov     ax,4C00h
        int     21h             ; emulated by dos32.
        ;
;--------------------------------
UpdatePlayer    Proc    Near
;---------------------------------
        mov     [ScreenOffset],160*5
        mov     [BarNumber],0
        mov     ecx,16
        mov     esi,[ChanPointer]
upLoop: push    ecx esi

        call    DisplayInfos

        mov     dl,[esi.Volume]
        mov     cl,[esi.s3mNote]
        mov     al,[esi.CurrSamp]
        dec     al
        jl      xNoNote
        mov     edi,[esi.SampHeader]
        add     edi,030H
        call    ShowInstrument          ; Display instrument name
        call    ShowNote                ; Display note
        call    ShowVolume
        call    UpdateVolumeBar
xNoNote:call    ShowEffect
        add     [ScreenOffset],80*2  ; next screen line
        inc     [BarNumber]
        pop     esi ecx
        add     esi,ChannelSize
        loop    upLoop
        ret
        ENDP

ShowNote        Proc    Near
        push    edi edx esi
        or      cl,cl
        jne     snGoodNote
        mov     cl,0Dh
snGoodNote:
        mov     dl,cl           ; save the paramater
        and     cl,0FH          ; mask note
        mov     ch,0
        mov     bx,cx
        shl     bx,3            ; * 8
        mov     edi,[ScreenOffset]
        add     edi,[VideoAdress]
        add     edi,NoteY
        mov     ax,'[' + (17H shl 8)
        stosw
        mov     eax,dword ptr [NotesNames+bx]
        stosd
        mov     cl,dl
        shr     cl,4            ; get octave
        add     cl,'0'          ; cl = octave in ASCII
        mov     ah,byte ptr [bx+NotesNames+5]        ; Get color
        mov     al,cl
        stosw
        mov     ax,']' + (17H shl 8)
        stosw
        pop     esi edx edi
        ret
        ENDP

ShowInstrument  Proc    Near
        ; ds:edi = Text to dislay
        ; offset of the line in ScreenOffset var
        push    ecx edx esi
        mov     esi,edi
        mov     edi,[ScreenOffset]
        add     edi,[VideoAdress]
        add     edi,InstrumentY
        ;
        mov     ax,'[' + (14H shl 8)
        stosw
        mov     cx,28
        mov     ah,017H
        call    DisplayText
        mov     ax,']' + (14H shl 8)
        stosw
        pop     esi edx ecx
        ret
        ENDP

DisplayText     Proc    Near
        ; cx = string length
        ; ah = background color
        ; ds:esi = text offset
        ; es:edi = screen offset
siLoop: lodsb
        stosw
        dec     cx
        jg      siLoop
        ret
        ENDP

ShowEffect      Proc    Near
        push    esi
        movzx   eax,[esi.Effect]
        or      al,al
        je      seExit
        dec     ax
        shl     ax,4            ; * 16
        mov     esi,offset EffectsText
        add     esi,eax
        mov     edi,[ScreenOffset]
        add     edi,[VideoAdress]
        add     edi,EffectsY
        mov     ah,04H
        mov     cx,16
        call    DisplayText
seExit: pop     esi
        ret
        ENDP


ShowVolume      Proc    Near
        ; IN : dl = Volume
        push    edx esi
        movzx   bx,dl           ; dl = Volume
        mov     edi,offset xx27xx+1
        mov     word ptr [edi],0
        mov     esi,edi
        call    pBin2Dec
        dec     esi
        mov     edi,[ScreenOffset]
        add     edi,[VideoAdress]
        add     edi,VolumeY
        mov     ah,015H
        mov     cx,4
        call    DisplayText
        pop     esi edx
        ret
xx27xx  db '-..-'
        ENDP

UpdateVolumeBar         Proc    Near
        push    esi
        mov     bx,[BarNumber]
        cmp     [esi.VolumeBar],0
        jne     uvbKick
        dec     byte ptr [bx+offset VolBars]
        jge     uvbDisplayBar
        mov     byte ptr [bx+offset VolBars],0
        jmp     uvbDisplayBar
uvbKick:
        mov     [esi.VolumeBar],0
        shr     dl,2
        mov     [bx+offset VolBars],dl
uvbDisplayBar:
        mov     edi,[ScreenOffset]
        add     edi,[VideoAdress]
        add     edi,BarsY
        movzx   cx,byte ptr [bx+offset VolBars]
        or      cx,cx
        jz      uvbExit
        mov     esi,offset xxVoxx
        mov     ah,06H
        call    DisplayText
uvbExit:
        pop     esi
        ret
xxVoxx  db 'נננננננננננננ==-'
        ENDP

DisplayInfos    proc    near
        push    esi
        call    GetInfos                ; call player server
        ;
        push    eax
        mov     bx,cx                   ; speed
        mov     edi,offset TBuffer
        ;
        movzx   eax,bl
        shr     al,4
        mov     al,[HexTable+eax]
        mov     byte ptr [edi],'0'
        mov     [edi+1],al
        and     bx,0FH
        mov     al,[HexTable+bx]
        mov     [edi+2],al
        mov     byte ptr [edi+3],'h'
        mov     byte ptr [edi+4],0
        ;
        mov     esi,offset TBuffer
        mov     edi,SpeedLocation + (9*2)
        add     edi,[VideoAdress]
        mov     cx,4
        mov     ah,06H
        call    DisplayText
        pop     eax
        ;
        movzx   bx,al                   ; Tempo
        mov     edi,Offset TBuffer
        mov     dword ptr [edi],0
        call    pBin2Dec
        mov     esi,offset TBuffer
        mov     edi,SpeedLocation + (6*2)
        add     edi,[VideoAdress]
        mov     cx,1
        mov     ah,06H
        call    DisplayText
        ;
        movzx   bx,dl                   ; row
        mov     edi,Offset TBuffer
        mov     dword ptr [edi],0
        call    pBin2Dec
        mov     esi,offset TBuffer
        mov     edi,RowLocation + (4*2)
        add     edi,[VideoAdress]
        mov     cx,2
        mov     ah,06H
        call    DisplayText
        ;
        movzx   bx,dh                   ; order
        mov     edi,Offset TBuffer
        mov     dword ptr [edi],0
        call    pBin2Dec
        mov     esi,offset TBuffer
        mov     edi,OrderLocation + (6*2)
        add     edi,[VideoAdress]
        mov     cx,3
        mov     ah,06H
        call    DisplayText
        pop     esi
        ret
Tbuffer: db '    '
        ENDP

DrawBox Proc    Near
        ; IN :  di = screen offset
        ;       cx = Width
        ;       bx = Heigth
        ;       ah = Color
        push    edi
        mov     edx,ecx
        mov     al,'Ú'
        stosw
        sub     ecx,2
        mov     al,'Ä'
        repz    stosw
        mov     al,'¿'
        stosw
        mov     ecx,edx
        pop     edi
        add     edi,80*2
        mov     al,'³'
        xchg    ecx,ebx
        dec     ebx
        shl     ebx,1
        sub     ecx,2
        jz      dbNoHeigth
dbLoop:
        mov     [edi],ax
        mov     [edi+ebx],ax
        add     edi,80*2
        loop    dbLoop
dbNoHeigth:
        ;
        mov     al,'À'
        stosw
        mov     ecx,edx
        sub     ecx,2
        mov     al,'Ä'
        repz    stosw
        mov     al,'Ù'          ;
        stosw
        ret
        ENDP
;--------------------------------;
ClearWorkArea   Proc    Near
;--------------------------------;
        mov     edi,160*5 + (2*2)
        add     edi,[VideoAdress]
        mov     ecx,16
        xor     eax,eax
cwaLoop1:
        push    ecx
        mov     ecx,5
        repz    stosw
        inc     edi
        inc     edi
        mov     ecx,4
        repz    stosw
        inc     edi
        inc     edi
        mov     ecx,16
        repz    stosw
        inc     edi
        inc     edi
        mov     ecx,30
        repz    stosw
        inc     edi
        inc     edi
        mov     ecx,16
        repz    stosw
        pop     ecx
        add     edi,(160-150)
        loop    cwaLoop1
        ret
        ENDP

;------------------------------------------------------------------------------
; This functions converts a 16 bit register to an Binary,Octal or Decimal ASCII string
; In    : bx = binary number
;       : ds:di = destination byffer
; Out   : ds:di = a string (not null terminated).
; NB    : this function is recursive
;--------------------------------;
pBin2Dec proc near
;--------------------------------;
        push    eax ebx edx
        xchg    bx,ax
        cwd                                     ; 1 byte less than a XOR.
        div     [wDigitBase]
        xchg    bx,ax
        or      bx,bx
        jz      b2dNoRemainder
        call    pBin2Dec
b2dNoRemainder:
        add     dl,'0'
        mov     [edi],dl
        inc     edi
        pop     edx ebx eax
        ret
wDigitBase      dw      10
        ENDP

;--------------------------------;
        WaitBorder Proc near
;--------------------------------;
        mov     dx,3dah
wbr2:   in      al,dx
        test    al,8
        jnz     wbr2
wbr22:  in      al,dx
        test    al,8
        jz      wbr22
        ret
        ENDP

;------------------------------------------------------------
; Procudure to call a DOS interrupt. Taken from VESA.ASM that comes
; with DOS 32
;------------------------------------------------------------
DOSinterrupt PROC
        push    dword ptr 0             ; ignore  SS, SP
        lea     esp,[esp - 8]           ; ignore  CS, IP ,FS, GS
        push    [Dos_Segs]
        pushf
        pushad
        mov     edi,esp
        mov     ax,0300h
        xor     cx,cx
        movzx   ebx,byte ptr [esp+36h]  ; Get int number from stack param
        int     031h                    ; Emulate Real Mode Interrupt
        popad
        popf
        lea     esp,[esp+16]            ; Ignore SS,SP,CS,IP,FS,GS,ES & DS
        ret     4

Dos_Segs label dword
        Real_Es dw      0
        Real_Ds dw      0
DOSinterrupt ENDP

;--------------------------------;
        SetPal  Proc Near
;--------------------------------;
;       DS:SI == Palette offset
;       cx= number of colors to set
        push    eax edx ecx                ; save regs
        mov     dx,03C8H
        out     dx,al
        inc     dx
        repz    outsb
        pop     ecx edx eax                ; restore regs
        ret
SetPal  ENDP

;
VolBars db      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0         ; Volumes
;
ScreenOffset    dd      0
BarNumber       dw      0
;
ChanPointer     dd      0
InstPointer     dd      0
VideoAdress     dd      0
EnviroAdress    dd      0
PspAdress       dd      0
InterSelector   dw      0
;
NoFileError     db      0dh,0ah,"Scream Tracker module not found! $"
                ErrorStringLen = $ - offset NoFileError
BadFileError    db      0dh,0ah,"The specified file is not an S3M!$"
NoMemErro       db      0dh,0ah,"There is no enough low mem !$"

include ET.INC
Palette = this byte
include PAL.ASM
;
HexTable        DB '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'
       END      Start

