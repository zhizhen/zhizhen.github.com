---
layout: post
title: "php5.3引入的延迟静态绑定"
date: 2013-09-24 12:52
comments: true
categories: php
---

先看这段代码：
    <?php
    abstract class A{
        public static funciton create(){
            return new static();
        }
        public static function createself(){
            return new self();
        }
    }

    class B extends A{

    }

    class C extends A{
    
    }
    var_dump( B::create() );
    var_dump( C::createself() );
    ?>

得到结果如下
    object(B)#1 (0) { } 
    object(A)#1 (0) { } 
原因是self关键词的执行环境是定义self的类，而不是调用它的对象，
static与self的区别就是它的执行环境是调用它的对象。
