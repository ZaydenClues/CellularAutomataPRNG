# CellularAutomataPRNG

This repository contains the CPU and GPU implementation of a Cellular Automaton based Pseudo-Random Number Generator.

## Pre-requisites:
1) C++11 or above:
  CPU implementation of the PRNG uses the C++11 thread function to support multiplatform threading and parallelization.
2) NVIDIA CUDA Toolkit:
  GPU implementation of the PRNG uses CUDA to support parallel generation of random numbers on GPU.
3) NVIDIA GPU and Drivers:
  NVIDIA GPU and drivers are required to run CUDA based files.
  

## Instructions
1) To use the generator you need to include the header file in your working directory.
2) You have to instantiate the generator with your (initial_seed, generator_type) for CPU and (initial_seed, number_of_threads, generator_type) for GPU.
3) Once instantiated, you can call the gen() using the instantiated object.
4) The gen() will return a vector array of parallel numbers.

CPU implementation of the PRNG currently generates 4 numbers at parallel, while the GPU can produce 32,64,128,256,512,1024,2048 numbers at parallel.

Files in the examples directory shows the usage of this PRNG.
