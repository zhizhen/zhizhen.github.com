---
layout: post
title: "Linux c (三) gdb"
date: 2013-06-15 16:31
comments: true
categories: c
---
ubuntu上面是默认装了gdb的，输入
    gdb -v
查看gdb的版本信息
    zhang@note:~/test_make$ gdb -v
    GNU gdb (Ubuntu/Linaro 7.4-2012.02-0ubuntu2) 7.4-2012.02
    Copyright (C) 2012 Free Software Foundation, Inc.
    License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
    and "show warranty" for details.
    This GDB was configured as "i686-linux-gnu".
    For bug reporting instructions, please see:
    <http://bugs.launchpad.net/gdb-linaro/>.
上一篇介绍了Makefile，在上一篇的例子里，我们在Makefile中加入-g编译选项，使Makefile文件如下：
    CFLAGS = -g
    main:main.o test1.o test2.o
	    gcc -o $@ $^
    ..c.o:
	    gcc $(CFLAGS) -c $< 
然后先删了老的main* 和*.o文件
    zhang@note:~/test_make$ rm main
    zhang@note:~/test_make$ rm *.o
好了，重新编译
    zhang@note:~/test_make$ make
    cc -g   -c -o main.o main.c
    cc -g   -c -o test1.o test1.c
    cc -g   -c -o test2.o test2.c
    gcc -o main main.o test1.o test2.o
    zhang@note:~/test_make$
编译完后运行gdb
    zhang@note:~/test_make$ gdb ./main
    GNU gdb (Ubuntu/Linaro 7.4-2012.02-0ubuntu2) 7.4-2012.02
    Copyright (C) 2012 Free Software Foundation, Inc.
    License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
    and "show warranty" for details.
    This GDB was configured as "i686-linux-gnu".
    For bug reporting instructions, please see:
    <http://bugs.launchpad.net/gdb-linaro/>...
    Reading symbols from /home/zhang/test_make/main...done.
    (gdb)
输入命令
    (gdb) list
    1   #include "test1.h"
    2   #include "test2.h"
    3   
    4   void main(int argc, char **argv)
    5   {
    6       test1_print("Hello ");
    7       test2_print("World !");
    8   }
    (gdb) 
    Line number 9 out of range; main.c has 8 lines.
    (gdb)
注意，这里我试过，如果Makefile里面的-g参数不写，或者写得不正确，list的时候会报：
    (gdb) list
    No symbol table is loaded.  Use the "file" command.
    (gdb)
如果只想列出2-9行之间的代码
    (gdb) list 2,9
    2   #include "test2.h"
    3   
    4   void main(int argc, char **argv)
    5   {
    6       test1_print("Hello ");
    7       test2_print("World !");
    8   }
如果只想列出某个函数
    (gdb) list test1_print 
    1   #include "stdio.h"
    2   #include "test1.h"
    3   
    4   void test1_print(char *print_str)
    5   {
    6       printf("This is test1 print %s \n", print_str);
    7   }
    (gdb)
为了能够下断点查看变量值，我们改下main函数
    void main(int argc, char **argv)
       {
           char msg1[128] = "Hello ";
           char msg2[128] = "World !";
           test1_print(msg1);
           test2_print(msg2);
       }
然后
    zhang@note:~/test_make$ make        #编译
    cc -g   -c -o main.o main.c
    cc -g   -c -o test1.o test1.c
    cc -g   -c -o test2.o test2.c
    gcc -o main main.o test1.o test2.o
    zhang@note:~/test_make$ gdb ./main
    GNU gdb (Ubuntu/Linaro 7.4-2012.02-0ubuntu2) 7.4-2012.02
    Copyright (C) 2012 Free Software Foundation, Inc.
    License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
    and "show warranty" for details.
    This GDB was configured as "i686-linux-gnu".
    For bug reporting instructions, please see:
    <http://bugs.launchpad.net/gdb-linaro/>...
    Reading symbols from /home/zhang/test_make/main...done.
    (gdb) list                          #列出代码
    1   #include "test1.h"
    2   #include "test2.h"
    3   
    4   void main(int argc, char **argv)
    5   {
    6       char msg1[128] = "Hello ";
    7       char msg2[128] = "World !";
    8       test1_print(msg1);
    9       test2_print(msg2);
    10  }
    (gdb) break 7                       #在第7行的位置下断点
    Breakpoint 1 at 0x804847c: file main.c, line 7.
    (gdb) run main                      #执行调试
    Starting program: /home/zhang/test_make/main main

    Breakpoint 1, main (argc=2, argv=0xbffff2c4) at main.c:7
    7       char msg2[128] = "World !";
    (gdb) print msg1                    #查看断点处变量msg1的值
    $1 = "Hello ", '\000' <repeats 121 times>
    (gdb) continue                      #继续往下执行
    Continuing.
    This is test1 print Hello  
    This is test2 print World ! 
    [Inferior 1 (process 3270) exited normally]
    (gdb)
看吧，这就是用gdb调试一个程序的完整过程，简单吧？:-)

