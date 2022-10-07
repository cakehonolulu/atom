<p align="center">
<picture>
  <source srcset="https://raw.githubusercontent.com/cakehonolulu/atom/main/resources/logo_light.png"
          media="(prefers-color-scheme: light)">
  <source srcset="https://raw.githubusercontent.com/cakehonolulu/atom/main/resources/logo_dark.png"
          media="(prefers-color-scheme: dark)">
  <img alt="Atom Logo" />
</picture>
  </p>

<h2 align="center">A simple, i386 2-stage bootloader written in C</h2>

## ✨ Features
* MBR support
* FAT16 Read-Only Filesystem Support (Stage 1 and 2)
* EXT2 Read-Only Filesystem Support (Stage 1.5 and 2)
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


## 👷🏼‍♂️ Roadmap


* Documentation
