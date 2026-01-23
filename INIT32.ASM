; this asm file will work only with DOS32.
        .386
        .model flat


        .code
public  _32BitInfo

_32BitInfo      Proc    Near
        push    ds
        mov     ax,@code
        mov     ds,ax
        ;
        mov     ax,0EE02H
        int     031H
        mov     [BaseAdress],ebx
        mov     [CodeSize],edx
        mov     [PSPAdress],esi
        mov     [EnvAdress],edi
        ;
        mov     edx,offset message1
        mov     ah,9
        int     021H            ; call dos service emulation
        ;
        mov     edx,offset message2
        mov     ah,9
        int     021H
        ;
        mov     ax,0EE00H
        int     031H            ; get dos32 version and selector values
        ;
        shr     dl,1            ; /2
        movzx   edx,dl
        mov     edx,dword ptr [DlArray+edx*4]
        mov     ah,9
        int     021H
        ;
        mov     edx,offset message3
        mov     ah,9
        int     021h
        ;
        mov     edi,offset message4 + 34
        mov     eax,[BaseAdress]
        call    WriteRegister
        mov     edi,offset message5 + 34
        mov     eax,[PspAdress]
        call    WriteRegister
        mov     edi,offset message6 + 34
        mov     eax,[EnvAdress]
        call    WriteRegister
        mov     edi,offset message7 + 34
        mov     eax,[CodeSize]
        call    WriteRegister
        ;
        mov     edx,offset message4
        mov     ah,9
        int     021H
        ;
        pop     ds
        ret
        ENDP

WriteRegister   Proc    Near
; call with:
;       eax = number
;       es:edi = destination for the ASCII string
        mov     dx,8
        mov     cl,0
        ;
wrLoop: mov     ebx,eax
        shr     ebx,cl
        and     ebx,0FH
        movzx   ebp,byte ptr [ebx+bin]
        push    ebp
        add     cl,4
        dec     dx
        jnz     wrLoop
        ;
        mov     dx,8
wrLoop2:pop     ebp
        mov     eax,ebp
        stosb
        dec     dx
        jnz     wrLoop2
        ret

Bin     db      "0123456789ABCDEF"
        ENDP

BaseAdress      dd      0
CodeSize        dd      0
EnvAdress       dd      0
PSPAdress       dd      0
;
message1        db      "_32BitInfo for DOS32",0dh,0dh,0ah,"$"
message2        db      "This system is currently running in '$"
message3        db      "' mode.",0dh,0dh,0ah,"$"
;
message4        db      "Linear BASE adress of the demo : 000000000H",0dh,0ah
message5        db      "Linear PSP adress              : 000000000H",0dh,0ah
message6        db      "Linear ENVIRONEMENT adress     : 000000000H",0dh,0ah
message7        db      "demo code size                 : 000000000H",0dh,0ah
                db      0dh,0ah
                db      "......$"
;
DlArray = this  dword
                dd      offset SystemType
                dd      offset SystemType+8
                dd      offset SystemType+16
                dd      0
                dd      offset SystemType+32
                ;
SystemType = this byte
                db      "RAW DOS$"
                db      "XMS DOS$"
                db      "  VCPI $"
                db      "  DPMI $"
        end

