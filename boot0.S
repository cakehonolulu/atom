.code16							# 16-Bit Mode (Real Mode)

.global bootstrap				# Make our function globally available

bootstrap:						# bootstrap function
	mov $stage2msg, %si            
	mov $0x0E, %ah          
.loop:
	lodsb       
	or %al, %al
	jz continue             
	int $0x10           
	jmp .loop    

continue:
	mov $0, %dl
	mov $2, %ah
	mov $1, %al
	mov $0, %ch
	mov $0, %dh
	mov $2, %cl
	mov $0, %dl
	mov $0, %bx
	mov %bx, %es
	mov $0x1000, %bx
	int $0x13
	ljmp $0x0, $0x1000

stage2msg: .asciz "Ferrum: Loading Second Stage..."

.fill 510-(.-bootstrap), 1, 0	# Preprocessor directive from GNU as that fills 'x'
								# count of bytes, with a 'y' size that has 'z' value.
								# args: count, size, value

.word 0xaa55					# BIOS 2-byte magic number that enables the proper
								# booting of this bootloader
