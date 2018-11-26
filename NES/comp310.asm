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

Enemy_Team_Width = 1
Enemy_Team_Height = 3
NUM_Enemies = Enemy_Team_Width * Enemy_Team_Height
Enemy_Spacing = 10

    .rsset $0000
joypad1_state      .rs 1
bullet_alive       .rs 1
temp_x             .rs 1
temp_y             .rs 1
zombie_info        .rs 4 * NUM_Enemies
nametable_address  .rs 2
scroll_x           .rs 1


    .rsset $0200
sprite_player      .rs 4
sprite_bullet      .rs 4
sprite_zombie      .rs 4 * NUM_Enemies
sprite_zombie_1      .rs 4 * NUM_Enemies
sprite_zombie_2      .rs 4 * NUM_Enemies

    .rsset $0000
SPRITE_Y           .rs 1
SPRITE_TILE        .rs 1
SPRITE_ATTRIBUTE   .rs 1
SPRITE_X           .rs 1

    .rsset $000
Zombie_Direction    .rs 1
Zombie_Alive        .rs 1

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

    ; Writing address $3F10 (background palette) to the PPU which deals with background colour
    LDA #$3F
    STA PPUADDR
    LDA #$10
    STA PPUADDR

    ;Writing the background colour
    LDA #$03
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

    ; Writing address $3F00 (background palette) to the PPU which deals with background colour
    LDA #$3F
    STA PPUADDR
    LDA #$00
    STA PPUADDR

    ;Writing the background colour
    LDA #$0F
    STA PPUDATA
    LDA #$24
    STA PPUDATA
    LDA #$11
    STA PPUDATA
    LDA #$0D
    STA PPUDATA

    ;Wrting the palette colour
    LDA #$0D
    STA PPUDATA
    LDA #$11
    STA PPUDATA
    LDA #$24
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

    ;Initialise zombie 0
    LDX #0
    LDA #Enemy_Team_Height * Enemy_Spacing
    STA temp_y
InitZombie_LoopY:
    LDA #Enemy_Team_Width * Enemy_Spacing
    STA temp_x
InitZombie_LoopX:
    STA sprite_zombie+SPRITE_X, x
    LDA temp_y
    STA sprite_zombie+SPRITE_Y, x
    LDA #2
    STA sprite_zombie+SPRITE_TILE, x
    LDA #0
    STA sprite_zombie+SPRITE_ATTRIBUTE, x
    LDA #1
    STA zombie_info + Zombie_Direction, x
    STA zombie_info + Zombie_Alive, x
    ; increment x by 4
    TXA
    CLC
    ADC #4
    TAX
    ; loop check for x value
    LDA temp_x
    SEC
    SBC #Enemy_Spacing
    STA temp_x
    BNE InitZombie_LoopX
    ; loop check for y value
    LDA temp_y
    SEC
    SBC #Enemy_Spacing
    STA temp_y
    BNE InitZombie_LoopY

    ;Initialise zombie 1
    LDX #0
    LDA #Enemy_Team_Height * Enemy_Spacing
    STA temp_y
InitZombie_1_LoopY:
    LDA #Enemy_Team_Width * Enemy_Spacing
    STA temp_x
InitZombie_1_LoopX:
    STA sprite_zombie_1+SPRITE_X, x
    LDA temp_y
    STA sprite_zombie_1+SPRITE_Y, x
    LDA #3
    STA sprite_zombie_1+SPRITE_TILE, x
    LDA #0
    STA sprite_zombie_1+SPRITE_ATTRIBUTE, x
    ; increment x by 4
    TXA
    CLC
    ADC #4
    TAX
    ; loop check for x value
    LDA temp_x
    SEC
    SBC #Enemy_Spacing
    STA temp_x
    BNE InitZombie_1_LoopX
    ; loop check for y value
    LDA temp_y
    SEC
    SBC #Enemy_Spacing
    STA temp_y
    BNE InitZombie_1_LoopY

    ;Name Table Data_0
    LDA #$20          ;Writing addres $2000 to PPUADDR
    STA PPUADDR
    LDA #$00
    STA PPUADDR


    LDA #LOW(NameTableData)
    STA nametable_address
    LDA #HIGH(NameTableData)
    STA nametable_address+1
LoadNameTable_OuterLoop:
    LDX #0
LoadNameTable_InnerLoop:
    LDA [nametable_address], Y
    BEQ LoadNametable_End
    STA PPUDATA
    INY
    BNE LoadNameTable_InnerLoop
    INC nametable_address+1
    JMP LoadNameTable_OuterLoop
LoadNametable_End:

    ;Load attribute table
    LDA #$23          ;Writing addres $23C0 to PPUADDR
    STA PPUADDR
    LDA #$C0
    STA PPUADDR

    LDA #%01010101
    LDX #64
LoadAttributes_Loop:
    STA PPUDATA
    DEX
    BNE LoadAttributes_Loop


  ;   ;Name Table Data_1
  ;   LDA #$24          ;Writing addres $2400 to PPUADDR
  ;   STA PPUADDR
  ;   LDA #$00
  ;   STA PPUADDR
  ;
  ;
  ;   LDA #LOW(NameTableData)
  ;   STA nametable_address
  ;   LDA #HIGH(NameTableData)
  ;   STA nametable_address+1
  ; LoadNameTable2_OuterLoop:
  ;   LDX #0
  ; LoadNameTable2_InnerLoop:
  ;   LDA [nametable_address], Y
  ;   BEQ LoadNametable2_End
  ;   STA PPUDATA
  ;   INY
  ;   BNE LoadNameTable2_InnerLoop
  ;   INC nametable_address+1
  ;   JMP LoadNameTable2_OuterLoop
  ; LoadNametable2_End:
  ;
  ;   ;Load attribute table_1
  ;   LDA #$27          ;Writing addres $27C0 to PPUADDR
  ;   STA PPUADDR
  ;   LDA #$C0
  ;   STA PPUADDR
  ;
  ;   LDA #%01010101
  ;   LDX #64
  ; LoadAttributes2_Loop:
  ;   STA PPUDATA
  ;   DEX
  ;   BNE LoadAttributes2_Loop


    LDA #%10000000 ; Enable Non Maskable interrupt(NMI)
    STA PPUCTRL

    LDA #%00011000 ;Enable sprites and background
    STA PPUMASK

    LDA #0
    STA PPUSCROLL ; X scroll
    STA PPUSCROLL ;Y scroll

    ;enter an infinite loop


forever:
    JMP forever

; ---------------------------------------------------------------------------

; NMI is called on every frame
NMI:
    LDA sprite_zombie + sprite_player
    CLC
    ADC #1
    STA sprite_zombie + sprite_player

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

    ;react to A button
    LDA joypad1_state
    AND #BUTTON_A
    BEQ ReadA_Done

    ;Spawn Bullet if one is not active
    LDA bullet_alive
    BNE ReadA_Done
    ;if no bullet active spawn one
    LDA #1
    STA bullet_alive
    LDA sprite_player + SPRITE_Y   ; Y position of bullet
    STA sprite_bullet + SPRITE_Y
    LDA #1      ; Tile Number
    STA sprite_bullet + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_bullet + SPRITE_ATTRIBUTE
    LDA sprite_player + SPRITE_X    ;X position of bullet
    STA sprite_bullet + SPRITE_X

ReadA_Done:

    ;bullet update
    LDA bullet_alive
    BEQ UpdateBullet_Done
    LDA sprite_bullet + SPRITE_Y
    SEC
    SBC #1
    STA sprite_bullet + SPRITE_Y
    BCS UpdateBullet_Done
    ;if carry flag is clear, bullet has left the screen, destroy it
    LDA #0
    STA bullet_alive

UpdateBullet_Done:

  ;Update zombies
  LDX #(NUM_Enemies-1) * 4

UpdateEnemies_Loop:
  ;check if enemy alive
  LDA zombie_info+Zombie_Alive, x
  BEQ UpdateZombie_Next
  LDA sprite_zombie+SPRITE_X, x
  CLC
  ADC zombie_info + Zombie_Direction, x
  STA sprite_zombie+SPRITE_X, x
  CMP #256 - Enemy_Spacing
  BCS UpdateZombies_Reverse
  CMP #Enemy_Spacing
  BCC UpdateZombies_Reverse
  JMP UpdateZombies_NoReverse

UpdateZombies_Reverse:
  ;Reverse direction
  LDA #0
  SEC
  SBC zombie_info + Zombie_Direction, x
  STA zombie_info + Zombie_Direction, x

UpdateZombies_NoReverse:
  ;check collision between enemy and bullet
  LDA sprite_zombie + SPRITE_X, x ; calculate x postion of enemy - width of bullet
  SEC
  SBC #8                          ; Assume width is 8x8 sprites
  CMP sprite_bullet + SPRITE_X    ; compare with x bullet
  BCS UpdateEnemies_NoCollision
  CLC
  ADC #16
  CMP sprite_bullet + SPRITE_X
  BCC UpdateEnemies_NoCollision

  LDA sprite_zombie + SPRITE_Y, x ; calculate y postion of enemy - width of bullet
  SEC
  SBC #8                          ; Assume width is 8x8 sprites
  CMP sprite_bullet + SPRITE_Y    ; compare with y bullet
  BCS UpdateEnemies_NoCollision
  CLC
  ADC #16
  CMP sprite_bullet + SPRITE_Y
  BCC UpdateEnemies_NoCollision
  ; Handle collision
  LDA #0
  STA bullet_alive
  STA zombie_info + Zombie_Alive, x            ;Destroy Bullet
  LDA #$FF
  STA sprite_bullet+SPRITE_Y
  STA sprite_zombie+SPRITE_Y, x

UpdateEnemies_NoCollision:

  ; LDA scroll_x
  ; CLC
  ; ADC #1
  ; STA scroll_x
  ; STA PPUSCROLL
  ; LDA #0
  ; STA PPUSCROLL

UpdateZombie_Next:
  DEX
  DEX
  DEX
  DEX
  BPL UpdateEnemies_Loop

  ;Copy sprite data to PPU
  LDA #0
  STA OAMADDR
  LDA #$02
  STA OAMDMA



  RTI         ; Return from interrupt

; ---------------------------------------------------------------------------

NameTableData:
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23,$20,$21,$22,$23
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13,$10,$11,$12,$13
  .db $00 ;Null Terminator
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------

    .bank 1
    .org $FFFA
    .dw NMI
    .dw RESET
    .dw 0

; ---------------------------------------------------------------------------

    .bank 2
    .org $0000

    .incbin "spriteMan"

    ; TODO: add graphics
