; S3M asm loading module. Blouche , bamougne.


; STRUCS.ASM for structures description

; constants
TRUE            = 1
FALSE           = 0
ASMRULEZ        = TRUE
; file cnsts
SEEK_BEG        = 0
SEEK_CUR        = 1
SEEK_END        = 2
; error flgs
NOFILE          = -1                    ; file not found
BADFILE         = -2                    ; not a s3m or bad offset in EAX
NOMEM           = -3                    ; Patterns or samples.

; variables
s3mHeader       s3mHeaderS 1 dup (<>)
;
LoadVarStart = this byte
PattOrder       db 256 dup (0)          ; order length = 256
InsPara         dw 100 dup (0)          ; maximum of 100 instruments
PatPara         dw 100 dup (0)          ; maximum of 100 patterns
PatternPointer  dd 101 dup (0)
;
GUSMem          dd 0
PatternsSize    dd 0                    ; Number of Bytes used by Patterns
LargestSample   dd 0                    ;
TotalSamplea    dd 0                    ; Total sample size
LoadVarSize = $ - LoadVarStart
;
ChannelsPan     db 32 dup (7)
DefaultPan      db 32 dup (7)           ; Mono

NullByte        db 128                  ; not so null.
;
;
FileHandle      dw 0
SeekVal         dd 0
;
SampHeadersSeg  dd 0
SamplesSeg      dd 0
PatternsSeg     dd 0
;
LoadModule Proc Near
        push    esi edi ebx edx ecx ebp
        cli
        mov     [SeekVal],eax
        cld                             ; don't forget this one!
        mov     ax,03d00h
        int     021h
        jnc     lmOpenedOk
        mov     ax,NOFILE
        jmp     lmExit
lmOpenedOk:
        mov     [FileHandle],ax
        mov     eax,[SeekVal]
        or      eax,eax
        jz      lmNoSeek
        mov     edx,eax
        mov     al,SEEK_END
        call    FileSeek
lmNoSeek:
        ;-------Reset all variables, because we can be called several times
        mov     ax,ds
        mov     es,ax
        mov     edi,offset LoadVarStart
        mov     ecx,LoadVarSize
        xor     ax,ax
        cld
        repz    stosb

        ;-------Load Header
        mov     ecx,s3mHeader_Size
        mov     edx,offset s3mHeader
        call    ReadFile

        ;-------Check if it's a S3M file.
        cmp     dword ptr [s3mHeader.s3mID],'MRCS'      ; ST module?(ID='SCRM')
        je      lsGoodS3M
        stc                     ; carry flag on for incoming error checks.
        mov     ax,BADFILE
        jmp     lmExit1
lsGoodS3M:

        ;-------Set Period limits (for amiga compatibility mode..slides..etc)
        mov     al,0            ; C-0
        mov     cl,07BH         ; B#7
        test    [s3mHeader.s3mFlags],16 ; amiga limits?
        jz      PcTracked
        mov     al,030H         ; C-3
        mov     cl,05BH         ; B#5
PcTracked:
        mov     ebp,8363
        push    ebp
        call    CalcS3MNote
        mov     [Limits],bp
        pop     ebp
        mov     al,cl
        call    CalcS3MNote
        mov     [Limits+2],bp

        ;------- Set Default Pannings
        mov     al,[s3mHeader.s3mM_V]
        test    al,10000000b
        jz      MonoS3M
        mov     ax,ds
        mov     es,ax
        mov     edi,offset DefaultPan
        mov     eax,0C030C03H   ; Left-Right-Left-Right-...
        mov     ecx,4           ; 4*4 = 16 channels
        repz    stosd
MonoS3M:

        ;-------Init Channels settings
        mov     esi,offset s3mHeader.s3mChannelsSett
        mov     edi,offset SampChans
        xor     edx,edx
        mov     ecx,16
        icsLoop:
        lodsb
        test    al,128                  ; unused
        jz      icsChannelOn
        mov     [edi.ChanFlag],128       ; channel off
        jmp     icsJmp
        icsChannelOn:
        mov     edx,ecx
        icsJmp:
        add     edi,ChannelSize
        dec     ecx
        jnz     icsLoop
        ;
        mov     eax,16
        sub     eax,edx
        inc     eax
        cmp     eax,16
        jbe     NoChannelsClip
        mov     eax,16
NoChannelsClip:
        mov     [NumChans],eax
        cmp     eax,14
        jbe     NoVoicesClip
        mov     [NumVoices],al
        sub     eax,15
        mov     ebx,[Divisors+eax*4]
        mov     [CurrDivisor],ebx
NoVoicesClip:
        ;
        ;------- Now we can init the GUS
        call    InitDevice
        ;
        ;-------Set Some vars for the playing process
        mov     al,byte ptr [s3mHeader.s3mI_S]
        mov     [Tempo],al
        mov     [TempoWait],al
        movzx   ax,byte ptr [s3mHeader.s3mI_T]
        call    SpeedSet
        ;
        ;-------Load pattern order
        mov     cx,[s3mHeader.s3mOrdNum]
        mov     edx,offset PattOrder
        call    ReadFile

        ;-------Load Instrument parapointers
        mov     cx,[s3mHeader.s3mInsNum]
        add     cx,cx
        mov     edx,offset InsPara
        call    ReadFile

        ;-------Load Patterns parapointers.
        mov     cx,word ptr [s3mHeader.s3mPatNum]
        add     cx,cx
        mov     edx,offset PatPara
        call    ReadFile

        ;-------Load Channel default pan positions
        mov     cx,16           ; maximum of 16 channels
        mov     edx,offset ChannelsPan
        call    ReadFile

        ;-------Allocate Memory for sample headers
        movzx   eax,[s3mHeader.s3mInsNum]
        imul    eax,smpSize              ; smpSize = size of 1 sample header
        mov     edx,eax
        mov     ax,0EE42H
        int     031h                    ; allocate memory
        jnc     lmNoMemProblem0
        mov     ax,-1
        jmp     lmExit1                 ; close file & exit
lmNoMemProblem0:
        mov     [SampHeadersSeg],edx    ; save adress

        ;-------Read all sample headers.
        mov     edi,offset InsPara
        mov     esi,[SampHeadersSeg]
        movzx   ecx,[s3mHeader.s3mInsNum]
        mov     [LargestSample],0
SampleHeaderLoad:
        push    edi ecx esi
        movzx   edx,word ptr [edi]      ; get a parapointer
        shl     edx,4                   ; * 16
        mov     al,SEEK_BEG             ; seek from beginning of file
        call    FileSeek
        ; read Sample Header
        mov     cx,smpSize
        mov     edx,esi
        call    ReadFile
        ; Find out the larget sample
        mov     eax,[esi.smpLength]
        cmp     eax,[LargestSample]
        jbe     shlEnough
        mov     [LargestSample],eax
shlEnough:
        pop     esi ecx edi
        add     esi,smpSize
        inc     edi
        inc     edi
        loop    SampleHeaderLoad

        ;------- Load Instrument to GUS memory (slow&ugly)
        mov     edx,[LargestSample]
        mov     ax,0EE42H
        int     031H            ; alloc memory
        mov     [SamplesSeg],edx
        ;
        mov     edi,[SampHeadersSeg]
        movzx   ecx,[s3mHeader.s3mInsNum]
LoadInstruments:
        push    ecx edi esi
        xor     edx,edx
        mov     dl,byte ptr [edi.smpMemSeg]
        shl     edx,16
        mov     dx,word ptr [edi.smpMemSeg+1]
        or      edx,edx
        jz      BadSample
        shl     edx,4
        mov     al,SEEK_BEG             ; seek from beginning.
        call    FileSeek
        mov     cx,word ptr [edi.smpLength]
        or      cx,cx
        je      BadSample
        mov     edx,[SamplesSeg]
        call    ReadFile
        ;******************************
        mov     cx,word ptr [edi.smpLength]
        mov     bp,word ptr [GUSMem]
        mov     bl,byte ptr [GUSMem+2]
        mov     word ptr [edi.smpGUSadress],bp
        mov     byte Ptr [edi.smpGUSadress+2],bl
        mov     esi,[SamplesSeg]
        mov     dx,[CommandPort]
MSamp2GUS:                              ; cx = byte count
        call    UploadByte              ; one call per byte. Slow but small. :P
        inc     esi
        dec     cx
        jnz     MSamp2GUS

        mov     cx,8
        cmp     [edi.smpFlag],1
        jne     SampleNotLooped
        ; Sample Looped if you're here.
        movzx   esi,word ptr [edi.smpLoopBeg]
        add     esi,[SamplesSeg]
AntiClick1:
        call    UploadByte
        inc     esi
        dec     cx
        jnz     AntiClick1
        jmp     AntiClickEnd

SampleNotLooped:
        mov     esi,offset NullByte
lmAC2:  call    UploadByte      ; Blouche!
        dec     cx
        jnz     lmAC2
AntiClickEnd:
        ;
        mov     word ptr [GUSMem],bp
        mov     byte ptr [GUSMem+2],bl
        ;********************************
BadSample:
        pop     esi edi ecx
        add     edi,smpSize
        dec     cx
        jnz     LoadInstruments
        ;
        mov     ax,0EE40h
        int     031h            ; Free previously allocated memory. DOS32

        ;------- Allocate Memory for Patterns
        mov     edx,200*1024            ; a big chunk
        mov     ax,0EE42h
        int     031H                    ; alloc. largest block. DOS32
lmNoMemProblem1:
        mov     [PatternsSeg],edx

        ;-------Load All Patterns from .s3m
        mov     edi,offset PatPara       ; di = pointer to "parapointers"
        mov     cx,[s3mHeader.s3mPatNum]
        mov     esi,[PatternsSeg]
        mov     ebp,offset PatternPointer+4
        mov     [PatternsSize],0
LoadPatterns:
        push    cx ebp
        ;
        xor     cx,cx
        movzx   edx,word ptr [edi]        ; get a "parapointer"
        or      dx,dx
        jne     lmGoodPattern
        mov     word ptr [esi],0
        jmp     lmDontReadSize
lmGoodPattern:
        shl     edx,4
        mov     al,SEEK_BEG             ; seek from beginning
        call    FileSeek
        mov     cx,2                    ; read pattern length
        mov     edx,esi
        call    ReadFile
lmDontReadSize:
        movzx   ecx,word ptr [esi]
        add     [PatternsSize],ecx
        mov     eax,ecx                   ; get length
        add     eax,dword ptr ds:[ebp-4] ; and add it to previous pattern offset
        mov     dword ptr ds:[ebp],eax  ; so we get the offset of the current
                                        ; pattern
        or      cx,cx                   ; check if pattern length = 0
        jz      BadPattern              ; dont' read if so.

        mov     edx,esi
        call    ReadFile                ; read pattern
BadPattern:
        pop     ebp cx
        ;
        mov     esi,dword ptr ds:[ebp]
        add     esi,[PatternsSeg]
        add     edi,2                    ; next parapointer
        add     ebp,4                    ; next pattern offset entry.
        dec     cx
        jnz     LoadPatterns

        ;------------------------------- Set Channels Panning
        mov     ebx,offset DefaultPan
        mov     esi,offset ChannelsPan
        mov     edi,offset SampChans
        mov     ecx,16
PanSetLoop:
        mov     al,[ebx]
        mov     [edi.Chan_Side],al       ; make it default for now
        lodsb                   ; get a byte
        and     al,0111111b     ; strips reserved bits
        test    al,100000b      ; test for bit 5
        jz      UseDefaultPan
        and     al,01111b       ; MASK Pan Position
        mov     [edi.Chan_Side],al
UseDefaultPan:
        add     edi,size ChanInfo
        inc     ebx
        loop    PanSetLoop
        clc

lmExit1:pushf                   ; save flags ( we need carry flag )
        push    ax              ; save error code (if there is one)
        mov     bx,[FileHandle]
        mov     ah,03eh
        int     021H            ; Close the file
        pop     ax
        popf
lmExit: pop     ebp ecx edx ebx edi esi
        sti
        ret
        ENDP

UploadByte      Proc    Near
        mov     al,DRAMAddrLo
        out     dx,al
        inc     dx
        mov     ax,bp
        out     dx,ax
        dec     dx
        mov     al,DRAMAddrHi
        out     dx,al
        add     dx,2
        mov     al,bl
        out     dx,al
        add     dx,2
        mov     al,[esi]         ; copy first bytes to the End of the loop
        add     al,128
        out     dx,al
        sub     dx,4
        add     bp,1
        adc     bl,0
        ret
        ENDP

FileSeek Proc   Near
; Call with EDX = Offset from beginning of the File.
; al = seek mode.
        pushad
        rol     edx,16
        mov     cx,dx
        rol     edx,16
        mov     bx,[FileHandle]
        mov     ah,042H
        int     021H
        popad
        ret
        ENDP

ReadFile Proc Near
; Call with cx = number of bytes to read.
;        ds:dx = buffer.
        pushad
        mov     ah,03fh
        mov     bx,[FileHandle]
        int     021h
        popad
        ret
        ENDP

DeAlloc Proc Near
        ret
        ENDP
