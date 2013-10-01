---
layout: post
title: "nginx中的try_files"
date: 2013-10-02 00:32
comments: true
categories: nginx 
---
在nginx的配置项里有try_files这一项，查了一下，是nginx0.6.36后增加的功能，
用于搜索指定目录下的N文件，如果找不到fileN，则调用fallback中指定的位置来
处理请求。利用它可以代替部分复杂的nginx rewrite
语法
    try_files file1 [file2...fileN] fallback
默认值：无
作用域：location
今天碰到一个问题，nginx 中这样写:
    try_files $url $url/ /index.php
然后访问
    localhost/guess/add/playWay/?pwid=3&gpid=1&inajax=1
这个访问被跳转到/index.php 之后，后面的参数
    pwid=3&gpid=1&inajax=1
没有出现在$_GET变量中
于是上网查了try_files 的写法，说是如果要带上参数的话，必须这样写
    try_files $url $url/ /index.php?$args
这样子前面那些参数就被带到了index.php中的$_GET变量里
