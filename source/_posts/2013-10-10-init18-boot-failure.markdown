---
layout: post
title: "INIT18 BOOT FAILURE"
date: 2013-10-10 11:40
comments: true
categories: gentoo 
---

## 问题描述
在安装gentoo的时候，一切都安装完，在执行reboot这一步之后，无法正常启动grub

* * * 
## 问题原因
相信你在执行reboot的时候，关机信息中看到了，系统无法umount cdrom

* * *
## 解决办法
改reboot为shutdown -h now，然后手工将安装光驱从virtualbox中删掉，再重新启动gentoo
<!--more-->
