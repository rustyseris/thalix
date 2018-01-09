ENTRY(_start)

SECTIONS {
    . = 1M;

    .multiboot_header : {
        KEEP(*(.multiboot_header))
    }

    .rodata : {
        *(.rodata, .rodata.*)
    }

    .data.rel.ro : {
        *(data.rel.ro .data.rel.ro.*)
    }

    .initdata : {
        *(.initdata .initdata.*)
    }

    .text32 : {
        *(.text32 .text32.*)
    }

    .text : {
        *(.text .text.*)
    }
}
