ca65 -vvv --cpu 65C02 -l  build/listing.txt -o  build/BIOS-My6502.o BIOS-My6502.s
ld65 -o build/BIOS-My6502.bin -C memmap.cfg build/BIOS-My6502.o
