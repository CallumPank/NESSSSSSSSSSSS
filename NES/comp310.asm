    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 1



PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
OAMADDR   = $2003
OAMDATA   = $2004
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007
OAMDMA    = $4014
JOYPAD1   = $4016
JOYPAD2   = $4017


BUTTON_A      = %10000000
BUTTON_B      = %01000000
BUTTON_Select = %00100000
BUTTON_Start  = %00010000
BUTTON_Up     = %00001000
BUTTON_Down   = %00000100
BUTTON_Left   = %00000010
BUTTON_Right  = %00000001



    .rsset $0010
joypad1_state      .rs 1

    .rsset $0200
sprite_player      .rs 4

    .rsset $0000
SPRITE_Y           .rs 1
SPRITE_TILE        .rs 1
SPRITE_ATTRIBUTE   .rs 1
SPRITE_X           .rs 1


    .bank 0
    .org $C000

; Initialisation code based on https://wiki.nesdev.com/w/index.php/Init_code
RESET:
    SEI        ; ignore IRQs
    CLD        ; disable decimal mode
    LDX #$40
    STX $4017  ; disable APU frame IRQ
    LDX #$ff
    TXS        ; Set up stack
    INX        ; now X = 0
    STX PPUCTRL  ; disable NMI
    STX PPUMASK  ; disable rendering
    STX $4010  ; disable DMC IRQs

    ; Optional (omitted):
    ; Set up mapper and jmp to further init code here.

    ; If the user presses Reset during vblank, the PPU may reset
    ; with the vblank flag still true.  This has about a 1 in 13
    ; chance of happening on NTSC or 2 in 9 on PAL.  Clear the
    ; flag now so the vblankwait1 loop sees an actual vblank.
    BIT PPUSTATUS

    ; First of two waits for vertical blank to make sure that the
    ; PPU has stabilized
vblankwait1:
    BIT PPUSTATUS
    BPL vblankwait1

    ; We now have about 30,000 cycles to burn before the PPU stabilizes.
    ; One thing we can do with this time is put RAM in a known state.
    ; Here we fill it with $00, which matches what (say) a C compiler
    ; expects for BSS.  Conveniently, X is still 0.
    TXA
clrmem:
    STA $000,x
    STA $100,x
    STA $300,x
    STA $400,x
    STA $500,x
    STA $600,x
    STA $700,x  ; Remove this if you're storing reset-persistent data

    ; We skipped $200,x on purpose.  Usually, RAM page 2 is used for the
    ; display list to be copied to OAM.  OAM needs to be initialized to
    ; $EF-$FF, not 0, or you'll get a bunch of garbage sprites at (0, 0).

    LDA #$FF
    STA $200,x


    INX
    BNE clrmem

    ; Other things you can do between vblank waits are set up audio
    ; or set up other mapper registers.

vblankwait2:
    BIT PPUSTATUS
    BPL vblankwait2

    ; End of initialisation code -

    ;Resets the PPU
    LDA PPUSTATUS

    ; Writing address $3F10 to the PPU which deals with background colour
    LDA #$3F
    STA PPUADDR
    LDA #$10
    STA PPUADDR


    ;Wrting the background colour
    LDA #$0f
    STA PPUDATA


    ;Writing the palette colour sprite 1
    LDA #$30
    STA PPUDATA
    LDA #$26
    STA PPUDATA
    LDA #$05
    STA PPUDATA
    LDA #$26
    STA PPUDATA


    ;Wrting the palette colour
    LDA #$30
    STA PPUDATA
    LDA #$26
    STA PPUDATA
    LDA #$05
    STA PPUDATA



    ;Write Sprite Data

    LDA #120    ; Y position
    STA sprite_player + SPRITE_Y
    LDA #0      ; Tile Number
    STA sprite_player + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player + SPRITE_ATTRIBUTE
    LDA #128    ;X position
    STA sprite_player + SPRITE_X



    LDA #%10000000 ; Enable Non Maskable interrupt(NMI)
    STA PPUCTRL

    LDA #%00010000 ;Enable sprites
    STA PPUMASK


    ;enter an infinite loop


forever:
    JMP forever

; ---------------------------------------------------------------------------

; NMI is called on every frame
NMI:
    ;Initialise controller 1

    LDA #1
    STA JOYPAD1
    LDA #0
    STA JOYPAD1

    ;Read Joypad state
    LDX #0
    STX joypad1_state
ReadController:
    LDA JOYPAD1
    LSR A
    ROL joypad1_state
    INX
    CPX #8
    BNE ReadController

    ;React to right button
    LDA joypad1_state
    AND #BUTTON_Right
    BEQ ReadRight_Done
    LDA sprite_player + SPRITE_X
    CLC
    ADC #1
    STA sprite_player + SPRITE_X


ReadRight_Done:

    ;Read down button
    LDA joypad1_state
    AND #BUTTON_Down
    BEQ ReadDown_Done
    LDA sprite_player + SPRITE_Y
    CLC
    ADC #1
    STA sprite_player + SPRITE_Y

ReadDown_Done:

;Read up button
    LDA joypad1_state
    AND #BUTTON_Up
    BEQ ReadUp_Done
    LDA sprite_player + SPRITE_Y
    SEC
    SBC #1
    STA sprite_player + SPRITE_Y

ReadUp_Done:

;Read left button
    LDA joypad1_state
    AND #BUTTON_Left
    BEQ ReadLeft_Done
    LDA sprite_player + SPRITE_X
    SEC
    SBC #1
    STA sprite_player + SPRITE_X

ReadLeft_Done:

    ;Copy sprite data to PPU

    LDA #0
    STA OAMADDR
    LDA #$02
    STA OAMDMA



    RTI         ; Return from interrupt

; ---------------------------------------------------------------------------

    .bank 1
    .org $FFFA
    .dw NMI
    .dw RESET
    .dw 0

; ---------------------------------------------------------------------------

    .bank 2
    .org $0000

    .incbin "comp310Sprite"

    ; TODO: add graphics
