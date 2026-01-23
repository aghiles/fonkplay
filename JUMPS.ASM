;------------------------------------------------
; One Call Effects :
; these effects are called once
align 16
PattJumps       dd offset SetTempo            ; A.
                dd offset PosJump             ; B.
                dd offset BreakPatt           ; C.
                dd offset VolumeComs          ; D.
                dd offset SlideComs           ; E.
                dd offset SlideComs           ; F.
                dd offset PortToInit          ; G.
                dd offset VibratoInit         ; H.
                dd offset TremorInit          ; I. Tremor
                dd offset ArpeggioInit        ; J.
                dd offset Dummy               ; K. Vibrat&Vslide
                dd offset PVSlideInit         ; L. Porto+VSlide
                dd offset Dummy               ; M.
                dd offset Dummy               ; N.
                dd offset SampleOff           ; O.
                dd offset Dummy               ; P.
                dd offset RetrigInit          ; Q. (retrig)
                dd offset TremoloInit         ; R. (tremolo)

Comment &
        In ExtraEffects, you'll find the following effects :
        o Set filter
        o Glissando
        o Set Finetune (ProTracker compatibility)
        o Set Vibrato waveform (0 - Sine , 1 - Ramp Down , 2 - Random)
        o Set Tremolo waveform (0 - Sine , 1 - Ramp Down , 2 - Random)
        o Amiga command
        o Stereo control (Panic.s3m only...)    (* not implemented *)
        o Pattern Loop
        o NoteCut
        o NoteDelay
        o FunkRepeat     (* not implemented *)
        &
                dd offset ExtraEffects        ; S.
                dd offset SpeedSet            ; T.
                dd offset VibratoInit         ; U.
                dd offset SetGlobalVol        ; V.
                dd offset Dummy               ; W.
                dd offset SetPanPos2          ; X.
                dd offset Dummy               ; Y.
                dd offset Dummy               ; Z.
;------------------------------------------------
; Multiple call effects:
EffectJumps     dd offset Dummy               ; A. SetTempo
                dd offset Dummy               ; B. PosJump
                dd offset Dummy               ; C. BreakPatt
                dd offset VolumeComs          ; D.
                dd offset SlideComs           ; E.
                dd offset SlideComs           ; F.
                dd offset PortToTone          ; G.
                dd offset Vibrato             ; H.
                dd offset Tremor              ; I.
                dd offset Arpeggio            ; J.
                dd offset VibratoVSlide       ; K.
                dd offset TonePortVSlide      ; L.
                dd offset Dummy               ; M.
                dd offset Dummy               ; N.
                dd offset Dummy               ; O.
                dd offset Dummy               ; P.
                dd offset Retrig              ; Q.
                dd offset Tremolo             ; R.
                dd offset ExtraEffects        ; S.
                dd offset Dummy               ; T.
                dd offset Vibrato             ; U.
                dd offset Dummy               ; V.
                dd offset Dummy               ; W.
                dd offset Dummy               ; X.
                dd offset Dummy               ; Y.
                dd offset Dummy               ; Z.

 ExtraEffectsTable = this word
                dd offset Dummy               ; S0x = Set Filter
                dd offset Dummy               ; S1x = Set Glissando Control
                dd offset SetFineTune         ; S2x = Set Fine Tune
                dd offset SetVibratoWave      ; S3x = Set vibrato waveform
                dd offset SetTremoloWave      ; S4x = Set Tremolo WaveForm
                dd offset Dummy               ; S5x
                dd offset Dummy               ; S6x
                dd offset Dummy               ; S7x
                dd offset SetPanPos           ; S8x
                dd offset Dummy               ; S9x
                dd offset StereoControl       ; SAx = Stereo Control (panic)
                dd offset PatternLoop         ; SBx = Pattern Loop
                dd offset CutNote             ; SCx = Note Cut
                dd offset DelayNote           ; SDx = Note Delay
                dd offset PatternDelay        ; SEx = Pattern Delay
                dd offset Dummy               ; SFx = FunkRepeat
