---
layout: post
title: "PlistBuddy修改Xcode工程版本号"
date: 2014-12-20 01:48
comments: true
categories: mac
---

上一篇博客整得那么蛋疼，其实是想修改xcode工程的版本号，也就是plist文件里的这行：

    <key>CFBundleShortVersionString</key>
    <string>1.0</string>

后来发现mac下直接有现成工具可用:

    /usr/libexec/PlistBuddy -c 'Set :CFBundleShortVersionString 1.0.4' Info.plist

<!--more-->
最后准备把这东西用上去的时候，发现之前队友已经加过了，给力。
