    prg_npage = 1
    chr_npage = 1
    mapper = 0
    mirroring = 1

    .segment "INES"
    .byte $4e, $45, $53, $1a
    .byte prg_npage
    .byte chr_npage
    .byte ((mapper & $0f) << 4) | (mirroring & 1)
    .byte mapper & $f0
