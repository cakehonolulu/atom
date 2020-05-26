.code32
.section .text
.extern _kmain
.global _start
.type _start, @function
_start:
	call _kmain
	cli
	hlt
