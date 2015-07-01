---
layout: post
title: "How to set_cookie in escript"
date: 2014-05-21 10:10
comments: true
categories: erlang
---
###Question
As you see, I got a problem when I want to write a plugin with escript for nagios. I want to run net_adm:ping(Node) in an escript.  
* * *
<!--more-->
As you know, I need to keep my escript's cookie the same as the remote node. So what I need is to do erlang:set_cookie(node(), mycookie)  

    #!/usr/bin/env escript

    main([Node]) ->
    erlang:set_cookie(node(), mycookie),
    Resp = net_adm:ping(list_to_atom(Node)),
    io:format("~p~n", [Resp]).

The result maybe

    Eshell V5.10.4  (abort with ^G)
    1> erlang:set_cookie(node(), mycookie).
    ** exception error: no function clause matching 
                        erlang:set_cookie(nonode@nohost,mycookie) 
    2> 

Wait a minute, what's nonode@nohost?
    Eshell V5.10.4  (abort with ^G)
    1> erlang:set_cookie(node(), mycookie).
    ** exception error: no function clause matching 
                        erlang:set_cookie(nonode@nohost,mycookie) 
    2> node().
    nonode@nohost
    3> 

So we need to start a erlang node, Oh! the escript didn't start one for us! when I searching in google, found someone who noticed erlang:setnode() , But there's no manual about how the specs we need? Somebody who knows? please contact me, thanks!
* * *
So how could we solve this?  

    Eshell V5.10.4  (abort with ^G)
    1> net_kernel:start(['mynode@127.0.0.1', longnames]).
    {ok,<0.35.0>}
    (mynode@127.0.0.1)2>

You see? we got a node named 'mynode@127.0.0.1', then we can set_cookie 

    Eshell V5.10.4  (abort with ^G)
    1> net_kernel:start(['mynode@127.0.0.1', longnames]).
    {ok,<0.35.0>}
    (mynode@127.0.0.1)2> node().                                           
    'mynode@127.0.0.1'
    (mynode@127.0.0.1)3> erlang:set_cookie(node(), mycookie).
    true
    (mynode@127.0.0.1)4> erlang:get_cookie().
    mycookie
    (mynode@127.0.0.1)5> 

* * * 
So, we can write our escript like this:  

    #!/usr/bin/env escript

    main([Node]) ->
    {ok, _} = net_kernel:start(['mynode@127.0.0.1', longnames]).
    erlang:set_cookie(node(), mycookie),
    Resp = net_adm:ping(list_to_atom(Node)),
    io:format("~p~n", [Resp]).

###Notice
If you want to use this escript in nagios, better to add try catch for all:

    #!/usr/bin/env escript

    main([Node]) ->
    try
        {ok, _} = net_kernel:start(['mynode@127.0.0.1', longnames]).
        erlang:set_cookie(node(), mycookie),
        case net_adm:ping(list_to_atom(Node)) of
        pong -> halt(0);
        pang -> halt(2)
        end
    catch _:Reason
        io:format("~p~n", [Reason]),
        halt(3)
    end.
   
