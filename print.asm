	global	print

	section .bss
buffer_pointer resb 4
format_pointer resb 4
number_pointer resb 4

input_data resb 36
number resb 16
nuber_str resb 50
sign resb 1

plus_f resb 1
minus_f resb 1
zero_f resb 1
space_f resb 1
width_f resb 4


	section	.text    
print:
	; ====================================================================================
	; init

	mov dword [number], 0
	mov dword [number+4], 0
	mov dword [number+8], 0
	mov dword [number+12], 0

	mov byte [sign], 0

	mov byte [plus_f], 0
	mov byte [minus_f], 0
	mov byte [zero_f], 0
	mov byte [space_f], 0

	mov dword [width_f], 0

	; ====================================================================================
	; Saving arguments

	mov eax, [esp + 4 + 0*4]
	mov dword [buffer_pointer], eax	
	mov eax, [esp + 4 + 1*4]
	mov dword [format_pointer], eax	
	mov eax, [esp + 4 + 2*4]
	mov dword [number_pointer], eax	

	push ebp	; Saving register
	push ebx 

	; ====================================================================================
	; format parse

	mov dword eax, [format_pointer]

	while_format_mark:
		mov byte dl, [eax]	; Getting the current character

		CMP dl, 0			; End-of-line check
        Je break_format_mark

		CMP dl, '+'
		Jne minus_fromat_mark
		mov byte [plus_f], 0xFF
		JMP end_cycle

		minus_fromat_mark:
		CMP dl, '-'
		Jne space_fromat_mark
		mov byte [minus_f], 0xFF
		JMP end_cycle

		space_fromat_mark:
		CMP dl, ' '
		Jne zero_fromat_mark
		mov byte [space_f], 0xFF
		JMP end_cycle

		zero_fromat_mark:
		CMP dl, '0'
		Jne width_fromat_mark
		mov byte [zero_f], 0xFF
		JMP end_cycle

		width_fromat_mark:
		CMP dl, '1'
		Jl end_cycle

		mov ecx, eax

		while_format_width_forward_mark:
			mov byte dl, [eax]

			cmp dl, '0'			; less than '0'
			jl end_width
			cmp dl, '9'			; greater than '9'
			jg end_width	

			INC eax
			JMP while_format_width_forward_mark
			
		end_width:
		DEC eax

		mov ebp, eax
		mov ebx, 1

		while_format_width_backward_mark:
			push eax
			mov byte dl, [eax]
			SUB dl, '0'
			xor eax, eax
			mov byte al, dl
			MUL ebx
			add [width_f], eax
			mov eax, ebx
			mov edx, 10
			MUL edx
			mov ebx, eax
			pop eax

			DEC eax

			CMP eax, ecx			
			Jl end_width_backward
			JMP while_format_width_backward_mark

		end_width_backward:

		mov eax, ebp

		end_cycle:

		INC eax

		JMP while_format_mark

	break_format_mark:


	; ====================================================================================
	; reverse the original line

	mov dword eax, [number_pointer]
	while_reverse_1_forward_mark:
		mov byte dl, [eax]

		CMP dl, 0			
        Je break_reverse_1_forward_mark

		INC eax

		JMP while_reverse_1_forward_mark
	break_reverse_1_forward_mark:

	DEC eax

	mov dword ecx, input_data
	mov dword ebp, [number_pointer]
	while_backward_1_forward_mark:
		mov byte dl, [eax]
		mov byte [ecx], dl

		INC ecx
		DEC eax

		CMP eax, ebp			
        Jl break_backward_1_forward_mark

		JMP while_backward_1_forward_mark
	break_backward_1_forward_mark:
	mov byte [ecx], 0


	; ====================================================================================

	; For quick access to the memory
	mov dword eax, input_data
	mov dword ecx, number

	; Converting characters to a number
	while_1_mark:
		; ------------------ First character ------------------
		mov byte dl, [eax]	; Getting the current character
		
		CMP dl, '-'
		Je sign_break_1_mark

		CMP dl, 0			; End-of-line check
        Je break_1_mark

		cmp dl, '0'			; less than '0'
		jl write_symbol1
		cmp dl, '9'			; less than '9'
		jbe digit1			

		; Letter processing
		and dl, 0xDF		; uppercase conversion

		cmp dl, 'X'
		Jne normal_letter_processing1
		INC eax
		INC eax
		JMP while_1_mark

		normal_letter_processing1:

		sub dl, 'A'			
		add dl, 10
		JMP write_symbol1
		
		; digit processing
		digit1:
		sub dl, '0'

		write_symbol1:
		mov byte [ecx], dl	; Writing a number to memory 

		INC eax				; Move to the next character

		; ------------------ Second character ------------------
		while_1_second_character_mark:
		mov byte dl, [eax]	; Getting the current character
		
		CMP dl, '-'
		Je sign_break_1_mark

		CMP dl, 0			; End-of-line check
        Je break_1_mark

		cmp dl, '0'			; less than '0'
		jl write_symbol2
		cmp dl, '9'			; less than '9'
		jbe digit2			

		; Letter processing
		and dl, 0xDF		; uppercase conversion

		cmp dl, 'X'
		Jne normal_letter_processing2
		INC eax
		INC eax
		JMP while_1_second_character_mark

		normal_letter_processing2:
		sub dl, 'A'			
		add dl, 10
		JMP write_symbol2

		; digit processing
		digit2:
		sub dl, '0'

		write_symbol2:
		SHL dl, 4
		OR dl, [ecx]
		mov byte [ecx], dl	; Writing a number to memory 

		INC eax				; Move to the next character

		INC ecx				; Move to the next byte
        JMP while_1_mark

	; ------------------------------------------------------------------------------------
	sign_break_1_mark:

	NOT dword [number]
	NOT dword [number+4]
	NOT dword [number+8]
	NOT dword [number+12]

	add dword [number], 1
	adc dword [number+4], 0
	adc dword [number+8], 0
	adc dword [number+12], 0

	; ------------------------------------------------------------------------------------

	break_1_mark:
	TEST dword [number+12], 0x80000000
	Js number_neg
	JMP skip_neg_1

	; ------------------------------------------------------------------------------------

	number_neg:
	NOT dword [number]
	NOT dword [number+4]
	NOT dword [number+8]
	NOT dword [number+12]

	add dword [number], 1
	adc dword [number+4], 0
	adc dword [number+8], 0
	adc dword [number+12], 0

	mov byte [sign], 0xFF

	skip_neg_1:

	; ====================================================================================

	; For quick access to the memory
	mov dword ecx, nuber_str

	; Recording a response
	while_2_mark:
		mov ebx, 10   ;divisor
		mov edx, 0

		mov eax, [number+12]   ;EDX:EAX = number to divide
		div ebx
		mov [number+12], eax

		mov eax, [number+8]
		div ebx
		mov [number+8], eax

		mov eax, [number+4]
		div ebx
		mov [number+4], eax

		mov eax, [number]
		div ebx
		mov [number], eax

		ADD dl, '0'
		mov byte [ecx], dl

		INC ecx

		mov eax, [number+12]
		CMP eax, 0
        Je eq_2
		JMP continue

		eq_2:
		mov eax, [number+8]
		CMP eax, 0
        Je eq_3
		JMP continue

		eq_3:
		mov eax, [number+4]
		CMP eax, 0
        Je eq_4
		JMP continue

		eq_4:
		mov eax, [number]
		CMP eax, 0
        Je break_2_mark
		JMP continue

		continue:
        JMP while_2_mark

	break_2_mark:

	; ------------------------------------------------------------------------------------

	TEST byte [sign], 0x80
	Js minus_bit_set

	TEST byte [plus_f], 0x80
	Js plus_bit_set

	TEST byte [space_f], 0x80
	Js space_bit_set

	JMP skip_checks

	; ------------------------------------------------------------------------------------

	minus_bit_set:
	mov byte [ecx], '-'
	INC ecx
	JMP skip_checks

	; ------------------------------------------------------------------------------------

	plus_bit_set:
	mov byte [ecx], '+'
	INC ecx
	JMP skip_checks

	; ------------------------------------------------------------------------------------

	space_bit_set:
	mov byte [ecx], ' '
	INC ecx
	JMP skip_checks

	; ------------------------------------------------------------------------------------

	skip_checks:
	mov byte [ecx], 0

	; ====================================================================================
	; fill zeros the answer

	mov ecx, 0
	mov eax, 42
	mov ebx, [buffer_pointer]

	while_fill_zeros_mark:
		CMP eax, ecx
		Jl break_while_fill_zeros_mark

		mov byte [ebx], 0

		INC ebx
		INC ecx

		JMP while_fill_zeros_mark

	break_while_fill_zeros_mark:

	; ====================================================================================
	; fill the answer

	mov ecx, 0
	mov eax, [width_f]
	mov edx, ' '
	mov ebx, [buffer_pointer]

	while_width_mark:
		CMP eax, ecx
		Jle break_while_width_mark

		mov [ebx], edx

		INC ebx
		INC ecx

		JMP while_width_mark

	break_while_width_mark:
	mov byte [ebx], 0

	; ====================================================================================

	TEST byte [minus_f], 0x80
	Js reverse_for_minus
	JMP reverse_usial

	; ====================================================================================
	; reverse the answer for format -

	reverse_for_minus:

	mov dword eax, nuber_str
	while_reverse_2_forward_mark:
		mov byte dl, [eax]

		CMP dl, 0			
        Je break_reverse_2_forward_mark

		INC eax

		JMP while_reverse_2_forward_mark
	break_reverse_2_forward_mark:

	DEC eax

	left_orientation:
	mov dword ecx, [buffer_pointer]

	left_orientation_without_ecx:
	mov dword ebp, nuber_str

	while_backward_2_forward_mark:
		mov byte dl, [eax]
		mov byte [ecx], dl

		INC ecx
		DEC eax

		CMP eax, ebp			
        Jl break_backward_2_forward_mark

		JMP while_backward_2_forward_mark
	break_backward_2_forward_mark:                     

	JMP return_mark

	; ====================================================================================
	; reverse the answer usial
	
	reverse_usial:

	mov dword ecx, 0
	mov dword eax, nuber_str
	while_usial_reverse_2_forward_mark:
		mov byte dl, [eax]

		CMP dl, 0			
        Je break_usial_reverse_2_forward_mark

		INC eax
		INC ecx

		JMP while_usial_reverse_2_forward_mark
	break_usial_reverse_2_forward_mark:

	DEC eax

	CMP ecx, [width_f]
	Jge left_orientation

	mov edx, [width_f]
	SUB edx, ecx
	ADD edx, [buffer_pointer]
	mov ecx, edx

	TEST byte [zero_f], 0x80
	Jns left_orientation_without_ecx
	
	mov edx, [buffer_pointer]
	while_fill_start_number:
		CMP edx, ecx
		Je break_while_fill_start_number
		mov byte [edx], '0'
		INC edx
		JMP while_fill_start_number
	break_while_fill_start_number:
	mov byte [edx], '0'

	mov byte dl, [eax]
	CMP dl, '0'
	Jge left_orientation_without_ecx

	DEC eax
	INC ecx

	mov ebp, [buffer_pointer]
	mov byte [ebp], dl 

	JMP left_orientation_without_ecx

	; ====================================================================================

	return_mark:

	pop ebx
	pop ebp

    ret
