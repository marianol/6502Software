if [ ! -d build ]; then
	mkdir build
fi

for i in my6502; do

echo $i
ca65 -D $i msbasic.s -o build/$i.o &&
ld65 -C ../my6502.cfg build/$i.o -o build/$i.bin -Ln build/$i.lbl

done