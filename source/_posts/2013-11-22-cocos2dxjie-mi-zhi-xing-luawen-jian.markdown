---
layout: post
title: "cocos2dx解密执行lua文件"
date: 2013-11-22 20:54
comments: true
categories: cocos2dx
---

前一篇写了怎么将lua文件加密成，那么接着就该在cocos2dx中修改代码，使之能执行
解密后的lua代码了  

* * *
cocos2dx是这样使用lua引擎的
    // 初始化lua引擎
    CCLuaEngine* pEngine = CCLuaEngine::defaultEngine();
    CCScriptEngineManager::sharedManager()->setScriptEngine(pEngine);
                
    CCLuaStack *pStack = pEngine->getLuaStack();
                            
    pStack->addLuaLoader(cocos2dx_lua_loader);
这里添加了cocos2dx_lua_loader,那么，在cocos2dx_lua_loader里面：
    
    int cocos2dx_lua_loader(lua_State *L)
    {
        std::string filename(luaL_checkstring(L, 1));
        // 这里我们将它改成查找.so后缀的lua文件
        size_t pos = filename.rfind(".so");
        if (pos != std::string::npos)
        {
            filename = filename.substr(0, pos);
        }
        
        pos = filename.find_first_of(".");
        while (pos != std::string::npos)
        {
            filename.replace(pos, 1, "/");
            pos = filename.find_first_of(".");
        }
        //后缀改为.so
        filename.append(".so");
        
        //使用一个tmpBuffer来读取密文
        unsigned long tmpSize = 0;
        unsigned char* tmpBuffer = CCFileUtils::sharedFileUtils()->getFileData(filename.c_str(), "rb", &tmpSize);
        if(!tmpBuffer){ return 1;}

        //解密后再传给codeBuffer执行
        unsigned long codeBufferSize = 0;
        unsigned char* codeBuffer = xxtea_decrypt(tmpBuffer, tmpSize, (unsigned char*)SCRIPT_KEY, sizeof(SCRIPT_KEY), &codeBufferSize);
        
        if (codeBuffer)
        {
            if (luaL_loadbuffer(L, (char*)codeBuffer, codeBufferSize, filename.c_str()) != 0)
            {
                luaL_error(L, "error loading module %s from file %s :\n\t%s",
                    lua_tostring(L, 1), filename.c_str(), lua_tostring(L, -1));
            }
            delete []codeBuffer;
        }
        else
        {
            CCLog("can not get file data of %s", filename.c_str());
        }
        
        return 1;
    }

我们采用的是xxtea加密，所以在这里，调用相反的算法，使用相同的秘钥SCRIPT_KEY 解密。
cocos2dx_lua_loader 这个函数会在当lua文件被required 进来的时候调用，因此就达到了加密和
解密的效果。
enjoying!
