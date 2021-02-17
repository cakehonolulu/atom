# Initium

## Memory Map
```
| 0x00000000 ---------------
|
|		BIOS Reserved Memory Region
|
| 0x00000500 ---------------
|
|		Initium: Stage 1 Bootloader (512 bytes) (Relocated from 0x7C00)
|
| 0x00000700 ---------------
|
|		Initium: Stage 1 Stack
|
| 0x00000900 ---------------
|
|		Initium: Memory Map and free space
|
| 0x00001000 ---------------
|
|		Initium: Stage 2 Bootloader (Variable Size)
|		
| 0x00002000 ---------------
|	
|		Initium: Stage 2 (Unreal Mode) Stack
|		
| 0x00003000 ---------------
|			
|		Initium: Stage 2 (Protected Mode) Stack
|	
| 0x00004000 ---------------
|
|		Buffer for loading the kernel before relocation
|				
| 0x00010000 ---------------
|		
| 		Free space (Roughly 400-500 KiB depending on the kernel size)
|	
| 0x0007FFFF ---------------
|
|		BIOS-related stuff
|	
| 0x000FFFFF ---------------
|
|
| 0x00100000 ---------------
|
|		Relocated Kernel Binary
|
| 0xffffffff
```