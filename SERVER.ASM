GetPointers     Proc    Near
        ; OUT : ebx = pointer to First channel
        ;       edi = pointer to first instrument
        mov     ebx,offset SampChans
        mov     edi,cs:[SampHeadersSeg]
        ret
        ENDP

GetInfos        Proc    Near
        ; OUT   al : Tempo
        ;       cx : Speed
        ;       dl : Row
        ;       dh : Order
        ;       bp : Current Playing Pattern
        ;
        mov     al,cs:[Tempo]
        movzx   cx,cs:[PlayerSpeed]
        mov     dl,byte ptr cs:[Row_In_Pattern]
        mov     dh,byte ptr cs:[CurrentOrder]
        mov     ah,byte ptr cs:[s3mHeader.s3mOrdNum]
        ret
        ENDP

SetInfos        Proc    Near
        ; IN    al : Tempo or -1
        ;       cx : Speed or 0
        ;       dl : Row or -1
        ;       dh : Order
        push    ds
        ;
        mov     ax,@code
        mov     ds,ax
        ;
        cmp     al,-1
        je      siNoTempo
        call    SetTempo        ; This is an effect  (see efx.asm)
siNoTempo:
        or      cx,cx
        jz      siNoSpeed
        mov     [Speed],cx
siNoSpeed:
        cmp     dl,63
        ja      siNoRow
        mov     [BreakToRow],dl
siNoRow:
        ;
        pop     ds
        ret
        ENDP

GetChanNum      Proc    Near
        ; OUT   ecx : Number of use channels
        mov     ecx,cs:[NumChans]
        ret
        ENDP

