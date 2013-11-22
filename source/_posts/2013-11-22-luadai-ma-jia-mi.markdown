---
layout: post
title: "lua代码加密"
date: 2013-11-22 12:45
comments: true
categories: cocos2dx
---

开发者为了防止代码泄漏，在发布前一般会对脚本进行加密，加密方式有多种，
比如常见的AES, XXTEA .. 等等，在cocos2dx加载加密后的lua文件后，解密之后再
执行.

* * *
加密工具我用c写了一个,代码放在github上了：https://github.com/zhizhen/cocos2dx-lua-crypto.git  
关键代码如下
    FILE *file;
    char* inPath = argv[1];     //源文件路径
    char* outPath = argv[2];    //目标文件路径
    unsigned char* fileData = malloc(FILE_LEN);

    file = fopen(inPath, "rb");
    unsigned long num = fread(fileData, 1, FILE_LEN, file);
    fclose(file);

    unsigned int dataLen = 0;
    unsigned char* data = xxtea_encrypt(fileData, num, (unsigned char*)KEY, 32, &dataLen);

    file = fopen(outPath, "web+");
    fwrite(data, 1, dataLen, file);
    fclose(file);
在sh代码中遍历文件夹，调用c生成的工具对单个文件进行加密
    #!/bin/sh
    EXDIR=`cd $(dirname $0); pwd`
    cd "$EXDIR/$1"
    
    #echo please input source dir:
    #read FROMDIR
    #echo please input output dir:
    #read TODIR
    
    FROMDIR="lua"
    TODIR="out"
    
    rm -rf $TODIR
    cp -r $FROMDIR $TODIR
    
    deepls(){
        for x in $1/*
        do
            y=`basename $x .lua`
            if [ -f $x ]
            then
                $EXDIR/debug/file_encrypto "$EXDIR/$1/$y.lua" "$EXDIR/$2/$y.so"
            fi
            if [ -d $x ]
            then
                deepls "$1/$y" "$2/$y"
            fi
        done
    }
    
    deepls $FROMDIR $TODIR
    
    find $TODIR -name '*.lua' -exec rm {} \;
执行./build.sh 就能将lua文件夹中的lua脚本全部加密后放到out目录下，然后就剩下
怎么在cocos2dx里面修改代码读取加密后的脚本问题了
