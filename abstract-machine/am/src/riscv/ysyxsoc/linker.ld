ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }

MEMORY {
  mrom : ORIGIN = 0x20000000, LENGTH = 1M
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
  . = ORIGIN(mrom);
  .text : {
	*(entry)
	*(.text*)
  } >mrom AT>mrom : text
  .rodata : {
    *(.rodata*)
	*(.srodata*)
	. = ALIGN(4);
  } >mrom AT>mrom
  _erodata = .;

  .data : {
	_data = .;
    *(.data)
  } >sram AT>mrom : data
  .bss : {
    _edata = .;
    _bstart = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  	_bend = .;
  } >sram AT>mrom
  _heap_start = ALIGN(4);
  . = _heap_start + _heap_size;
  _stack_top = .;
  . = ORIGIN(sram) + LENGTH(sram) - 16;
  _stack_pointer = .;
  end = .;
  _end = .;
}
