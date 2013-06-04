---
layout: post
title: "Linux c（二）Makefile"
date: 2013-06-04 13:03
comments: true
categories: c
---
关于Makefile的介绍，不多说，详情见百度百科：  
[Makefile](http://baike.baidu.com/view/974566.htm)  
下面就来看看Makefile的作用
假如我们的项目有main.c; test1.h; test1.c; test2.h; test2.c 这几个文件如下:  
main.c
    /* main.c */
    #include "test1.h"
    #include "test2.h"

    int main(int argc, char **argv)
    {
        test1_print("hello ");
        test2_print("world !");
    }
test1.h
    /* test1.h */
    #ifndef _TEST_1_H
    #define _TEST_1_H

    void test1_print(char *print_str);
    #endif
test1.c
    /* test1.c */
    #include "test1.h"
    
    void test1_print(char *print_str)
    {
        printf("This is test1 print %s \n", print_str);
    }
test2.h
    /* test2.h */
    #ifndef _TEST_2_H

    void test2_print(char *print_str);
    #endif
test2.c
    /* test2.c */
    #include "test2.h"

    void test2_print(char *print_str)
    {
        printf("This is test2 print %s \n", print_str);
    }
在没有Makefile的情况下，我们这样子编译整个工程生成一个可执行程序main
    gcc -c main.c   # 生成main.o 目标代码
    gcc -c test1.c  # 生成test1.o 目标代码
    gcc -c test2.c  # 生成test2.o 目标代码
    gcc -o main main.o test1.o test2.o  # 生成名为main的可执行文件

    ./main  # 执行就能看到输出结果了
而Makefile就是用来说明这样一种关系的,看看我们怎么样用Makefile来达到同样的效果：
Makefile
    main:main.o test1.o test2.o
    gcc -o main main.o test1.o test2.o

    main.o:main.c test1.h test2.h
    gcc -c main.c

    test1.o:test1.c test1.h
    gcc -c test1.c

    test2.o:test2.c test2.h
    gcc -c test2.c
有了这个Makefile之后，我们只需要在目录下执行
    make
就生成了名为main的可执行文件
    ./main
Makefile有三个非常有用的变量，$@; $^; $< ：
    $@ ：目标文件
    $^ ：所有的依赖文件
    $< ：第一个依赖文件
于是简化后的Makefile变成了
    main:main.o test1.o test2.o
    gcc -o $@ $^

    main.o:main.c test1.h test2.h
    gcc -c $<

    test1.o:test1.c test1.h
    gcc -c $<

    test2.o:test2.c test2.h
    gcc -c $<
经过简化后是简单了一点，不过还不是最简，Makefile有一个缺省规则：
    ..c.o:
    gcc -c $<
这个规则表示所有的.o文件都是依赖与之相应的.c文件的.例如test1.o依赖于test1.c
于是Makefile变成了
    main:main.o test1.o test2.o
    gcc -o $@ $^

    ..c.o:
    gcc -c $<
然后make一下，发现了吧，这就Makefile的作用所在！关于Makefile，更多的可以查看相应文档
