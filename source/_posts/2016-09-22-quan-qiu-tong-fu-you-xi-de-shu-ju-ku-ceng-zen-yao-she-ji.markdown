---
layout: post
title: "全球同服游戏的数据库层怎么设计"
date: 2016-09-22 23:34
comments: true
categories: 
---
* * *
 
##怎么样设计百万DAU的数据层？

老大最近说公司要做一款百万级DAU的产品，考虑服务器端承对数据库的读写压力，需要一个数据库的优化方案。有一同事说准备用mnesia分布式，然后问我们会不会有性能问题，仔细思考了一下，感觉这位同学并没有找准解决方向。

###数据库集群解决什么问题  

>并行数据库系统的目标是充分发挥并行计算机的优势，利用系统中的各个处理机结点并行完成数据库任务，提高数据库系统的整体性能。  

###分布式数据库解决什么问题

>分布式数据库系统主要目的在于实现场地自治和数据的全局透明共享，而不要求利用网络中的各个结点来提高系统处理性能。  

***
mnesia的分布式是提供了一个分布式数据库的解决方案，然而他并不适用于解决百万级用户量数据库读写的性能问题。所以说，那位同学没有找到解决问题的方向。

##简单了解一下mnesia的分布式

* 适用范围：  
  较低负载情况下，需要全局透明的数据，比如全局排行榜之类的数据。
* 优势：  
  erlang原生支持，使用方便，开发速度较快，问题容易排查。
* 问题：  
  mnesia分布式是一个全联通网络，节点间通信成本与节点关系是:  
n(n-1)/2，承载有限。

###实例：  
    -module(db_sync).

    -export([create_schema/0, create_table/0, i/0]).
    -export([add_account/3, del_account/1,
            read_account/1]).

    -record(account, {id = 0, name = "", phone =
            13800000000}).

    create_schema() ->
    net_kernel:connect('two@MacAir'),
    io:format("Self:~w, Connect
            Nodes:~w",[node(),
            nodes()]),
    mnesia:create_schema([node()|nodes()]).

    create_table() ->
        mnesia:create_table(account,
                [{disc_copies, [node()|nodes()]},
                {attributes,
                record_info(fields,
                    account)}]
                ).

    i() ->
    mnesia:system_info().

    add_account(ID, Name, Phone) ->
    mnesia:transaction(fun() ->
            mnesia:write(#account{id
                = ID, name
                = Name,
                phone =
                Phone})
            end).

    del_account(ID) ->
        mnesia:transaction(fun() ->
                mnesia:delete({account,
                    ID})
                end).

    read_account(ID) ->
        mnesia:transaction(fun()
                ->
                mnesia:read({account,
                    ID})
                end).
xterm1中  
    erl -pa ebin -sname two -mnesia dir "two"
xterm2中
    erl -pa
    ebin -sname one -mnesia dir "one"
    db_sync:create_schema().
xterm1,xterm2中分别：
    mnesia:start().
任意节点创建表:
    db_sync:create_table().
one节点插入数据:
    db_sync:add_account(2, "zhizhen", 18588748984).
two节点查找数据:
    db_sync:read_account(2).
这就是mnesia的分布式全联通节点，它已经在底层把数据同步了。比较简单.一旦DAU达到一定量级，全联通节点之间的数据同步，是肯定有性能压力的。mnesia分布式甚至对节点间底层通信带宽要求很高，分布式节点最好处于同一机房内。

##我们还是以mnesia为例，再来了解一下水平切分
  * 适用范围：
    百万级甚至千万级大数据情况通用解决方案
  * 问题：
    单点故障恢复难做
  
###简单的水平切分，hash
未完待续。。。

##参考文章

* [浅谈web网站架构演变过程](http://www.cnblogs.com/xiaoMzjm/p/5223799.html) 

