.code16							# 16-Bit Mode (Real Mode)

.global bootstrap				# Make our function globally available

bootstrap:						# bootstrap function
	cli							# Disable interrupts
.hlt:							# .hlt function
	hlt							# Halt the system
	jmp .hlt					# Repeat the function endlessly

.fill 510-(.-bootstrap), 1, 0	# Preprocessor directive from GNU as that fills 'x'
								# count of bytes, with a 'y' size that has 'z' value.
								# args: count, size, value

.word 0xaa55					# BIOS 2-byte magic number that enables the proper
								# booting of this bootloader
