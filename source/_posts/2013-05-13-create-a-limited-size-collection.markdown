---
layout: post
title: "create a limited size collection"
date: 2013-03-14 15:17
comments: true
categories: mongo 
---
we create a collection with limited size 100000:
    > db.createCollection("colcase1", {capped:true, size:100000})
    { "ok" : 1 }
    > show collections
    colcase
    colcase1
    system.indexes
    >
and, we can convert a exist collection to a limited one:
    > db.colcase.isCapped()
    false
    > db.runCommand({"convertToCapped":"colcase",size:100000})
    { "ok" : 1 }
    > db.colcase.isCapped()
    true
    >
Look ! we did it

![123] (/sources/images/qiaofeng.jpg)
