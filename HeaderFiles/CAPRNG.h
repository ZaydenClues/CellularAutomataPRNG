#include<bits/stdc++.h>
#include<thread>

#define numOfBits 35
const unsigned int nthreads = std::thread::hardware_concurrency();


class caprng{
    private:
        //Precalculated values
        std::vector<int> t4{1,1,1,1,1,0,0,1,1,0,1,0,1,0,1,1,1,1,0,1,0,0,0,1,0,1,0,1,0,1,0,1,0,0,0,1,1,1,1,0,1,1,1,0,0,1,0,1,0,0,0,0,1,0,0,1,0,1,1,0,1,0,0,0,0,0,0,1,0,0,1,1,1,0,1,0,0,1,0,1,1,0,1,1,1,1,0,0,1,0,0,0,0,0,0,1,1,1,0,1,0,0,0,1,0,1,1,0,1,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,1,1,0,1,1,1,0,0,0,0,1,1,0,0,0,1,1,0,1,0,0,0,0,1,1,1,0,0,1,1,1,0,1,1,0,0,1,0,0,0,1,0,1,1,1,1,1,1,0,0,1,0,1,0,0,0,0,1,0,0,0,1,1,1,0,1,0,1,0,1,0,1,1,1,0,1,0,1,1,1,0,1,0,1,1,0,0,1,0,0,0,1,1,0,1,0,0,1,1,1,0,0,1,1,1,0,1,1,1,0,0,0,1,1,0,1,0,1,0,0,0,1,1,1,0,1,0,0,0,0,1,0,0,1,1,0,1,1,1,0,0,0,1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,0,0,0,1,0,1,0,0,1,1,0,1,1,0,1,1,0,0,0,0,1,1,1,1,0,1,0,0,1,1,0,0,1,1,0,0,1,1,1,0,0,1,1,0,1,0,0,0,0,1,1,0,0,0,1,0,0,1,0,1,0,0,0,1,0,0,1,0,0,1,1,1,0,0,1,0,0,1,1,1,1,1,1,1,1,1,1,0,1,0,0,0,1,1,0,0,0,1,0,0,1,0,0,1,0,0,0,0,0,1,1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,1,0,1,0,0,1,1,0,1,1,0,1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,0,1,0,1,1,0,1,1,0,0,1,0,1,0,1,1,1,0,1,0,1,0,0,1,1,1,1,1,1,0,0,0,1,0,1,1,0,0,0,1,0,0,1,1,0,1,0,1,1,0,0,0,0,1,0,1,0,0,1,0,0,1,1,0,0,1,0,1,1,0,0,0,0,0,0,1,0,0,1,0,1,0,0,0,0,1,1,1,1,0,1,1,1,0,0,0,0,1,0,1,1,0,0,1,0,1,0,0,0,0,0,1,1,1,0,0,1,1,1,1,1,1,1,1,0,1,1,0,0,0,0,0,1,0,0,0,1,0,0,0,0,1,0,0,0,0,0,1,1,1,0,0,1,0,1,1,0,0,1,0,1,1,0,0,0,0,1,1,1,1,0,1,1,1,0,0,0,1,0,0,0,0,1,0,0,1,0,0,1,1,0,0,0,0,0,1,1,1,0,0,1,0,1,1,0,0,1,1,0,1,0,0,0,1,0,0,1,1,1,0,0,1,0,0,0,0,0,0,1,1,0,1,1,1,1,1,1,1,0,0,1,0,0,1,0,1,0,0,0,1,1,1,1,0,1,0,1,1,1,1,0,0,1,0,0,1,1,0,0,0,1,1,0,0,1,0,0,0,1,1,0,1,0,0,1,1,0,0,0,0,0,0,0,1,1,1,1,0,0,0,1,0,0,1,0,1,0,0,1,0,0,0,1,0,1,1,1,1,1,1,0,0,1,0,1,0,1,0,1,1,1,1,0,0,1,1,0,1,1,0,0,0,1,0,0,0,1,0,1,0,1,0,1,0,1,0,1,1,1,1,0,1,0,0,0,1,1,1,1,0,1,0,0,0,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1,0,1,1,0,1,1,1,1,1,0,0,1,1,0,0,1,0,1,0,1,0,0,1,0,0,1,1,1,1,1,1,1,0,0,0,0,1,0,1,0,0,1,0,1,1,0,1,0,1,1,0,1,1,1,1,0,0,0,0,0,1,0,0,0,0,0,1,0,1,1,1,0,1,0,0,0,1,1,0,0,0,0,1,0,1,1,0,1,0,0,1,0,1,0,1,0,0,1,1,1,0,1,0,1,1,1,1,0,0,0,1,0,1,0,1,0,0,0,1,0,1,1,1,0,0,0,0,1,0,0,0,1,1,0,0,0,0,0,1,1,0,1,0,0,1,1,1,0,0,0,1,0,0,0,1,1,0,1,1,0,1,1,1,1,1,1,0,1,0,1,0,1,1,1,0,1,1,1,1,0,0,0,0,0,0,0,1,0,0,0,1,1,1,0,0,0,0,1,0,1,1,1,0,1,0,0,0,1,1,1,0,1,1,0,0,1,1,0,0,0,0,0,1,0,0,1,0,1,0,0,1,0,1,1,1,1,0,1,0,1,0,0,0,1,0,1,1,0,0,1,1,1,1,0,0,0,0,0,1,1,1,1,1,1,1,0,0,1,1,1,1,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,1,0,0,0,0,1,1,0,0,0,1,0,0,1,0,1,0,1,0,0,0,0,0,1,0,0,1,0,1,1,0,0,1,1,0,0,1,0,0,1,1,0,0,1,0,1,0,1,1,1,0,1,0,0,0,0,0,0,0,1,1,0,0,0,1,0,1,1,1,1,0,1,1,1,1,1,0,1,1,0,1,0,1,0,0,1,0,0,0,0,0,};
        std::vector<int> res;
        std::vector<uint32_t> randomNumbers;
        int generatorType;      
        std::vector<uint32_t> seeds;
        std::vector<char> first3Bits;

        uint32_t temper(uint32_t num) {    
            uint32_t y = num ^ (num >> 11);
            y ^= (y << 7) & 0x9D2C5680;
            y ^= (y << 15) & 0xEFC60000;
            return y ^ (y >> 18);
        }

        void generatorLinear(uint32_t *num, char *first3Bits){
            char fourthBit = ((*num & 0x80000000) != 0) ? 1 : 0;
            *first3Bits = *first3Bits ^ (((*first3Bits << 1) & 0x7) ^ fourthBit) ^ ((*first3Bits >> 1) & 0x7) ^ (*first3Bits & 0x4);
            *num ^= (*num << 1) ^ (*num >> 1);
        }

        void generatorNonLinear(uint32_t *num, char *first3Bits){
            uint32_t q = *num;
            uint32_t r = (*num << 1);
            uint32_t p = (*num >> 1) ^ (*first3Bits&0x1 != 0 ? 0x80000000 : 0);
            uint32_t temp = q ^ r;
            char firstq = *first3Bits;
            char firstr = ((*first3Bits << 1)&0x7) ^ ((q & 0x80000000) != 0 ? 1 : 0);
            char firstp = ((*first3Bits >> 1)&0x7);

            *first3Bits = firstq ^ firstr;
            *first3Bits = (*first3Bits ^ *first3Bits&0x4) ^ ((firstr&0x4)^0x4);
            *first3Bits = ((*first3Bits | firstq&0x2)^0x2);
            *first3Bits = *first3Bits ^ firstp;

            temp = ((temp | q&0x4000000)^0x4000000); //Rule 225 pos
            temp = (temp | ((r&0x40800000))^0x40800000); //Rule 135 pos
            temp = ((temp ^ q&0x10000000) | ((q&0x10000000)^0x10000000)); //Rule 75 pos
            temp = (temp ^ (temp&0x1040)) ^ ((r&0x1040)^0x1040); //Rule 165 pos
            
            temp = temp ^ p;
            temp = (((temp ^ r&0x200000) | (r&0x200000)) ^ (q&0x200000)); //Rule 195 pos
            temp = (temp ^ (r&0x80000100) ^ ((r&0x80000100)^0x80000100)); //Rule 105 pos
            temp = (temp ^ (q&0x280E80A8)); //Rule 90 pos
            temp = ((temp ^ (temp&0x1))) ^ ((p&0x1)^0x1);//35thBit - 5

            //cout<<bitset<3>(*first3Bits)<<bitset<32>(temp)<<endl;
            //std::cout<<temp<<std::endl;
            *num = temp;
        }

        void generator(uint32_t *num, char *first3Bits){
            if(!this->generatorType){
                generatorLinear(num, first3Bits);
            } else {
                generatorNonLinear(num, first3Bits);
            }
        }

        void multiply(std::vector<int> arr1, std::vector<int> arr2) {
            // Convert arr1 to a 2D matrix
            int mat1[1][numOfBits];
            for (int i = 0; i < 1; i++) {
                for (int j = 0; j < numOfBits; j++) {
                    mat1[i][j] = arr1[i * numOfBits + j];
                }
            }
            
            // Convert arr2 to a 2D matrix
            int mat2[numOfBits][numOfBits];
            for (int i = 0; i < numOfBits; i++) {
                for (int j = 0; j < numOfBits; j++) {
                    mat2[i][j] = arr2[i * numOfBits + j];
                }
            }
            
            // Multiply the two matrices
            for (int i = 0; i < 1; i++) {
                for (int j = 0; j < numOfBits; j++) {
                    res[i * numOfBits + j] = 0;
                    for (int k = 0; k < numOfBits; k++) {
                        res[i * numOfBits + j] += mat1[i][k] * mat2[k][j];
                    }
                }
            }


            for(int i = 0; i < numOfBits; i++){
                res[i] = res[i] % 2;
            }
        }


    public:
        caprng(uint32_t seed, int flag = 0){

            std::vector<int> initialConfig;  
            res.resize(numOfBits,0); 
            initialConfig.resize(numOfBits,0);
            randomNumbers.resize(4,0);
            seeds.resize(4,0);
            first3Bits.resize(4,0);
            generatorType = flag;

            for(int i = 0; i < numOfBits; i++){
                initialConfig[i] = std::bitset<64>(seed)[numOfBits-1-i];
            }            
            this->seeds[0] = seed;
            for(int i = 1; i < 4; i++){
                multiply(initialConfig, this->t4); 
                for(int j = 0; j < numOfBits; j++){
                    initialConfig[j] = res[j];
                }              
                std::string s = "";
                std::string f = "";

                for(int j = 0; j < numOfBits; j++){
                    if(j < 3 && numOfBits == 35){
                        f += std::to_string(this->res[j]);
                        continue;
                    }
                    s += std::to_string(this->res[j]);
                }
                this->seeds[i] = (std::bitset<32>(s).to_ulong());
                if(f != ""){
                    this->first3Bits[i] = (std::bitset<3>(f).to_ulong());
                } else {
                    this->first3Bits[i] = (0);
                }
            }
        }

        std::vector<uint32_t> gen(){
            //Use thread to call generator and store value in randomNumbers
            if(randomNumbers[0] == 0){
                for (int i = 0; i < 4; i++) {
                    randomNumbers[i] = temper(this->seeds[i]);
                }
                return randomNumbers;
            }
            std::thread threads[4];
            for (int i = 0; i < 4; i++) {
                threads[i] = std::thread(&caprng::generator, this, &this->seeds[i], &this->first3Bits[i]);
            }
            for (int i = 0; i < 4; i++) {
                threads[i].join();
            }            
            std::vector<uint32_t> r;
            for (int i = 0; i < 4; i++) {
                randomNumbers[i] = temper(this->seeds[i]);
            }
            return randomNumbers;
        }        
};