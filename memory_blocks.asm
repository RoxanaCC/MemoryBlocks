.386
.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;including the libraries and mentioning the functions
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;cod section
.data
;declaring variables
window_title DB "Memory blocks",0
area_width EQU 400
area_height EQU 350
area DD 0

matrix 	db 'X','T','R','H' ;the game's cards matrix
	db 'S','O','H','X'
	db 'R','O','S','T'
		
check	db 0,0,0,0 ;a matrix to check which cards have already been found
	db 0,0,0,0
	db 0,0,0,0
		
nr1 dd 0
nr2 dd 0
contor dd 0
		

X1 DD 0 ;the coordonates for the group of pressed cards
Y1 DD 0
X2 DD 0 
Y2 DD 0		

poz1x dd 0 ;the positions of the cards in the matrix
poz1y dd 0
poz2x dd 0
poz2y dd 0

time dd 0

val1 Db 0 ;the cards value (for the matrix)
val2 Db 0

counter DD 0 ;no found pairs
count_click DD 0

block_width EQU 40 ;cards sizes
block_height EQU 40

culoare_simb DD 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20

include digits.inc
include letters.inc
include blocks.inc

.code
; procedure make_text writes a letter or a number at the given coordinates
; arg1 - symbol
; arg2 - pointer to the pixels array
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; reading the simbol
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	
	cmp eax,' '
	jg make_point
	mov eax, 26 ; 0 to 25 are letters, 26 is space
	lea esi, letters
	jmp draw_text

make_point:
	mov eax, 10
	lea esi, digits
		
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer the the pixels matrix
	mov eax, [ebp+arg4] ; pointer to coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer to coord x
	shl eax, 2 ; multiply by 4, DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 1
	je simbol_pixel_alb
	mov dword ptr [edi], 1
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 06c74e2h
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; a macro to call the procedure easer
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

make_symbol proc   
	;procedure for drawing a symbol (card)
	push ebp
	mov ebp,esp
	pusha
Empty:
	;drawing turned card
	mov eax, [ebp + arg1]  ;reading the symbol
	cmp eax, 'E'
	jne make_X
	sub eax, 'E'
	lea esi, blocks
	mov culoare_simb, 0290e4fh ;picking the color
	jmp draw_symbol
	
make_X:
	;drawing X in orange
	mov eax, [ebp + arg1]
	cmp eax, 'X'
	jne make_O
	mov eax, 1
	lea esi, blocks
	mov culoare_simb, 0cc6a14h
	jmp draw_symbol
	
make_O:
	;drawing O in purple
	cmp eax, 'O'
	jne make_R
	mov eax, 2 
	mov culoare_simb, 0ab32dbh
	lea esi, blocks
	jmp draw_symbol
	
make_R:
	;drawing dimond in yellow
	cmp eax, 'R'
	jne make_T
	mov eax, 3 
	mov culoare_simb, 0ddd30dh
	lea esi, blocks
	jmp draw_symbol

make_T:
	;drawing cover in green
	cmp eax, 'T'
	jne make_H
	mov eax, 4
	mov culoare_simb, 022c155h
	lea esi, blocks
	jmp draw_symbol
	
make_H:
	;drawing heart in red
	cmp eax, 'H'
	jne make_S
	mov eax, 5 
	mov culoare_simb, 0ce0404h
	lea esi, blocks
	jmp draw_symbol
	
make_S:
	;drawing spade in blue
	cmp eax, 'S'
	jne make_N
	mov eax, 6
	mov culoare_simb, 00f88d8h 
	lea esi, blocks
	jmp draw_symbol

make_N:
	;drawing empty space
	mov eax, 7
	mov culoare_simb, 0 
	lea esi, blocks

draw_symbol:
	mov ebx, block_height
	mul ebx
	mov ebx, block_height
	mul ebx
	add esi, eax
	mov ecx, block_height
bucla_simbol_linii_block:
	mov edi, [ebp+arg2]
	mov eax, [ebp+arg4]
	add eax, block_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3]
	shl eax, 2
	add edi, eax
	push ecx
	mov ecx, block_height
bucla_simbol_coloane_block:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb_block
	mov edx, culoare_simb
	mov dword ptr [edi], edx
	jmp simbol_pixel_next_block
simbol_pixel_alb_block:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next_block:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane_block
	pop ecx
	loop bucla_simbol_linii_block
	popa
	mov esp, ebp
	pop ebp
	ret
make_symbol endp

; a macro to call the procedure easer
make_symbol_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_symbol
	add esp, 16
endm

; procedure ft_randomizer mixes the cards matrix
ft_randomizer proc

	push ebp
	mov ebp, esp
	pusha
	mov contor, 10
	
gen_nr_ran:
	rdtsc
	mov ebx, 12
	mov edx, 0
	div ebx
	mov nr1, edx
	rdtsc
	mov edx, 0
	div ebx
	mov nr2, edx
et_excange:
	mov eax, nr1
	mov bl, matrix[eax]
	mov ecx, nr2
	mov bh, matrix[ecx]
	mov matrix[eax], bh
	mov matrix[ecx], bl
	dec contor
	cmp contor, 0
	ja gen_nr_ran
	
	popa
	mov esp, ebp
	pop ebp
	ret
ft_randomizer endp
	
; procedura check_card checks the picked cards and turns or deletes them
; arg1 - positions in the matrix
; arg2 - 
; arg3 - coordinates x
; arg4 - and y
check_card proc

	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	mov edx, [ebp+arg2]
	mov bl, matrix[eax][edx]
	mov bh, check[eax][edx]
	cmp bh, 1
	je et_exista
	cmp count_click, 1
	je val_1
	cmp count_click, 2
	je val_2
	cmp count_click, 3
	je check_con
	
val_1:
	mov eax, [ebp+arg1]
	mov edx, [ebp+arg2]
	mov bl, matrix[eax][edx]
	mov val1, bl
	mov check[eax][edx], 1
	mov poz1x, eax
	mov poz1y, edx
	mov eax, [ebp+arg3]
	mov ebx, [ebp+arg4]
	mov X1, eax
	mov Y1, ebx
	cmp val1, 'X'
	je make_X
	cmp val1, 'O'
	je make_O
	cmp val1, 'R'
	je make_romb
	cmp val1, 'T'
	je make_trifoi
	cmp val1, 'H'
	je make_heart
	cmp val1, 'S'
	je make_spade
	
val_2:
	mov eax, [ebp+arg1]
	mov edx, [ebp+arg2]
	mov bl, matrix[eax][edx]
	mov val2, bl
	mov check[eax][edx], 1
	mov poz2x, eax
	mov poz2y, edx
	mov eax, [ebp+arg3]
	mov ebx, [ebp+arg4]
	mov X2, eax
	mov Y2, ebx
	cmp val2, 'X'
	je make_X
	cmp val2, 'O'
	je make_O
	cmp val2, 'R'
	je make_romb
	cmp val2, 'T'
	je make_trifoi
	cmp val2, 'H'
	je make_heart
	cmp val2, 'S'
	je make_spade
	
make_X:
	mov eax, [ebp+arg3]
	mov ebx, [ebp+arg4]
	make_symbol_macro 'X', area, eax, ebx
	jmp final
make_O:
	mov eax, [ebp+arg3]
	mov ebx, [ebp+arg4]
	make_symbol_macro 'O', area, eax, ebx
	jmp final
make_romb:
	mov eax, [ebp+arg3]
	mov ebx, [ebp+arg4]
	make_symbol_macro 'R', area, eax, ebx
	jmp final
make_trifoi:
	mov eax, [ebp+arg3]
	mov ebx, [ebp+arg4]
	make_symbol_macro 'T', area, eax, ebx
	jmp final
make_heart:
	mov eax, [ebp+arg3]
	mov ebx, [ebp+arg4]
	make_symbol_macro 'H', area, eax, ebx
	jmp final
make_spade:
	mov eax, [ebp+arg3]
	mov ebx, [ebp+arg4]
	make_symbol_macro 'S', area, eax, ebx	
	jmp final
	
check_con:
	cmp val1, 'X'
	je et_X
	cmp val1, 'O'
	je et_O
	cmp val1, 'R'
	je et_R
	cmp val1, 'T'
	je et_T
	cmp val1, 'H'
	je et_H
	cmp val1, 'S'
	je et_S
	
et_X:
	cmp val2, 'X'
	je et_ok
	jmp et_fail
et_O:
	cmp val2, 'O'
	je et_ok
	jmp et_fail
et_R:
	cmp val2, 'R'
	je et_ok
	jmp et_fail
et_T:
	cmp val2, 'T'
	je et_ok
	jmp et_fail
et_H:
	cmp val2, 'H'
	je et_ok
	jmp et_fail
et_S:
	cmp val2, 'S'
	je et_ok
	jmp et_fail

	
et_ok:
	inc counter
	make_symbol_macro 'N', area, X1, Y1
	make_symbol_macro 'N', area, X2, Y2
	mov count_click, 0
	mov time, 0
	cmp counter, 6
	je winner
	jmp final
	
et_fail:
	make_symbol_macro 'E', area, X1, Y1
	make_symbol_macro 'E', area, X2, Y2
	mov count_click, 0
	mov time, 0
	mov eax, poz1x
	mov ebx, poz1y
	mov check[eax][ebx], 0
	mov eax, poz2x
	mov ebx, poz2y
	mov check[eax][ebx], 0
	jmp final
	
winner:
	make_text_macro 'Y', area, 150, 130
	make_text_macro 'O', area, 190, 130
	make_text_macro 'U', area, 230, 130
	make_text_macro 'W', area, 150, 160
	make_text_macro 'I', area, 190, 160
	make_text_macro 'N', area, 230, 160
	
et_exista:
	cmp count_click, 3
	je check_con
	dec count_click
	
final:
	popa
	mov esp, ebp
	pop ebp
	ret
	
check_card endp

check_card_macro macro X_mat, Y_mat, x, y
	push y
	push x
	push Y_mat
	push X_mat
	call check_card
	add esp, 16
endm


; drawing function called at every click or every 200ms
; arg1 - evt (0 - initializ, 1 - click, 2 - time up)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp count_click, 2
	je et_time
	cmp eax, 2
	jz  final_draw
	
clear:
	
	mov count_click, 0
	mov time, 0
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	
	push eax
	push 0
	push area
	call memset ;black screen
	add esp, 12
	mov counter, 0
	mov count_click, 0
	make_symbol_macro 'E', area, 100, 100
	make_symbol_macro 'E', area, 150, 100
	make_symbol_macro 'E', area, 200, 100
	make_symbol_macro 'E', area, 250, 100
	make_symbol_macro 'E', area, 100, 150
	make_symbol_macro 'E', area, 150, 150
	make_symbol_macro 'E', area, 200, 150
	make_symbol_macro 'E', area, 250, 150
	make_symbol_macro 'E', area, 100, 200
	make_symbol_macro 'E', area, 150, 200
	make_symbol_macro 'E', area, 200, 200
	make_symbol_macro 'E', area, 250, 200
	call ft_randomizer
	;reinitializare matricei check
	
	mov ebx, 0 ;for the lines
	mov eax, 0 ;for the colons	
	
	mov check[eax][ebx], 0
	inc ebx
	mov check[eax][ebx], 0
	inc ebx
	mov check[eax][ebx], 0
	inc ebx
	mov check[eax][ebx], 0
 
	add eax, 4
	mov ebx, 0
	mov check[eax][ebx], 0
	inc ebx
	mov check[eax][ebx], 0
	inc ebx
	mov check[eax][ebx], 0
	inc ebx
	mov check[eax][ebx], 0
	
	add eax, 4
	mov ebx, 0
	mov check[eax][ebx], 0
	inc ebx
	mov check[eax][ebx], 0
	inc ebx
	mov check[eax][ebx], 0
	inc ebx
	mov check[eax][ebx], 0
	
	jmp final_draw
	
evt_click:	
	
	mov ebx,[ebp+arg2]
	mov edx,[ebp+arg3]	
	push edx
	push ebx
	add esp, 8
	mov eax, 99
	cmp eax, 99
	jne clear

play_again:

	mov eax,[ebp+arg2]
	mov ebx,[ebp+arg3]
	cmp eax, 30
	jb check_out
	cmp eax, 80
	ja check_out
	cmp ebx, 290
	jb check_out
	cmp ebx, 330
	ja check_out
	jmp clear
	
check_out:

	cmp eax, 100
	jb final_draw
	cmp eax, 300
	ja final_draw
	cmp ebx, 100
	jb final_draw
	cmp ebx, 250
	ja final_draw
	
check_rand:

	cmp eax, 150
	jb check_col1
	cmp eax, 200
	jb check_col2
	cmp eax, 250
	jb check_col3
	cmp eax, 300
	jb check_col4

check_col1:

	cmp ebx, 150
	jb card11
	cmp ebx, 200
	jb card12
	cmp ebx, 250
	jb card13
	
check_col2:

	cmp ebx, 150
	jb card21
	cmp ebx, 200
	jb card22
	cmp ebx, 250
	jb card23
	
check_col3:

	cmp ebx, 150
	jb card31
	cmp ebx, 200
	jb card32
	cmp ebx, 250
	jb card33
	
check_col4:

	cmp ebx, 150
	jb card41
	cmp ebx, 200
	jb card42
	cmp ebx, 250
	jb card43
	
card11:
	
	inc count_click
	check_card_macro 0, 0, 100, 100
	jmp final_draw
	
card12:

	inc count_click
	check_card_macro 4, 0, 100, 150
	jmp final_draw
	
card13:

	inc count_click
	check_card_macro 8, 0, 100, 200
	jmp final_draw
	
card21:

	inc count_click
	check_card_macro 0, 1, 150, 100
	jmp final_draw
	
card22:

	inc count_click
	check_card_macro 4, 1, 150, 150
	jmp final_draw
	
card23:

	inc count_click
	check_card_macro 8, 1, 150, 200
	jmp final_draw
	
card31:

	inc count_click
	check_card_macro 0, 2, 200, 100
	jmp final_draw
	
card32:

	inc count_click
	check_card_macro 4, 2, 200, 150
	jmp final_draw
	
card33:

	inc count_click
	check_card_macro 8, 2, 200, 200
	jmp final_draw
	
card41:

	inc count_click
	check_card_macro 0, 3, 250, 100
	jmp final_draw
	
card42:

	inc count_click
	check_card_macro 4, 3, 250, 150
	jmp final_draw
	
card43:
	
	inc count_click
	check_card_macro 8, 3, 250, 200
	jmp final_draw
	
et_time:
	inc time
	cmp time, 5
	je et_check
	jmp final_draw
	
et_check:
	inc count_click
	check_card_macro 0, 0, 0, 0
	
final_draw:

	make_text_macro 'M', area, 130, 40
	make_text_macro 'E', area, 140, 40
	make_text_macro 'M', area, 150, 40
	make_text_macro 'O', area, 160, 40
	make_text_macro 'R', area, 170, 40
	make_text_macro 'Y', area, 180, 40
	make_text_macro ' ', area, 190, 40
	make_text_macro 'B', area, 200, 40
	make_text_macro 'L', area, 210, 40
	make_text_macro 'O', area, 220, 40
	make_text_macro 'C', area, 230, 40
	make_text_macro 'K', area, 240, 40
	make_text_macro 'S', area, 250, 40

	make_text_macro ' ', area, 30, 290
	make_text_macro 'P', area, 40, 290
	make_text_macro 'L', area, 50, 290
	make_text_macro 'A', area, 60, 290
	make_text_macro 'Y', area, 70, 290
	make_text_macro 'A', area, 30, 310
	make_text_macro 'G', area, 40, 310
	make_text_macro 'A', area, 50, 310
	make_text_macro 'I', area, 60, 310
	make_text_macro 'N', area, 70, 310

	make_text_macro 'C', area, 160, 300
	make_text_macro 'I', area, 170, 300
	make_text_macro 'O', area, 180, 300
	make_text_macro 'R', area, 190, 300
	make_text_macro 'E', area, 200, 300
	make_text_macro 'A', area, 210, 300
	make_text_macro ' ', area, 220, 300
	make_text_macro 'C', area, 230, 300
	make_text_macro 'R', area, 240, 300
	make_text_macro 'I', area, 250, 300
	make_text_macro 'S', area, 260, 300
	make_text_macro 'T', area, 270, 300
	make_text_macro 'E', area, 280, 300
	make_text_macro 'S', area, 290, 300
	make_text_macro 'C', area, 300, 300
	make_text_macro 'U', area, 310, 300
	make_text_macro ' ', area, 320, 300
	make_text_macro 'R', area, 330, 300
	make_text_macro 'O', area, 340, 300
	make_text_macro 'X', area, 350, 300
	make_text_macro 'A', area, 360, 300
	make_text_macro 'N', area, 370, 300
	make_text_macro 'A', area, 380, 300
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocating memory to draw
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;call drawing function
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;end program
	push 0
	call exit
end start
