        ; entry size = 16 bytes
EffectsText:
        db      '*   Set Tempo  *'      ;A
        db      '*Position  Jump*'      ;B
        db      '*Break  Pattern*'      ;C
        db      '* Volume Slide *'      ;D
        db      '*  Slide Down  *'      ;E
        db      '*   Slide Up   *'      ;F
        db      '* Port To Tone *'      ;G
        db      '*    Vibrato   *'      ;H
        db      '*    Tremor    *'      ;I
        db      '* Arpeggiation *'      ;J
        db      '*Vibrato+VSlide*'      ;K
        db      '* Port +VSlide *'      ;L
        db      '*  NO  EFFECT  *'      ;M
        db      '*  NO  EFFECT  *'      ;N
        db      '* SampleOffset *'      ;O
        db      '*  EFFECT  P   *'      ;P
        db      '*    Retrig    *'      ;Q
        db      '*   Tremolo    *'      ;R
        db      '* General Shit *'      ;S
        db      '*  Set Speed   *'      ;T
        db      '* Fine Vibrato *'      ;U
        db      '*Set Global Vol*'      ;V
        db      '*   EFFECT W   *'      ;W
        db      '*   EFFECT X   *'      ;X
        db      '*   EFFECT Y   *'      ;Y
        db      '*   EFFECT Z   *'      ;Z

NotesNames      = this byte
db 'C',17H,'-',17H,'?',17H,0,0
db 'C',17H,'#',17H,'?',17H,0,0
db 'D',17H,'-',17H,'?',17H,0,0
db 'D',17H,'#',17H,'?',17H,0,0
db 'E',17H,'-',17H,'?',17H,0,0
db 'F',17H,'-',17H,'?',17H,0,0
db 'F',17H,'#',17H,'?',17H,0,0
db 'G',17H,'-',17H,'?',17H,0,0
db 'G',17H,'#',17H,'?',17H,0,0
db 'A',17H,'-',17H,'?',17H,0,0
db 'A',17H,'#',17H,'?',17H,0,0
db 'B',17H,'-',17H,'?',17H,0,0
db 'B',17H,'-',17H,'?',17H,0,0
db ' ',17H,' ',17H,' ',17H,0,0

PlayerName:
db      'FonkPlay vA.dos32 by Psyke/DCB (10/1995)'
PlayerS = $ - PlayerName

SpeedText:
db      'Speed:  /    '
RowText:
db      'Row:  /64'
OrderText:
db      'Order:   /   '

Channels:
db      '1 ','2 ','3 ','4 ','5 ','6 ','7 ','8 ','9 ','10','11','12','13','14'
db      '15','16'

TestText:
I = 0
REPT 32
        db '+'
        db I
        I = I + 1
ENDM
