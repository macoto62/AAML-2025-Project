# Report

tags:`AAML`

## Procedure
1. See the structure of wav2letter
    - 10 times conv2D + leaky_relu
    - 2D's matrix convolution: maybe we can use 1. SIMD 2. TPU  to accelerate

## Intro
- First golden test: CONV_2D is mainly bottleneck
![alt text](image.png)
## Method
1. SIMD
2. TPU
3. sparse matrix
4. leaky_relu

## Result
1. SIMD
![alt text](image-1.png)
    - Accuracy: 72.22%
    - Average Latency: 611917.92ms
![alt text](image-2.png)
2. TPU
## prompt(gemini 3)
```
I'm doing the final project of accelerating architecture for machine learning
Please read carefully the link of final project: https://nycu-caslab.github.io/AAML2025/project/final_project.html
I will use CFU-playground to accelerate some operations like conv2D and leakyRelu
and right now How to accelerate the leaky_relu.h by using the cfu_op0 operator to communicate with cfu.v to accelerate in the hardware system
where the model is a quantized version of the Wav2Letter architecture. The default implementation, provided by Arm, is pruned to 50% sparsity and quantized using the TensorFlow Model Optimization Toolkit.
and through the netron to see the structure of wav2letter, the wav2letter mainly have conv2D and leakyRely these two operators
```