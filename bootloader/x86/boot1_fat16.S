# Thanks to Octocontrabass, Combuster and MichaelPetch for the help @ forum.osdev.org
.global init1

.code16

.section .text

.extern kmain
init1:
	call kmain
