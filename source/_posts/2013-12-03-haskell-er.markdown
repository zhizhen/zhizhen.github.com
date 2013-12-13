---
layout: post
title: "haskell(二)"
date: 2013-12-03 11:50
comments: true
categories: haskell
---

在haskell(一)中学习了haskell的基本语法。在输入ghci之后能够进入haskell终端，
在终端里可以执行运算，写一些简单的函数，接下来要在文件中写代码，并编译，执行  
创建hello.hs文件
    main = putStrLn "Hello world !"
保存之后，编译
    ghc -o hello hello.hs
编译之后执行
    ./hello
便能够看到
    Hello world !
