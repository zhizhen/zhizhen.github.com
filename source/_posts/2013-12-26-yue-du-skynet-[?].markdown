---
layout: post
title: "阅读skynet(一)"
date: 2013-12-26 09:57
comments: true
categories: c
---
一直在关注云风大神的skynet，大神已经写了21篇关于skynet设计以及
优化的博客了。  
云风关于skynet的介绍说了，skynet主要还是参照了erlang的
服务器异步编程思想，鉴于做过erlang开发的缘故，我比较能理解他博客里面
关于设计思想方面的说明。  
不过c根基薄弱，加上也比较懒惰，一直没认真读代码，不过skynet主要部分
代码并不多，代码跟设计一样飘逸，是深入学习c的好教材。
<!--more-->

### skynet是什么
请看原作者博客[skynet开源](http://blog.codingnow.com/2012/08/skynet.html)  
*“其实底层框架需要解决的基本问题是，把消息有序的，从一个点传递到另一个点。每个点是一个概念上的服务进程。这个进程可以有名字，也可以由系统分配出唯一名字。本质上，它提供了一个消息队列，所以最早我个人是希望用 zeromq 来开发的。  
现在回想起来，无论是利用 erlang 还是 zeromq ，感觉都过于重量了。”*  
由此可知它是一个服务器端的消息框架，由于引入了lua，用户基于skynet可以创建由lua写的服务，也叫agent，而不同agent之间的通信就类似erlang里面不同进程的通信一样(不懂erlang的童鞋理解起来可能有点费力)。   
***
下面来看关于skynet架构的说明：  
*“这个系统是单进程多线程模型。”*   
*“我用多线程模型来实现它。底层有一个线程消息队列，消息由三部分构成：源地址、目的地址、以及数据块。框架启动固定的多条线程，每条工作线程不断的从消息队列取到消息。根据目的地址获得服务对象。当服务正在工作（被锁住）就把消息放到服务自己的私有队列中。否则调用服务的 callback 函数。当 callback 函数运行完后，检查私有队列，并处理完再解锁。  
线程数应该略大于系统的 CPU 核数，以防止系统饥饿。（只要服务不直接给自己不断发新的消息，就不会有服务被饿死”*  
skynet是单进程多线程模型，可以看skynet/config 这个配置文件里面：  
	
	root = "./"
	thread = 8                                                                      
	logger = nil 
	harbor = 1 
	address = "127.0.0.1:2526"
	master = "127.0.0.1:2013"
	start = "main"
	standalone = "0.0.0.0:2013"
	luaservice = root.."service/?.lua;"..root.."service/?/init.lua"
	cpath = root.."service/?.so"
	protopath = root.."proto"
	redis = root .. "redisconf"
thread = 8 这里给skynet的线程池配置了8个线程，并在skynet_start里面给它们起起来  
***
来看看关于agent的说明：  
*“每个内部服务的实现，放在独立的动态库中。由动态库导出的三个接口 create init release 来创建出服务的实例。init 可以传递字符串参数来初始化实例。比如用 lua 实现的服务（这里叫 snlua ），可以在初始化时传递启动代码的 lua 文件名。”*  
是不是跟erlang的init, terminate 很像？  
*“每个服务都是严格的被动的消息驱动的，以一个统一的 callback 函数的形式交给框架。框架从消息队列里取到消息，调度出接收的服务模块，找到 callback 函数入口，调用它。服务本身在没有被调度时，是不占用任何 CPU 的。框架做两个必要的保证。  
一、一个服务的 callback 函数永远不会被并发。  
二、一个服务向两一个服务发送的消息的次序是严格保证的。  
我用多线程模型来实现它。底层有一个线程消息队列，消息由三部分构成：源地址、目的地址、以及数据块。框架启动固定的多条线程，每条工作线程不断的从消息队列取到消息。根据目的地址获得服务对象。当服务正在工作（被锁住）就把消息放到服务自己的私有队列中。否则调用服务的 callback 函数。当 callback 函数运行完后，检查私有队列，并处理完再解锁。”*  
来看它的启动流程：  
skynet_start函数里，显示group, harbor, handle, mq, module 这些组件的初始化  
然后启动所有服务模块，并根据配置中standalone来判断是否要启动skynet_context  
接着是logger, harbor, snlua这些服务模块的启动  
所有这些启动完毕之后，转入_start 函数开始线程池，进行消息dispatch循环  
亮代码：  

	void 
	skynet_start(struct skynet_config * config) {
    	skynet_group_init();
    	skynet_harbor_init(config->harbor);
    	skynet_handle_init(config->harbor);
    	skynet_mq_init();
    	skynet_module_init(config->module_path);
    	skynet_timer_init();
    	skynet_socket_init();

    	struct skynet_context *ctx;
    	ctx = skynet_context_new("logger", config->logger);
    	if (ctx == NULL) {
        	fprintf(stderr,"launch logger error");
        	exit(1);
    	}   

    	if (config->standalone) {
        	if (_start_master(config->standalone)) {
            	fprintf(stderr, "Init fail : mater");
            	return;
        	}   
    	}   
    	// harbor must be init first
    	if (skynet_harbor_start(config->master , config->local)) {
        	fprintf(stderr, "Init fail : no master");
        	return;
    	}   

    	ctx = skynet_context_new("localcast", NULL);
    	if (ctx == NULL) {
        	fprintf(stderr,"launch local cast error");
        	exit(1);
    	}   
    	ctx = skynet_context_new("snlua", "launcher");
    	if (ctx) {
        	skynet_command(ctx, "REG", ".launcher");
        	ctx = skynet_context_new("snlua", config->start);
    	}   

    	_start(config->thread);
    	skynet_socket_free();                                                       
	}



### skynet集群及RPC
云风的博客[skynet集群及RPC](http://blog.codingnow.com/2012/08/skynet_harbor_rpc.html)上这么写着：  
*“最终，我们希望整个 skynet 系统可以部署到多台物理机上。这样，单进程的 skynet 节点是不够满足需求的。我希望 skynet 单节点是围绕单进程运作的，这样服务间才可以以接近零成本的交换数据。这样，进程和进程间（通常部署到不同的物理机上）通讯就做成一个比较外围的设置就好了。”*  
按照云风说的设计思路，我是这样理解的，服务器分为多个节点，例如网关节点，登陆节点，游戏场景节点等等，节点之间通过rpc通信，而节点内则是单进程多线程（后文统称skynet进程），采用共享内存进行数据交换。  
而进行skynet进程间数据交换的部件就是skynet_harbor，我们来看skynet_harbor.h文件 
	
	#ifndef SKYNET_HARBOR_H                                                          
	#define SKYNET_HARBOR_H

	#include <stdint.h>
	#include <stdlib.h>

	#define GLOBALNAME_LENGTH 16
	#define REMOTE_MAX 256

	// reserve high 8 bits for remote id
	// 可以看到，这里取高8位用来作为机器识别，而低24位用作服务节点id
	#define HANDLE_MASK 0xffffff
	#define HANDLE_REMOTE_SHIFT 24

	// 消息目的skynet节点名，包含一个名字和一个32位无符号的id
	struct remote_name {
    	char name[GLOBALNAME_LENGTH];
    	uint32_t handle;
	};

	struct remote_message {
    	struct remote_name destination;
    	const void * message;
	    size_t sz; 
	};

	// 发送消息，同时带上发送者的id
	void skynet_harbor_send(struct remote_message *rmsg, uint32_t source, int session);
	// 向master节点注册一个skynet进程
	void skynet_harbor_register(struct remote_name *rname);
	// 这个函数用来判断消息是来自本机器还是外部机器
	int skynet_harbor_message_isremote(uint32_t handle);
	// 初始化harbor
	void skynet_harbor_init(int harbor);
	// 启动harbor
	int skynet_harbor_start(const char * master, const char *local);

	#endif
看这段文字：  
*"为了定位方便，我希望整个系统里，所有服务节点都有唯一 id 。那么最简单的方案就是限制有限的机器数量、同时设置中心服务器来协调。我用 32bit 的 id 来标识 skynet 上的服务节点。其中高 8 位是机器标识，低 24 位是同一台机器上的服务节点 id 。我们用简单的判断算法就可以知道一个 id 是远程 id 还是本地 id （只需要比较高 8 位就可以了）。"*  
HANDLE_REMOTE_SHIFT 其实是用来取高8位机器识别码，而HANDLE_MASK则是取低24位skynet节点唯一id长度。我们看一下skynet_harbor_send(skyner_harbor.c 13行) 发消息函数的实现就知道：  
 
	void 
	skynet_harbor_send(struct remote_message *rmsg, uint32_t source, int session) {
    	int type = rmsg->sz >> HANDLE_REMOTE_SHIFT;
    	rmsg->sz &= HANDLE_MASK;
    	assert(type != PTYPE_SYSTEM && type != PTYPE_HARBOR);                                       
    	skynet_context_send(REMOTE, rmsg, sizeof(*rmsg) , source, type , session);
	}
通过将sz向右移24位来取高8位的机器识别码，而通过与0xffffff相与来取低24位的id，在断言这里，有PTYPE_SYSTEM 和PTYPE_HARBOR 两个宏定义在skynet.h中定义着，它们标识着skynet中的消息类型，看skynet.h:
	
	...
	#define PTYPE_TEXT 0
	#define PTYPE_RESPONSE 1
	#define PTYPE_MULTICAST 2
	#define PTYPE_CLIENT 3
	#define PTYPE_SYSTEM 4 // SYSTEM
	#define PTYPE_HARBOR 5 // HARBOR                                                               
	#define PTYPE_SOCKET 6
	// read lualib/skynet.lua lualib/simplemonitor.lua
	#define PTYPE_RESERVED_ERROR 7  
	// read lualib/skynet.lua lualib/mqueue.lua
	#define PTYPE_RESERVED_QUEUE 8
	#define PTYPE_RESERVED_DEBUG 9
	#define PTYPE_RESERVED_LUA 10

	#define PTYPE_TAG_DONTCOPY 0x10000
	#define PTYPE_TAG_ALLOCSESSION 0x20000
	...
再来看 skynet_harbor.c里面skynet_harbor_message_isremote(skynet_harbor.c 36行) 的实现:

	int 
	skynet_harbor_message_isremote(uint32_t handle) {
		int h = (handle & ~HANDLE_MASK);
		return h != HARBOR && h !=0;
	}
挺简单的一个位运算，好了，再看skynet_harbor_register(skynet_harbor.c 21行)：

	void 
	skynet_harbor_register(struct remote_name *rname) {
    	int i;
    	int number = 1;
    	for (i=0;i<GLOBALNAME_LENGTH;i++) {
        	char c = rname->name[i];
        	if (!(c >= '0' && c <='9')) {
           		number = 0;
            	break;
        	}   
    	}   
    	assert(number == 0); 
    	skynet_context_send(REMOTE, rname, sizeof(*rname), 0, PTYPE_SYSTEM , 0); 
	}
看到了，harbor在register的时候向master节点发送的是类型PTYPE_SYSTEM的系统消息，并且source id为0， session 也为0，但是skynet_context_send 函数干了什么呢？  
好了，等我们先看完skynet_harbor_init(skynet_harbor.c 42行) 和skynet_harbor_start(skynet_harbor.c 47行)分别做了什么之后，再来看skynet_context_send 到底干了什么  

	void
	skynet_harbor_init(int harbor) {
    	HARBOR = (unsigned int)harbor << HANDLE_REMOTE_SHIFT;
	}

	int
	skynet_harbor_start(const char * master, const char *local) {
		size_t sz = strlen(master) + strlen(local) + 32; 
		char args[sz];
    	sprintf(args, "%s %s %d",master,local,HARBOR >> HANDLE_REMOTE_SHIFT);
    	struct skynet_context * inst = skynet_context_new("harbor",args);
    	if (inst == NULL) {
        	return 1;
    	}   
    	REMOTE = inst;

    	return 0;
	}  
哦，init函数里设置了HARBOR的值，它在skynet_harbor.c 第10行声明着。  
而start函数设置了REMOTE的值，它在skynet_harbor.c 第9行声明着。  
skynet_context_send(skynet_server.c 第682行)

	void
	skynet_context_send(struct skynet_context * ctx, void * msg, size_t sz, uint32_t 	source, int type, int session) {
    	struct skynet_message smsg;
    	smsg.source = source;
    	smsg.session = session;
    	smsg.data = msg;
    	smsg.sz = sz | type << HANDLE_REMOTE_SHIFT;

    	skynet_mq_push(ctx->queue, &smsg);
	} 
它调用的是skynet_mq_push(skynet_mq.c 182行)，可见harbor使用skynet_mq 来传递消息，而skynet_mq则是skynet里面非常重要的一个组件，它实现了skynet agent之间的消息传递（这个有点类似erlang的cast message）。  
最终harbor的register消息发向了哪里呢？master !
***
#### RPC核心和模块化思想
RPC的实现，就是先创建一个master，然后所有的worker向master注册，而master纪录下所有注册信息，用云风的原话来讲：  
*"master 服务其实就是一个简单的内存 key-value 数据库。数字 key 对应的 value 正是 harbor 的通讯地址。另外，支持了拥有全局名字的服务，也依靠 master 机器同步。比如，你可以从某台 skynet 节点注册一个叫 DATABASE 的服务节点，它只要将 DATABASE 和节点 id 的对应关系通知 master 机器，就可以依靠 master 机器同步给所有注册入网络的 skynet 节点。  
master 做的事情很简单，其实就是回应名字的查询，以及在更新名字后，同步给网络中所有的机器。  
skynet 节点，通过 master ，认识网络中所有其它 skynet 节点。它们相互一一建立单向通讯通道。也就是说，如果一共有 100 个 skynet 节点，在它们启动完毕后，会建立起 1 万条通讯通道。"*  
skynet/config配置文件里面有这么两条配置：
	
	master = "127.0.0.1:2013"
	standalone = "0.0.0.0:2013"  
然后再看：

	skynet_start(struct skynet_config * config) {
	// ...
	if (config->standalone) {
		if (_start_master(config->standalone)) {
			fprintf(stderr, "Init fail : mater");
			return;
		}
	}
	
	// harbor must be init first
	if (skynet_harbor_start(config->master , config->local)) {
		fprintf(stderr, "Init fail : no master");
		return;
	}
	// ...
	}
这里配得standalone = "0.0.0.0:2013" 就表示这个skynet节点在本机开启2013端口作为master使用。  
而如果这个节点不是master，那么这里配的master = "127.0.0.1:2013" 则告诉它master在哪里。  

master纪录所有worker的信息是在skynet_handle文件实现的一个哈希表存储的。当由skynet_harbor发起注册register的时候，它就实现了一个句柄handle到skynet_context的映射。

真正到master的实现，得先了解模块化思想，这里每个服务提供者都做成了一个模块，放在service-src目录下，比如service_master.c,service_harbor.c ...等等。  这里文件名都叫service_XXX 其实就是文章开头所说的agent。在agent中，用户可以用c来实现所有需求，也可以调用lua。这样就用lua实现了类似erlang的gen_server 回调模式。skynet_module 的作用就是模块管理。最终这些模块（agent）都做成了.so文件加载。每个模块都实现了create, init, release 几个函数。  

基本上以上就是skynet的主体流程了。
