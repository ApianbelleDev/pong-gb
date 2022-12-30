INCLUDE "src/hardware.inc" 

SECTION "Start", ROMX

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

    ;commit test
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
MoveBall:
	ld a, [_OAMRAM + 8]
	ld b, a
	ld a, [wBallYVelocity] ; wBallYVelocity is set to 1 in the init code.
	add a, b
	
	cp a, 153 ; Did the ball hit the bottom of the screen?
	jp z, SetUpwardsVel
	cp a, 10 ; Did the ball hit the top of the screen?
	jp z, SetDownwardsVel
	ld [_OAMRAM  + 8], a

	ld a, [_OAMRAM + 9]
	ld b, a
	ld a, [wBallXVelocity]
	add a, b
	
	cp a, 5
	jp z, SetLeftVel
	cp a, 165
	jp z, SetRightVel
	ld [_OAMRAM + 9], a
	
	call Input

; First, check if the up button is pressed.
CheckUp:
	ld a, [wCurKeys]
	and a, PADF_UP
	jp z, CheckDown
Up:
	ld a, [_OAMRAM]
	dec a
	; If we've already hit the top of the screen, don't move
	cp a, 15
	jp z, Main
	ld [_OAMRAM], a
	jp Main
; Then check the down button
CheckDown:
	ld a, [wCurKeys]
	and a, PADF_DOWN
	jp z, Main
Down:
	ld a, [_OAMRAM]
	inc a 
	; If we've already hit the bottom of the screen, don't move
	cp a, 145 
	jp z, Main
	ld [_OAMRAM], a 
	jp Main
	
; --------------------------------------------------------------------------------------------------------------
; Ball to screen collision
; --------------------------------------------------------------------------------------------------------------
SetUpwardsVel:
	ld a, 0
	dec a
	ld [wBallYVelocity], a
	jp Main
SetDownwardsVel:
	ld a, 0
	inc a
	ld [wBallYVelocity], a
	jp Main
SetLeftVel:
	ld a, 0
	inc a
	ld [wBallXVelocity], a
	jp Main
SetRightVel:
	ld a, 0
	dec a
	ld [wBallXVelocity], a
	jp Main

	
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
	dw `00322300
	dw `00322300
	dw `00322300
	dw `00322300
	dw `00322300
	dw `00322300
	dw `00322300
	dw `00322300
	dw `00322300
	dw `00322300
	dw `00322300
	dw `00322300
	dw `00322300
	dw `00322300
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
