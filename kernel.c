/*
Driver that:
 - Remembers location of next in VGA text mode buffer
 - Provides primitive for adding a new char

Written in a freestanding environment, which means there is no C stdlib, only
some default headers shipped by GCC like <stdbool.h> for bool, <stddef.h> to get size_t and NULL,
and <stdint.h> to get intx_t and uintx_t. 

Some additional provided headers:
 - <float.h>
 - <iso646.h>
 - <limits.h>
 - <stdarg.h>

Uses VGA text mode buffer (located at 0xB8000) as output device.
No support for scrolling.
*/

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

//Checks at compile time if you're targeting the wrong OS
#if defined(__linux__) 
#error "Not using cross-compiler"
#endif

//Tutorial only works for 32-bit ix86 targets
#if !defined(__i386__)
#error "This tutorial should be compiled w/ ix86-elf compiler"
#endif

//Text mode color constants
enum vga_color {
    VGA_COLOR_BLACK = 0,
    VGA_COLOR_BLUE = 1,
	VGA_COLOR_GREEN = 2,
	VGA_COLOR_CYAN = 3,
	VGA_COLOR_RED = 4,
	VGA_COLOR_MAGENTA = 5,
	VGA_COLOR_BROWN = 6,
	VGA_COLOR_LIGHT_GREY = 7,
	VGA_COLOR_DARK_GREY = 8,
	VGA_COLOR_LIGHT_BLUE = 9,
	VGA_COLOR_LIGHT_GREEN = 10,
	VGA_COLOR_LIGHT_CYAN = 11,
	VGA_COLOR_LIGHT_RED = 12,
	VGA_COLOR_LIGHT_MAGENTA = 13,
	VGA_COLOR_LIGHT_BROWN = 14,
	VGA_COLOR_WHITE = 15,
};

/*
 - uint8_t is an unsigned integer of 1 byte (8 bits) 
 - inline tells compiler to build the function into the code where it's used to improve execution speed
*/
static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg) {
    return fg | bg << 4;
}

static inline uint16_t vga_entry(unsigned char uc, uint8_t color) {
    return (uint16_t)uc | (uint16_t)color << 8;
}

/*
 - sizeof() returns size_t
*/
size_t strlen(const char* str) {
    size_t len = 0;
    while(str[len]) {
        len++;
    }
    return len;
}

static const size_t VGA_WIDTH = 80;
static const size_t VGA_HEIGHT = 25;

size_t terminal_row;
size_t terminal_column;
uint8_t terminal_color;
uint16_t* terminal_buffer;

/*
 - void in arguments means that it takes no arguments
 - different than terminal_initialize(), () means it can take any number of parameters
   of unknown types
*/
void terminal_initialize(void) {
    terminal_row = 0;
    terminal_column = 0;
    terminal_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
    terminal_buffer = (uint16_t*) 0xB8000;
    for(size_t y = 0; y < VGA_HEIGHT; y++) {
        for(size_t x = 0; x < VGA_WIDTH; x++) {
            const size_t index = y * VGA_WIDTH + x;
            terminal_buffer[index] = vga_entry(' ', terminal_color); //Fill whole terminal with the color
        }
    }
}

void terminal_setcolor(uint8_t color) {
    terminal_color = color;
}

void terminal_putentryat(char c, uint8_t color, size_t x, size_t y){
    const size_t index = y * VGA_WIDTH + x;
    terminal_buffer[index] = vga_entry(c, color);
}

void terminal_putchar(c) {
    terminal_putentryat(c, terminal_color, terminal_column, terminal_row);
    //Increments the current column and row, also checks if new position is within bounds
    if(++terminal_column == VGA_WIDTH || c == '\n') { 
        terminal_column = 0;
        if(++terminal_row == VGA_HEIGHT) { 
            terminal_row = 0;
        }
    }
}

void terminal_write(const char* data, size_t size) {
    for(size_t i = 0; i < size; i++) {
        terminal_putchar(data[i]);
    }
}

void terminal_writestring(const char* data) {
    terminal_write(data, strlen(data));
}

void kernel_main(void) {
    terminal_initialize();

    terminal_writestring("Hello, kernel World!\n");
}