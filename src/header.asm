INCLUDE "src/hardware.inc"

SECTION "Header", ROM0[$0100]

	jp EntryPoint

	ds $150 -@, 0 ; Make room for the header
