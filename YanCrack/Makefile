CPPFLAGS = -D _DEBUG -ggdb3 -std=c++2a -O0 -Wall -Wextra -Weffc++ -Waggressive-loop-optimizations -Wc++14-compat -Wmissing-declarations -Wcast-align -Wcast-qual -Wchar-subscripts -Wconditionally-supported -Wconversion -Wctor-dtor-privacy -Wempty-body -Wfloat-equal -Wformat-nonliteral -Wformat-security -Wformat-signedness -Wformat=2 -Winline -Wlogical-op -Wnon-virtual-dtor -Wopenmp-simd -Woverloaded-virtual -Wpacked -Wpointer-arith -Winit-self -Wredundant-decls -Wshadow -Wsign-conversion -Wsign-promo -Wstrict-null-sentinel -Wstrict-overflow=2 -Wsuggest-attribute=noreturn -Wsuggest-final-methods -Wsuggest-final-types -Wsuggest-override -Wswitch-default -Wswitch-enum -Wsync-nand -Wundef -Wunreachable-code -Wunused -Wuseless-cast -Wvariadic-macros -Wno-literal-suffix -Wno-missing-field-initializers -Wno-narrowing -Wno-old-style-cast -Wno-varargs -Wstack-protector -fcheck-new -fsized-deallocation -fstack-check -fstack-protector -fstrict-overflow -flto-odr-type-merging -fno-omit-frame-pointer -Wlarger-than=8192 -Wstack-usage=8192 -pie -fPIE -fsanitize=address,bool,bounds,enum,float-cast-overflow,float-divide-by-zero,integer-divide-by-zero,nonnull-attribute,leak,null,object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,undefined,unreachable,vla-bound,vptr -lsfml-graphics -lsfml-window -lsfml-system -lsfml-audio

CRACK = cracker/build/cracker.exe

FOLDERS = cracker/obj cracker/build

.PHONY: all

all: folders $(CRACK)

clean: 
	find . -name "*.o" -delete

folders:
	mkdir -p $(FOLDERS)

graphs_clean:
	find . -name "*.png" -delete
	find . -name "*.dot" -delete

$(CRACK): cracker/obj/cracker.o cracker/obj/reading.o
	g++ cracker/obj/reading.o cracker/obj/cracker.o -o $(CRACK) $(CPPFLAGS)

cracker/obj/cracker.o: cracker/cracker.cpp cracker/file_reading.h
	g++ -c cracker/cracker.cpp  -o cracker/obj/cracker.o $(CPPFLAGS)

cracker/obj/reading.o: cracker/file_reading.cpp cracker/file_reading.h
	g++ -c cracker/file_reading.cpp -o cracker/obj/reading.o $(CPPFLAGS)
