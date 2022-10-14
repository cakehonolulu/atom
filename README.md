<p align="center">
<picture>
  <source srcset="https://raw.githubusercontent.com/cakehonolulu/atom/main/resources/logo_light.png"
          media="(prefers-color-scheme: light)">
  <source srcset="https://raw.githubusercontent.com/cakehonolulu/atom/main/resources/logo_dark.png"
          media="(prefers-color-scheme: dark)">
  <img alt="Atom Logo" />
</picture>
  </p>

<h2 align="center">An x86 2-stage bootloader written in Assembly and C</h2>

## ✨ Features
* MBR support
* FAT16 Read-Only Filesystem Support
* EXT2 Read-Only Filesystem Support
* Simple ATAPIO 24-bit disk driver
* Built with ❤️ for i386

<p align="center">
  <img src="resources/screenshot.png" alt="Atom" width="750" height="500"/>
</p>


## 🏁 Compilation

```bash
$ git clone https://github.com/cakehonolulu/atom && cd atom/
$ make
```

## 🔧 Dependencies

```
* mtools
* mkfs.fat
* mkfs.ext2
* e2tools
* clang
* gcc
* qemu
* bochs
```

## 🌊 Constraints

* Processor: i386 or higher
* Memory: 1 megabyte or more
* BIOS: INT13 Extensions Support

## 👷🏼‍♂️ Roadmap


* Documentation
