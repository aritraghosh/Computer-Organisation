Chan_Start_Prot: 
section .text 
 BITS 32 
 code_base EQU 0xa000  
 ;Storing the previous GDTR and IDTR
	 SGDT [code_base + 0x3ffa]; IP = 0x0000
	 SIDT [code_base + 0x3ff2]; IP = 0x0007
 ;Clearing Task Switch
	 CLTS; IP = 0x000e
 ;Initializing Test Status Bytes 1 and 2 to 0xdead 
 mov word [code_base+0x3200], 0xdead; IP = 0x0010
 ;Initializing Test Status Bytes 3 and 4 to 0x0001 
 mov word [code_base+0x3208], 0x0001; IP = 0x0019
 ;Initializing Exception Counter to 0x0000 
 mov word [code_base+0x3ff8], 0x0; IP = 0x0022
 ;Loading GDTR and IDTR with my GDT and my IDT base/limit
	LGDT [code_base+0x3202]; IP = 0x002b
	LIDT [code_base+0x320A]; IP = 0x0032
 ;Loading LDTR with my LDT selector in current GDT
	 mov ax,0x58; IP = 0x0039
	 LLDT ax; IP = 0x003d
 ;Loading LTR with my default TSS selector in current GDT
	 mov ax,0x60; IP = 0x0040
	 LTR ax; IP = 0x0044
 ;Loading the selectors with my default index GDT entry
 	mov ax,0x10; IP = 0x0047
 	mov DS,ax; IP = 0x004b
 	mov SS,ax; IP = 0x004e
 	mov ES,ax; IP = 0x0051
 	mov FS,ax; IP = 0x0054
 	mov GS,ax; IP = 0x0057
 ; A Far jump into my default code selector
 	jmp 0x8:dword start-code_base; IP = 0x005a
 start:
 ; Initializing Flags
	 mov dword [0x1ff0], 0x0; IP = 0x006c
	 mov esp, 0x1ff0; IP = 0x0076
	 popfd ; IP = 0x007b
;----------------------KAMA: YOUR CODE----------------------------------
 
 mov ax,0x18
 mov fs,ax
 mov ax,0x38
 mov ss,ax
 mov esp,0xcf70
 
 mov ax,0x30
 mov ds,ax                    ;code segment from 0xd000
 ;EXCEPTION 11
 mov ax, 0x28
 mov es, ax
 
 mov ax,0x20
 mov es,ax
 ;EXCEPTION 13
 mov eax, [es:0xfe]
 
 
 ;EXCEPTION 0
 mov ax,0x12
 mov bl,0x0 
 div bl       	                ;ax = ax/bl
 mov dword[fs:4],0xaaaa
 

 jmp chanHappy                  ;to check if the interrrupt service routine returns the control


  ;INTERRUPT SERVICE ROUTINE FOR EXCEPTION 0
 align 0x100
 mov dword[fs:0],0xbbbb
 mov bl,0x3                     ;changing the value after division
 iretd
  
  ;INTERRUPT SERVICE ROUTINE FOR EXCEPTION 11         
 align 0x100                    ;aligining to 0xa200
 mov dword[ds:0x2c],0x409000    ;changing the present bit
 pop eax                        ;popping the error code
 iretd
 
 
  ;  INTERRUPT SERVICE ROUTINE FOR EXCEPTION 13
 align 0x100                     ;aligining to 0xa300
  
 mov dword[ds:0x20],0xb32001ff   ;changing the sement limit
 mov ax, 0x20                    ;changing for the shadow register
 mov es, ax
 pop ebx                         ;popping the error code
 iretd
 
;----------------------KAMA: YOUR CODE ENDS HERE-----------------

 ;Moving 0xbabe at specific location in 3rd data page to indicate successful completion of test
 chanHappy:
	 mov ax,0x10; IP = 0x087d
	 mov DS,ax; IP = 0x0881
	 clts; IP = 0x0890
;Comparing Exception counter with actual number of induced eceptions
	 mov word [0x2208],0xdece; IP = 0x0892
	 cmp word [0x2ff8], 0; IP = 0x089b
	jne chanSad; IP = 0x08a4
 HLT_L: mov word [0x2200], 0xbabe; IP = 0x08a6
 Chan_End_Prot:
;Start of X86 GDB specific section for displaying result on Postcard 
	 mov word [0x2208],0xcafe
	mov	al, 0xbb
	jmp	bulb
 chanSad:
	 mov ax,0x10; IP = 0x087d
	 mov DS,ax; IP = 0x0881
	 clts; IP = 0x0890
	mov	al, 0xff
 bulb:
	mov	edx, 0x0080
	;out	dx, al
	mov	edx, 0x2fffff
 delay:
	dec	edx
	jnz	delay
;Restoring the previous GDTR and IDTR 
	LGDT [0x2ffa]
	LIDT [0x2ff2]
;Restoring the Segment definitions specific to X86 GDBs  
;for proper execution of int 3 
 jmp 0x8:dword fin
 fin:	mov ax,0x10
	mov DS,	ax
	mov SS,	ax
	mov ES,  ax
	mov GS,	ax
	mov FS,	ax
	mov ESP, 0x8000
	mov EBP, 0x9000
	 clts
	 int	3
 Chan_Test_End:
  align 0x1000
;----------------------------------YOUR DATA -----------------------------------

dd 0x6867238

align 0x1000

dd 0xabcdabcd

align 0x1000
;--------------------The GDT starts here---------------------------
gdt_start:
;Offset 0x0 - Null and Code Descriptor with PL=0
 dd 0x0,0x0
; Offset 0x8
 dd 0xa000ffff,0x4f9b00 
; Offset 0x10
; Default Data Segment Descriptor of type 2, DPL = 0
 db 0xff
 db 0xbf
 db 0x0
 db 0xb0
 db 0x0
 db 0x92
 db 0x40
 db 0x0
; Offset 0x18
;Data Segment Descriptor of type 0, random DPL and Base
 dd 0xb000031f , 0x409200
; Offset 0x20
;Data Segment Descriptor of type 1, random DPL and Base
 dd 0xb32000ff , 0x409000                                 ;segment limit is made 0x0ff for checking exception 13
; Offset 0x28
;Data Segment Descriptor of type 2, random DPL and Base
 dd 0xbc80095f , 0x401000			          ;  making P as 0 (change in exception 11)
; Offset 0x30
;Data Segment Descriptor of type 3, random DPL and Base
 dd 0xd0000100,0x409200                                   ;code segment from 0xd000 of segment limit 0x100
; Offset 0x38
;Data Segment Descriptor of type 4, random DPL and Base
 dd 0xcf70008f , 0x409600
;------------KAMA - PUT CODE SEGMENT DESCRIPTOR FOR ISR------
 dw 0x300
 dw 0xa100
 db 0x0
 db 0x9a
 db 0x40
 db 0x0
		
;----KAMA-END OF ISR DESCRIPTOR--------------
;Data Segment Descriptor of type 6, random DPL and Base
 db 0x0
 db 0x0
 db 0x7c
 db 0xb4
 db 0x0
 db 0xb6
 db 0x40
 db 0x0
;Data Segment Descriptor of type 7, random DPL and Base
 db 0x0
 db 0x0
 db 0xcb
 db 0xb7
 db 0x0
 db 0x97
 db 0x40
 db 0x0
;Kama - Moved Descriptor to Second place.
;LDT descriptor
 db 0xff
 db 0x0
 db 0x0
 db 0xd1
 db 0x0
 db 0x82
 db 0x0
 db 0x0
;TSS Descriptor for default task - starting of the test
 db 0x67
 db 0x0
 db 0x0
 db 0xda
 db 0x0
 db 0x89						
 db 0x40
 db 0x0
;TSS Descriptor for Double fault exception handler
 db 0x67			;making limit as 9ff
 db 0x0			;
 db 0x68
 db 0xda
 db 0x0
 db 0x89
 db 0x40
 db 0x0
;TSS [0.1] Descriptor
 db 0x67
 db 0x0
 db 0xd0
 db 0xda
 db 0x0
 db 0xa9
 db 0x40
 db 0x0
;TSS [0.2] Descriptor
 db 0x67
 db 0x0
 db 0x38
 db 0xdb
 db 0x0
 db 0xc9
 db 0x40
 db 0x0
;TSS [0.3] Descriptor
 db 0x67
 db 0x0
 db 0xa0
 db 0xdb
 db 0x0
 db 0xe9
 db 0x40
 db 0x0
;TSS [1.0] Descriptor
 db 0x67
 db 0x0
 db 0x8
 db 0xdc
 db 0x0
 db 0xe9
 db 0x40
 db 0x0
;TSS [1.1] Descriptor
 db 0x67
 db 0x0
 db 0x70
 db 0xdc
 db 0x0
 db 0xe9
 db 0x40
 db 0x0
;TSS [1.2] Descriptor
 db 0x67
 db 0x0
 db 0xd8
 db 0xdc
 db 0x0
 db 0xe9
 db 0x40
 db 0x0
;TSS [1.3] Descriptor
 db 0x67
 db 0x0
 db 0x40
 db 0xdd
 db 0x0
 db 0xe9
 db 0x40
 db 0x0
;Code Descriptor DPL = 1, Non Conforming
 db 0xff
 db 0xff
 db 0x0
 db 0xa0
 db 0x0
 db 0xba
 db 0x40
 db 0x0
;Code Descriptor DPL = 2, Non Conforming
 db 0xff
 db 0xff
 db 0x0
 db 0xa0
 db 0x0
 db 0xda
 db 0x40
 db 0x0
;Code Descriptor DPL = 3, Non Conforming
 db 0xff
 db 0xff
 db 0x0
 db 0xa0
 db 0x0
 db 0xfa
 db 0x40
 db 0x0
;Code Descriptor DPL = 0, Conforming
 db 0xff
 db 0xbf
 db 0x0
 db 0xa0
 db 0x0
 db 0x9e
 db 0x40
 db 0x0
 ;End of My GDT
 dw 0xf3a2
 dw 0x3fda
 dw 0xc866
 dw 0x6a8c
 dw 0x69f9
 dw 0x80c2
 dw 0x8e0a
 dw 0x396d
 dw 0x52a
 dw 0x7ad5
 dw 0x8465
 dw 0xc90f
 dw 0x4dea
 dw 0x23ab
 dw 0x7822
 dw 0x726b
 dw 0xeb0c
 dw 0x2c00
 dw 0x5b30
 dw 0xfc6d
 dw 0xfcfb
 dw 0x9431
 dw 0x7b4
 dw 0xc993
 dw 0x8e76
 dw 0x5f52
 dw 0x2e8a
 dw 0x9108
 ;Start of My LDT
ldt_start:
 ;Null Descriptor
 dd 0x0
 dd 0x0
;Data Segment Descriptor of type 0, random DPL and Base
 db 0x55
 db 0x1e
 db 0xab
 db 0xb1
 db 0x0
 db 0xb0
 db 0x40
 db 0x0
;Data Segment Descriptor of type 1, random DPL and Base
 db 0x87
 db 0x1c
 db 0x79
 db 0xb3
 db 0x0
 db 0xb1
 db 0x40
 db 0x0
;Data Segment Descriptor of type 2, random DPL and Base
 db 0x7b
 db 0x19
 db 0x85
 db 0xb6
 db 0x0
 db 0xb2
 db 0x40
 db 0x0
;Data Segment Descriptor of type 3, random DPL and Base
 db 0xb0
 db 0x1e
 db 0x50
 db 0xb1
 db 0x0
 db 0x93
 db 0x40
 db 0x0
;Data Segment Descriptor of type 4, random DPL and Base
 db 0x0
 db 0x0
 db 0x9f
 db 0xb0
 db 0x0
 db 0xd4
 db 0x40
 db 0x0
;Data Segment Descriptor of type 5, random DPL and Base
 db 0x0
 db 0x0
 db 0x1b
 db 0xb5
 db 0x0
 db 0xd5
 db 0x40
 db 0x0
;Data Segment Descriptor of type 6, random DPL and Base
 db 0x0
 db 0x0
 db 0x3e
 db 0xb2
 db 0x0
 db 0xd6
 db 0x0
 db 0x0
;Data Segment Descriptor of type 7, random DPL and Base
 db 0x0
 db 0x0
 db 0x70
 db 0xb1
 db 0x0
 db 0xf7
 db 0x0
 db 0x0
 ; A Type 2, PL 1 data segment, for use in Stack Switch during CALL GATE/TSS
 db 0xff
 db 0xbf
 db 0x0
 db 0xb0
 db 0x0
 db 0xb2
 db 0x40
 db 0x0
 ; A Type 2, PL 2 data segment, for use in Stack Switch during CALL GATE/TSS
 db 0xff
 db 0xbf
 db 0x0
 db 0xb0
 db 0x0
 db 0xd2
 db 0x40
 db 0x0
 ; Task Gate for TSS [0.0] with DPL 3
 db 0x0
 db 0x0
 db 0x60
 db 0x0
 db 0x0
 db 0xe5
 db 0x0
 db 0x0
 ; Task Gate for TSS [0.1] with DPL 3
 db 0x0
 db 0x0
 db 0x70
 db 0x0
 db 0x0
 db 0xe5
 db 0x0
 db 0x0
 ; Task Gate for TSS [0.2] with DPL 3
 db 0x0
 db 0x0
 db 0x78
 db 0x0
 db 0x0
 db 0xe5
 db 0x0
 db 0x0
 ; A Type 2, PL 3 data segment, for use in Stack Switch during CALL GATE/TSS
 db 0xff
 db 0xbf
 db 0x0
 db 0xb0
 db 0x0
 db 0xf2
 db 0x40
 db 0x0
 ; A Type 2, PL 3 data segment with size 0x2000, for use in Exception Handling
 db 0xff
 db 0x1f
 db 0x0
 db 0xb0
 db 0x0
 db 0xf2
 db 0x40
 db 0x0
 ; Task Gate for TSS [0.3] with DPL 3
 db 0x0
 db 0x0
 db 0x80
 db 0x0
 db 0x0
 db 0xe5
 db 0x0
 db 0x0
 ; Call Gate (DPL = 3) for Non-conforming Code segment with DPL 0 in GDT
 db 0x0
 db 0x0
 db 0x8
 db 0x0
 db 0x0
 db 0xec
 db 0x0
 db 0x0
 ; Call Gate (DPL = 3) for Non-conforming Code segment with DPL 1 in GDT
 db 0x0
 db 0x0
 db 0xa8
 db 0x0
 db 0x0
 db 0xec
 db 0x0
 db 0x0
 ; Call Gate (DPL = 3) for Non-conforming Code segment with DPL 2 in GDT
 db 0x0
 db 0x0
 db 0xb0
 db 0x0
 db 0x0
 db 0xec
 db 0x0
 db 0x0
 ; Call Gate (DPL = 3) for Non-conforming Code segment with DPL 3 in GDT
 db 0x0
 db 0x0
 db 0xb8
 db 0x0
 db 0x0
 db 0xec
 db 0x0
 db 0x0
 ; Conforming Code segment with DPL 0 (4GB) Paging Special
 db 0xff
 db 0xff
 db 0x0
 db 0x0
 db 0x0
 db 0x9e
 db 0xcf
 db 0x0
 ; Type 2 Data  with DPL 3 (4GB) Paging Special
 db 0xff
 db 0xff
 db 0x0
 db 0x0
 db 0x0
 db 0xf2
 db 0xcf
 db 0x0
 ;End of My LDT
 db 0x6
 db 0x4c
 db 0xfa
 db 0xa8
 db 0x27
 db 0x60
 db 0x35
 db 0x20
 db 0x22
 db 0x3f
 db 0x8d
 db 0x4c
 db 0x14
 db 0xf3
 db 0x5b
 db 0xfe
 db 0x9e
 db 0x7d
 db 0x69
 db 0xaa
 db 0x7d
 db 0x99
 db 0x18
 db 0x79
 db 0xca
 db 0xcc
 db 0xc
 db 0x40
 db 0x1e
 db 0x96
 db 0x48
 db 0x25
 db 0xe3
 db 0x42
 db 0xcd
 db 0xa
 db 0xa2
 db 0x2
 db 0x2a
 db 0xc4
 db 0x41
 db 0xb8
 db 0x10
 db 0x55
 db 0xab
 db 0x6b
 db 0x53
 db 0x49
 db 0xe9
 db 0xbc
 db 0xf4
 db 0x66
 db 0x55
 db 0xc
 db 0xdf
 db 0x1f
 db 0xd8
 db 0xec
 db 0x5f
 db 0xf7
 db 0x82
 db 0xa8
 db 0x1c
 db 0x65
 db 0xea
 db 0xe9
 db 0x6f
 db 0x8d
 db 0xec
 db 0x9a
 db 0x51
 db 0x2d
 db 0x52
 db 0x62
mygdt_base:
 ;storing limit and base for my GDT
 dw 0xff
 dd 0xd000
 ;Reserved Locations 0x208 and 0x209 in data page three
 db 0x83
 db 0xfd
myidt_base:
 ;My IDTs limit and base 0x20A and 0x20F in data page three
 db 0xa0
 db 0x0
 dd 0xd210
 ;My IDT Starts here at location 0x210 in data page three
idt_start:
;Exception gate for type 0
;--------FILL UP IDT ENTRY FOR Type 0 HERE------
;Exception gate for type 0

 dw 0x0
 dw 0x40
 dw 0x8f00                 ;p = 1, DPL = 0 , 01110 , 00000000
 dw 0x0
 
;Exception gate for type 1
 db 0x19
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0
;Exception gate for type 2
 db 0x22
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0
;Exception gate for type 3
 db 0x2b
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0
;Exception gate for type 4
 db 0x34
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0
;Exception gate for type 5
 db 0x3d
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0
;Exception gate for type 6
 db 0x46
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0
;Exception gate for type 7
 db 0x4f
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0
;Exception gate for type 8
 db 0x0
 db 0x0
 db 0x68
 db 0x0
 db 0x0
 db 0xe5
 db 0x0
 db 0x0
;Exception gate for type 9
 db 0xb2
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0
;Exception gate for type 10
 db 0x61
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0

;Exception gate for type 11
 dw 0x100
 dw 0x40
 dw 0x8f00                 ;p = 1, DPL = 0 , 01110 , 00000000 studark
 dw 0x0

;--------FILL UP IDT ENTRY FOR Type 11 HERE------

;Exception gate for type 12
 db 0x73
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0

;Exception gate for type 13
 dw 0x200
 dw 0x40
 dw 0x8f00                 ;p = 1, DPL = 0 , 01110 , 00000000
 dw 0x0
;--------FILL UP IDT ENTRY FOR Type 13 HERE------

;Exception gate for type 14
 db 0x85
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0
;Exception gate for type 15
 db 0xb2
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0
;Exception gate for type 16
 db 0x8e
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0
;Exception gate for type 17
 db 0x97
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0
;Exception gate for type 18
 db 0xa0
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0
;Exception gate for type 19
 db 0xa9
 db 0x33
 db 0x8
 db 0x0
 db 0x0
 db 0xef
 db 0x0
 db 0x0
 ;My IDT ends here for (0-18) descriptors
 ;Random data in remaining bytes of IDT (13 more descriptors can be added)
 db 0xcd
 db 0xd6
 db 0x46
 db 0xb6
 db 0x93
 db 0x3a
 db 0x1d
 db 0xe8
 db 0x46
 db 0xfc
 db 0x8
 db 0x1f
 db 0xe8
 db 0x67
 db 0x16
 db 0x6b
 db 0xf
 db 0x32
 db 0xd0
 db 0xfa
 db 0x1b
 db 0x40
 db 0x87
 db 0x7
 db 0xda
 db 0xd8
 db 0x35
 db 0x2c
 db 0x3a
 db 0xb8
 db 0x29
 db 0x8
 db 0x8e
 db 0x6f
 db 0xbe
 db 0x21
 db 0xaa
 db 0xdb
 db 0xa
 db 0xf0
 db 0xd8
 db 0x12
 db 0xf
 db 0xc0
 db 0x79
 db 0x25
 db 0x2b
 db 0x89
 db 0x57
 db 0xfc
 db 0x83
 db 0x73
 db 0x3c
 db 0xa
 db 0x7a
 db 0x16
 db 0xe2
 db 0xaf
 db 0x42
 db 0x1d
 db 0x67
 db 0x6b
 db 0x25
 db 0xf6
 db 0xda
 db 0xe3
 db 0x17
 db 0x84
 db 0xbf
 db 0x21
 db 0x75
 db 0x97
 db 0x33
 db 0x84
 db 0x57
 db 0xad
 db 0xaa
 db 0x83
 db 0x36
 db 0x1
 db 0x7f
 db 0xb9
 db 0x74
 db 0xbb
 db 0xc3
 db 0xef
 db 0xd1
 db 0xa5
 db 0x9e
 db 0x13
 db 0xc2
 db 0x6
 db 0x7e
 db 0xe7
 db 0xfc
 db 0x58
;Exception Handler routines

  excep_0: mov bx,0
           jmp excep_noerr
  excep_1: mov bx,1
           jmp excep_noerr
  excep_2: mov bx,2
           jmp excep_noerr
  excep_3: mov bx,3
           jmp excep_noerr
  excep_4: mov bx,4
           jmp excep_noerr
  excep_5: mov bx,5
           jmp excep_noerr
  excep_6: mov bx,6
           jmp excep_noerr
  excep_7: mov bx,7
           jmp excep_noerr
  excep_8: mov bx,8
           jmp double_handl
  excep_10: mov bx,10
           jmp excep_err
  excep_11: mov bx,11
           jmp excep_err
  excep_12: mov bx,12
           jmp excep_err
  excep_13: mov bx,13
           jmp excep_err
  excep_14: mov bx,14
           jmp excep_err
  excep_16: mov bx,16
           jmp excep_noerr
  excep_17: mov bx,17
           jmp excep_err
  excep_18: mov bx,18
           jmp excep_noerr
  excep_19: mov bx,19
           jmp excep_noerr
  excep_default: mov ax,0x50
           mov DS,ax
  	 mov word [0x2208],0xface
  	 jmp chanSad
  excep_noerr:   mov ax,0x50
                 mov DS,ax
  	       cmp byte [0x2208],0
  	       jne excep_noerr1
  	       and esp,0xffff
  excep_noerr1:  mov eax,[ss:esp]
                 cmp word [0x2200],0xdead
                 jne near ind_excep
                 cmp bx,16
                 je fp_excep_point
                 mov [0x2200],ax
                 mov [0x2208],bx
                 jmp chanSad
  fp_excep_point: fnclex
                 inc word [0x2ff0]
                 jmp ind_ret2
  excep_err:    mov ax,0x50
                mov DS,ax
  	      cmp byte [0x2208],0
  	      jne excep_err1
  	      and esp,0xffff
  excep_err1:   pop ecx
  	      mov eax,[ss:esp]
  	      cmp word [0x2200],0xdead
  	      jne near ind_excep
  	      mov [0x2200],ax
                mov [0x2208],bx
  	      jmp chanSad
  ind_excep:   add ax, word [0x2200]
               and eax,0xffff
               mov [ss:esp], eax
  	     mov word [0x2200],0xdead
 	     inc word [0x2ff8]
 	     cmp bx, word 7
 	     jne ind_ret
 	     clts
        ind_ret:cmp bx, word 19 	   
        jne ind_ret1 	   
        and dword [esp+8],0xfffdffff 	   
        mov word [esp+4],0x8 	   
        ind_ret1: 	cmp bx, word 14
        jne ind_ret2 	   
        mov edx,cr2 	   
 ind_ret2: iretd
  double_handl: pop ecx
                cmp word [0x2a68],0x60 
               je excp_l60 
               cmp word [0x2a68],0x70 
               je excp_l70 
               cmp word [0x2a68],0x78
               je excp_l78 
               cmp word [0x2a68],0x80 
               je excp_l80
               cmp word [0x2a68],0x88 
               je excp_l88 
               cmp word [0x2a68],0x90 
               je excp_l90 
               cmp word [0x2a68],0x98 
               je excp_l98 
               cmp word [0x2a68],0xA0 
               je excp_lA0 
  	     mov word [0x2200], 0xdfdf
  	      jmp chanSad
  excp_l60:    mov eax,dword [0x2a20]
               mov ebx,0x2a20
               jmp excp_2
  excp_l70:    mov eax,dword [0x2af0]
               mov ebx,0x2af0
               jmp excp_2
  excp_l78:    mov eax,dword [0x2b58]
               mov ebx,0x2b58
               jmp excp_2
  excp_l80:    mov eax,dword [0x2bc0]
               mov ebx,0x2bc0
               jmp excp_2
  excp_l88:    mov eax,dword [0x2c28]
               mov ebx,0x2c28
               jmp excp_2
  excp_l90:    mov eax,dword [0x2c90]
               mov ebx,0x2c90
               jmp excp_2
  excp_l98:    mov eax,dword [0x2cf8]
               mov ebx,0x2cf8
               jmp excp_2
  excp_lA0:    mov eax,dword [0x2d60]
               mov ebx,0x2d60
 excp_2:       cmp word [0x2200],0xdead
                jne ind_excep1
                mov [0x2200],ax
                mov word [0x2208],8
  	      jmp chanSad
  ind_excep1:      add ax,word [0x2200]
               mov word [ebx],ax
 	      mov dword [ebx+0x14],8
 	      mov dword [ebx+0xc],ecx
               mov word [0x2200],0xdead
 	     inc word [0x2ff8]
  	      iretd
  	      jmp double_handl
 end_excep_rout:
;Empty space in third page filled with Random data
 db 0xe2
 db 0x99
 db 0xcd
 db 0x6c
 db 0xce
 db 0x1f
 db 0x8d
 db 0x37
 db 0xf5
 db 0x5
 db 0x4c
 db 0x76
 db 0x1
 db 0x98
 db 0xf8
 db 0x7b
 db 0x9c
 db 0xee
 db 0xb1
 db 0x64
 db 0xd4
 db 0xb7
 db 0xd1
 db 0x58
 db 0xd1
 db 0x0
 db 0xe2
 db 0x68
 db 0x17
 db 0x68
 db 0x58
 db 0xf9
 db 0x1
 db 0x25
 db 0x65
 db 0xd0
 db 0x44
 db 0xf2
 db 0x7
 db 0x3a
 db 0xf8
 db 0x53
 db 0xb0
 db 0xf9
 db 0xeb
 db 0xa8
 db 0x74
 db 0x88
 db 0x96
 db 0x25
 db 0xec
 db 0x6a
 db 0xdd
 db 0xbd
 db 0xc2
 db 0xae
 db 0xbd
 db 0xa4
 db 0x16
 db 0xd5
 db 0xc
 db 0x6f
 db 0xce
 db 0xe
 db 0x94
 db 0x34
 db 0xde
 db 0xd9
 db 0x26
 db 0xe5
 db 0x13
 db 0x1e
 db 0x38
 db 0xc3
 db 0x17
 db 0x24
 db 0x6b
 db 0x8c
 db 0xac
 db 0x1
 db 0xb1
 db 0x98
 db 0x6c
 db 0x8e
 db 0x55
 db 0x2e
 db 0x3c
 db 0x12
 db 0xd3
 db 0x53
 db 0xe7
 db 0xdf
 db 0xc2
 db 0xb6
 db 0xed
 db 0x56
 db 0xea
 db 0xcb
 db 0x2f
 db 0x10
 db 0xb0
 db 0x42
 db 0x2f
 db 0xe9
 db 0x5
 db 0x46
 db 0xd
 db 0x70
 db 0xd2
 db 0xb9
 db 0x72
 db 0x84
 db 0x51
 db 0xde
 db 0x12
 db 0xa6
 db 0xc
 db 0x4f
 db 0xb8
 db 0xdf
 db 0xa2
 db 0xa0
 db 0xbf
 db 0x64
 db 0x56
 db 0xac
 db 0xba
 db 0x40
 db 0x78
 db 0xea
 db 0x50
 db 0x28
 db 0x2c
 db 0x7f
 db 0x11
 db 0x32
 db 0xc6
 db 0x1e
 db 0xa2
 db 0x98
 db 0xd7
 db 0x14
 db 0x1c
 db 0x28
 db 0xf2
 db 0x2f
 db 0xce
 db 0xff
 db 0x7e
 db 0x87
 db 0xde
 db 0x20
 db 0x27
 db 0x9d
 db 0x84
 db 0x7d
 db 0x4a
 db 0x3e
 db 0xbd
 db 0xc2
 db 0x28
 db 0xd
 db 0xea
 db 0x55
 db 0x8d
 db 0xfc
 db 0x87
 db 0x53
 db 0x1a
 db 0x29
 db 0xeb
 db 0xf2
 db 0x3e
 db 0x8
 db 0x1a
 db 0x30
 db 0x37
 db 0xe9
 db 0x2f
 db 0xb5
 db 0x70
 db 0xe
 db 0xd5
 db 0x97
 db 0xab
 db 0x59
 db 0x14
 db 0xf5
 db 0x97
 db 0xd1
 db 0xb7
 db 0xc0
 db 0xde
 db 0xa2
 db 0x15
 db 0x6b
 db 0x9e
 db 0x9c
 db 0xbe
 db 0xb8
 db 0xc5
 db 0xaa
 db 0xaa
 db 0x3
 db 0xb2
 db 0xc5
 db 0x34
 db 0xe9
 db 0xae
 db 0x63
 db 0x9e
 db 0x1e
 db 0x71
 db 0x73
 db 0xb5
 db 0x1d
 db 0xcc
 db 0xc9
 db 0x12
 db 0x63
 db 0x9a
 db 0xca
 db 0x23
 db 0x78
 db 0x6c
 db 0x38
 db 0xe4
 db 0xa
 db 0xd4
 db 0xa2
 db 0xc2
 db 0x9a
 db 0x4c
 db 0x6d
 db 0x9d
 db 0xfe
 db 0x32
 db 0xd1
 db 0xe7
 db 0xe0
 db 0x35
 db 0x85
 db 0xfe
 db 0xa6
 db 0xf8
 db 0xb3
 db 0xc3
 db 0xc4
 db 0x7c
 db 0xd6
 db 0x28
 db 0x16
 db 0xa0
 db 0x4b
 db 0x8e
 db 0xc
 db 0x84
 db 0x72
 db 0x16
 db 0x58
 db 0x15
 db 0xd8
 db 0xf2
 db 0x61
 db 0x45
 db 0x90
 db 0x60
 db 0x77
 db 0x61
 db 0x47
 db 0x57
 db 0x96
 db 0xcd
 db 0x55
 db 0x3d
 db 0xc5
 db 0x8
 db 0x0
 db 0x8a
 db 0x84
 db 0xd6
 db 0xb2
 db 0x9a
 db 0x76
 db 0xfd
 db 0x29
 db 0x82
 db 0x81
 db 0x9b
 db 0x98
 db 0xda
 db 0xb0
 db 0x71
 db 0xcc
 db 0x12
 db 0xb6
 db 0x5c
 db 0x72
 db 0x2e
 db 0xbe
 db 0xb9
 db 0x85
 db 0x54
 db 0x86
 db 0xdb
 db 0x91
 db 0x4c
 db 0xe3
 db 0x92
 db 0xd6
 db 0x68
 db 0x68
 db 0x88
 db 0x2
 db 0xdf
 db 0x85
 db 0x2b
 db 0x61
 db 0x7
 db 0xc7
 db 0xfa
 db 0xe1
 db 0x77
 db 0x6b
 db 0xad
 db 0x89
 db 0x21
 db 0xa
 db 0xfb
 db 0x4f
 db 0xc8
 db 0xb5
 db 0xd5
 db 0x1c
 db 0x3b
 db 0xb0
 db 0xae
 db 0x87
 db 0x93
 db 0x40
 db 0x5d
 db 0xfb
 db 0xa8
 db 0xe5
 db 0xfe
 db 0x87
 db 0x6b
 db 0x29
 db 0xe9
 db 0x72
 db 0xf0
 db 0xe3
 db 0x53
 db 0x68
 db 0x4e
 db 0x0
 db 0xf1
 db 0x6f
 db 0xa
 db 0xed
 db 0xbf
 db 0xd2
 db 0xa2
 db 0x94
 db 0xef
 db 0xdd
 db 0x44
 db 0x9d
 db 0x65
 db 0xd7
 db 0xdd
 db 0xc2
 db 0xd3
 db 0x85
 db 0xa8
 db 0xd1
 db 0xd
 db 0x13
 db 0xfa
 db 0xf6
 db 0x85
 db 0xeb
 db 0xd9
 db 0xd8
 db 0x53
 db 0x27
 db 0xd8
 db 0x44
 db 0x96
 db 0xe3
 db 0x31
 db 0x55
 db 0xb5
 db 0xd3
 db 0xe9
 db 0xa4
 db 0xb1
 db 0x2d
 db 0x41
 db 0x16
 db 0x5
 db 0x1e
 db 0xd8
 db 0xd8
 db 0xa4
 db 0x80
 db 0xa9
 db 0xb1
 db 0x93
 db 0xa3
 db 0xa7
 db 0x18
 db 0x8e
 db 0x80
 db 0xf0
 db 0xe1
 db 0xa7
 db 0xc9
 db 0x26
 db 0x3d
 db 0xac
 db 0x57
 db 0x93
 db 0x61
 db 0x2b
 db 0x7c
 db 0x6
 db 0xdc
 db 0xaa
 db 0x47
 db 0xf2
 db 0xaf
 db 0x66
 db 0xca
 db 0x87
 db 0xa
 db 0x4b
 db 0x30
 db 0xbb
 db 0xde
 db 0xd3
 db 0x62
 db 0xf7
 db 0x62
 db 0xe2
 db 0xe7
 db 0x43
 db 0x89
 db 0xb0
 db 0x69
 db 0xc6
 db 0x5c
 db 0xc1
 db 0x59
 db 0xbe
 db 0xec
 db 0xd6
 db 0xc4
 db 0xc8
 db 0x80
 db 0xb
 db 0xba
 db 0x2f
 db 0x71
 db 0x84
 db 0xb6
 db 0x7b
 db 0xcf
 db 0xe6
 db 0x36
 db 0xae
 db 0xb9
 db 0x98
 db 0xa5
 db 0x1b
 db 0x7a
 db 0x8c
 db 0x5f
 db 0x3
 db 0x3d
 db 0xc8
 db 0xca
 db 0x99
 db 0x89
 db 0x23
 db 0x57
 db 0x75
 db 0xf9
 db 0x1b
 db 0x3d
 db 0x79
 db 0x27
 db 0xf7
 db 0xa8
 db 0x98
 db 0x7c
 db 0x5e
 db 0x14
 db 0x4b
 db 0x44
 db 0x4a
 db 0xf9
 db 0xfe
 db 0xe3
 db 0x9e
 db 0x19
 db 0x5d
 db 0x2b
 db 0x78
 db 0x61
 db 0x68
 db 0x41
 db 0x2b
 db 0x1
 db 0xca
 db 0x4e
 db 0x59
 db 0x40
 db 0x48
 db 0x74
 db 0x7d
 db 0xc1
 db 0x9b
 db 0x75
 db 0x6a
 db 0x34
 db 0xf1
 db 0xc8
 db 0x48
 db 0x3c
 db 0xd
 db 0x92
 db 0x36
 db 0xb
 db 0x75
 db 0xd4
 db 0x24
 db 0xd3
 db 0xff
 db 0x9d
 db 0x34
 db 0x67
 db 0xde
 db 0x5f
 db 0x69
 db 0xa8
 db 0xad
 db 0xc2
 db 0xe8
 db 0xf5
 db 0x36
 db 0x66
 db 0xb7
 db 0xd2
 db 0xdb
 db 0x21
 db 0x6
 db 0xcc
 db 0xe9
 db 0x4e
 db 0x8
 db 0xf6
 db 0xe0
 db 0x3e
 db 0x1
 db 0x56
 db 0x13
 db 0x26
 db 0x29
 db 0x12
 db 0xc3
 db 0x5d
 db 0x7a
 db 0xa1
 db 0xbc
 db 0xe3
 db 0x49
 db 0x69
 db 0xa5
 db 0x32
 db 0x5f
 db 0xdb
 db 0x98
 db 0x16
 db 0xad
 db 0x73
 db 0x37
 db 0xb3
 db 0x3f
 db 0x20
 db 0x1
 db 0x47
 db 0x17
 db 0xe2
 db 0x86
 db 0x18
 db 0x38
 db 0x99
 db 0x3e
 db 0x61
 db 0xab
 db 0x1
 db 0xbe
 db 0x25
 db 0xa2
 db 0x7a
 db 0x8
 db 0xec
 db 0xe3
 db 0xad
 db 0x1e
 db 0x42
 db 0x89
 db 0xb6
 db 0x58
 db 0x36
 db 0x29
 db 0x8f
 db 0xea
 db 0x68
 db 0xb0
 db 0xeb
 db 0xaf
 db 0xc7
 db 0xcd
 db 0x35
 db 0xdf
 db 0x5
 db 0xce
 db 0x1e
 db 0x66
 db 0x7a
 db 0x1f
 db 0x24
 db 0x9f
 db 0xc2
 db 0x9e
 db 0xa8
 db 0xae
 db 0x82
 db 0x55
 db 0xcc
 db 0xc4
 db 0xde
 db 0x82
 db 0x1d
 db 0x15
 db 0xab
 db 0xac
 db 0xff
 db 0x13
 db 0x5c
 db 0xea
 db 0xc2
 db 0x23
 db 0xb8
 db 0xf8
 db 0x3
 db 0xbd
 db 0xc6
 db 0x21
 db 0x24
 db 0x40
 db 0x40
 db 0x48
 db 0xe0
 db 0x2
 db 0xe7
 db 0x88
 db 0xb0
 db 0x69
 db 0xdd
 db 0x7c
 db 0x2d
 db 0xbc
 db 0xfe
 db 0x4a
 db 0xd1
 db 0xa9
 db 0xf7
 db 0xd0
 db 0xbc
 db 0x53
 db 0xba
 db 0x7f
 db 0x77
 db 0x72
 db 0x77
 db 0x7a
 db 0x30
 db 0x3d
 db 0x9b
 db 0x54
 db 0x7e
 db 0xdb
 db 0x9c
 db 0x5e
 db 0xde
 db 0x83
 db 0xe6
 db 0x8e
 db 0xec
 db 0xc3
 db 0xb
 db 0x1a
 db 0x7f
 db 0x9
 db 0x64
 db 0x50
 db 0xb3
 db 0x5b
 db 0x20
 db 0x6f
 db 0xaf
 db 0xdb
 db 0xee
 db 0x26
 db 0x4d
 db 0x65
 db 0xa0
 db 0x7d
 db 0xa3
 db 0x3b
 db 0xd1
 db 0x21
 db 0x16
 db 0x6e
 db 0x7f
 db 0xf4
 db 0xf1
 db 0x65
 db 0x83
 db 0xde
 db 0x28
 db 0x8e
 db 0xf8
 db 0xa8
 db 0x97
 db 0x5c
 db 0xf8
 db 0x4a
 db 0xb8
 db 0x19
 db 0xba
 db 0x67
 db 0xf4
 db 0xa8
 db 0x8d
 db 0x41
 db 0xe
 db 0x2d
 db 0xbf
 db 0xb1
 db 0x68
 db 0x90
 db 0xd2
 db 0x7e
 db 0xfe
 db 0x51
 db 0x73
 db 0xf0
 db 0xb6
 db 0xf6
 db 0xce
 db 0xde
 db 0x84
 db 0xc6
 db 0x86
 db 0x1b
 db 0x22
 db 0x7f
 db 0x66
 db 0xda
 db 0x98
 db 0x20
 db 0x41
 db 0x8c
 db 0xc8
 db 0xce
 db 0xcd
 db 0xd6
 db 0xfb
 db 0x8c
 db 0x87
 db 0x63
 db 0x1d
 db 0x59
 db 0xe2
 db 0x1b
 db 0xaa
 db 0x55
 db 0xb
 db 0x60
 db 0x4b
 db 0xd9
 db 0x3f
 db 0xcf
 db 0x9f
 db 0xc5
 db 0xea
 db 0xc2
 db 0x44
 db 0x50
 db 0x9c
 db 0xdc
 db 0x70
 db 0xde
 db 0x68
 db 0x39
 db 0xac
 db 0x36
 db 0xf
 db 0xa8
 db 0xc2
 db 0x97
 db 0xb
 db 0xdf
 db 0xf0
 db 0xed
 db 0xfb
 db 0x9b
 db 0x42
 db 0x6
 db 0xfb
 db 0x8d
 db 0xe0
 db 0x3a
 db 0x5c
 db 0x7f
 db 0x0
 db 0x47
 db 0x41
 db 0x44
 db 0x97
 db 0xde
 db 0x21
 db 0x8
 db 0xbc
 db 0x89
 db 0x41
 db 0x68
 db 0xbf
 db 0x50
 db 0x10
 db 0x82
 db 0xe7
 db 0x1c
 db 0x61
 db 0xd8
 db 0x9
 db 0x5c
 db 0x73
 db 0x4c
 db 0x63
 db 0x6e
 db 0xd9
 db 0x43
 db 0xa9
 db 0x36
 db 0xc2
 db 0xa9
 db 0x7d
 db 0x4
 db 0xed
 db 0x14
 db 0xe2
 db 0xe
 db 0x1c
 db 0x9e
 db 0x98
 db 0x5d
 db 0x6
 db 0x57
 db 0xae
 db 0x17
 db 0xd9
 db 0x95
 db 0x33
 db 0x3b
 db 0x6d
 db 0x3c
 db 0x97
 db 0xe0
 db 0x88
 db 0xfa
 db 0x4f
 db 0x62
 db 0x3d
 db 0xf8
 db 0x98
 db 0x0
 db 0xa1
 db 0x15
 db 0x4
 db 0x8e
 db 0x29
 db 0xe6
 db 0x9d
 db 0x46
 db 0x84
 db 0x35
 db 0xa3
 db 0x8a
 db 0x8c
 db 0x51
 db 0xa1
 db 0x66
 db 0xe7
 db 0xd4
 db 0xa1
 db 0x54
 db 0x11
 db 0x38
 db 0x35
 db 0x99
 db 0x33
 db 0x84
 db 0xfb
 db 0x70
 db 0x7c
 db 0x93
 db 0x70
 db 0x1d
 db 0xa8
 db 0x74
 db 0xab
 db 0xd2
 db 0x5a
 db 0x48
 db 0x18
 db 0xde
 db 0x7d
 db 0xbb
 db 0x69
 db 0xa
 db 0xd
 db 0xa
 db 0x70
 db 0xf4
 db 0xdf
 db 0x11
 db 0x48
 db 0xf0
 db 0x49
 db 0x7d
 db 0x89
 db 0x7c
 db 0x1
 db 0x85
 db 0xed
 db 0x7d
 db 0x18
 db 0x5d
 db 0x9a
 db 0xc1
 db 0xd2
 db 0x46
 db 0x93
 db 0x2c
 db 0x8e
 db 0xab
 db 0xb
 db 0xc
 db 0x66
 db 0x74
 db 0x16
 db 0x73
 db 0x7e
 db 0x86
 db 0x67
 db 0x5d
 db 0x97
 db 0xb0
 db 0x4d
 db 0xe0
 db 0x2d
 db 0xd7
 db 0x5d
 db 0x2f
 db 0x5c
 db 0x4a
 db 0xac
 db 0x74
 db 0xa7
 db 0x47
 db 0x35
 db 0x79
 db 0x8d
 db 0xc8
 db 0xa6
 db 0x1b
 db 0x73
 db 0xb1
 db 0x27
 db 0xda
 db 0x25
 db 0x3d
 db 0x4d
 db 0xa3
 db 0xc3
 db 0xb5
 db 0x1
 db 0x5a
 db 0x65
 db 0x4e
 db 0x3b
 db 0x92
 db 0x25
 db 0x98
 db 0xc1
 db 0x81
 db 0xe2
 db 0x6e
 db 0xf6
 db 0x89
 db 0xb5
 db 0x2b
 db 0x3
 db 0x42
 db 0xf4
 db 0xa9
 db 0x5d
 db 0x67
 db 0x5a
 db 0x85
 db 0x41
 db 0x7f
 db 0xc2
 db 0x8f
 db 0x22
 db 0x86
 db 0x44
 db 0x23
 db 0xe0
 db 0xa9
 db 0x72
 db 0x1b
 db 0x3b
 db 0x97
 db 0xb3
 db 0xfd
 db 0x19
 db 0x95
 db 0x6b
 db 0xf
 db 0x1f
 db 0x20
 db 0x3a
 db 0x22
 db 0x62
 db 0x2e
 db 0xcb
 db 0xbf
 db 0x96
 db 0x25
 db 0x44
 db 0xd7
 db 0xa4
 db 0x7
 db 0x66
 db 0xc6
 db 0x8d
 db 0xaa
 db 0xea
 db 0x6d
 db 0x53
 db 0x5c
 db 0x89
 db 0x8f
 db 0xf3
 db 0x3c
 db 0x8c
 db 0xc
 db 0xd2
 db 0xf7
 db 0x1b
 db 0xf1
 db 0x17
 db 0x56
 db 0x13
 db 0x79
 db 0x84
 db 0xde
 db 0x38
 db 0x1a
 db 0x3
 db 0x7d
 db 0xf2
 align 0x3A00
 tss0.0:
; TSS for default code when Test starts
 dd 0x0
 dd 0x1000
 dd 0x50
 dd 0x1000
 dd 0x4d
 dd 0x1000
 dd 0x56
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x58
 dd 0x0
 tssd.d:
; TSS for double exception handler
 dd 0x0
 dd 0x1000
 dd 0x50
 dd 0x1000
 dd 0x4d
 dd 0x1000
 dd 0x56
 dd 0x0
 dd 0x3358
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x1000
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x50
 dd 0x8
 dd 0x50
 dd 0x50
 dd 0x50
 dd 0x50
 dd 0x58
 dd 0x0
 tss0.1:
; TSS [0.1]
 dd 0x0
 dd 0x1000
 dd 0x50
 dd 0x1000
 dd 0x4d
 dd 0x1000
 dd 0x56
 dd 0x0
 dd 0x3358
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x1000
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x4d
 dd 0xa9
 dd 0x4d
 dd 0x4d
 dd 0x4d
 dd 0x4d
 dd 0x58
 dd 0x0
 tss0.2:
; TSS [0.2]
 dd 0x0
 dd 0x1000
 dd 0x50
 dd 0x1000
 dd 0x4d
 dd 0x1000
 dd 0x56
 dd 0x0
 dd 0x3358
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x1000
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x56
 dd 0xb2
 dd 0x56
 dd 0x56
 dd 0x56
 dd 0x56
 dd 0x58
 dd 0x0
 tss0.3:
; TSS [0.3]
 dd 0x0
 dd 0x1000
 dd 0x50
 dd 0x1000
 dd 0x4d
 dd 0x1000
 dd 0x56
 dd 0x0
 dd 0x3358
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x1000
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x77
 dd 0xbb
 dd 0x77
 dd 0x77
 dd 0x77
 dd 0x77
 dd 0x58
 dd 0x0
 tss1.0:
; TSS [1.0]
 dd 0x0
 dd 0x1000
 dd 0x50
 dd 0x1000
 dd 0x4d
 dd 0x1000
 dd 0x56
 dd 0x0
 dd 0x3358
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x1000
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x50
 dd 0x8
 dd 0x50
 dd 0x50
 dd 0x50
 dd 0x50
 dd 0x58
 dd 0x0
 tss1.1:
; TSS [1.1]
 dd 0x0
 dd 0x1000
 dd 0x50
 dd 0x1000
 dd 0x4d
 dd 0x1000
 dd 0x56
 dd 0x0
 dd 0x3358
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x1000
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x4d
 dd 0xa9
 dd 0x4d
 dd 0x4d
 dd 0x4d
 dd 0x4d
 dd 0x58
 dd 0x0
 tss1.2:
; TSS [1.2]
 dd 0x0
 dd 0x1000
 dd 0x50
 dd 0x1000
 dd 0x4d
 dd 0x1000
 dd 0x56
 dd 0x0
 dd 0x3358
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x1000
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x56
 dd 0xb2
 dd 0x56
 dd 0x56
 dd 0x56
 dd 0x56
 dd 0x58
 dd 0x0
 tss1.3:
; TSS [1.3]
 dd 0x0
 dd 0x1000
 dd 0x50
 dd 0x1000
 dd 0x4d
 dd 0x1000
 dd 0x56
 dd 0x0
 dd 0x3358
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x1000
 dd 0x0
 dd 0x0
 dd 0x0
 dd 0x77
 dd 0xbb
 dd 0x77
 dd 0x77
 dd 0x77
 dd 0x77
 dd 0x58
 dd 0x0
;Empty space in third page filled with Random data
 db 0xa7
 db 0x84
 db 0x58
 db 0x6d
 db 0x11
 db 0x3
 db 0x57
 db 0x7e
 db 0x56
 db 0xb3
 db 0x7
 db 0xe5
 db 0xa7
 db 0x44
 db 0x71
 db 0xb3
 db 0x16
 db 0x68
 db 0xcf
 db 0x7
 db 0x7f
 db 0x25
 db 0x1a
 db 0xf8
 db 0xa9
 db 0xf8
 db 0x31
 db 0xc4
 db 0xfb
 db 0xae
 db 0xb6
 db 0xa2
 db 0x32
 db 0xe
 db 0xf
 db 0x43
 db 0x11
 db 0x67
 db 0xc1
 db 0x68
 db 0x1a
 db 0xc9
 db 0x4d
 db 0xc1
 db 0xd
 db 0xbf
 db 0x75
 db 0x23
 db 0x27
 db 0x44
 db 0x2a
 db 0xa7
 db 0x69
 db 0x44
 db 0x9f
 db 0x12
 db 0x3c
 db 0xd0
 db 0xd6
 db 0x37
 db 0x7e
 db 0x8c
 db 0xd9
 db 0xb0
 db 0x9b
 db 0xe8
 db 0xf3
 db 0xac
 db 0x4f
 db 0xb5
 db 0x14
 db 0x6a
 db 0x7e
 db 0x62
 db 0x2b
 db 0x8b
 db 0x21
 db 0xa0
 db 0xae
 db 0x48
 db 0xe4
 db 0xd8
 db 0xef
 db 0x4d
 db 0x1c
 db 0x8f
 db 0x60
 db 0x58
 db 0x5f
 db 0x36
 db 0x8f
 db 0xde
 db 0xc3
 db 0x68
 db 0x8e
 db 0x5e
 db 0x50
 db 0x82
 db 0xa
 db 0xa0
 db 0x37
 db 0x1f
 db 0xa
 db 0xb5
 db 0x81
 db 0x35
 db 0x40
 db 0xa2
 db 0xd6
 db 0xee
 db 0xea
 db 0xba
 db 0xc6
 db 0xda
 db 0x8
 db 0xe2
 db 0x69
 db 0x68
 db 0x3a
 db 0xc8
 db 0x9e
 db 0xc9
 db 0xa6
 db 0x61
 db 0x31
 db 0x35
 db 0xbf
 db 0x81
 db 0xb7
 db 0xca
 db 0x21
 db 0xee
 db 0xe9
 db 0x2b
 db 0xa3
 db 0x6a
 db 0x61
 db 0xe3
 db 0xc
 db 0x37
 db 0xd1
 db 0xf6
 db 0xf1
 db 0x97
 db 0xd0
 db 0xf9
 db 0x79
 db 0x39
 db 0x61
 db 0xb3
 db 0x2
 db 0x0
 db 0x7c
 db 0xa8
 db 0x61
 db 0xad
 db 0xdd
 db 0x21
 db 0x2e
 db 0x94
 db 0xeb
 db 0x50
 db 0x82
 db 0xd4
 db 0x7b
 db 0x25
 db 0x3e
 db 0xdc
 db 0x8
 db 0x4a
 db 0x13
 db 0xd9
 db 0x40
 db 0x5
 db 0x70
 db 0x11
 db 0xfe
 db 0xe9
 db 0x4a
 db 0x60
 db 0x9c
 db 0x4c
 db 0x60
 db 0x18
 db 0xf5
 db 0xc1
 db 0xc5
 db 0xd2
 db 0xe2
 db 0xf4
 db 0x67
 db 0xcd
 db 0x44
 db 0xe9
 db 0xa1
 db 0xbf
 db 0xf
 db 0xdf
 db 0x9c
 db 0x17
 db 0x29
 db 0xaf
 db 0xf1
 db 0x6a
 db 0xb4
 db 0x61
 db 0x7b
 db 0xb3
 db 0x4b
 db 0xc5
 db 0x13
 db 0xe7
 db 0x12
 db 0x73
 db 0x0
 db 0x7
 db 0x34
 db 0xc5
 db 0xd9
 db 0x17
 db 0xb9
 db 0x40
 db 0xe4
 db 0xfd
 db 0x2a
 db 0x86
 db 0xbd
 db 0x39
 db 0x65
 db 0x59
 db 0x50
 db 0x8f
 db 0x8
 db 0x41
 db 0xf9
 db 0xbd
 db 0xa3
 db 0x74
 db 0x70
 db 0xee
 db 0x39
 db 0x83
 db 0xd5
 db 0x4b
 db 0xf6
 db 0xd5
 db 0x52
 db 0x2a
 db 0x9b
 db 0x2c
 db 0x41
 db 0x54
 db 0x6c
 db 0x26
 db 0x52
 db 0x96
 db 0xac
 db 0xf
 db 0xcf
 db 0x11
 db 0x68
 db 0x20
 db 0xa0
 db 0x70
 db 0x61
 db 0x99
 db 0x2d
 db 0x4
 db 0xd
 db 0x9d
 db 0xf2
 db 0x47
 db 0x20
 db 0xc8
 db 0x92
 db 0x16
 db 0x9d
 db 0xe5
 db 0x41
 db 0x38
 db 0x11
 db 0x82
 db 0x8d
 db 0x7d
 db 0xa8
 db 0xdf
 db 0x14
 db 0x54
 db 0xee
 db 0xe3
 db 0x66
 db 0x56
 db 0x3
 db 0x6
 db 0xc6
 db 0x65
 db 0xa0
 db 0xf4
 db 0x69
 db 0xad
 db 0x91
 db 0x5c
 db 0xf4
 db 0xb2
 db 0x24
 db 0x87
 db 0xc8
 db 0xc1
 db 0x6c
 db 0x9
 db 0xfa
 db 0x7d
 db 0x8c
 db 0x87
 db 0xfa
 db 0x34
 db 0x66
 db 0xe
 db 0x89
 db 0x54
 db 0xf2
 db 0xef
 db 0xaa
 db 0xf5
 db 0xf5
 db 0x70
 db 0x5a
 db 0x95
 db 0x64
 db 0xc4
 db 0x43
 db 0xf6
 db 0x20
 db 0x37
 db 0xa8
 db 0x44
 db 0xbe
 db 0x70
 db 0x5
 db 0x2a
 db 0x7a
 db 0xff
 db 0xa7
 db 0x6
 db 0x86
 db 0xa2
 db 0x3a
 db 0xec
 db 0xb0
 db 0xc3
 db 0x40
 db 0xa2
 db 0xb2
 db 0xea
 db 0x98
 db 0xa8
 db 0x5b
 db 0xf2
 db 0x3d
 db 0xbf
 db 0xb6
 db 0x80
 db 0xb5
 db 0xd6
 db 0xb8
 db 0x5d
 db 0x1a
 db 0x76
 db 0xce
 db 0x20
 db 0xa1
 db 0x48
 db 0x1f
 db 0x48
 db 0x4e
 db 0xa6
 db 0xea
 db 0x88
 db 0x92
 db 0x9b
 db 0x4c
 db 0xd3
 db 0x3d
 db 0xfe
 db 0xbd
 db 0xd5
 db 0xa6
 db 0x18
 db 0xc8
 db 0xe4
 db 0xd8
 db 0x7e
 db 0x64
 db 0x8d
 db 0x55
 db 0x1c
 db 0xeb
 db 0x6f
 db 0x93
 db 0xb9
 db 0x8f
 db 0x34
 db 0x1
 db 0xaf
 db 0x7c
 db 0x4f
 db 0x55
 db 0x67
 db 0xd7
 db 0xe7
 db 0x2
 db 0x23
 db 0xba
 db 0x3f
 db 0x22
 db 0x78
 db 0x15
 db 0xc8
 db 0x90
 db 0xdd
 db 0xac
 db 0x68
 db 0x5b
 db 0x11
 db 0xf6
 db 0xb0
 db 0x2d
 db 0xe1
 db 0x20
 db 0xc0
 db 0x9a
 db 0xaf
 db 0xf4
 db 0x9b
 db 0x5e
 db 0x71
 db 0xea
 db 0xb3
 db 0xd8
 db 0xc1
 db 0x9b
 db 0xda
 db 0xe5
 db 0x55
 db 0x19
 db 0x7
 db 0xcd
 db 0x2e
 db 0xcf
 db 0x5e
 db 0xb
 db 0x7c
 db 0xc6
 db 0x67
 db 0x8d
 db 0xbc
 db 0x17
 db 0xba
 db 0x9d
 db 0x37
 db 0x7b
 db 0x37
 db 0xe7
 db 0x6f
 db 0xd2
 db 0x45
 db 0xe0
 db 0xbc
 db 0xf9
 db 0xb8
 db 0x7e
 db 0x94
 db 0x92
 db 0x63
 db 0xe9
 db 0xac
 db 0x6a
 db 0xb7
 db 0xda
 db 0x39
 db 0x15
 db 0xe6
 db 0xb5
 db 0xdb
 db 0x4d
 db 0x42
 db 0x98
 db 0x64
 db 0xfd
 db 0x35
 db 0x9c
 db 0x78
 db 0x6d
 db 0x83
 db 0xe7
 db 0x3f
 db 0xc8
 db 0xc8
 db 0xfc
 db 0xc1
 db 0x80
 db 0x7a
 db 0x55
 db 0x13
 db 0xdd
 db 0x3f
 db 0xbf
 db 0x47
 db 0xf6
 db 0x99
 db 0x80
 db 0xb
 db 0x7f
 db 0x36
 db 0xe6
 db 0xcc
 db 0x78
 db 0x7e
 db 0x31
 db 0x75
 db 0xb4
 db 0xcd
 db 0xed
 db 0x21
 db 0x50
 db 0xd5
 db 0x60
 db 0x18
 db 0x9d
 db 0x5c
 db 0xda
 db 0x1d
 db 0xd6
 db 0x2f
 db 0x30
 db 0xb3
 db 0x6e
 db 0xef
 db 0xfa
 db 0x64
 db 0x89
 db 0x7b
 db 0x6f
 db 0x8
 db 0xb1
 db 0x56
 db 0xd5
 db 0x29
 db 0xd4
 db 0x6
 db 0x9f
 db 0x88
 db 0xd3
 db 0x8c
 db 0xa9
 db 0x23
 db 0x61
 db 0xa
 db 0x3b
 db 0xfe
 db 0x66
 db 0x15
 db 0x1c
 db 0x3d
 db 0x45
 db 0x4c
 db 0xf0
 db 0xb3
 db 0x3c
 db 0xeb
 db 0x18
 db 0xc5
 db 0x66
 db 0x87
 db 0xcd
 db 0x17
 db 0xdd
 db 0xa2
 db 0x40
 db 0xb2
 db 0xa8
 db 0xdf
 db 0x3a
 db 0x7b
 db 0x6c
 db 0xe4
 db 0x9e
 db 0xcd
 db 0xee
 db 0xda
 db 0xcc
 db 0x54
 db 0xef
 db 0xe8
 db 0x91
 db 0x34
 db 0x34
 db 0x82
 db 0xe8
 db 0x70
; End of Page 3 of data

