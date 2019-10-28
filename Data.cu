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
#include <fstream> //file processing
#include <cstdlib> //exit function
#include <string.h>
using namespace std;

#define N 87395 //Number of data in the csv

__global__ void getK(float *a,float *c )
{
	float A = 1000000000.0f;
	float e = 2.71828182846f;
	float Ea = 45000.0f;
	float R = 8.314f;
	int myID = threadIdx.x + blockDim.x * blockIdx.x;				
	if (myID < N)
	{
		c[myID] = (A*float(pow(e,(-Ea)/(R*(a[myID]+273.15f)))));
	}
}

int main(int argc, char** argv)
{

	cudaStream_t stream1;							// stream1 and stream2 instantiation
	cudaStream_t stream2;
	cudaStreamCreate(&stream1);
	cudaStreamCreate(&stream2);
	
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
			if(count%2==0){
				std::string token = row.substr(row.find(delimiter)+1);
				double temp = ::atof(token.c_str());
				float temperature = float(temp);
				a1[count/2] = temperature;
			}			
		}
	  	count++;
	}

	for(int i=0;i<N;i+= N*2) { // loop over data in chunks
	// interweave stream 1 and steam 2
		if(i%2==0){
			cudaMemcpyAsync(dev_a1,a1,N*sizeof(int),cudaMemcpyHostToDevice,stream1);			//Copy N*Size(int) bytes from a1 to dev_a1, host to device
			getK<<<(int)ceil(N/1024)+1,1024,0,stream1>>>(dev_a1,dev_c1);
			cudaMemcpyAsync(c1,dev_c1,N*sizeof(int),cudaMemcpyDeviceToHost,stream1);
		}
		else{
			cudaMemcpyAsync(dev_a1,a1,N*sizeof(int),cudaMemcpyHostToDevice,stream2);			//Copy N*Size(int) bytes from a1 to dev_a1, host to device
			getK<<<(int)ceil(N/1024)+1,1024,0,stream1>>>(dev_a1,dev_c1);
			cudaMemcpyAsync(c1,dev_c1,N*sizeof(int),cudaMemcpyDeviceToHost,stream2);
		}
	}
	
	for (int k=0;k<N-1;k++){
		cout<<"Dato: "<<k<<" | Value of K: "<<c1[k]<<"\n";
	}

	cout<<"\n\n\n------------------------------Values of K by period:------------------------------";
	cout<<"\n\n          All values returned are based on the Cyclopentadiene Dimerization";
	cout<<"\n\n\n                                H2 + I2 --> 2HI                              \n\n\n";
	std::ofstream myfile;
    myfile.open ("outData.csv");
    myfile<<"Hour,People,Velocity of reaction\n";
	int medPerPeriod = 12000; //300 Data taken per second 12000 in 1 period
	float sum = 0;
	int period = 0;
	for (int k=0;k<N-1;k++){
		sum+=c1[k];
		if(k%medPerPeriod==0&&k!=0){
			period++;
			int people = 0;
			std::string hour = " ";
			if(period==1){
				hour = "07:00 - 07:50";
				people = 38;
			}
			else if(period==2){
				hour = "07:50 - 08:40";
				people = 37;
			}
			else if(period==3){
				hour = "08:40 - 09:30";
				people = 36;
			}
			else if(period==4){
				hour = "09:30 - 10:15";
				people = 36;
			}
			else if(period==5){
				hour = "10:15 - 10:40";
				people = 3;
			}
			else if(period==6){
				hour = "10:40 - 11:30";
				people = 34;
			}
			else if(period==7){
				hour = "11:30 - 12:15";
				people = 35;
			}
			double average = double(sum)/double(medPerPeriod);
			double velocity = (average*0.05*0.05);
			cout<<"\tHour: "<<hour<<"\tPeople: "<<people<<"\tVelocity of reaction: "<< velocity<<"s\n";
			myfile<<hour<<","<<people<<","<< velocity<<"s\n";
			sum=0;
		}
	}
	cout<<"-----------------------------------------------------------------------------------\n\n\n";
	myfile.close();
	cudaStreamDestroy(stream1);					//Destruir cudaStreamDestroy(stream1)
	return 0;
}