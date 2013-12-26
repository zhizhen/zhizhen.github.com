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
### skynet集群及RPC
云风的博客上这么写着：  
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
说点心得，skynet的集群有点类似erlang的节点这一概念