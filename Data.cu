/*----------
* Authors:
* 	Saúl Contreras (Suulcoder)
* 	Michele Benvenuto
* 	Luis Urbina
* ----------
* Universidad del Valle
* Programación de Microprocesadores
* Semestre 4, 2019
* ----------
*/

#include <iostream> //cout, cin, cerr
#include <unistd.h>
#include <cmath>
#include <fstream> //file processing
#include <cstdlib> //exit function
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <cuda_runtime.h>
using namespace std;

#define N 87395 //Number of data in the csv

__global__ void getK(float *a,float *c )
{
	float A = 156.15f;
	float e = 2.71828182846f;
	float Ea = 23.515f;
	float R = 8.314f;
	int myID = threadIdx.x + blockDim.x * blockIdx.x;				
	if (myID < N)
	{
		c[myID] = (A*float(pow(e,(-Ea)/(R*a[myID]))));
	}
}

int main(int argc, char** argv)
{

	cudaStream_t stream1;							// strem2 instantiation
	cudaStreamCreate(&stream1);
	
	float *a1, *c1; 									// stream 1 mem ptrs
	float *dev_a1, *dev_c1; 						// stream 1 mem ptrs
	
	//stream 1
	cudaMalloc( (void**)&dev_a1, N * sizeof(float));									//CudaMalloc
	cudaMalloc( (void**)&dev_c1, N * sizeof(float));

	cudaHostAlloc( (void**)&a1, N * sizeof(int), cudaHostAllocDefault);				//CudaHostAlloc allowing the device to get access to mem. 
	cudaHostAlloc( (void**)&c1, N * sizeof(int), cudaHostAllocDefault);
	ifstream read("data.csv",ios::in);
	if(!read){
		cerr<<"Fail to read data.csv"<<endl;
	  	exit(EXIT_FAILURE);
	}
	int count = 0;
	string row;
	while(read>>row){
		if(count!=0){
			std::string delimiter = ",";
			std::string token = row.substr(row.find(delimiter)+1);
			double temp = ::atof(token.c_str());
			float temperature = float(temp);
			a1[count] = temperature;
		}
	  	count++;
	}

	for(int i=0;i < N;i+= N*2) { // loop over data in chunks
	// interweave stream 1 and steam 2
		cudaMemcpyAsync(dev_a1,a1,N*sizeof(int),cudaMemcpyHostToDevice,stream1);			//Copy N*Size(int) bytes from a1 to dev_a1, host to device
		getK<<<(int)ceil(N/1024)+1,1024,0,stream1>>>(dev_a1,dev_c1);
		cudaMemcpyAsync(c1,dev_c1,N*sizeof(int),cudaMemcpyDeviceToHost,stream1);
	}

	for (int k=0;k<N;k++){
		cout<<c1[k]<<"\n";
	}

	cudaStreamDestroy(stream1);					//Destruir cudaStreamDestroy(stream1)
	return 0;
}