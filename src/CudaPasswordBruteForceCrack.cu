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

__global__ void kernel(int* resultsDevice, int dim, uint64_t* hashesDevice) {

	int date = threadIdx.x+blockDim.x*blockIdx.x;
	int year=(date/417)+1940;
	int month=((date%417)/32);
	int day=(date%32);
	uint64_t key = year*10000+month*100+day;
	uint64_t encoded = 0;
	encoded = full_des_encode_block(key, key);
	if(date==29690)
		printf("data: %d \n", key);
	if(month == 0 || day == 0){
	}else{
		if(date==29120)
			printf("%d \n",key);
		for(int i=0;i<dim;i++){
			if (hashesDevice[i] == encoded){
				resultsDevice[i] = 1;
			}
		}
	}
}


int main(void)
{
	#define dim 500
	int resultsHost[dim];
	FILE * fp;
	char * line = NULL;
	size_t len = 0;
	ssize_t read;
	uint64_t hashesHost[dim];
	int k=0;
	fp = fopen("PswDb/db500.txt", "r");
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

	CUDA_CHECK_RETURN( cudaMalloc((void **)&hashesDevice, dim * sizeof(uint64_t)) );

	CUDA_CHECK_RETURN( cudaMemcpy(hashesDevice, hashesHost, dim * sizeof(uint64_t), cudaMemcpyHostToDevice) );

	CUDA_CHECK_RETURN( cudaMalloc((void **) &resultsDevice, sizeof(int) * dim));
	//My machine is currently running on 3SM & 128 cudaCore/SM
	//@@ INSERT CODE HERE

	clock_t start = clock();
	kernel<<<232,128>>>(resultsDevice,dim,hashesDevice);
	// copy results from device memory to host

	cudaDeviceSynchronize();
	CUDA_CHECK_RETURN(
		  cudaMemcpy(resultsHost, resultsDevice, dim * sizeof(int),
			  cudaMemcpyDeviceToHost));
	clock_t end = clock();
	float seconds = (float) (end - start) / CLOCKS_PER_SEC;
	cudaFree(hashesDevice);
	cudaFree(resultsDevice);

	int count = 0;
	for(int i = 0; i < dim; i++){
		if(resultsHost[i] == 1){
			count++;
		}
	}
	printf("ccc: %d\n",count);
	printf("time: %f",seconds);
	return 0;
}
