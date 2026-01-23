ChanInfo        Struc
                ChanFlag        db 0    ; if bit 7 = 1 then unused channel
                                        ; if bit 6 = 1 then must update channel
                ;
                SampHeader      dd 0    ; offset of Sample header in mem
                ;
                Volume          db 0    ; current channel volume
                Gus_Volume      dw 0    ; Hardware volume
                s3mNote         db 0    ; byte taken from the packed patterm
                NotePeriod      dw 0    ; s3m Period
                OldNotePeriod   dw 0    ;
                BasePeriod      dw 8363 ; base period (tune)
                FreqVal         dw 0    ; GUS Frequence of the voice
                OffsetAdd       dw 0    ; for Offset Add Effect
                CurrSamp        db 0    ; current sample
                ;
                LowClip         dw ?    ; Lowest possible period
                HiClip          dw ?    ; Highest possible period
                ;
                Effect          db 0    ; effect number
                EfxParam        db 0    ; effect Parameter
                LastEfx         db 0    ; Last effect
                LastEfxParam    db 0    ; Last effect Parameter
                VibratoIndex    db 0    ; Used also in Tremolo
                Arp             dw 0,0,0; 3 frequencies
                ArpIndex        db 0    ; 1,2 or 3
                EffectTime      db 0
                PortStart       dw 0
                PortEnd         dw 0
                WaveForm        db 0    ; Hi nibble = Tremolo Wave Form
                                        ; Lo nibble = Vibrato Wave Form
                ;
                OldVolSlide     db 0    ; D (volume slides)
                OldVibrato      db 0    ; V (vibrato)
                OldTremor       db 0    ; I (Tremor)
                OldFineVibrato  db 0    ; U (fine vibrato)
                OldVibrato_K    db 0    ; K (vibrato + volume slide)
                OldArpeggio     db 0    ; J (Arpeggio)
                OldSlide        db 0    ;
                OldPortTo       db 0    ; G (Port to tone)
                OldPortTo_L     db 0    ; L ( G + volume slide)
                OldRetrig       db 0    ; Q
                OldTremolo      db 0    ;
                ;
                SampleOperation db 0    ; Playing? Idling? ..
                NoteBool        db 0    ; is there a note on this row?
                VolumeBar       db 0    ; = 1 if Must Kick Volume bar
                LoopBOOL        db 0    ; Looped ?
                Chan_Side       db 0    ; Panning
                ChannelSize = $ - ChanInfo
                ENDS

s3mHeaderS      Struc                                   ; Offset
                here = this byte
                s3mSongName     db      28 dup(0)       ; 0
                s3mFuckU1       db      0               ; 1CH
                s3mFileTyp      db      0               ; 1DH
                s3mFuckU2       dw      0               ; 1EH
                s3mOrdNum       dw      0               ; 20H
                s3mInsNum       dw      0               ; 22H
                s3mPatNum       dw      0               ; 24H
                s3mFlags        dw      0               ; 26H
                s3mCwt          dw      0               ; 28H (tracker/Version)
                s3mFfv          dw      0               ; 2AH (file fmt version)
                s3mID           db      4 dup (0)       ; 2CH (IDentification)
                s3mG_V          db      0               ; 30H (Global Volume)
                s3mI_S          db      0               ; 31H (Initial speed)
                s3mI_T          db      0               ; 32H (Initial tempo)
                s3mM_V          db      0               ; 33H (Master Volume)
                s3mFuckU3       db      10 dup (0)      ; 34H
                s3mSpecial      dw      0               ; 3EH
                s3mChannelsSett db      32 dup (0)      ; 40H (255 = unused,+128 disabled)
                s3mHeader_Size = $ - Here
                ENDS

s3mSamplesS     Struc
                here2   = this byte
                smpType         db      0               ; 0H
                smpFilename     db      12 dup (0)      ; 1H
                smpMemSeg       db      3 dup (0)       ; 0EH
                smpLength       dd      0               ; 10H
                smpLoopBeg      dd      0               ; 14H
                smpLoopEnd      dd      0               ; 18H
                smpVol          db      0               ; 1CH
                smpFuckU1       db      0               ; 1DH
                smpPack         db      0               ; 1EH
                smpFlag         db      0               ; 1FH
                smpC2Spd        dd      0               ; 20H
                smpLimits       dw      2 dup (0)       ; 24H (not used by ST)
                smpGp           dw      0               ; 26H
                smpSbFuck       dw      0               ; 28H
                smpGUSadress    dd      0               ; 2CH
                smpSampleName   db      28 dup (0)      ; 30H
                smpID           db      4 dup (' ')     ; 4CH "SCRS"
                smpSize = $ - here2
                ENDS
