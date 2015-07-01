---
layout: post
title: "erlang-mysql-driver"
date: 2014-12-27 11:41
comments: true
categories: erlang, mysql
---
## 历史
erlang-mysql-driver 是Yariv Sadan 从Yxa这个数据库引擎的ejabberd这个分支里fork出来的一个项目，他(Yariv Sadan)把它做成了一个独立项目，并给他起了一个高大上的名字。之后便挂在Google Code 上。  

在Yariv Sadan去Facebook工作之前，他给加上了高级的prepared statements 和transactions 机制。并且修复了Yxa 版本之前落后的连接池问题。  

在erlang-mysql-driver从ejabberd分支fork出来之后，Yxa跟ejabberd分支都有一些改动并没有合并到erlang-mysql-driver里来，不过很有可能这些也不重要。这些小修改对erlang-mysql-driver是否能达到最终目的来讲并不明显。  

这几个fork发展到现在，似乎最终都在上层接口层变得非常复杂，mysql.erl,开始与mysql_conn.erl 高度耦合在一起。也许这也正是为什么这几个fork从来没有合并过了。

erlang-mysql-driver 一直没被知晓，直到07年十月，写rebar项目的这个家伙Dave Smith,对他做了一些更新，并且放到了github上。现在它已经被很多开发者fork并且活跃在github上。 

从Yariv原项目里面fork出来的许多并行分支里，有一个跟Dave（rebar）fork出来的没有关联，就是Nick Gerakines 的项目，我猜他应该是erlang-mysql-driver 这些forks里面技术最强的。Nick对它进行了大量的代码整理工作，尽管它很少被人知道，被fork也不多。并且到最后，这个项目因为更好的Emysql而终止。

老古董了，呵呵  
有兴趣的可以看看Emysql,在[Eonblast](https://github.com/Eonblast/Emysql)这个分支里，有对这几个驱动的分析

## 模型

这是它的进程模型：  
![](/images/erlang-mysql-driver-model.png "")

call process 是调用数据库进程，mysql_dispatcher是调度进程，mysql_conn 是真正的数据库连接进程，它们是standalone的。  

在mysql_dispatcher进程里进行调度，mysql_dispatcher 进程中，维护了一份连接进程的调度信息，用gb_trees存储。  

mysql_dispatcher只做一个调度，并不真正替call process 工作，所以对于call process的call请求，是noreply的，把请求者Pid分发给mysql_conn，他们得到数据库结果后，分别去reply call process进程。这便是整个erlang-mysql-driver的pool 模型。
