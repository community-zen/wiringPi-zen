#!bin/sh

rm -f *.o setup

sleep 1

zen build-obj --c-source WiringPi/wiringPi/wiringPi.c   -I WiringPi/wiringPi --library c -target armv8_5a-linux-gnueabihf
zen build-obj --c-source WiringPi/wiringPi/piHiPri.c   -I WiringPi/wiringPi --library c -target armv8_5a-linux-gnueabihf
zen build-obj --c-source WiringPi/wiringPi/softTone.c   -I WiringPi/wiringPi --library c -target armv8_5a-linux-gnueabihf
zen build-obj --c-source WiringPi/wiringPi/softPwm.c    -I WiringPi/wiringPi --library c -target armv8_5a-linux-gnueabihf
zen build-obj  src/main.zen    -I  WiringPi/wiringPi -target armv8_5a-linux-gnueabihf
zen build-exe --object main.o  --object wiringPi.o --object softPwm.o --object softTone.o --object piHiPri.o --name setup -target armv8_5a-linux-gnueabihf --library c
