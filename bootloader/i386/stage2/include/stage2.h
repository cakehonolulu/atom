#include <textmode.h>
#include <ata.h>
#include <libc.h>
#include <fat16.h>
#include <mmap.h>

// https://stackoverflow.com/questions/38530981/output-compiler-version-in-a-c-program
#define STRINGIFY(x) #x
#define VER_STRING(major, minor, patch) STRINGIFY(major) "." STRINGIFY(minor) "." STRINGIFY(patch)
