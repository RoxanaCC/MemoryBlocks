.386
.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Memory blocks",0
area_width EQU 400
area_height EQU 350
area DD 0

matrix 	db 'X','T','R','H'
		db 'S','O','H','X'
		db 'R','O','S','T'
		
check	db 0,0,0,0
		db 0,0,0,0
		db 0,0,0,0
		
nr1 dd 0
nr2 dd 0
contor dd 0
		

X1 DD 0 ;coordonatele primei carti
Y1 DD 0
X2 DD 0 ;coordonatele celei de-a doua carti
Y2 DD 0		

poz1x dd 0 ;pozitile din matrice a celor 2 block-uri, folosite in resetarea matricei check
poz1y dd 0
poz2x dd 0
poz2y dd 0

time dd 0

val1 Db 0 ;valoarea din matrice a cartilor
val2 Db 0

counter DD 0 ;nr perechi gasite
count_click DD 0

block_width EQU 40 ;dimensiune block
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
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
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
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
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
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
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

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

make_symbol proc   
	;procedura pentru desenare simboluri
	push ebp
	mov ebp,esp
	pusha
Empty:
	;desenam pe blocul gol
	mov eax, [ebp + arg1]  ;citim simbolul de afisat
	cmp eax, 'E'
	jne make_X
	sub eax, 'E'
	lea esi, blocks
	mov culoare_simb, 0290e4fh ;selectam culoarea pentru blocul gol
	jmp draw_symbol
	
make_X:
	;desenam pe X in portocaliu
	mov eax, [ebp + arg1]  ;citim simbolul de afisat
	cmp eax, 'X'
	jne make_O
	mov eax, 1 ;al doilea simbol de afisat din fisierul de blocks
	lea esi, blocks
	mov culoare_simb, 0cc6a14h ;selectam culoarea
	jmp draw_symbol
	
make_O:
	;desenam pe O in mov
	cmp eax, 'O'
	jne make_R
	mov eax, 2 
	mov culoare_simb, 0ab32dbh
	lea esi, blocks
	jmp draw_symbol
	
make_R:
	;desenam Rombul in galben
	cmp eax, 'R'
	jne make_T
	mov eax, 3 
	mov culoare_simb, 0ddd30dh
	lea esi, blocks
	jmp draw_symbol

make_T:
	;desenam Trifoiul in verde
	cmp eax, 'T'
	jne make_H
	mov eax, 4
	mov culoare_simb, 022c155h
	lea esi, blocks
	jmp draw_symbol
	
make_H:
	;desenam Inima in rosu
	cmp eax, 'H'
	jne make_S
	mov eax, 5 
	mov culoare_simb, 0ce0404h
	lea esi, blocks
	jmp draw_symbol
	
make_S:
	;desenam Spade in albastru
	cmp eax, 'S'
	jne make_N
	mov eax, 6
	mov culoare_simb, 00f88d8h 
	lea esi, blocks
	jmp draw_symbol

make_N:
	;desenam spatiu gol
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
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, block_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
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
	mov dword ptr [edi], 0FFFFFFh ;fundal patratel cu simbol 
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

; un macro ca sa apelam mai usor desenarea simbolului
make_symbol_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_symbol
	add esp, 16
endm

; procedura ft_randomizer amesteca elementele matricei de carti
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
	
; procedura check_card verifica pozitile alese din matrice si daca au acelasi simbol, urmand sa afiseze/sterga/intoarca tartile alese
; arg1 - linia din matrice
; arg2 - coloana din matrice
; arg3 - pos_x
; arg4 - pos_y
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


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
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
	call memset			;ecran negru
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
	
	mov ebx, 0 ;pentru parcurgerea liniilor
	mov eax, 0 ;pentru parcurgerea coloanelor	
	
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
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start