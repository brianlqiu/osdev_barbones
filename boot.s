# Kernel entry point that sets up the processor environment
/* 
Constants for multiboot header in accordance to Mutltiboot Standard (interface between
bootloader and OS kernel).
These values allow GRUB (the bootloader) to recognize that the kernel is multiboot compatible.
Done in assembly since there is no stack yet
*/

.set ALIGN, 1<<0 # align loaded modules on page boundaries
.set MEMINFO, 1<<1 # provide memory map 
.set FLAGS, ALIGN | MEMINFO # Mutlboot 'flag' field 
.set MAGIC, 0x1BADB002 # 'magic number' lets bootloader find the header 
.set CHECKSUM, -(MAGIC + FLAGS) # checksum of above, to prove we are multiboot 

/*
Declares a multiboot header that marks the program as a kernel. 
Magic values are documented in the multiboot standard,
bootloader will search for this signature in the first 8 KiB of the kernel file,
aligned at a 32-bit boundary. Signature in its own section so the heaer is forced
to be within the first 8 KiB of the kernel file.
*/

.section .multiboot # defines the multiboot section, attributes following:
.align 4 # aligns this section 4 bytes, or 32 bits 
.long MAGIC 
.long FLAGS
.long CHECKSUM

/*
Multiboot standard doesn't define the value of the stack pointer register,
kernel has to provide a stack. 
This allocates room for a small stack by creating a symbol at bottom, then
allocating 16384 bytes for it, and then creating a symbol at top.
Stack grows downwards (from higher addresses to lower addresses).
The stack is in its own section so it can be marked nobits, which means
kernel file is smaller since it doesn't contain an uninitialized stack.
Stack on x86 must be 16-byte aligned according to System V ABI standard.
Compiler assumes stack is properly aligned and failure to align will result
in undefined behavior.

.bss denots uninitialized read-write data
*/
.section .bss 
.align 16 # aligns the 16-bytes 
stack_bottom: # places the symbol 
.skip 16384 # skips 16 KiB
stack_top: # places symbol

/*
Linker script specifies _start as the entry point to the kernel.
The bootloader will jump to this position once the kernel has been loaded.
Don't need to return, since the bootloader is gone afterwards.

Executable instructions here
*/
.section .text
.global _start # global scope
.type _start, @function # declares variable _start a function 
_start: 
    /*
    Bootloader loads us into 32-bit protected mode on a x86 machine. 
    Interrupts disabled, paging disabled, processor state is as defined in
    multiboot standard. Kernel has full control of CPU. Kernel can only make
    use of hardware features and any code it provides as part of itself.
    No printing, no security, no safeguards, no debugging, etc.
    Has absolute and complete power over the machine.
    */

    /*
    Setting up stack, necessary for C.
    */
    mov $stack_top, %esp # esp is stack pointer, moves stack pointer to stack_top

    /*
    Now initialize processor state before high-level kernel is entered. Processor is
    not fully initialized yet: extended instruction sets and floating point instructions
    are not initialized yet.
    Global descriptior table is loaded here, table containing entries about the
    CPU's memory segments. 
    Paging is loaded here. 
    */

    /*
    Enter high-level kernel. System V ABI (specifications about assembly programming)
    requires stack is 16-byte aligned at the time of call instruction, afterwards
    pushing the return pointer of size 4 bytes. Stack originally 16-byte aligned above, 
    and we've pushed a multiple of 16 bytes to the stack since (0 is a multiple of 16), so
    the alignment is preserved.
    */
    call kernel_main

    /*
    If system has nothing more to do, put the computer in an infinite loop.
    First, disable interrupts with cli, but bootloader already disables it.
    Then, wait for next interrupt to arrive with hlt (halt instruction).
    Currently disabled, so this will lock up the computer.
    Finally, jump to the hlt instruction if it every wakes up due to a 
    non-maskable interrupt occuring or due to system management mode
    */

    cli
    1: hlt
    jmp 1b

/*
Sets size of the _start symbol to current location '.' minus its start.
Useful for debugging.
*/
.size _start, . - _start 