TITLE Low Level I/O     (cmoore06.asm)

; Author: Chantel Moore
; Last Modified: 6/7/2020
; OSU email address: moorchan@oregonstate.edu
; Course number/section: CS 271 / 400
; Project Number:         06        Due Date: 6/7/2020
; Description: implementing and using macros while designing,
;	implementing, & calling low level input/output. User input
;	is verified and converted from strings to integers before
;	stored to an array for displaying along with sum and average.

INCLUDE Irvine32.inc

;-------------------------------------------------
;getString
;Procedure: display prompt, move input into memory locale
;Receives: prompt message offset, buffer offset, size of buffer
;Returns: eax=number of chars read
;Preconditions: 3 inputs passed by address
;Registers changed: EDX ECX EBX EAX
;--------------------------------------------------
getString MACRO prompt, buffer, sizeBuffer
	push	ecx
	push	edx
	mov		edx,prompt
	call	writeString					;write prompt
	mov		edx,buffer
	mov		ecx,sizeBuffer
	call	ReadString					;get string input from user
	pop		edx
	pop		ecx
ENDM

;-------------------------------------------------
;displayString
;Procedure: print string from specified memory location
;Receives: address of string to display
;Returns: n/a
;Preconditions: n/a
;Registers changed: EDX
;--------------------------------------------------
displayString MACRO string1
	push	edx
	mov		edx, string1			;address of input buffer
	call	writeString					;print input buffer
	pop		edx
ENDM

sizeArray = 10

.data
intro1	BYTE	"Designing Low-Level I/O by Chantel Moore",0
intro2	BYTE	"This program requires you to enter 10 signed integers that will fit in a 32 bit register.",0
intro3	BYTE	"Once completed, the program will display the integers along with their sum and average.",0
prompt1	BYTE	"Please enter a signed integer: ",0
ePrompt	BYTE	"Error: input was invalid.",0
temp	BYTE	30 DUP(0)
uInput	BYTE	30 DUP(?)
uCount	SDWORD	$-uInput			; try to find a better way for this
array	SDWORD	sizeArray DUP(0)
ec1		BYTE	"Extra Credit - nope. Wishful Thinking. WriteVal does not work. Uncomment line 252 ",0
ec2		BYTE	"to view string is converted to integer and passed to writeVal.",0
atext	BYTE	"Entered Array: ",0
stext	BYTE	"Sum of Array: ",0
rtext	BYTE	"The Rounded Average of Array is: ",0
isNeg	BYTE	?		
space	BYTE	": ", 0
spaceC	BYTE	" ", 0


.code
main PROC
	
;display intro & instructions
	push	OFFSET ec2
	push	OFFSET ec1
	push	OFFSET intro3
	push	OFFSET intro2
	push	OFFSET intro1
	push	5					; number of messages to display
	call	introduction
; invoke getString and verify input before converting and saving to array
	push	OFFSET eprompt
	push	uCount
	push	OFFSET prompt1
	push	OFFSET array
	push	OFFSET uInput
	push	OFFSET isNeg
	push	OFFSET space
	push	sizeArray
	call	readVal	
;diplay array, sum, and average
	push	OFFSET spaceC
	push	OFFSET array
	push	sizeArray
	push	OFFSET rtext
	push	OFFSET stext
	push	OFFSET atext
	call	displayTestStuff

	exit	; exit to operating system
main ENDP

;-------------------------------------------------
;introduction
;Procedure: simple loop to increment through stack
;	to diplay four messages
;Receives: intro1-3 OFFSET on stack & ec1
;Returns: N/A
;Preconditions: 4 strings passed by reference
;Registers changed: EBP, ESI, ECX, EDX, EAX
;--------------------------------------------------
introduction PROC
	pushad
	mov		ebp, esp
	add		ebp, 36
	mov		eax, TYPE ebp
	mov		ecx, [ebp]
	add		ebp, eax
loopIntros:
	displayString [ebp]
	call	CrLf
	add		ebp, eax
	loop	loopIntros
	popad
	ret		24
introduction ENDP

;-------------------------------------------------
;readVal
;Procedure: Take 10 string inputs from user, convert
;		it to signed int, while checking validity
;Receives:	space, isNeg, uInput, array, sizeArray, prompt1, eprompt
;Returns:	user validate input in array
;Preconditions: items on stack
;Registers changed: EBX, ECX, EDI, EAX, ECX, ESI, EBP
;--------------------------------------------------
readVal PROC
	pushad
	mov		ebp, esp
	mov		ecx,[ebp+36]					;take inputs equal to size of array,i=arraySize
inputloop:								;loop to take inputs from user
	mov		eax,[ebp+36]
	sub		eax,ecx						
	inc		eax						
	call	writeDec				
	displayString [ebp+40]
	getString [ebp+56], [ebp+48], [ebp+60]	;prompt1, uInput, uCount
;set sign flag
	mov		edi, [ebp+44]				; update isNeg via edi = isNeg address
	mov		edi,'+'					
	mov		esi, [ebp+48]			
	mov		bl,[esi]				
	cmp		bl,'+'				
	je		signPresent			
	cmp		bl,'-'				
	jne		startConvert	
signPresent:			
	mov		[ebp+44],bl					;save isNeg
	push	ecx				
	dec		eax						
	mov		ecx,eax					
	mov		edi, [ebp+48]		
	mov		esi,edi
	inc		esi					
	rep		movsb						;get rid of sign char
	pop		ecx							
	jmp		startConvert

error1:
	pop		ecx							;retrieve ecx
	displayString [ebp+64]
	call	CrLf
	mov		bl, '+'
	mov		[ebp+44],bl
	;inc		ecx							;this iteration does not count due to error
	jmp		inputLoop

error2:
	pop		ecx
	pop		ecx
	displayString [ebp+64]
	call	CrLf
	mov		bl, '+'
	mov		[ebp+44],bl
	;inc		ecx
	jmp		inputLoop

startConvert:				
	push	ecx							;save main loop counter
	mov		ecx,eax					
	mov		esi,[ebp+48]		
	xor		ebx,ebx						;result of conversion
convertDigit:
	xor		eax,eax
	lodsb								;load next digit, buffer[i]
	cmp		al,'0'						;<'0'?
	jb		error1						;yes, invalid input, not digit
	cmp		al,'9'						;>'9'?
	ja		error1						;yes, invalid input, not digit
;number is digit
	sub		al,30h						;convert char to digit
	push	eax
	mov		eax,10d
	mul		ebx							;result=result x 10
	jc		error2						; too large
	pop		ebx
	add		ebx,eax						;result=result x 10 + ith digit
	loop	convertDigit			;loop througth string
	pop		ecx							;retrieve main loop counter
	mov		al,[ebp+44]
	cmp		al,'-'						;negative number?
	jne		con_rv_loop					;no continue
;negative number
	neg		ebx							;negate number		
con_rv_loop:
	mov		eax,[ebp+36]
	sub		eax,ecx						;array offset
	mov		edx,4						;4 bytes per element
	mul		edx							;offset of ith element
	mov		edi, [ebp+52]
	add		edi,eax						;array[i]
	mov		[edi],ebx					;save number to array
	dec		ecx							;main loop counter
	mov		bl, '+'
	mov		[ebp+44],bl
	cmp		ecx,0
	je		rvExit						;if loop counter 0, exit out of loop
	jmp		inputloop					;continue loop
	;loop	inputLoop					; jump destination too far by 48 bytes  - try to fix if time
rvExit:
	call	CrLf							;next line
	popad
	ret		32
readVal ENDP

;-------------------------------------------------
;writeVal
;Procedure: Converts a number to string and displays it
; via displayString
;Receives:	integer passed on stack
;Returns:	n/a
;Preconditions:	n/a
;Registers changed: EBP, EDI, EBX, EAX, ESI, EDX
;--------------------------------------------------
writeVal PROC
	LOCAL	converted:DWORD
	pushad
	mov		ebp, esp
	xor		edi, edi
	mov		ebx, 10
	mov		eax, [ebp+44]
	;call	WriteInt
	cmp		eax, 0
	jge		startConvert
	neg		eax
	mov		esi, 2dh
	jmp		loopInteger
startConvert:
	mov		esi, 2bh
loopInteger:
	cdq
	div		ebx
	add		dl, 30h
	push	edx
	inc		edi
	push	edi
	xor		edi, edi
	cmp		eax, edi
	je		lastDigit
	pop		edi
	loop	loopInteger
lastDigit:
	pop		ecx
	push	esi
	inc		ecx
	lea		edi, converted
store2Local:
	pop		eax
	mov		byte ptr [edi], al
	inc		edi
	loop	store2Local
	mov		al, 0
	mov		byte ptr [edi], al
	displayString edi
	popad
	ret		4
writeVal ENDP

;-------------------------------------------------
;displayTeststuff
;Procedure: cycles through array and calculates sum and
; average. Displays info via writeVal
;Receives:	atext, stext, rtext, array, sizearray, and spacec
;Returns: n/a
;Preconditions: all items passed on stack
;Registers changed: EBP, ECX, ESI, EBX, EDX, EAX
;--------------------------------------------------
displayTestStuff PROC
	pushad
	mov		ebp, esp
	displayString [ebp+36]
	mov		ecx, [ebp+48]
	mov		esi, [ebp+52]	
	mov		ebx, TYPE esi
	xor		edx, edx
displayArray:
	mov		eax, [esi]
	push	eax
	call	WriteVal
	displayString [ebp+56]
	add		edx, [esi]
	add		esi, ebx				
	loop	displayArray
	call	CrLf						;next line
;display sum
	displayString [ebp+40]
	push	edx
	call	WriteVal
	call	CrLf
	mov		eax, edx			; save this if you use displayString to print sum
	cdq
	mov		ebx, [ebp+48]		; ebx now = sizeArray
	idiv	ebx			; eax = rounded average
;display average
	displayString [ebp+44]
	push	eax
	call	writeVal
	popad
	ret		24
displayTestStuff ENDP

END main