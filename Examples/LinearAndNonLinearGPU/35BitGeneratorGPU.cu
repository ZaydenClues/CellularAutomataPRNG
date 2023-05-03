#include<bits/stdc++.h>
#include "CAPRNG.cuh"

using namespace std;

#define timesToCallGenerator 20

int main(){
    cout<<"\n Enter initial seed: ";
    uint32_t seed;
    cin>>seed;
    cout<<"\n Enter number of threads (32,64,128,256,512,1024,2048) : ";
    int n;
    cin>>n;
    map<int,vector<uint32_t>> threadNumbers;

    // Initialize the PRNG with a seed and generator type:
    // 0 = Linear, 1 = Non-Linear
    caprng prng(seed,n,1);

    for(int i = 0; i < timesToCallGenerator; i++){
        vector<uint32_t> num = prng.gen();
        threadNumbers[i] = num;
    }

    ofstream resultFile("resultsGen.txt");

    for (int i = 0; i < n; i++)
    {
        resultFile << "Thread " << i << "\t";
    }
    resultFile << endl;

    for (int i = 0; i < timesToCallGenerator; i++)
    {
        for (int j = 0; j < n; j++)
        {
            resultFile << threadNumbers[i][j] << "\t";
        }
        resultFile << endl;
    }
}