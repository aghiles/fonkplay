
        .386

        .model flat

Extrn   LoadModule: Near,StartP:Near,HaltP:Near,InitGus: Near
Extrn   FlushMem : Near
Extrn   PlayOneSample : Near
Extrn   GetPointers : Near
Extrn   GetInfos : Near
Extrn   Debug   : Near
;
Extrn   _32BitInfo : Near

        STACK 1024

        include strucs.asm



.Code

Begin:  mov     ax,0EE02H
        int     031H
        ;
        mov     [EnviAdress],edi
        mov     [PspAdress],esi
        ;
;--------------------------------------- Init Gus... AX = BASE ADRESS!
        call    Debug
        call    _32BitInfo
        ;
        mov     cx,64
        mov     ax,0220H
        mov     si,7
        mov     di,11
        mov     edx,[EnviAdress]
        call    InitGus
        ;
        mov     esi,[PspAdress]
        mov     edi,esi
        add     edi,082H
        mov     edx,edi
        mov     ecx,0100h
        mov     al,0dh
        repnz   scasb
        dec     edi
        mov     byte ptr [edi],0
        xor     eax,eax
        Call    LoadModule
        ;
        call    StartP
;-------------- Clear Screen
repeatxx:
        in      al,060h
        dec     al
        jnz     repeatxx        ; Press ESCAPE to quit.
        ;
        call    HaltP
        ;
        mov     ax,04c00h
        int     021h
        ;
EnviAdress      DD      0
PspAdress       DD      0
        END     Begin

