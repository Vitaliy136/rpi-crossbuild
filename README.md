# Сross compiling arm raspberry pi projects on x86 64 machine
```
in container:
/home/user/qt-raspi/bin/./qmake -project
/home/user/qt-raspi/bin/./qmake test-qt.pro
```
```
make
```
```
aarch64-linux-gnu-gcc --sysroot=/sysroot test.c -ljansson
```
```
aarch64-linux-gnu-g++ --sysroot=/sysroot test2.cpp
```


