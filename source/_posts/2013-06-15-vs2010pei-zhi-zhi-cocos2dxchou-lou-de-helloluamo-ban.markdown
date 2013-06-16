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
第一步，下载[cocos2dx](www.cocos2d-x.org/projects/cocos2d-x/wiki/Download)，下载后解压，这个放在哪个目录都没关系。  
第二步，安装cocos2dx工程模板，双击解压后目录下的 install-templates-msvc.bat 这个文件，如下图  
![](/images/vs-cocos2d/anzhuangmuban.png "")  
第三步，打开你的vs2010,文件-> 新建项目，这时候你会看到，已安装的模板一栏里有Cocos2d-win32 Application 这个模板，并且有cocos2dx的经典图标在那！  
![](/images/vs-cocos2d/xinjianxiangmu.png)  
这时候，你需要输入名称，然后点确认.  
![](/images/vs-cocos2d/Wizard.png)  
点击下一步  
![Select engile](/images/vs-cocos2d/selectengine.png)  
选择引擎，这里选择audio和lua引擎  
然后就能看到刚刚创建的项目了:  
![init project](/images/vs-cocos2d/initproject.png)  
这时候如果我们点debug按钮，项目是不能运行起来的，因为它缺少一些库  
第四步，运行cocos2dx目录下，也就是之前解压的目录下的build-win32.bat，等运行完后，会在当前目录下生成Debug.win32这个目录
![build cocos2dx](/images/vs-cocos2d/buildcocos2d.png)
然后找到Demo项目下的Debug.win32,如果没有这个目录的话，执行一下Demo项目的Debug就有了（尽管执行报错），但是会生成这个目录:
![](/images/vs-cocos2d/demodebugdir.png)
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
![libs](/images/vs-cocos2d/libs.png)  
第五步，在Demo/Demo目录下创建Libs目录，把cocos2dx目录下的cocos2dx;CocosDenshion;extensions;以及cocos2dx/scripting 目录下的lua 都拷贝到新建的Libs中来。  
![copylibs](/images/vs-cocos2d/copylibs.png)  
第六步，配置包含路径，项目上点右键 -> 属性 -> C/C++ -> 常规-> 附加包含目录 ，删除它原来的那些，将下面这些加入  
![fujiamulu](/images/vs-cocos2d/fujiamulu.png)  
再打开链接器的输入，加入lua51.lib
![lianjieqi](/images/vs-cocos2d/lianjieqi.png)
设置完后点击应用，然后就可以运行了，结果如下，瞧！一个小农场游戏：
![Demo](/images/vs-cocos2d/Demo.png)

当然，还没完，因为我们不仅仅是要运行第一个cocos2dx + lua项目，我们是要改它生成的不美观的目录结构：
![](/images/vs-cocos2d/demo_pic1.png)![](/images/vs-cocos2d/demo_pic2.png)
首先，删掉Demo目录下的proj.win32文件夹，因为里面什么东西都没有！  
然后在项目的资源管理器面板中，在Demo.rc;Demo.ico;Demo.png这三个文件上点击右键-> 移除-> 删除; 
再删除Demo/Demo/proj.win32下的res文件夹.  
将main.h;main.cpp这两个文件移动到Demo/Demo/Classes 文件夹中.退出vs2010.  
将Demo.win32.vcxproj;Demo.win32.vcxproj.filters;Demo.win32.vcxproj.user 三个文件移动到Demo目录下；删除Demo/Demo/proj.win32这个文件夹  
将Demo/Demo下的Classes;Libs;Resources三个文件夹移动到Demo目录下；并删除Demo/Demo这个目录.  
修改完之后，整个项目目录结构是这样子的：
![](/images/vs-cocos2d/final.png)  
然而这时候是无法打开项目的，打开Demo.sln文件编辑,并删掉这一部分：
![](/images/vs-cocos2d/modifysln.png)  
删除Demo.win32.vcxproj.filters这个文件，让我们来重新设置filters过滤器,删除之后打开Demo.sln。移除项目中的所有文件:
然后依次按照我们项目中Classes;Libs;Resources这样的目录重新设置filters,分别用点击右键 -> 添加筛选器;右键 -> 添加现有项， 将我们的文件导入:
![](/images/vs-cocos2d/newfilter.png)  
由于采用的是相对路径，所以附加目录这里得改一下啦：
![](/images/vs-cocos2d/newfujia.png)  
还有这里，我习惯把中间目录跟Debug目录放到一块儿去
![](/images/vs-cocos2d/zhongjianmulu.png)  
这时候改完之后发现跑不动了，因为找不到Resources目录
![](/images/vs-cocos2d/resourcebug.png)  
看到没，在这里设置的
![](/images/vs-cocos2d/resourcefinal.png)  
好了，修改完之后，又能够看到我们的农场游戏了：
![](/images/Demo.png)  
这时候的项目组织方式，已经按照我自己的想法完全改了:
![](/images/vs-cocos2d/final.png)  
按照这些方法，你完全可以以你自己的方式去组织项目结构
