# Initium

## Memory Map
```
| 0x00000000 ---------------
|
|		BIOS Reserved Memory Region
|
| 0x00000500 ---------------
|
|		Free Memory -> Stack grows downwards from 0x00007C00
|
| 0x00007C00 ---------------
|
|		Initium: Stage 1 Bootloader (512 bytes)
|
| 0x00007E00 ---------------
|
|		Initium: Stage 2 Bootloader (Variable Size)
|
| 0x00100000 ---------------
|
|		Kernel Binary
|
| 0xffffffff
```