blink180.bin : blink180.z80
	date +'    db ", Built %F %R"' > built180.z80
	z80asm --list=blink180.lst --output=blink180.bin blink180.z80

test180.bin : test180.z80
	date +'    db ", Built %F %R"' > tbuilt180.z80
	z80asm --list=test180.lst --output=test180.bin test180.z80
