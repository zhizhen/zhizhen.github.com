---
layout: post
title: "cocos2dx shader 模糊"
date: 2019-04-11 14:38
comments: true
categories: 
---

 > 模糊效果在游戏中经常会用到，有的为了突出前景会把背景给模糊化，有的是因为一些技能需要模糊效果。模糊是shader中较为简单的一种应用。cocos2dx 3.x给的demo中，就有sprite的模糊的效果。

先说下这个模糊算法的大致思路，我们在片段着色器中可以得到当前像素点的颜色值，要想让这个颜色变得模糊，就要让它与它周围的像素点的颜色稍微接近一点，那么我们就需要拿到这个像素点周围的像素点的颜色值，我们把这些个像素点的值加起来取平均值，就得到了一个区域内的平均颜色。

如果直接使用这个颜色的话，最终的效果会变得很模糊，如果我们只是想稍微模糊一点的话，就要让这个平均值更接近于当前像素点原本的颜色，为此，我们取均值的时候对每个像素点增加了一个权重的定义，当前像素点的权重最高，依次向周围减弱，使得最后得到的均值的颜色更接近于当前像素点原始的颜色。

 看代码：
```
#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

uniform vec2 resolution;//模糊对象的实际分辨率
uniform float blurRadius;//半径
uniform float sampleNum;//间隔的段数

vec4 blur(vec2);

void main(void){
vec4 col = blur(v_texCoord); //* v_fragmentColor.rgb;
gl_FragColor = vec4(col) * v_fragmentColor;
}

vec4 blur(vec2 p){
if (blurRadius > 0.0 && sampleNum > 1.0)
{
vec4 col = vec4(0);
vec2 unit = 1.0 / resolution.xy;//单位坐标

float r = blurRadius;
float sampleStep = r / sampleNum;

float count = 0.0;
//遍历一个矩形，当前的坐标为中心点，遍历矩形中每个像素点的颜色
for(float x = -r; x < r; x += sampleStep)
{
for(float y = -r; y < r; y += sampleStep)
{
float weight = (r - abs(x)) * (r - abs(y));//权重，p点的权重最高，向四周依次减少
col += texture2D(CC_Texture0, p + vec2(x * unit.x, y * unit.y)) * weight;
count += weight;
}
}

//得到实际模糊颜色的值

return col / count;
}

return texture2D(CC_Texture0, p);
}
```

 精度限定符和varying变量等的一些基础的知识在前面的博客中遇到的已经说过。

uniform变量是顶点着色器和片段着色器共享使用的变量，uniform的值不能被改变。

uniform变量是由宿主程序设置的，代码如下：

```
 void EffectBlur::setTarget(EffectSprite *sprite)
{
Size size = sprite->getTexture()->getContentSizeInPixels();
_glprogramstate->setUniformVec2("resolution", size);
#if (CC_TARGET_PLATFORM != CC_PLATFORM_WINRT)
_glprogramstate->setUniformFloat("blurRadius", _blurRadius);
_glprogramstate->setUniformFloat("sampleNum", _blurSampleNum);
#endif
}
```

 这里宿主程序设置了resolution，blurRadius和sampleNum三个uniform变量。渲染的时候，顶点着色器和片段着色器都可以用到这三个变量的值。

resolution是当前渲染node的实际分辨率。

blurRadius是像素点模糊处理的参考矩形的半径

sampleNum选择像素点的间隔的数量，相邻像素点的间距等于blurRadius / sampleNum

blur函数就是计算该像素点的最终颜色，参数p是当前像素点的坐标，我们以p点为中点以2r为边长得到一个矩形，这个矩形中每隔sampleStep长度的像素点是当前像素点的颜色参考像素。每个像素点会乘以一个weight权重，这个weight越靠近p点值越高，目的是为了让最终的值更接近于p点的像素颜色，然后各个像素点乘以权重后的颜色加起来，得到col，把各个权重也加起来得到count。最终的颜色值就是col/count。

效果图如下：

模糊前后：

![](/images/cocos2dxshader2.jpg)![](/images/cocos2dxshader3.jpg)
