/*
 ============================================================================
 Name        : CudaPasswordBruteForceCrack.cu
 Author      : CelozziCiabini
 Version     :
 Copyright   : Your copyright notice
 Description : CUDA compute reciprocals
 ============================================================================
 */

#include <iostream>
#include <numeric>
#include <stdlib.h>
#include <stdio.h>
#include <fstream>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sort.h>
#include "crypt.h"
#include "c_utils.h"
#include "des.h"
#include "des_utils.h"
#include "bit_utils.h"
#include "des_consts.h"
#include "des_kernel.h"
#include "cuda_utils.h"


static void CheckCudaErrorAux(const char *, unsigned, const char *,
    cudaError_t);
#define CUDA_CHECK_RETURN(value) CheckCudaErrorAux(__FILE__,__LINE__, #value, value)

/**
 * Check the return value of the CUDA runtime API call and exit
 * the application if the call has failed.
 */
static void CheckCudaErrorAux(const char *file, unsigned line,
    const char *statement, cudaError_t err) {
  if (err == cudaSuccess)
    return;
  std::cerr << statement << " returned " << cudaGetErrorString(err) << "("
      << err << ") at " << file << ":" << line << std::endl;
  exit(1);
}
//__constant__ char dictionary[10]={'0','1','2','3','4','5','6','7','8','9'};
__global__ void kernel(int* resultsDevice, int dim, u_int64_t* hashesDevice) {
	int mI = threadIdx.y+blockIdx.y*blockDim.y;
	int yI = threadIdx.x+blockIdx.x*blockDim.x + 1940;
	int dI = threadIdx.z;
	//printf("%d \n",(yI-1940)*12*31+mI*31+dI);
	//printf("---%d, ---%d, --  %d\n", yI,mI,dI);
	//resultsDevice[(yI-1940)*12*31+mI*31+dI] = 1;
	uint64_t block = yI*10000+mI*100+dI;
	uint64_t encoded = full_des_encode_block(block, block);
	//test
	for(int i=0;i<dim;i++){
		if (hashesDevice[i] == encoded){
			resultsDevice[i]=1;
		}else{
			printf("hash %d -- enc %d -- blk %d -- it: %d\n", hashesDevice[i], encoded, block, i);
		}
	}
	/*
	//days
	char dd[2];
	if(dI<10){
		dd[0]='0';
		dd[1]=dictionary[dI];
	}
	else{
		int tens = dI/10;
		dd[0]=dictionary[tens];
		int units = dI%10;
		dd[1]=dictionary[units];
	}
	//months
	char mm[2];
	if(mI<10){
			mm[0]='0';
			mm[1]=dictionary[mI];
		}
		else{
			int tens = mI/10;
			mm[0]=dictionary[tens];
			int units = mI%10;
			mm[1]=dictionary[units];
		}
	//years -suppose yI=1996
	char yyyy[4];
	int thousands = yI/1000; //yI/1000=1 poichè è int
	yyyy[0]=dictionary[thousands];
	int tmp = yI%1000; //yI%1000=996
	int hundreds = tmp/100; //996/100 = 9
	yyyy[1]=dictionary[hundreds];
	tmp = tmp%100; // 996%100=96
	int tens= tmp/10;//96/10=9
	yyyy[2]=dictionary[tens];
	tmp=tmp%10;//96%10 = 6
	int units = tmp;//6
	yyyy[3]=dictionary[units];

	//end conversion


	char yyyymmdd[9] = {yyyy[0],yyyy[1],yyyy[2],yyyy[3],mm[0],mm[1],dd[0],dd[1],0};*/
	//printf("%d device \n",hashesDevice[55]); //test cudaMemcpy
	/*for(int i=0; i<dim; i++){
		uint64_t block = yI*10000+mI*100+dI; //0x0123456789ABCDEF;
		//printf("block %d", block);
		uint64_t encoded = full_des_encode_block(block, block);
		//printf("en: %d", encoded);

		if (hashesDevice[i] == encoded){
			printf("hash: %d  enc: %d ----YEP \n",hashesDevice[i], encoded);
			break;
	    //  resultsDevice[i]=yyyymmdd;
	    }
		else{
			printf("hash: %d  enc: %d ----NOPE \n",hashesDevice[i], encoded);
		}
	}*/
}


int main(void)
{
	#define dim 100
	int resultsHost[dim];
	FILE * fp;
	char * line = NULL;
	size_t len = 0;
	ssize_t read;
	u_int64_t hashesHost[dim];
	int k=0;
	fp = fopen("PswDb/db100.txt", "r");
	while ((read = getline(&line, &len, fp)) != -1) {
		char* hash =(char*) malloc(sizeof(char)*9);
		for(int i = 0; i<9; i++){
		  hash[i]=line[i];
		}
		hash[8]= '\0'; //string termination
		hashesHost[k]=full_des_encode_block(atoi(hash),atoi(hash));
		k++;
	}
	fclose(fp);
	free(line);

	//GPU memory allocation
	u_int64_t* hashesDevice;
	int* resultsDevice;

	CUDA_CHECK_RETURN( cudaMalloc((void **)&hashesDevice, dim * sizeof(u_int64_t)) );

	CUDA_CHECK_RETURN( cudaMemcpy(hashesDevice, hashesHost, dim * sizeof(u_int64_t), cudaMemcpyHostToDevice) );

	CUDA_CHECK_RETURN(
			  cudaMalloc((void **) &resultsDevice, sizeof(int) * dim));

	//@@ INSERT CODE HERE
	dim3 dimGrid(7,4);
	dim3 dimBlock(10,3,31);
	kernel<<<dimGrid,dimBlock>>>(resultsDevice,dim,hashesDevice);
	// copy results from device memory to host

	CUDA_CHECK_RETURN(
	  cudaMemcpy(resultsHost, resultsDevice, dim * sizeof(int),
		  cudaMemcpyDeviceToHost));

	cudaFree(hashesDevice);
	cudaFree(resultsDevice);
	int count = 0;
	for(int i = 0; i < dim; i++){
		if(resultsHost[i]==1)
			count++;
	}
	printf("ccc: %d", count);
	return 0;
}
