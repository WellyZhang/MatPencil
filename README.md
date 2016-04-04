# MatPencil

## Introduction

This Matlab function implements the algorithm proposed by Cewu Lu et al in [1], which generates the grayscale and colorful pencil sketches of an image. You're highly encouraged to play with the parameters in the function, as demonstrated in the demo.m.

I'm also grateful for candycat1992's implementation of the algorithm[2], without which it would take me way more time than expected.

To generate the sketches:
```C++
I = MatPencil(img, ks, width, dirNum, gammaS, gammaI, theta, pencil_stroke, sm_kr, group_num, avg_ks);
```

## Requirement
* Image Processing Toolbox

## Parameters

For detailed explanation of the parameters, please refer to the comments in the .m file

## Examples

Original image:

<center>![original](https://github.com/WellyZhang/MatPencil/blob/master/inputs/demo.JPG)</center>

Colorful and grayscale:

<center>![colorful](https://github.com/WellyZhang/MatPencil/blob/master/outputs/demo.jpg) ![grayscale](https://github.com/WellyZhang/MatPencil/blob/master/outputs/demo2.jpg)</center>

## Reference

[1] Cewu Lu, Li Xu, Jiaya Jia. Combining Sketch and Tone for Pencil Drawing Production. In Proceedings of the Symposium on Non-Photorealistic Animation and Rendering. Eurographics Association, 2012: 65-73.

[2] candycat1992. [PencilDrawing](https://github.com/candycat1992/PencilDrawing).
