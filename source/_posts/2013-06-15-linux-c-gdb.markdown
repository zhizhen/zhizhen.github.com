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
附上常用命令：
    小结：常用的gdb命令
    backtrace 显示程序中的当前位置和表示如何到达当前位置的栈跟踪（同义词：where）
    breakpoint 在程序中设置一个断点
    cd 改变当前工作目录
    clear 删除刚才停止处的断点
    commands 命中断点时，列出将要执行的命令
    continue 从断点开始继续执行
    delete 删除一个断点或监测点；也可与其他命令一起使用
    display 程序停止时显示变量和表达时
    down 下移栈帧，使得另一个函数成为当前函数
    frame 选择下一条continue命令的帧
    info 显示与该程序有关的各种信息
    jump 在源程序中的另一点开始运行
    kill 异常终止在gdb 控制下运行的程序
    list 列出相应于正在执行的程序的原文件内容
    next 执行下一个源程序行，从而执行其整体中的一个函数
    print 显示变量或表达式的值
    pwd 显示当前工作目录
    pype 显示一个数据结构（如一个结构或C++类）的内容
    quit 退出gdb
    reverse-search 在源文件中反向搜索正规表达式
    run 执行该程序
    search 在源文件中搜索正规表达式
    set variable 给变量赋值
    signal 将一个信号发送到正在运行的进程
    step 执行下一个源程序行，必要时进入下一个函数
    undisplay display命令的反命令，不要显示表达式
    until 结束当前循环
    up 上移栈帧，使另一函数成为当前函数
    watch 在程序中设置一个监测点（即数据断点）
    whatis 显示变量或函数类型 

