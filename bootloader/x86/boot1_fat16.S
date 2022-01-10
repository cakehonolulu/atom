# Thanks to Octocontrabass, Combuster and MichaelPetch for the help @ forum.osdev.org
.global init1

.code16

.section .text

.extern stage2
init1:
	call stage2
