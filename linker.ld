/* Links boot.o and kernel.o */

/* 
Bootloader will look at this image and start execution at the symbol
at entry point in boot.s
*/
ENTRY(_start)

/*
Tell where various sections of the object files will be put in the final 
kernel image
*/
SECTIONS
{
    /* Begin putting sections at 1 MiB, conventional place for kernels to be loaded */
    . = 1M

    /* 
    Put multiboot header first, so bootloader can recognize file format 
    BLOCK(4K) advances the location counter 4K
    */
    .text BLOCK(4K) : ALIGN(4K)
    {
        *(.multiboot)
        *(.text)
    }

    /* Read-only data */
    .rodata BLOCK(4K) : ALIGN(4K)
    {
        *(.rodata)
    }

    /* Initiailized read-write data */
    .data BLOCK(4K) : ALIGN(4K)
    {
        *(.data)
    }

    /* Uninitiailized read-write data and stack */
    .bss BLOCK(4K) : ALIGN(4K)
    {
        *(COMMON)
        *(.bss)
    }
    
}