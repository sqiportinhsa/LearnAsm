.PHONY: all

Folders = bubble/obj/ insertion/obj selection/obj testing/obj testing/build qsort/obj/ merge/obj/ LSD/obj

OPT_FLAGS = -O3 -march=native -mtune=native -flto

all: cracker

clean:
	find . -name "*.o" -delete

folders:
	mkdir -p $(Folders)


bench1: testing/obj/benchmark1.o bubble/obj/bubble.o insertion/obj/insertion.o selection/obj/selection.o testing/obj/common.o
	gcc $(OPT_FLAGS) testing/obj/benchmark1.o bubble/obj/bubble.o insertion/obj/insertion.o selection/obj/selection.o testing/obj/common.o -o testing/build/benchmark1

bench2: testing/obj/benchmark2.o qsort/obj/qsort.o testing/obj/common.o
	gcc $(OPT_FLAGS) testing/obj/benchmark2.o qsort/obj/qsort.o testing/obj/common.o -o testing/build/benchmark2
