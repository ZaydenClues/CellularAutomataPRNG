#include<bits/stdc++.h>

#define numOfBits 35

__global__ void genConfig(int *initialConfig, int *nextConfig, int *tMatrix){
    int row = blockIdx.x * blockDim.x + threadIdx.x;
    if (row < numOfBits) {
        int sum = 0;
        for (int i = 0; i < numOfBits; i++) {
            sum += initialConfig[i] * tMatrix[numOfBits * row + i];
        }
        nextConfig[row] = sum % 2;
    }
    __syncthreads();
}

__host__ __device__ uint32_t temper(uint32_t num) {    
    uint32_t y = num ^ (num >> 11);
    y ^= (y << 7) & 0x9D2C5680;
    y ^= (y << 15) & 0xEFC60000;
    return y ^ (y >> 18);
}

__device__ uint32_t generatorNonLinear(uint32_t &num, char &first3Bits){
    uint32_t q = num;
    uint32_t r = (num << 1);
    uint32_t p = (num >> 1) ^ (first3Bits&0x1 != 0 ? 0x80000000 : 0);
    uint32_t temp = q ^ r;
    char firstq = first3Bits;
    char firstr = ((first3Bits << 1)&0x7) ^ ((q & 0x80000000) != 0 ? 1 : 0);
    char firstp = ((first3Bits >> 1)&0x7);

    first3Bits = firstq ^ firstr;
    first3Bits = (first3Bits ^ first3Bits&0x4) ^ ((firstr&0x4)^0x4);
    first3Bits = ((first3Bits | firstq&0x2)^0x2);
    first3Bits = first3Bits ^ firstp;

    temp = ((temp | q&0x4000000)^0x4000000); //Rule 225 pos
    temp = (temp | ((r&0x40800000))^0x40800000); //Rule 135 pos
    temp = ((temp ^ q&0x10000000) | ((q&0x10000000)^0x10000000)); //Rule 75 pos
    temp = (temp ^ (temp&0x1040)) ^ ((r&0x1040)^0x1040); //Rule 165 pos
    
    temp = temp ^ p;
    temp = (((temp ^ r&0x200000) | (r&0x200000)) ^ (q&0x200000)); //Rule 195 pos
    temp = (temp ^ (r&0x80000100) ^ ((r&0x80000100)^0x80000100)); //Rule 105 pos
    temp = (temp ^ (q&0x280E80A8)); //Rule 90 pos
    temp = ((temp ^ (temp&0x1))) ^ ((p&0x1)^0x1);//35thBit - 5

    num = temp;
    return temp;
}

__device__ uint32_t generatorLinear(uint32_t &num, char &first3Bits){
    char fourthBit = ((num & 0x80000000) != 0) ? 1 : 0;
    first3Bits = first3Bits ^ (((first3Bits << 1) & 0x7) ^ fourthBit) ^ ((first3Bits >> 1) & 0x7) ^ (first3Bits & 0x4);
    num ^= (num << 1) ^ (num >> 1);
    return num;
}

// Main CUDA Kernel to generate random numbers and test maximality
__global__ void generateRNGKernel(uint32_t *config, char *first3Bits, int flag)
{
    int threadIndex = threadIdx.x;
    int blockIndex = blockIdx.x;
    int blockOffset = blockIndex * blockDim.x;
    int threadOffset = threadIndex + blockOffset;
    uint32_t num = config[threadOffset];
    char f3 = first3Bits[threadOffset];

    //printf("Thread %d, Block %d, Offset %d, num %u \n", threadIndex, blockIndex, threadOffset, num);
    if(!flag)
        num = generatorLinear(num,f3);
    else
        num = generatorNonLinear(num,f3);
    
    config[threadOffset] = temper(num);    
    first3Bits[threadOffset] = f3;
    __syncthreads();
}

__global__ void matrixMultiply(int *M1, int *M2, int *M3){
    int row = blockIdx.x * blockDim.x + threadIdx.x;
    int col = blockIdx.y * blockDim.y + threadIdx.y;
    if (row < numOfBits && col < numOfBits) {
        int sum = 0;
        for (int i = 0; i < numOfBits; i++) {
            sum += M1[numOfBits * row + i] * M2[numOfBits * i + col];
        }
        M3[numOfBits * row + col] = sum % 2;
    }
    __syncthreads();
}

__device__ __host__ uint64_t llpow(uint64_t x, uint64_t y)
{
    uint64_t res = 1;
    while (y > 0)
    {
        if (y & 1)
            res *= x;
        y >>= 1;
        x *= x;
    }
    return res;
}

class caprng{
    private:

        //Pre-Calculated T-Matrix values
        int t2048[numOfBits*numOfBits] = {0,0,1,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,1,0,0,1,0,1,0,1,0,0,1,1,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,0,0,0,0,1,1,0,0,1,1,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,1,1,0,0,1,0,0,0,1,1,0,1,0,1,0,0,1,1,0,0,0,0,0,0,0,1,1,0,0,0,1,0,0,1,0,1,0,1,1,1,0,0,1,0,0,0,0,1,0,1,1,1,1,1,0,0,0,0,0,1,0,1,1,0,1,0,0,1,0,0,1,1,0,1,0,1,1,0,0,1,0,0,0,1,0,0,0,1,1,1,0,0,0,1,1,1,1,1,0,0,0,1,0,0,1,0,0,1,0,1,0,1,0,0,0,1,0,0,1,0,1,0,1,0,0,1,0,1,0,1,0,1,1,1,1,1,0,0,1,1,0,0,0,1,1,1,0,1,0,0,0,1,1,1,0,0,0,1,0,0,0,0,0,1,0,1,1,1,1,0,1,0,1,1,0,1,0,0,0,1,0,1,0,1,0,0,0,1,1,1,1,1,0,1,0,1,0,0,1,1,1,1,0,0,1,0,0,0,1,1,1,1,0,0,0,1,1,1,0,0,0,0,0,1,1,0,0,1,0,0,0,1,1,0,1,0,1,0,0,0,0,0,0,0,0,1,0,1,0,0,0,1,1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,1,1,0,1,0,1,0,1,0,0,0,1,0,1,1,1,1,0,0,0,0,1,0,0,0,0,0,0,1,0,1,0,0,1,0,1,1,1,1,1,0,0,0,1,0,1,0,0,0,1,0,0,1,0,1,0,1,0,0,0,0,0,0,0,0,0,1,1,0,1,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,1,1,0,1,0,1,0,1,0,0,0,1,0,1,0,0,0,1,0,0,1,0,1,0,1,0,0,0,0,0,1,0,1,1,0,1,1,1,0,1,0,0,1,1,0,1,0,0,0,1,0,1,1,1,1,0,0,0,0,1,0,0,0,0,1,1,1,0,1,1,0,1,1,1,0,0,1,1,1,0,0,0,0,0,0,0,1,0,1,0,0,0,1,1,0,0,0,0,1,0,1,0,1,1,0,1,1,0,0,0,1,1,1,1,1,1,0,0,0,1,1,0,1,1,0,0,1,0,0,0,0,0,1,1,1,1,1,1,1,1,0,1,0,1,1,1,1,1,0,0,0,1,0,1,0,0,1,1,0,1,1,0,0,1,0,0,1,0,0,1,1,1,1,0,0,1,0,0,0,1,1,1,0,0,1,0,1,0,1,0,0,0,0,1,1,0,0,1,1,1,1,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,0,1,1,0,1,0,1,1,0,1,0,0,1,0,1,1,1,0,0,0,0,0,1,0,1,0,1,0,1,0,0,0,1,0,1,0,0,0,0,0,0,1,0,0,1,1,0,1,0,1,0,1,0,1,0,0,1,0,0,1,1,0,0,0,1,0,1,0,0,0,1,1,1,0,1,1,1,0,1,0,0,0,0,0,0,1,1,1,1,1,1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,1,0,1,0,0,1,1,0,0,1,0,0,1,0,0,1,0,0,0,1,0,1,0,0,0,1,1,1,1,1,0,0,0,1,1,0,0,0,1,1,1,1,0,0,1,0,1,0,0,1,1,1,0,1,0,0,0,1,0,1,0,0,1,0,0,0,0,1,1,1,0,0,0,1,1,1,0,1,1,1,0,0,0,1,1,0,1,0,0,0,0,0,0,0,1,0,0,0,0,1,0,1,1,1,0,1,0,1,0,0,0,1,1,0,0,1,1,1,0,0,1,1,1,1,0,0,0,1,1,0,1,0,1,1,0,0,1,1,0,1,1,0,1,0,1,0,1,1,1,0,1,0,1,0,0,0,1,0,1,1,0,1,1,0,1,1,0,0,1,0,1,0,0,1,1,1,0,0,0,1,0,0,1,0,0,0,1,0,1,0,0,0,1,1,0,0,0,1,1,1,0,1,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,1,1,0,0,1,1,0,1,0,0,0,1,0,0,0,1,0,0,1,1,1,1,0,1,0,0,1,1,0,1,0,1,1,0,0,1,0,1,1,1,0,1,1,1,0,0,0,1,0,1,0,0,0,1,0,0,0,0,0,1,1,0,0,0,1,1,1,0,0,1,1,0,1,0,0,1,0,1,0,1,0,0,0,0,0,0,0,1,0,0,1,1,0,0,1,1,0,1,1,1,1,0,0,1,1,1,1,0,0,0,1,1,0,1,1,1,0,1,0,1,0,1,0,0,1,1,0,1,1,1,1,0,0,0,1,0,0,1,0,0,0,1,0,0,1,0,0,1,0,1,1,0,0,0,0,0,1,0,1,1,1,1,1,1,1,0,1,1,0,0,0,1,1,0,1,1,0,1,1,0,0,0,0,1,0,0,1,1,0,1,1,0,0,0,1,0,0,1,0,0,1,1,1,1,1,1,1,1,0,1,0,};
        int t1024[numOfBits*numOfBits] = {1,0,1,0,1,1,1,1,0,1,1,1,0,1,1,1,1,1,0,1,1,1,0,1,0,0,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,1,1,0,0,1,0,0,0,1,0,0,1,0,1,1,0,0,1,1,0,0,0,0,1,0,1,1,0,0,1,1,1,1,1,0,0,1,1,0,1,0,0,0,1,0,0,0,0,1,0,0,1,0,1,1,0,0,1,1,1,1,1,1,0,0,0,1,0,1,1,0,1,1,0,1,1,0,1,1,1,0,1,1,0,0,1,1,1,0,1,1,1,0,0,0,0,1,1,1,1,0,1,1,0,0,0,1,0,0,0,1,0,1,1,0,0,0,1,0,1,1,0,1,1,0,0,0,0,1,1,0,0,1,0,1,0,0,1,0,1,1,0,0,0,0,1,0,0,0,0,0,0,1,0,1,0,1,0,1,0,1,1,1,0,1,1,0,1,0,1,1,0,0,0,1,0,0,0,0,1,0,1,1,1,0,0,1,0,0,0,1,0,1,0,0,0,0,1,1,1,1,0,0,1,1,1,1,1,1,0,0,0,0,1,0,1,1,0,1,1,1,1,0,0,0,0,1,0,0,0,1,0,1,1,1,1,1,0,1,0,0,1,1,0,0,0,0,1,1,1,0,1,1,1,0,0,0,1,0,0,0,0,0,0,1,1,0,0,1,0,1,0,0,1,1,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,1,0,0,1,0,0,1,0,1,1,0,1,0,0,1,0,0,1,0,1,1,1,1,0,0,1,0,1,1,1,1,0,1,1,1,1,1,0,1,1,1,1,0,1,0,1,1,1,0,0,0,1,0,0,1,0,0,1,1,1,0,1,0,1,1,0,0,1,0,1,0,0,0,1,0,0,1,0,1,1,1,0,0,1,1,1,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,1,1,1,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1,1,0,1,0,1,0,1,1,1,1,1,0,1,0,1,0,0,0,1,0,1,1,1,0,0,1,1,1,0,0,0,1,1,1,1,1,0,1,1,1,0,1,0,1,1,0,0,1,1,1,1,0,1,1,0,1,0,1,1,1,0,0,0,1,0,0,1,0,0,1,0,0,0,1,0,0,1,1,0,0,0,1,1,1,1,0,0,1,1,0,1,1,0,1,0,0,1,0,0,1,0,1,0,0,0,0,0,0,1,0,1,1,0,0,1,1,1,1,1,1,0,1,1,0,0,1,0,1,1,0,1,1,1,0,1,1,1,1,0,1,0,0,1,1,0,0,1,0,1,0,1,1,1,1,1,0,0,1,0,1,0,1,0,0,0,1,0,1,0,1,1,0,0,0,1,1,1,0,0,1,0,0,0,1,1,1,1,1,1,1,1,0,0,0,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,0,0,0,0,0,0,1,1,1,0,0,1,0,0,0,1,0,1,1,1,0,0,0,0,0,1,0,0,1,0,1,0,1,1,0,0,1,1,0,0,0,0,1,0,0,0,0,0,1,0,0,1,0,1,1,0,1,1,0,0,1,0,0,1,0,0,1,1,0,0,1,1,0,1,0,0,0,1,0,0,0,1,1,1,1,0,1,1,0,1,0,1,1,1,1,0,1,1,0,1,0,1,0,0,1,1,0,1,0,1,0,1,1,1,0,1,1,1,0,0,0,1,1,1,0,0,0,1,0,0,1,0,1,1,0,0,0,1,1,0,1,1,0,1,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,1,0,1,1,0,1,1,0,0,0,1,1,1,0,1,1,1,1,0,1,0,1,1,0,0,0,1,0,0,0,0,1,1,1,1,1,0,0,1,1,0,0,0,0,1,1,0,1,0,1,0,1,0,1,1,0,1,1,1,0,1,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,1,1,0,1,1,0,1,1,0,1,0,0,0,0,1,0,0,0,1,0,1,0,0,1,1,1,0,0,0,0,0,1,0,1,0,0,0,1,1,0,0,0,1,1,1,0,1,0,0,1,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,1,0,0,1,1,1,0,0,1,0,0,0,1,0,0,0,1,1,1,0,1,0,0,0,0,1,0,0,0,1,0,1,1,0,1,1,0,1,0,1,1,1,0,0,1,0,1,0,0,1,1,1,0,0,1,0,1,0,0,0,1,0,1,0,1,1,1,0,1,0,1,0,1,1,1,1,0,1,0,1,0,1,0,1,1,0,1,0,0,1,1,1,1,0,1,1,0,0,0,0,1,1,0,1,1,1,0,0,1,1,1,1,0,0,1,0,1,0,0,1,1,1,1,1,0,1,1,1,0,1,1,1,1,0,0,0,0,1,0,1,1,1,0,0,0,1,0,0,1,0,0,0,1,0,0,0,0,0,0,1,0,0,1,0,1,1,0,1,1,0,1,0,0,0,0,1,1,1,1,0,0,0,1,0,0,0,0,0,1,1,1,1,1,0,0,0,0,1,0,0,1,1,1,1,0,0,1,1,0,0,0,1,0,0,1,1,1,0,0,0,0,0,0,0,1,1,0,0,1,1,0,1,1,1,0,1,1,0,0,1,0,1,0,};
        int t512[numOfBits*numOfBits] = {0,0,1,0,0,1,0,1,0,0,0,1,1,0,1,1,1,1,1,1,0,1,0,0,0,0,0,1,1,1,1,0,0,1,0,0,1,1,1,1,0,0,0,1,0,1,0,0,0,0,0,0,0,1,1,0,1,1,0,0,0,1,1,0,0,0,1,1,1,1,1,1,1,0,1,0,0,0,0,0,0,0,1,0,1,1,1,0,0,1,0,0,0,1,0,1,1,1,0,1,0,0,0,1,0,0,1,0,1,1,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,1,1,0,0,0,1,1,1,0,1,1,1,0,1,0,0,1,1,1,1,0,1,1,0,0,1,1,0,1,0,1,1,1,1,0,1,1,1,1,1,0,1,1,0,1,0,0,0,1,1,1,0,0,1,0,1,1,0,0,1,0,0,0,0,1,1,1,0,1,0,0,1,1,0,1,1,0,1,0,0,0,1,1,0,0,0,0,0,0,1,1,1,0,1,1,0,1,0,0,0,1,0,1,0,1,0,1,0,1,1,0,1,1,1,1,1,1,0,0,1,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,1,1,1,0,1,1,1,0,1,1,0,1,1,0,1,0,1,1,0,1,0,1,0,0,1,1,0,0,0,0,1,1,0,0,1,1,1,0,0,1,0,1,1,0,1,1,0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,0,1,0,1,1,1,1,0,0,0,1,1,1,0,1,1,0,0,0,0,1,1,1,1,1,0,1,0,1,1,0,0,0,0,0,1,0,1,0,0,1,1,0,1,1,1,1,0,1,0,1,0,1,0,1,0,0,0,0,0,1,0,0,1,1,0,1,0,0,1,0,1,0,0,0,1,1,0,1,1,1,0,1,0,1,1,0,1,0,1,0,1,1,1,1,1,0,1,0,0,0,0,1,1,0,1,0,0,0,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,1,0,0,0,1,1,0,1,1,1,1,0,1,0,0,0,0,0,1,0,1,0,1,1,1,1,1,0,1,1,0,1,0,0,0,1,0,0,1,1,0,1,1,1,0,0,0,1,0,1,1,0,1,1,0,1,0,0,0,0,0,1,0,1,1,1,1,1,0,0,1,1,1,1,0,1,0,0,1,0,1,1,1,0,1,1,0,1,1,0,0,1,1,1,1,1,1,0,1,0,1,1,0,1,1,1,1,1,1,1,1,0,0,1,0,1,1,1,0,1,1,0,1,0,1,0,0,0,1,1,1,1,0,0,1,1,0,1,1,1,0,0,0,0,1,1,1,1,1,0,0,0,1,0,1,1,0,0,1,0,1,1,0,1,0,0,1,1,0,0,1,1,0,1,1,0,1,1,0,1,0,0,0,0,1,1,0,0,0,1,1,1,0,0,1,1,0,0,0,0,1,1,1,1,0,0,0,1,1,0,0,1,1,0,1,0,1,1,0,1,0,1,1,1,0,1,1,1,0,0,1,0,0,1,1,1,0,0,0,1,1,0,0,0,0,1,1,1,0,0,0,1,1,0,0,1,0,1,1,1,1,0,0,1,0,1,1,1,0,1,0,1,1,0,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,0,0,0,0,0,0,1,0,1,0,0,1,1,0,0,1,0,0,1,1,0,1,0,1,0,1,1,0,0,0,0,0,0,1,1,0,1,1,1,0,1,0,0,0,0,0,1,0,1,0,0,1,0,1,0,1,1,1,0,1,0,1,0,1,1,1,1,1,0,1,0,1,1,0,0,1,0,0,1,0,1,0,1,0,0,0,0,0,1,1,1,0,1,1,0,1,1,0,1,1,1,1,1,1,1,0,1,0,0,1,1,1,1,1,0,1,1,0,0,0,0,1,1,0,1,0,1,0,1,1,1,0,0,0,0,0,0,1,1,0,0,0,0,1,1,1,1,1,1,0,1,1,0,0,0,1,1,1,1,0,1,1,1,0,0,0,0,0,1,1,1,0,0,1,0,0,1,1,1,1,1,0,0,1,0,1,0,1,0,1,1,1,1,1,1,1,0,1,0,1,1,0,1,1,1,0,1,0,0,1,1,0,0,1,1,0,0,0,0,0,0,1,0,1,1,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,1,1,0,0,0,1,0,0,1,1,0,1,0,1,1,1,0,1,1,0,0,1,1,0,1,1,0,0,1,1,1,1,1,0,1,1,1,1,0,1,0,1,1,1,0,0,1,0,0,1,0,0,1,0,1,1,0,0,0,0,0,1,0,1,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,1,0,1,0,1,1,1,1,1,0,1,0,1,0,1,0,0,0,0,1,0,0,1,1,1,1,0,0,1,0,0,1,1,0,0,1,0,0,0,1,0,0,0,1,0,1,0,1,0,1,1,1,0,1,0,1,1,0,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,1,0,0,1,0,1,0,1,0,1,0,1,1,0,0,1,1,1,0,1,0,0,1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,1,0,1,0,1,0,1,0,1,1,0,1,1,0,0,1,0,0,0,0,1,0,0,0,0,1,1,1,};
        int t256[numOfBits*numOfBits] = {1,0,1,0,1,1,0,1,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,1,0,1,1,0,1,0,1,1,0,0,0,1,0,0,1,0,0,1,0,0,0,1,0,1,0,0,0,1,0,1,1,1,1,1,1,0,1,1,0,1,0,0,0,1,1,1,1,1,0,0,1,0,0,1,0,1,0,1,1,0,1,0,1,1,0,1,0,0,0,0,0,1,1,0,1,1,1,0,1,0,0,1,1,1,0,0,1,0,0,0,0,1,1,0,0,1,0,0,0,1,1,0,1,1,1,1,1,1,0,0,1,1,0,0,1,0,0,1,1,1,0,1,1,1,0,0,1,0,0,1,0,1,1,0,1,0,0,1,0,0,0,0,1,1,0,1,0,1,1,1,1,0,0,1,0,0,1,0,1,1,1,1,0,1,1,1,0,1,0,1,0,1,1,0,1,1,0,1,0,0,0,1,1,0,0,0,1,0,0,0,1,1,1,1,1,1,1,0,0,1,1,1,0,0,0,0,1,1,0,0,0,0,1,0,0,0,0,1,0,1,0,0,1,1,1,1,0,0,1,1,1,0,1,0,1,0,0,0,0,1,1,1,0,1,1,1,1,0,1,0,0,0,1,1,0,1,0,0,1,0,1,0,0,1,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1,1,1,0,1,0,1,1,1,0,0,1,0,1,1,1,1,1,1,1,0,0,0,0,0,0,1,0,1,1,1,1,0,1,0,1,0,0,1,0,0,1,1,1,0,0,0,0,0,1,1,1,0,1,1,0,1,1,0,1,1,0,0,1,0,1,0,1,0,1,1,0,0,1,0,1,0,1,1,0,0,1,0,0,1,1,1,1,0,0,0,1,1,0,0,0,0,1,0,1,1,1,0,1,1,0,1,1,0,0,1,1,0,1,0,1,0,1,1,1,1,0,1,0,1,1,0,0,1,1,1,1,0,1,1,1,0,1,1,0,1,0,0,0,1,1,1,1,0,1,0,1,1,0,0,0,1,1,0,1,1,0,0,1,1,1,0,1,0,1,0,1,1,0,1,0,0,1,1,1,0,1,1,0,1,1,1,0,0,1,0,0,0,0,0,0,1,1,0,0,1,1,0,1,1,1,0,0,1,0,0,1,0,1,0,1,0,0,1,1,0,0,0,1,1,1,1,1,0,1,0,1,1,0,0,1,0,1,0,1,1,0,0,0,0,1,1,1,0,1,1,0,0,1,1,0,1,1,0,1,1,0,0,0,1,0,1,1,1,1,1,1,1,1,1,1,1,0,1,1,0,1,1,1,0,0,1,1,1,1,0,0,0,1,0,1,0,1,1,0,0,1,0,1,0,1,0,0,0,0,0,1,0,0,0,1,0,1,1,0,0,0,1,0,1,1,1,0,1,1,0,0,0,0,0,1,0,1,0,1,1,0,1,1,1,0,1,1,1,0,1,1,0,0,1,0,0,0,0,1,0,1,0,0,0,0,0,1,1,1,0,1,0,1,0,1,0,1,1,1,0,1,0,1,0,0,0,0,0,0,1,0,1,0,1,1,0,1,1,1,0,1,0,1,0,1,1,1,1,1,1,0,1,1,1,0,1,1,0,1,1,1,0,0,0,0,0,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,0,1,1,1,0,0,0,0,0,1,1,1,1,0,0,1,0,0,1,1,0,0,1,1,0,0,0,1,1,1,0,1,0,1,0,1,0,0,1,1,1,1,1,1,1,1,0,0,0,0,1,1,1,0,1,0,1,0,1,0,1,1,1,1,0,1,0,1,0,1,1,0,0,0,0,1,0,1,1,1,1,0,1,0,1,0,0,0,1,0,0,0,0,1,0,1,0,0,0,1,0,1,0,1,1,0,1,0,1,0,1,1,0,1,0,0,0,0,0,1,0,1,0,1,0,0,1,1,1,0,1,0,1,0,1,1,0,1,1,0,1,0,0,1,0,0,0,1,1,0,1,0,1,1,0,0,1,0,0,1,1,1,0,0,0,1,0,1,0,1,1,1,1,0,1,0,0,1,0,1,1,0,1,0,0,0,0,1,1,0,1,0,1,0,1,0,1,1,1,1,1,0,0,0,1,1,0,0,1,0,0,1,1,1,0,1,0,1,0,0,1,1,0,0,0,1,1,0,0,1,1,0,1,1,1,1,1,1,1,0,1,0,0,1,0,1,0,1,1,1,0,0,0,1,1,0,0,0,1,1,0,1,0,1,1,0,0,0,0,0,0,1,0,0,1,0,1,1,0,0,1,1,0,1,1,0,0,0,0,1,0,1,1,0,1,1,1,0,1,1,0,0,1,1,1,0,0,0,0,0,1,0,0,0,1,1,0,1,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1,1,0,0,0,1,1,1,0,0,0,0,0,1,1,1,0,1,1,0,0,0,1,0,1,0,1,1,0,0,0,1,1,0,0,0,1,1,1,0,1,1,0,1,0,0,1,1,0,1,1,1,0,0,1,0,0,0,0,1,1,0,0,1,1,1,1,1,1,0,0,1,1,1,0,0,0,1,1,1,1,1,1,1,0,1,1,0,0,1,1,0,1,1,0,0,0,0,1,0,1,0,0,1,1,1,0,1,0,1,1,0,1,0,0,1,1,1,1,1,0,0,1,1,1,0,0,0,1,0,1,0,1,1,1,0,0,0,0,1,1,1,0,};
        int t128[numOfBits*numOfBits] = {1,1,0,1,0,1,0,1,0,1,1,0,0,0,0,0,0,1,1,1,1,0,0,1,1,0,0,1,0,1,0,0,0,1,1,1,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,1,1,1,0,0,1,1,0,0,1,1,0,0,0,1,0,1,0,1,0,0,1,1,1,1,0,1,0,1,0,0,1,0,0,1,0,0,0,0,0,1,0,0,0,1,1,0,0,0,0,0,0,1,0,1,1,1,1,0,0,0,1,0,0,1,0,0,1,1,1,0,1,1,0,1,1,0,0,1,0,0,1,0,0,1,0,0,0,0,0,0,1,0,0,1,1,0,1,0,0,1,0,1,0,1,0,0,1,0,1,0,1,1,0,0,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1,0,1,0,0,0,1,1,0,1,0,1,0,1,1,0,1,0,0,1,1,1,0,1,1,0,0,1,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,1,0,0,0,0,1,0,1,0,1,1,0,1,0,1,0,0,1,0,0,1,0,1,1,0,1,1,0,0,1,0,0,0,0,1,1,0,0,1,1,1,1,1,1,1,1,1,0,1,1,0,0,0,1,1,0,0,0,0,1,0,1,0,0,0,0,1,1,0,0,0,1,1,0,0,0,1,1,1,0,0,0,1,1,0,1,0,0,0,1,1,0,1,0,0,1,1,1,0,1,1,1,1,1,1,0,0,0,0,1,0,0,0,0,0,1,0,0,1,1,0,1,0,0,0,1,0,0,1,0,0,1,0,0,1,0,1,1,0,1,1,1,1,1,1,1,1,1,1,1,0,1,0,1,0,1,1,1,0,1,0,1,0,0,1,0,1,0,1,1,1,0,0,1,0,1,1,1,0,0,0,0,1,0,1,1,0,0,0,1,1,0,1,0,1,0,0,1,0,0,0,1,0,1,1,1,0,0,0,1,1,0,1,0,1,1,0,0,1,0,1,0,0,0,0,0,1,1,0,0,0,0,0,1,1,1,1,0,0,1,0,1,0,0,1,1,1,0,0,0,1,1,0,0,1,1,1,0,0,1,0,0,0,1,1,0,0,0,1,0,1,0,1,0,1,1,0,1,1,0,0,0,0,0,0,0,1,1,0,1,1,1,1,1,1,1,1,0,1,0,0,0,1,1,1,0,1,1,0,0,1,1,1,1,0,1,1,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,1,0,0,1,0,0,0,1,0,0,1,0,1,1,0,1,0,1,1,1,0,0,0,1,1,0,0,1,0,1,0,0,1,1,1,0,1,1,1,0,1,0,0,0,0,1,0,1,1,1,0,0,0,1,1,1,0,1,0,1,1,1,0,1,1,0,1,0,0,0,1,0,1,1,0,1,1,1,0,1,0,0,1,0,0,0,0,0,0,1,0,0,1,1,0,1,0,1,0,0,0,0,0,1,0,1,0,1,0,0,0,0,0,0,1,0,1,1,0,1,0,0,0,0,0,0,1,0,1,1,1,1,0,0,1,0,1,1,1,0,1,1,1,0,0,1,1,1,1,1,0,0,1,0,1,1,0,0,0,1,1,0,1,1,0,0,0,0,1,0,0,1,1,0,0,1,1,0,1,1,1,0,1,0,1,1,0,1,0,0,1,1,0,1,0,1,1,1,0,0,1,1,1,0,0,1,1,0,0,1,0,1,0,1,0,0,1,0,1,1,1,0,1,1,0,0,1,0,1,1,0,1,0,0,1,1,0,1,0,1,0,1,0,1,0,1,0,1,0,0,0,1,1,0,1,1,0,1,0,1,0,0,0,0,1,1,1,0,1,1,1,1,0,0,0,1,1,0,0,1,1,0,1,0,0,1,0,0,1,1,0,0,1,1,0,1,1,0,0,1,0,1,0,1,0,1,1,0,0,0,0,1,1,0,1,0,1,0,1,1,0,0,0,1,1,0,1,0,1,1,1,1,1,1,0,1,0,0,1,1,0,0,1,0,0,0,1,1,0,1,1,1,0,1,1,0,0,1,0,1,0,0,1,0,0,1,1,1,0,1,0,0,1,0,0,0,0,0,1,0,1,1,0,0,0,0,1,1,0,0,1,1,1,1,0,1,0,0,0,0,0,1,1,1,1,0,1,0,0,1,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,1,1,0,1,1,1,1,0,0,0,1,1,0,0,0,0,0,1,0,1,0,0,1,0,0,1,1,1,1,1,1,1,0,0,0,1,0,1,1,0,1,0,1,0,1,1,0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,1,0,0,1,1,0,1,0,1,0,1,0,0,1,0,1,1,0,0,1,0,1,0,0,1,1,0,0,0,1,1,0,0,1,1,0,0,0,1,0,0,0,0,0,1,1,0,0,0,1,1,0,1,0,1,0,1,0,1,1,0,0,1,0,0,0,0,0,1,0,0,0,1,1,0,0,1,0,0,0,0,1,0,0,0,1,1,1,0,0,0,1,0,0,0,0,1,0,1,1,1,0,1,1,0,0,1,0,1,1,1,0,1,0,1,0,0,1,0,0,0,0,0,1,1,1,0,1,1,1,1,0,1,1,0,1,0,0,1,1,1,1,1,0,0,1,1,0,0,0,1,0,1,1,0,1,1,0,1,0,0,1,0,0,1,1,1,0,0,1,1,1,0,1,1,0,0,1,0,1,};
        int t64[numOfBits*numOfBits] = {1,1,1,0,1,0,0,0,0,1,0,1,0,0,1,1,0,0,0,1,1,0,1,1,0,1,0,0,0,1,1,0,1,0,0,1,1,0,0,1,1,0,0,1,1,0,1,1,1,0,1,1,0,1,1,0,0,1,0,0,1,1,0,1,1,0,0,1,1,0,1,0,0,1,0,0,1,1,1,0,0,0,0,1,1,1,0,0,1,1,0,1,0,0,1,0,1,0,0,1,0,1,0,1,1,0,0,1,0,0,0,1,1,0,0,0,1,0,0,0,1,0,1,0,1,0,0,0,1,0,1,1,1,0,0,0,1,1,0,0,1,1,0,0,0,1,0,1,0,0,1,0,1,1,0,0,0,1,1,0,1,1,1,0,1,1,1,0,1,1,1,1,1,0,1,0,1,0,0,1,1,1,0,1,1,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,0,1,0,1,0,0,0,0,1,0,0,1,1,0,1,0,1,0,0,1,0,0,0,1,0,0,1,0,0,1,0,0,0,0,1,1,0,1,1,0,1,1,1,1,0,0,1,1,1,0,1,1,0,0,0,0,1,0,1,0,0,0,0,0,1,1,0,1,0,0,1,1,0,1,0,0,0,0,1,0,1,1,0,0,1,0,0,1,0,1,1,1,0,0,1,0,1,0,1,1,0,0,1,1,0,1,1,1,1,1,1,1,0,1,1,1,0,0,0,1,0,0,0,0,1,0,0,1,0,1,0,1,0,0,0,0,1,0,1,0,0,0,1,0,0,1,1,0,0,0,0,0,0,1,0,1,0,1,1,1,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,1,0,1,1,1,1,0,1,0,1,0,0,1,0,0,1,0,1,0,1,0,0,1,1,0,0,0,0,1,0,1,1,1,0,1,0,1,1,0,0,1,0,0,1,1,0,1,1,0,0,0,0,0,0,1,1,1,0,1,0,1,1,0,1,1,0,1,0,0,0,1,1,0,0,0,1,1,0,1,1,0,0,0,1,0,1,0,1,1,1,1,0,1,0,0,1,0,0,0,1,1,0,0,0,0,0,0,0,0,1,0,1,0,0,1,1,1,0,0,0,0,0,1,0,0,1,1,0,0,1,1,0,0,0,0,1,0,0,0,0,1,1,0,0,1,1,1,1,0,1,0,0,1,1,0,1,1,1,0,0,1,0,0,1,1,0,1,0,0,0,1,1,0,0,1,0,1,1,0,0,1,0,0,0,1,0,0,0,0,0,0,1,1,1,1,1,0,1,1,1,1,0,1,0,1,1,1,1,1,1,1,1,0,1,0,0,0,1,1,1,1,0,1,1,0,0,1,0,1,0,0,0,0,1,0,0,1,1,0,0,0,1,0,0,0,0,1,1,0,0,1,1,0,1,1,0,0,0,0,1,1,0,1,0,0,1,0,0,1,0,0,1,1,1,1,0,1,0,1,1,0,1,0,0,1,1,1,1,0,1,0,0,1,0,1,1,1,0,0,1,1,1,1,0,1,1,1,1,0,1,0,0,0,0,1,0,1,0,0,1,0,0,0,1,1,1,1,1,0,1,0,0,0,1,1,1,0,0,1,0,1,1,1,1,0,1,1,0,0,0,0,0,1,0,0,0,1,0,1,0,0,1,0,0,1,0,1,1,1,0,1,0,0,1,1,0,0,1,1,1,1,0,1,0,1,0,0,0,1,1,1,0,0,1,0,0,0,0,1,1,0,1,0,0,1,0,1,1,1,1,0,0,0,1,0,0,1,1,0,0,1,0,0,1,1,0,0,1,0,1,0,1,1,0,1,0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,1,0,1,0,0,1,1,1,0,0,1,0,1,1,0,0,1,1,1,1,1,0,0,0,0,0,1,0,1,1,1,0,1,0,1,0,1,1,1,0,1,0,1,1,1,0,1,1,1,1,0,0,0,1,0,1,1,0,0,1,0,1,1,0,1,0,0,0,0,0,1,0,0,1,0,1,1,0,0,1,1,1,1,0,1,1,1,0,1,1,0,1,1,1,1,0,0,0,1,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,0,0,1,0,1,0,1,1,0,0,1,1,0,0,1,1,1,1,0,1,0,1,1,0,1,1,0,1,1,1,1,0,1,1,0,1,0,0,1,0,1,0,1,1,0,1,0,0,0,0,1,0,0,0,0,1,1,0,1,0,0,1,1,0,0,1,0,1,1,1,1,1,0,1,1,1,1,1,0,0,0,0,0,0,0,1,0,1,0,0,0,0,1,1,0,0,1,0,0,0,1,0,1,0,1,0,0,0,1,0,0,0,1,0,0,1,0,0,0,1,1,0,1,1,0,1,0,0,1,1,1,1,0,0,1,1,0,0,0,0,0,1,1,1,0,1,0,1,1,1,0,1,0,1,0,1,0,0,0,0,0,1,0,0,0,0,1,1,1,1,1,1,1,0,1,1,0,1,1,0,1,0,1,1,0,1,1,0,1,1,1,1,1,1,0,0,0,1,1,1,0,0,0,0,0,1,1,0,1,0,1,1,0,0,0,1,0,0,0,1,1,0,0,0,1,0,1,0,0,1,0,0,1,0,1,1,1,1,1,0,1,0,1,1,0,0,1,0,1,1,1,1,1,0,1,0,0,0,0,0,1,0,0,0,0,1,1,1,1,0,0,1,1,0,0,0,1,1,1,};
        int t32[numOfBits*numOfBits] = {0,1,1,1,0,1,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0,1,1,1,0,0,0,1,1,1,0,1,0,1,1,0,1,0,0,0,1,0,1,0,1,1,0,1,0,0,1,1,1,0,0,0,1,1,0,1,0,1,1,0,0,0,1,0,0,1,1,1,0,0,0,0,0,0,1,0,0,1,0,1,1,0,0,0,0,1,1,1,0,1,0,0,0,1,0,1,1,1,1,1,1,0,0,1,0,0,1,0,0,0,0,0,0,1,1,0,0,1,1,1,1,0,1,1,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,1,1,0,1,0,1,0,0,0,1,0,0,1,0,0,1,0,1,1,1,0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,1,0,1,1,0,0,1,0,1,1,0,1,1,0,0,0,1,1,0,0,1,0,0,1,0,0,0,1,1,1,1,0,1,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,1,0,0,0,1,0,0,1,1,1,0,0,1,1,1,1,1,0,0,0,0,0,1,1,0,0,0,0,1,1,0,1,0,0,1,1,1,0,0,1,1,1,0,0,1,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,0,1,1,1,0,0,0,1,0,1,1,0,1,1,1,0,0,0,0,0,0,0,0,1,0,0,0,0,1,0,1,0,1,0,0,0,1,0,0,0,0,0,0,0,1,1,1,0,0,0,0,1,0,0,1,0,1,1,0,1,1,0,0,1,1,0,0,0,1,1,1,1,0,1,0,0,0,1,1,1,0,1,0,1,1,1,0,1,1,0,0,0,0,1,0,1,1,0,1,1,0,0,0,0,0,1,0,0,0,1,0,1,1,1,1,1,1,0,1,0,0,1,1,1,0,0,1,0,0,1,0,1,1,1,0,1,0,0,1,0,0,0,0,0,0,0,1,1,0,0,1,0,0,1,0,0,1,1,0,1,1,1,1,0,1,1,0,0,0,1,0,1,1,1,1,1,0,0,0,1,1,0,0,0,0,0,0,1,1,1,1,0,0,1,1,1,0,0,0,1,1,0,1,0,0,1,1,0,0,0,0,1,0,1,1,1,0,1,0,0,1,1,0,1,0,0,0,0,1,1,1,0,1,1,1,0,0,1,0,0,1,0,0,1,1,0,0,0,1,1,0,0,0,1,1,0,1,1,1,0,1,0,1,0,1,1,0,0,0,1,0,1,0,0,1,0,0,1,1,0,1,1,1,1,1,0,0,0,1,1,1,1,0,1,0,0,0,1,1,1,0,1,1,0,1,0,1,0,1,1,0,1,0,0,1,1,1,1,0,1,1,0,1,0,1,0,1,1,0,1,1,1,1,1,1,1,1,1,0,1,0,0,1,1,1,0,1,0,0,0,1,0,1,1,1,0,0,1,1,1,1,1,1,1,0,0,1,0,0,0,0,1,0,0,1,1,0,0,1,0,0,1,1,0,0,0,1,0,0,0,0,1,0,1,0,1,1,0,1,0,0,1,0,1,1,0,0,0,1,1,1,1,1,1,0,1,1,0,1,0,0,1,0,1,1,1,1,1,1,1,0,1,1,0,1,1,0,0,0,0,1,1,1,0,1,0,1,1,0,0,1,0,1,1,1,1,1,0,1,0,0,1,0,0,0,1,0,0,1,1,0,0,0,1,0,0,1,0,1,0,1,0,1,1,1,1,1,1,0,0,1,0,0,1,0,0,1,0,1,0,1,0,0,1,0,0,0,1,0,1,0,0,1,0,1,0,1,0,1,1,0,1,1,0,0,1,0,1,0,1,1,0,0,0,0,1,1,1,0,0,0,1,1,1,1,1,0,0,1,0,1,1,0,1,0,1,0,0,1,1,0,0,0,1,1,1,0,0,1,1,1,0,0,0,0,1,1,1,0,1,0,1,0,0,1,1,0,1,0,1,0,0,0,0,1,0,0,0,1,1,0,1,1,0,1,1,0,1,0,1,0,1,0,1,1,1,1,1,0,0,0,1,1,0,0,0,0,0,0,1,1,0,1,0,0,1,1,1,1,1,1,0,1,0,0,1,1,1,1,1,1,0,0,1,1,0,1,1,0,1,0,0,0,1,0,0,0,0,0,0,1,1,1,1,0,1,0,0,1,0,0,1,0,1,1,1,0,0,1,0,0,0,1,1,1,1,0,1,0,0,1,0,1,0,1,1,0,0,0,1,1,1,0,1,1,0,0,1,1,0,0,1,1,0,0,0,0,1,1,0,0,0,1,0,1,0,0,1,0,0,1,0,1,0,1,1,0,0,1,0,1,0,0,1,0,0,1,1,0,0,0,1,1,1,0,1,1,0,0,1,0,1,0,1,0,0,0,1,0,0,0,0,1,0,1,0,1,0,0,1,1,0,0,1,0,1,0,0,0,0,1,1,0,1,1,0,0,1,0,1,1,1,1,1,1,1,1,1,1,0,1,0,1,0,1,0,0,0,0,0,0,0,1,1,1,1,1,0,1,1,1,0,1,1,0,1,1,0,0,0,0,1,1,0,1,0,1,1,0,0,0,0,0,1,0,1,1,0,0,0,1,0,0,1,1,0,0,0,1,1,0,0,0,1,1,0,0,1,1,0,1,1,0,1,1,0,0,1,0,0,1,1,0,1,0,1,0,1,1,0,0,0,0,0,1,0,1,1,0,0,1,0,1,1,1,0,0,1,1,1,1,1,1,0,1,0,0,1,};

        //tMatrix precalculated numbers
        std::set<int> pre{32,64,128,256,512,1024,2048};

        char f3 = 0;
        uint32_t initialSeed = 0;
        uint32_t n = 1;
        int block_size = 0;
        int thread_size = 0;
        std::vector<uint32_t> randomNumbers;
        int *tMatrix, *d_tMatrix;
        uint32_t *config, *d_config;
        char *first3Bits, *d_first3Bits;
        uint32_t *iterations, *d_iterations;
        int generatorType = 0;

        std::vector<int> rule{5, 225, 150, 105, 135, 90, 75, 90, 225, 150,
        150, 135, 150, 114, 150, 90, 90, 90, 150, 90, 150, 150, 165, 150, 150, 150, 105, 90,
        165, 90, 150, 90, 150, 150, 5};

        std::map<int,std::set<int>> dependency{{0,{}},
                                        {1,{}},
                                        {2,{}},
                                        {3,{}},
                                        {4,{}},
                                        {5,{5,90,165}},
                                        {6,{}},
                                        {7,{225,150,105,135,75,114}},
                                        };
        void createTMatrix(){
            tMatrix = (int*)malloc(sizeof(int) * numOfBits * numOfBits);
            memset(tMatrix, 0, sizeof(int) * numOfBits * numOfBits);
            for(int i = 0; i < numOfBits; i++){
                if(dependency[5].find(rule[i]) != dependency[5].end()){
                    tMatrix[i * numOfBits + i] = 0;
                    if(i != 0){
                        tMatrix[(i * numOfBits + i) - 1] = 1;
                    }
                    if(i != numOfBits - 1){
                        tMatrix[(i * numOfBits + i) + 1] = 1;
                    }
                } else {
                    tMatrix[i * numOfBits + i] = 1;
                    if(i != 0){
                        tMatrix[i * numOfBits + i - 1] = 1;
                    }
                    if(i != numOfBits - 1){
                        tMatrix[i * numOfBits + i + 1] = 1;
                    }
                }
            }
        }

        std::pair<std::vector<uint32_t>,std::vector<char>> preconfig(uint32_t initialSeed, int k){
            std::pair<std::vector<uint32_t>,std::vector<char>> config_vec;
            
            createTMatrix();

            int *M1, *M2, *M3;
            cudaMalloc(&M1, sizeof(int) * numOfBits * numOfBits);
            cudaMalloc(&M2, sizeof(int) * numOfBits * numOfBits);
            cudaMalloc(&M3, sizeof(int) * numOfBits * numOfBits);

            cudaMemcpy(M1, tMatrix, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
            cudaMemcpy(M2, tMatrix, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);

            cudaMalloc(&d_tMatrix, sizeof(int) * numOfBits * numOfBits);
            cudaMemcpy(d_tMatrix, tMatrix, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);

            dim3 block_size(2, 2);
            dim3 num_blocks((numOfBits + block_size.x - 1) / block_size.x, (numOfBits + block_size.y - 1) / block_size.y);

            if(this->pre.find(k) != this->pre.end()){
                if(k == 2048){
                    cudaMemcpy(M1, t2048, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                    cudaMemcpy(M2, t2048, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                    cudaMemcpy(M3, t2048, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                } else if(k == 1024){
                    cudaMemcpy(M1, t1024, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                    cudaMemcpy(M2, t1024, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                    cudaMemcpy(M3, t1024, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                } else if(k == 512){
                    cudaMemcpy(M1, t512, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                    cudaMemcpy(M2, t512, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                    cudaMemcpy(M3, t512, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                } else if(k == 256){
                    cudaMemcpy(M1, t256, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                    cudaMemcpy(M2, t256, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                    cudaMemcpy(M3, t256, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                } else if(k == 128){
                    cudaMemcpy(M1, t128, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                    cudaMemcpy(M2, t128, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                    cudaMemcpy(M3, t128, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                } else if(k == 64){
                    cudaMemcpy(M1, t64, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                    cudaMemcpy(M2, t64, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                    cudaMemcpy(M3, t64, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                } else if(k == 32){
                    cudaMemcpy(M1, t32, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                    cudaMemcpy(M2, t32, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                    cudaMemcpy(M3, t32, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
                }
            } else {
                uint64_t iter;
                // Find the product of the matrix k times
                for (iter = 1; iter < (llpow(2,numOfBits)-1) / k; iter *= 2)
                {
                    if(iter * 2 > (llpow(2,numOfBits)-1) / k){
                        break;
                    }
                    matrixMultiply<<<num_blocks, block_size>>>(M1, M2, M3);
                    cudaDeviceSynchronize();
                    cudaMemcpy(M1, M3, sizeof(int) * numOfBits * numOfBits, cudaMemcpyDeviceToDevice);
                    cudaMemcpy(M2, M3, sizeof(int) * numOfBits * numOfBits, cudaMemcpyDeviceToDevice);
                    //std::cout<<(llpow(2,numOfBits)-1 / k) - iter<<"\r";
                }

                while(iter < (llpow(2,numOfBits)-1) / k){
                    matrixMultiply<<<num_blocks, block_size>>>(M1, d_tMatrix, M3);
                    cudaDeviceSynchronize();
                    cudaMemcpy(M1, M3, sizeof(int) * numOfBits * numOfBits, cudaMemcpyDeviceToDevice);
                    iter++;
                    //std::cout<<((llpow(2,numOfBits)-1) / k) - iter<<"\r";
                }
            }
            int *productMatrix;
            productMatrix = (int *)malloc(sizeof(int) * numOfBits * numOfBits);
            cudaMemcpy(productMatrix, M3, sizeof(int) * numOfBits * numOfBits, cudaMemcpyDeviceToHost);

            int *conf, *d_conf, *d_nextConfig;
            int *initialConfig, *d_initialConfig;

            initialConfig = (int*)malloc(sizeof(int) * numOfBits);

            for(int i = 0; i < numOfBits; i++){
                initialConfig[i] = std::bitset<64>(initialSeed)[numOfBits-1-i];
            }

            conf = (int*)malloc(sizeof(int) * numOfBits * k);
            cudaMalloc(&d_conf, sizeof(uint64_t) * numOfBits * k);
            cudaMalloc(&d_initialConfig, sizeof(int) * numOfBits);
            cudaMalloc(&d_nextConfig, sizeof(int) * numOfBits);
            cudaMemcpy(d_initialConfig, initialConfig, sizeof(int) * numOfBits, cudaMemcpyHostToDevice);
            cudaMemcpy(conf, d_initialConfig, sizeof(int) * numOfBits, cudaMemcpyDeviceToHost);
            cudaMemcpy(M1, productMatrix, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
            cudaMemcpy(M2, productMatrix, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);
            cudaMemcpy(M3, productMatrix, sizeof(int) * numOfBits * numOfBits, cudaMemcpyHostToDevice);

            for(int i = 1; i < k; i++){
                genConfig<<<1, numOfBits>>>(d_initialConfig, d_nextConfig, M1);
                cudaDeviceSynchronize();
                cudaMemcpy(conf + i * numOfBits, d_nextConfig, sizeof(int) * numOfBits, cudaMemcpyDeviceToHost);
                cudaMemcpy(d_initialConfig, d_nextConfig, sizeof(int) * numOfBits, cudaMemcpyDeviceToDevice);
                cudaDeviceSynchronize();
            }

            cudaDeviceSynchronize();

            for(int i = 0; i < k; i++){
                std::string s = "";
                std::string f = "";

                for(int j = 0; j < numOfBits; j++){
                    if(j < 3 && numOfBits == 35){
                        f += std::to_string(conf[i * numOfBits + j]);
                        continue;
                    }
                    s += std::to_string(conf[i * numOfBits + j]);
                }

                config_vec.first.push_back(stoul(s,nullptr,2));
                if(f != "")
                    config_vec.second.push_back((char)stoul(f,nullptr,2));
                else
                    config_vec.second.push_back(0);
            }

            free(productMatrix);
            free(conf);
            free(initialConfig);
            cudaFree(d_conf);
            cudaFree(d_initialConfig);
            cudaFree(d_nextConfig);
            cudaFree(d_tMatrix);
            cudaFree(M1);
            cudaFree(M2);
            cudaFree(M3);

            return config_vec;
        }

    public:
        caprng(uint32_t seed, uint32_t no, int flag = 0){
            if(seed != 0){
                this->initialSeed = seed;
            }
            this->generatorType = flag;
            this->n = no;
            this->block_size = (this->n / 1024);
            this->thread_size = block_size != 0 ? 1024 : this->n;
            if(this->block_size == 0){
                this->block_size = 1;
            }

            this->randomNumbers.resize(this->n,0);
            std::pair<std::vector<uint32_t>,std::vector<char>> config_vec = preconfig(seed,no);

            // Allocate memory for the initial seed
            this->config = (uint32_t*)malloc(sizeof(uint32_t) * this->n);
            cudaMalloc((void**)&d_config, sizeof(uint32_t) * this->n);

            for(int i = 0; i < this->n; i++){
                this->config[i] = config_vec.first[i];
            }

            this->first3Bits = (char*)malloc(sizeof(char) * this->n);
            cudaMalloc((void**)&d_first3Bits, sizeof(char) * this->n);

            for(int i = 0; i < this->n; i++){
                this->first3Bits[i] = config_vec.second[i];
            }
            
            cudaMemcpy(this->d_config, this->config, sizeof(uint32_t) * this->n, cudaMemcpyHostToDevice);
            cudaMemcpy(this->d_first3Bits, this->first3Bits, sizeof(char) * this->n, cudaMemcpyHostToDevice);

            // Allocate memory for the iterations
            this->iterations = (uint32_t*)malloc(sizeof(uint32_t) * this->n);
            cudaMalloc((void**)&d_iterations, sizeof(uint32_t) * this->n);
        }

        std::vector<uint32_t> gen(){
            if(randomNumbers[0] == 0){
                for(int i = 0; i < this->n; i++){
                    this->randomNumbers[i] = temper(this->config[i]);
                }
                return this->randomNumbers;
            }
            generateRNGKernel<<<block_size, thread_size>>>(this->d_config, this->d_first3Bits, this->generatorType);
            cudaDeviceSynchronize();
            // if (cudaerr != cudaSuccess)
            //     printf("kernel launch failed with error \"%s\".\n",
            //         cudaGetErrorString(cudaerr));
            // else
            //     printf("kernel launch success.\n");
            cudaMemcpy(this->config, this->d_config, sizeof(uint32_t) * this->n, cudaMemcpyDeviceToHost);
            for(int j = 0; j < this->n; j++){
                this->randomNumbers[j] = this->config[j];
            }
            return this->randomNumbers;            
        }                
};