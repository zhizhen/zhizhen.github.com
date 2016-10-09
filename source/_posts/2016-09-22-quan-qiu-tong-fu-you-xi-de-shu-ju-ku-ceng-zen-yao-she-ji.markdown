---
layout: post
title: "全球同服游戏的数据库层怎么设计"
date: 2016-09-22 23:34
comments: true
categories: 
---
* * *
 
##我们要做一个牛逼的产品！

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
n(n-1)/2，一旦数据量大，节点多，IO通信压力巨大。

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
这就是mnesia的分布式全联通节点，它已经在底层把数据同步了。在应用层面，就比较简单了。所以说，它解决的，是一个数据节点共享的问题。mnesia分布式甚至对节点间底层通信带宽要求很高，分布式节点最好处于同一机房内。

##那么百万级DAU的数据库怎么设计呢？
  答案是水平分片(sharding) + 垂直分片,我们今天重点讲水平分片。

  * 适用范围：
    百万级甚至千万级大数据情况通用解决方案
    表的查询方式单一简单，最好是有唯一主键查询
    不做联表事务查询
  * 问题：
    如果有事务的话，涉及到分布式事务，是非常复杂的
  
###简单的水平切分，hash
我们一般将大表的唯一键值作为hash的key,比如我们如果准备拆分一张3千万数据的表，做完hash之后，分插入3个分片(sharding)中。
    simple_hash(Item) ->
        case Item rem 3 of
            0 ->
                %insert data into user_table (ip:127.0.0.1)
            1 ->
                %insert data into user_table (ip:127.0.0.2)
            2 ->
                %insert data into user_table (ip:127.0.0.3)
        end.

这时候，随着业务的增长，如果数据涨到5千万了，慢慢地发现3个sharding已经不能满足我们的需求了，这个时候，如果打算再增加两个sharding，我们需要怎么做呢？  
这个时候我们需要根据新的hash规则把数据重新导入到5个sharding中，几乎5千万行数据都要移动一遍。假设mysql美秒钟的插入速度快达2000/s，即使这样的速度，也要让服务暂停8个小时左右。这个时候DBA肯定会跟你急的，因为他需要通宵导数据。  
那有没有一种更好的办法，降低增加分片的成本呢？

###一致性hash
借用David Wheeler一句名言:  
>All problems in computer science can be solved by another level of indirection.  


是的，任何计算机相关的问题，都可以通过增加一层来解决。一致性hash就是实现了这个虚拟层。erlang一个一致性hash的开源实现：[hash_ring](https://github.com/sile/hash_ring)   
有了hash_ring 之后，增加2个sharding就比较简单了，下面部分是伪代码：  

    -module(hash).
    -compile(export_all).

    -define(PRINT(I, P), io:format(I, P)).

    start() ->
        Nodes = hash_ring:list_to_nodes([
                '127.0.0.1', 
                '127.0.0.2',
                '127.0.0.3'
            ]),
        Ring0 = hash_ring:make(Nodes),
        erlang:put(ring, Ring0).

    get_nodes() ->
        Ring = erlang:get(ring),
        hash_ring:get_nodes(Ring).

    add_node(Name) ->
        Ring0 = erlang:get(ring),
        Ring1 = hash_ring:add_node(hash_ring_node:make(Name), Ring0),
        erlang:put(ring, Ring1),
        %%新添加node时，对数据进行移动
        Fun = fun(I) ->
                OldServer = hash_ring:collect_nodes(I, 1, Ring0),
                NewServer = hash_ring:collect_nodes(I, 1, Ring1),
                if OldServer =/= NewServer ->
                        %todo delete data from old server
                        %todo insert data into new server
                        todo;
                    true ->
                        todo
                end
        end,
        lists:foreach(Fun, lists:seq(1, 5000)).

    insert(Item) ->
        Ring0 = erlang:get(ring),
        [Node] = hash_ring:collect_nodes(Item, 1, Ring0),
        ?PRINT("insert ~p into node ~p ~n", [Item, Node]).

    simple_hash(Item) ->
        case Item rem 3 of
            0 -> 
                %insert data into user_table (user table 0 ip:127.0.0.1)
                todo;
            1 -> 
                %insert data into user_table (user table 1 ip:127.0.0.2)
                todo;
            2 ->
                %insert data into user_table (user table 2 ip:127.0.0.3)
                todo
        end.

这样的话，增加2个sharding之后，只需要移动2千万条数据到新的sharding上即可。

##参考文章

* [浅谈web网站架构演变过程](http://www.cnblogs.com/xiaoMzjm/p/5223799.html) 

