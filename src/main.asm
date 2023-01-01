INCLUDE "src/hardware.inc" 

SECTION "Start", ROM0

EntryPoint::
	; Do not turn the LCD off outside of VBlank
WaitVBlank:
	ldio a, [rLY]
	cp 144
	jp c, WaitVBlank

	; Turn the LCD off
	ld a, 0
	ldh [rLCDC], a 

	; Reset hardware OAM
    ld a, 0
    ld b, 160
    ld hl, _OAMRAM
ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam

    ; Initialize variables
    ld a, 1
    ld [wBallYVelocity], a

    
    ld a, -1
    ld [wBallXVelocity], a
    
    ld a, 40 + 16
    ld [wP_PaddleYPos], a
    
    ld a, 1 + 8
    ld [wP_PaddleXPos], a
    

	; --------------------------------------------------------------------
	; Paddle
	; --------------------------------------------------------------------
	ld hl, _OAMRAM
	ld a, [wP_PaddleYPos]
	ld [hli], a
	ld a, [wP_PaddleXPos]
	ld [hli], a
	ld a, 0
	ld [hli], a
	ld [hl], a
	
	ld de, Paddle
	ld hl, $8000
	ld bc, PaddleEnd - Paddle
	call Memcpy
	; ----------------------------------------------------------------------
	; Ball
	; ----------------------------------------------------------------------
	ld hl, _OAMRAM + 8
	ld a, 60 + 16
	ld [hli], a 
	ld a, 76 + 8
	ld [hli], a 
	ld a, 2
	ld [hli], a
	ld a, 0 
	ld [hl], a 

	ld de, Ball
	ld hl, $8020
	ld bc, BallEnd - Ball
	call Memcpy
	; Turn the LCD on
	ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_OBJ16
	ldh [rLCDC], a 

	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a 
	ld [rOBP0], a
	ld [rOBP1], a 
Main:
    ld a, [rLY]
    cp 144
    jp nc, Main
WaitVBlank2:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank2
    call Input
    call MoveBall
    call MovePaddle
    jp Main
    
MoveBall:
    ld a, [_OAMRAM + 8]
    ld b, a
    ld a, [wBallYVelocity] ; wBallYVelocity is set to 1 in the init code.
    add a, b
    
CheckBottom:
    cp a, 153 ; Did the ball hit the bottom of the screen?
    jr nz, CheckTop
    ld a, -1
    ld [wBallYVelocity], a
    jr SetYPos

CheckTop:
    cp a, 10 ; Did the ball hit the top of the screen?
    jr nz, SetYPos
    ld a, 1
    ld [wBallYVelocity], a
    jr SetYPos 
CheckPaddle:
	ld a, [_OAMRAM + 9]
	 ld a, b
	 ld a, [wP_PaddleXPos]
	 cp a, b
	 jr z, Collision
	
	 ld a, [_OAMRAM + 8]
	 ld b, a
	 ld a, [wP_PaddleYPos]
	 cp a, b
	 jr nc, NoCollision
	 add a, 14
	 cp a, b
	 jr nc, Collision
	;fall through
SetYPos:
    ld a, [_OAMRAM + 8]
    ld b, a
    ld a, [wBallYVelocity]
    add a, b
    ld [_OAMRAM  + 8], a
MoveBallX:
	ld a, [_OAMRAM + 9]
	ld b, a
	ld a, [wBallXVelocity]
	jr SetXPos
CheckRight:
    cp a, 153 ; Did the ball hit the bottom of the screen?
    jr nz, SetXPos
    ld a, -1
    ld [wBallXVelocity], a
    jr SetYPos
.checkPaddle:
	call CheckPaddle ; Did the ball hit the paddle?
    jr nc, SetYPos
    ld a, [wBallYVelocity] ; Negate the velocity
    cpl
    inc a
    ld [wBallYVelocity], a
SetXPos:
	ld a, [_OAMRAM + 9]
	ld b, a
	ld a, [wBallXVelocity]
	add a, b
	ld [_OAMRAM +  9], a
	ret
NoCollision:
	ret
	scf
Collision:
	or a ; Clear the carry flag so that collision can be processed
	ret
MovePaddle:
; First, check if the up button is pressed.
CheckUp:
	ld a, [wCurKeys]
	and a, PADF_UP
	jp z, CheckDown
Up:
	ld a, [_OAMRAM]
	dec a
	ld b, a
	ld a, [wP_PaddleYPos]
	dec a
	ld a, b
	; If we've already hit the top of the screen, don't move
	cp a, 15
	ret z
	ld [_OAMRAM], a
; Then check the down button
CheckDown:
	ld a, [wCurKeys]
	and a, PADF_DOWN
	ret z
Down:
	ld a, [_OAMRAM]
	inc a 
	ld b, a
	ld a, [wP_PaddleYPos]
	inc a
	ld a, b
	; If we've already hit the bottom of the screen, don't move
	cp a, 145 
	ret z
	ld [_OAMRAM], a 
	ret
	
; --------------------------------------------------------------------------------------------------------------
; Ball to screen collision
; --------------------------------------------------------------------------------------------------------------
	
; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
Memcpy:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, Memcpy
    ret

Paddle:
	dw `00033000
	dw `00311300
	dw `00312300
	dw `00312300
	dw `00312300
	dw `00312300
	dw `00312300
	dw `00312300
	dw `00312300
	dw `00312300
	dw `00312300
	dw `00312300
	dw `00312300
	dw `00312300
	dw `00312300
	dw `00033000
PaddleEnd:
Ball:
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00033000
	dw `00333300
	dw `00333300
	dw `00033000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
BallEnd:


	
SECTION "Counter", WRAM0
wFrameCounter: db

SECTION "GameVariables", WRAM0
; ----------------------------------------------------------------------------------------------------
; Ball
; ----------------------------------------------------------------------------------------------------
wBallYVelocity: db
wBallXVelocity: db

; -----------------------------------------------------------------------------------------------------
; Paddle
; -----------------------------------------------------------------------------------------------------
wP_PaddleYPos: db
wP_PaddleXPos: db
