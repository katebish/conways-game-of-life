# CMakeLists.txt to build GoL.cu

cmake_minimum_required(VERSION 2.8)

find_package(CUDA QUIET REQUIRED)

 
# Specify binary name and source file to build it from

cuda_add_executable(
	GoL_cuda
	./GoL.cu)
