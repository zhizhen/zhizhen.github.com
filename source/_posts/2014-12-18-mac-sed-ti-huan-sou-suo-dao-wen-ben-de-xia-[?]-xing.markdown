---
layout: post
title: "mac sed 替换搜索到文本的下一行"
date: 2014-12-18 22:15
comments: true
categories: Linux
---
mac下用sed通过正则表达式实现文件中文本替换与linux还不一样，今天遇到一个很奇怪的需求，需要替换搜索到文本的下一行...
举个例子，比如有一个test文件,内容是：
    
    version
    1.0.1
    XXX
    version
    1.0.2
    XXX
    version
    1.0.3

<!--more-->
现在我要将所有version的下一行，也就是1.0.1, 1.0.2, 1.0.3全部都替换成我想要的值，比如1.0.4,在linux中，我们这样用
    
    sed -i '/version/{n;s/.*/1.0.4/g;}' test

不过在mac上，则得这样：

    sed -i '' '/version/{n;s/.*/1.0.4/g;}' test

多了个'',这是mac上sed用来存备份文件的，为空则不将修改前的文件备份。  
sed 基本语法：
    
    sed [options] { sed-commands } { input-file }

每次sed从{ input-file }读取一行，然后在这行上执行{ sed-commands }.  
n是sed命令之一，表示多读取一行，并从第二行开始操作，而后面的  

    s/.*/1.0.4/g

就是将这一行内容替换成1.0.4。s/old/new/g 是sed命令，跟vim里一样，表示替换，
而这里的old是一个正则, '.'在正则里表示匹配任意字符，而 ' * ' 在正则里表示重复，
' . * ' 组合起来表示替换这一行。

只要你还是一个程序员，你就永远免不了要跟正则表达式打交道。  
最后，向大家推荐Steve Mansour的这本《正则表达式之道》:

![](/images/regex-rules.png "")

全书只有11页，为数不多的案头必备书籍之一。
