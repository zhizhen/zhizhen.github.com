---
layout: post
title: "linux c（一）hello world"
date: 2013-06-04 12:35
comments: true
categories: c
---

在linux下面，我们使用GNU的gcc编译器来编译C语言程序。关于gcc编译器，请查看：
    man gcc
下面就编写一个hello world吧，新建hello.c 内容如下：
    int main(int argc, char ** argv)
    {
        printf("Hello world ! \n");
    }
要编译这个程序，我们在命令行下执行:
    gcc -o hello hello.c
-o  表示输出可执行文件
-c  表示输出目标代码
-g  表示加入调试信息
gcc编译器就会为我们生成一个名叫hello 的可执行文件
    ./hello
执行就能看到程序输出的hello world 了
