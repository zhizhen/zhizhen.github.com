---
layout: post
title: "simple introduction of mongodb"
date: 2013-03-12 16:12
comments: true
categories: mongo 
---

suppose you have correctly installed the mongodb, and opened a shell like this:
    zhang@linux:~$ mongo
    MongoDB shell version: 2.0.4
    connecting to: test
    >
first of all, let's show all the dbs:
    zhang@linux:~$ mongo
    MongoDB shell version: 2.0.4
    connecting to: test
    > show dbs
    local   (empty)
    >
then let's use one of it, we can switch between dbs use:
    > show dbs
    local   (empty)
    > use local
    switched to db local
    >
someone may ask, how to create a database then ? yeah, good question !  
In Mysql we can use "create database Name;" to create a database, but, 
MongoDB didn't provides any command to create database, Actually, we don't need to do it !
Look ! we just defined a database by command "use mydatabase", which is not created yet
    > use mydatabase
    switched to db mydatabase
    > show dbs
    local   (empty)
    >
MongoDB create it when we first save value into it
    > db.colcase.save( {testcase:"hello"} )
    > show dbs
    local   (empty)
    mydatabase  0.0625GB
    > show collections
    colcase
    system.indexes
    > db.colcase.find()
    { "_id" : ObjectId("513fe233aac1372ab215f350"), "testcase" : "hello" }
    >
P.S MongoDB created the "colcase" collection and the "mydatabase" database automatically 
when we first save value into it.
