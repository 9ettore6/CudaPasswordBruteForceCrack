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
__global__ void kernel(int* resultsDevice, int dim, uint64_t* hashesDevice, uint64_t* testTh) {
	int mI = threadIdx.y+blockIdx.y*blockDim.y;
	int yI = threadIdx.x+blockIdx.x*blockDim.x + 1940;
	int dI = threadIdx.z;
	//resultsDevice[(yI-1940)*12*31+mI*31+dI] = 1;
	uint64_t key = yI*10000+mI*100+dI;
	uint64_t encoded = 0;
	encoded = full_des_encode_block(key, key);
	for(int i=0;i<dim;i++){
		//printf("%d -- %d\n", hashesDevice[i], encoded);
		if (hashesDevice[i] == encoded){
			resultsDevice[i] = 1;
		}else{
			testTh[(yI-1940)*12*31+mI*31+dI] = key;
		}
	}
}


int main(void)
{
	#define dim 100
	int resultsHost[dim];
	uint64_t hostTestTH[26040];
	FILE * fp;
	char * line = NULL;
	size_t len = 0;
	ssize_t read;
	uint64_t hashesHost[dim];
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
	uint64_t* hashesDevice;
	int* resultsDevice;
	uint64_t* testTh;

	CUDA_CHECK_RETURN( cudaMalloc((void **)&hashesDevice, dim * sizeof(uint64_t)) );

	CUDA_CHECK_RETURN( cudaMemcpy(hashesDevice, hashesHost, dim * sizeof(uint64_t), cudaMemcpyHostToDevice) );

	CUDA_CHECK_RETURN( cudaMalloc((void **) &resultsDevice, sizeof(int) * dim));

	CUDA_CHECK_RETURN( cudaMalloc((void **) &testTh, sizeof(uint64_t) * 26040));
	//@@ INSERT CODE HERE
	dim3 dimGrid(7,4);
	dim3 dimBlock(10,3,31);//
	kernel<<<dimGrid,dimBlock>>>(resultsDevice,dim,hashesDevice,testTh);
	// copy results from device memory to host
	/*for(int i = 0; i < dim; i++){
		resultsHost[i] = 0;
	}*/
	//printf("***********%d\n",resultsHost[5]);
	CUDA_CHECK_RETURN(
	  cudaMemcpy(resultsHost, resultsDevice, dim * sizeof(int),
		  cudaMemcpyDeviceToHost));
	CUDA_CHECK_RETURN(
		  cudaMemcpy(hostTestTH, testTh, dim * sizeof(uint64_t),
			  cudaMemcpyDeviceToHost));
	//printf("***********%d\n",resultsHost[15]);
	cudaFree(hashesDevice);
	cudaFree(resultsDevice);

	int count = 0;
	int countff = 0;
	for(int i = 0; i < dim; i++){
		if(resultsHost[i] == 1){
			count++;
			printf("hash ok: %d\n", resultsHost[i]);
		}else{
			countff++;
			printf("hash nope: %d\n", hostTestTH[i]);
		}
	}
	printf("ccc: %d\n", count);
	printf("fff: %d", countff);
	return 0;
}
