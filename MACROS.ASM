_SaveRegs       Macro
        mov     [eaxSave],eax
        mov     [ebxSave],ebx
        mov     [ecxSave],ecx
        mov     [edxSave],edx
        mov     [esiSave],esi
        mov     [edisave],edi
        mov     [ebpSave],ebp
        ENDM

_RestoreRegs    Macro
        mov     eax,[eaxSave]
        mov     ebx,[ebxSave]
        mov     ecx,[ecxSave]
        mov     edx,[edxSave]
        mov     esi,[esiSave]
        mov     edi,[edisave]
        mov     ebp,[ebpSave]
        ENDM
