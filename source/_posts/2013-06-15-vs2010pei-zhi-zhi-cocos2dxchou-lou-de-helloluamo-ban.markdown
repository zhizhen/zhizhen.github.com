---
layout: post
title: "cocos2dx之修改vs2010下丑陋的hellolua模板"
date: 2013-06-15 20:06
comments: true
categories: cocos2dx
---
一直想抽时间把cocos2dx入门这自己的经历写一下，终于周末啦！  
首先说明，本人win7用户，IDE是vs2010，编译环境是win32，这篇文章是介绍如何在vs2010中开始你的第一个cocos2dx+lua项目的
前提是你必须安装了vs2010哈！  
第一步，下载cocos2dx,[cocos2dx-download](www.cocos2d-x.org/projects/cocos2d-x/wiki/Download)，下载后解压，这个放在哪个目录都没关系。  
第二步，安装cocos2dx工程模板，双击解压后目录下的 install-templates-msvc.bat 这个文件，如下图  
![](/images/anzhuangmuban.png "")  
第三步，打开你的vs2010,文件-> 新建项目，这时候你会看到，已安装的模板一栏里有Cocos2d-win32 Application 这个模板，并且有cocos2dx的经典图标在那！  
![](/images/xinjianxiangmu.png)  
这时候，你需要输入名称，然后点确认。  
![](/images/Wizard.png)  
点击下一步  
![Select engile](/images/selectengine.png)  
选择引擎，这里选择audio和lua引擎  
然后就能看到刚刚创建的项目了:  
![init project](/images/initproject.png)  
这时候如果我们点debug按钮，项目是不能运行起来的，因为它缺少一些库  
第四步，运行cocos2dx目录下，也就是之前解压的目录下的build-win32.bat，等运行完后，会在当前目录下生成Debug.win32这个目录
![build cocos2dx](/images/buildcocos2d.png)
然后找到Demo项目下的Debug.win32,如果没有这个目录的话，执行一下Demo项目的Debug就有了（尽管执行报错），但是会生成这个目录:
![](/images/demodebugdir.png)
然后我们把cocos2dx/Debug.win32 这个目录下的这些文件拷贝到 Demo/Debug.win32 下
    glew32.lib
    libcocos2d.lib
    libCocosDenshion.lib
    liblua.lib
    lua51.lib
    pthreadVCE2.lib

    glew32.dll
    libcocos2d.dll
    libCocosDenshion.dll
    libtiff.dll
    lua51.dll
    pthreadVCE2.dll
    zlib1.dll
有点多，需要一个一个拷贝过去，如果缺了其中一个的话，会报错  
![libs](/images/libs.png)  
第五步，在Demo/Demo目录下创建Libs目录，把cocos2dx目录下的cocos2dx;CocosDenshion;extensions;以及cocos2dx/scripting 目录下的lua 都拷贝到新建的Libs中来。  
![copylibs](/images/copylibs.png)  
第六步，配置包含路径，项目上点右键 -> 属性 -> C/C++ -> 常规-> 附加包含目录 ，删除它原来的那些，将下面这些加入  
![fujiamulu](/images/fujiamulu.png)  
再打开链接器的输入，加入lua51.lib
![lianjieqi](/images/lianjieqi.png)
设置完后点击应用，然后就可以运行了，结果如下，瞧！一个小农场游戏：
![Demo](/images/Demo.png)
