---
layout: post
title: "cocos2dx shader 描边"
date: 2019-04-11 14:47
comments: true
categories: 
---

 Cocos2d-x 3.x的label使用了freetype字体引擎（[http://www.freetype.org/](http://www.freetype.org/)），可以很轻松的实现描边和阴影效果。所以本篇文章只针对于sprite来实现描边效果。

官方demo中描边shader没有看懂，看效果好像是有点问题，透明的部分变成了黑色。作者也没有怎么解释，直接丢了一个网址出来（[http://www.idevgames.com/forums/thread-3010.html](http://www.idevgames.com/forums/thread-3010.html)），看样子是参考了这个帖子。

后来从网上别人的博客中找到了一遍关于描边shader的文章，这篇文章用的方法跟我想的差不多，优点是很容易理解，缺点是相对于官方demo给的描边shader效率上差了点。原文地址：[http://blog.csdn.net/u011281572/article/details/44999609](http://blog.csdn.net/u011281572/article/details/44999609)。

原文的代码考虑了label的描边，这个对于现在的cocos3.x版本来说有点多余，我就对原文的代码做了些改动，去掉了label描边的那块儿代码，有些逻辑也做了一些改变，使得更容易理解一些。

下面是我改动后的代码：

```
varying vec4 v_fragmentColor; // vertex shader传入，setColor设置的颜色
varying vec2 v_texCoord; // 纹理坐标
uniform float outlineSize; // 描边宽度，以像素为单位
uniform vec3 outlineColor; // 描边颜色
uniform vec2 textureSize; // 纹理大小（宽和高），为了计算周围各点的纹理坐标，必须传入它，因为纹理坐标范围是0~1

// 判断在这个角度上距离为outlineSize那一点是不是透明int getIsStrokeWithAngel(float angel){
int stroke = 0;
float rad = angel * 0.01745329252; // 这个浮点数是 pi / 180，角度转弧度
vec2 unit = 1.0 / textureSize.xy;//单位坐标
vec2 offset = vec2(outlineSize * cos(rad) * unit.x, outlineSize * sin(rad) * unit.y); //偏移量
float a = texture2D(CC_Texture0, v_texCoord + offset).a;
if (a >= 0.5)// 我把alpha值大于0.5都视为不透明，小于0.5都视为透明
{
stroke = 1;
}
return stroke;
}

void main(){
vec4 myC = texture2D(CC_Texture0, v_texCoord); // 正在处理的这个像素点的颜色
if (myC.a >= 0.5) // 不透明，不管，直接返回
{
gl_FragColor = v_fragmentColor * myC;
return;
}
// 这里肯定有朋友会问，一个for循环就搞定啦，怎么这么麻烦！其实我一开始也是用for的，但后来在安卓某些机型（如小米4）会直接崩溃，查找资料发现OpenGL es并不是很支持循环，while和for都不要用
int strokeCount = 0;
strokeCount += getIsStrokeWithAngel(0.0);
strokeCount += getIsStrokeWithAngel(30.0);
strokeCount += getIsStrokeWithAngel(60.0);
strokeCount += getIsStrokeWithAngel(90.0);
strokeCount += getIsStrokeWithAngel(120.0);
strokeCount += getIsStrokeWithAngel(150.0);
strokeCount += getIsStrokeWithAngel(180.0);
strokeCount += getIsStrokeWithAngel(210.0);
strokeCount += getIsStrokeWithAngel(240.0);
strokeCount += getIsStrokeWithAngel(270.0);
strokeCount += getIsStrokeWithAngel(300.0);
strokeCount += getIsStrokeWithAngel(330.0);

if (strokeCount > 0) // 四周围至少有一个点是不透明的，这个点要设成描边颜色
{
myC.rgb = outlineColor;
myC.a = 1.0;
}

gl_FragColor = v_fragmentColor * myC;
}
```

 大致的逻辑是：

先判断当前像素是否透明，如果不透明则直接返回。如果是透明像素，就判断这个点周围12个方向，每个方向距离当前像素距离是outlineSize的像素点是否透明，只要有一个是非透明像素，就把当前像素点设为描边的颜色，并设置成非透明。

效果如下：

![](/images/cocos2dxshader4.jpg)
