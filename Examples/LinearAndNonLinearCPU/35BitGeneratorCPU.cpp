#include<bits/stdc++.h>
#include "CAPRNG.h"

using namespace std;

#define timesToCallGenerator 20

int main(){
    cout<<"\n Enter initial seed: ";
    uint32_t seed;
    cin>>seed;
    map<int,vector<uint32_t>> threadNumbers;

    //Initialize the PRNG with a seed
    // 0 = Linear, 1 = Non-Linear
    caprng prng(seed,0);
    for(int i = 0; i < timesToCallGenerator; i++){
        vector<uint32_t> r = prng.gen();
        threadNumbers[i] = r;
    }
    ofstream resultFile("resultsGen.txt");

    for (int i = 0; i < 4; i++)
    {
        resultFile << "Thread " << i << "\t";
    }
    resultFile << endl;

    for (int i = 0; i < timesToCallGenerator; i++)
    {
        for (int j = 0; j < 4; j++)
        {
            resultFile << threadNumbers[i][j] << "\t";
        }
        resultFile << endl;
    }
}