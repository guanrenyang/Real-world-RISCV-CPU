ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }

SECTIONS {
  /* _sram_start and _mrom_start are defined in LDFLAGS */
  . = _mrom_start;
  .text : {
    *(entry)
    *(.text*)
  } : text
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
  }
  .data : {
    *(.data)
  } : data
  edata = .;
  _data = .;
  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  }
  . = _sram_start;
  _heap_start = ALIGN(0x1000);
  . = _heap_start + 0x1000;
  _stack_top = .;
  . = _stack_top + 0x1000;
  _stack_pointer = .;
  end = .;
  _end = .;
}
