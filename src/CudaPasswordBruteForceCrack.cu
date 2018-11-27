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
__constant__ char dictionary[10]={'0','1','2','3','4','5','6','7','8','9'};
__global__ void kernel(char** results, char** hashes, int dim) {
	int mI = threadIdx.y+blockIdx.y*blockDim.y;
	int yI = threadIdx.x+blockIdx.x*blockDim.x + 1940;
	int dI = threadIdx.z;

	//conversion from int to char


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


	char yyyymmdd[9] = {yyyy[0],yyyy[1],yyyy[2],yyyy[3],mm[0],mm[1],dd[0],dd[1],0};
	printf("%s \n", yyyymmdd);
	for(int i=0; i<dim; i++){
   /* char* pwd="";
    char* psw;
    char* salt = "parallel";
    psw = crypt("Ettore", salt);*/
    /*if (hashes[i] == crypt(pwd,"parallel")){
      results[i]=pwd;
    }*/
  }

}


int main(void)
{
  #define dim 100
  char * resultsHost[dim];
  char ** hashes;
  char ** results;
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
  //psw = crypt("19961024", salt);
  std::cout<< "19961024 " << psw << "\n";
  printf("--- %s\n", hashesHost[0]);

  // allocate device memory


  CUDA_CHECK_RETURN(
		  cudaMalloc((void **) &hashes, sizeof(char) * 13 * dim));

  CUDA_CHECK_RETURN(
		  cudaMalloc((void **) &results, sizeof(char) * 13 * dim));

  // copy from host to device memory
  CUDA_CHECK_RETURN(
      cudaMemcpy(hashes, hashesHost, dim * 13 * sizeof(char),
          cudaMemcpyHostToDevice));


  //@@ INSERT CODE HERE
  dim3 dimGrid(7,4);
  dim3 dimBlock(10,3,31);
  kernel<<<dimGrid, dimBlock>>>(results,hashes,dim);
  // copy results from device memory to host

  CUDA_CHECK_RETURN(
      cudaMemcpy(resultsHost, results, dim * 13 * sizeof(char),
          cudaMemcpyDeviceToHost));
  cudaFree(hashes);
  cudaFree(results);
  return 0;
}
