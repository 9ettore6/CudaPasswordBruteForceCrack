/*
 ============================================================================
 Name        : CudaPasswordBruteForceCrack.cu
 Author      : Ettore
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


#include "crypt.h"

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

__global__ void kernel(char** results, char** hashes, int dim) {
  for(int i=0; i<dim; i++){
	int mI = threadIdx.y+blockIdx.y*blockDim.y;
	int yI = threadIdx.x+blockIdx.x*blockDim.x;
	int dI = threadIdx.z;
	char m = mI +'0';//da int a char
	char y = yI +'0';
	char d = dI +'0';
    char yyyy[12];
    char mm[12];
    char dd[12];
    char* pwd="";
    /*if (hashes[i] == crypt(pwd,"parallel")){
      results[i]=pwd;
    }*/
  }

}


int main(void)
{
  #define dim 100
  char * resultsHost[dim];
  char * hashes[dim];
  char * results[dim];
  FILE * fp;
  char * line = NULL;
  size_t len = 0;
  ssize_t read;
  char* hashesHost[dim];
  int k=0;
  fp = fopen("PswDb/db100.txt", "r");
  while ((read = getline(&line, &len, fp)) != -1) {
    char* hash =(char*) malloc(sizeof(char)*13);
    for(int i = 0; i<13; i++){
      hash[i]=line[i+9];
    }
    hashesHost[k]=hash;
    k++;
  }
  fclose(fp);
  free(line);
  char* psw;
  char* salt = "parallel";
  psw = crypt("Ettore", salt);
  std::cout<< "Ettore " << psw << "\n";
  printf("--- %s\n", hashesHost[0]);
  printf("--- %s\n", hashesHost[1]);
  printf("--- %s\n", hashesHost[11]);
  // allocate device memory
  CUDA_CHECK_RETURN(
		  cudaMalloc((void **) &hashes, sizeof(char) * 13 * dim));

  CUDA_CHECK_RETURN(
		  cudaMalloc((void **) &results, sizeof(char) * 13 * dim));

  // copy from host to device memory
  CUDA_CHECK_RETURN(
      cudaMemcpy(hashesHost, hashes, dim * 13 * sizeof(char),
          cudaMemcpyHostToDevice));


  //@@ INSERT CODE HERE
  dim3 dimGrid(7,4);
  dim3 dimBlock(10,3,31);
  kernel<<<dimGrid, dimBlock>>>(results,hashes,dim);
  // copy results from device memory to host

  CUDA_CHECK_RETURN(
      cudaMemcpy(results, resultsHost, dim * 13 * sizeof(char),
          cudaMemcpyDeviceToHost));
  cudaFree(hashes);
  cudaFree(results);
  return 0;
}
