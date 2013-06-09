---
layout: post
title: "terminate 中try catch"
date: 2013-06-05 10:29
comments: true
categories: erlang
---
最近遇到一个业务问题，我们的数据库存档用erlang mysql driver，封装mysql driver的时候，如果数据库操作报错，则用throw 抛出异常，在实际应用中，
我发现terminate函数中调用存档，如果数据库报错，没有任何痕迹。这当然不行，首先我觉得是数据库封装有问题！怎么能有throw出来的消息没有catch 呢！鉴于客观原因我不能改那一快，
于是我只好在terminate函数中加上了try catch.于是灵异现象发生了，terminate
函数中catch 不到内部调用throw 出来的异常！
我做了一个实验：
test.erl
    -module(test).

    -behaviour(gen_server).
    %% API
    -export([start_link/0]).

    %% gen_server callbacks
    -export([init/1, handle_call/3, handle_cast/2, handle_info/2,
            terminate/2, code_change/3]).
    -define(SERVER, ?MODULE).
    -export([stop/0]).
    -record(seed, {seed}).
    %%%===================================================================
    %%% API
    %%%===================================================================
    start_link() ->
        gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
    stop() ->
        ?MODULE ! 'EXIT'.
    %%%===================================================================
    %%% gen_server callbacks
    %%%===================================================================
    init([]) ->
        {ok, #seed{}}.

    handle_call(_Request, _From, State) ->
        Reply = ok,
        {reply, Reply, State}.

    handle_cast(_Msg, State) ->
        {noreply, State}.

    handle_info('EXIT', State) ->
        {stop, "stop command", State};

    handle_info(_Info, State) ->
        {noreply, State}.
    
    terminate(Reason, _State) ->
        try error()
        catch
            _:Reason ->
                io:format("test try catch:~p~n", [Reason])
        end.
        ok.
    code_change(_OldVsn, State, _Extra) ->
        {ok, State}.
    
    error() ->
        throw({error, "My error"}).
然后
    zhang@note:~$ erl
    Erlang R16B (erts-5.10.1) [source] [async-threads:10] [hipe] [kernel-poll:false]

    Eshell V5.10.1  (abort with ^G)
    1> c(test).
    {ok,test}
    2> test:start_link().
    {ok,<0.41.0>}
    3> test:stop().

    =ERROR REPORT==== 5-Jun-2013::10:51:19 ===
    ** Generic server test terminating 
    ** Last message in was 'EXIT'
    ** When Server state == {seed,undefined}
    ** Reason for termination == 
    ** "sss"
    ** exception exit: "stop command"
    4>
看出来了吧，io:format的test try catch 消息并没有打印出来，也就是说，没有catch到我throw的这个消息,下面我改改下面这部分代码：
    terminate(Reason, _State) ->
        error(),
        ok.
    code_change(_OldVsn, State, _Extra) ->
        {ok, State}.
    
    error() ->
        try error1()
        catch
            _:Reason ->
                io:format("test try catch:~p~n", [Reason])
        end.

    error1() ->
        throw({error, "My error"}).
然后再重复上面执行，得到的结果是
    zhang@note:~$ erl
    Erlang R16B (erts-5.10.1) [source] [async-threads:10] [hipe] [kernel-poll:false]

    Eshell V5.10.1  (abort with ^G)
    1> c(test).
    {ok,test}
    2> test:start_link().
    {ok,<0.41.0>}
    3> test:stop().
    test try catch:{error,"My Error!"}

    =ERROR REPORT==== 5-Jun-2013::10:55:57 ===
    ** Generic server test terminating 
    ** Last message in was 'EXIT'
    ** When Server state == {seed,undefined}
    ** Reason for termination == 
    ** "stop command"
    ** exception exit: "stop command"
    4>
throw 的异常被catch到了,那么为什么在terminate中写就不可以呢？
下一个测验：
    terminate(Reason, _State) ->
        error(),
        io:format("Hello world ~n", []),
        ok.
    code_change(_OldVsn, State, _Extra) ->
        {ok, State}.

    error() ->
        throw({error, "My error"}).
这次连Hello world 都没有打印出来, 好了，基本上明了了，为了确定我们的实验结果，还是把terminate函数的源码贴上来吧
    terminate(Reason, Name, Msg, Mod, State, Debug) ->
        case catch Mod:terminate(Reason, State) of
            {'EXIT', R} ->
                error_info(R, Name, Msg, State, Debug),
                exit(R);
            _ ->
                case Reason of
                    normal ->
                        exit(normal);
                    shutdown ->
                        exit(shutdown);
                    {shutdown,_}=Shutdown ->
                        exit(Shutdown);
                    _ ->
                        FmtState =
                        case erlang:function_exported(Mod, format_status, 2) of
                            true ->
                                Args = [get(), State],
                                case catch Mod:format_status(terminate, Args) of
                                    {'EXIT', _} -> State;
                                    Else -> Else
                                end;
                             _ ->
                                State
                        end,
                        error_info(Reason, Name, Msg, FmtState, Debug),
                        exit(Reason)
                end 
        end.
重点是catch Mod:terminate 这行，也就是说，一旦我们的terminate函数中throw 了异常，他就直接执行exit(XX)退出进程了，于是没有继续打印Hello World
,这就解释了，为什么terminate执行了一半，就无声无息地退出了。
但是，为什么在terminate 中写try catch 就不能捕获到，而在error子函数中写try catch 就能捕获到，这个又是为什么？
原来是变量重复：
    terminate(Reason, _) ->
    ...
    catch
        _:Reason ->
    ...
无语了，erlang这语法........
