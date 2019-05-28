#include <iostream>
#include <fstream>
#include <stdio.h>
#include <unistd.h>
#include <string>

using namespace std;

void printBoard(char array[], int size, int width);
__global__
void getNeighbours(char startBoard[], char finalBoard[], int width, int height);

int main(int argc, char** argv){

	const char* filename;
	if(argc == 4 || argc == 5){
		string arg1 = argv[1];
		string arg3 = argv[3];
		if(argc == 4 && arg1 == "-i"){
			filename = argv[3];
		}
		else if(argc == 5 && arg1 == "-i" && arg3 == "-v"){
			filename = argv[4];
		}
		else{
			cout << "Wrong arguments given" << endl;
			return 0;
		}
	}
	else{
		cout << "Wrong number of arguments given" << endl;
		return 0;
	}


	int numIter = atoi(argv[2]);

	int width = 0;
	int height = 0;

	ifstream infile;
	infile.open(filename);

	//Getting width and Height from file
	string line;
	while(getline(infile, line)){
		if(width == 0){
			width = line.length();
		}
		if(line.length() == width){
			height ++;
		}
	}
	int arraySize = height * width;
	infile.clear();
	infile.seekg(0, infile.beg);

	//Creating arrays
	char* startBoard;
	char* finalBoard;
	char world[arraySize];

	for (int i = 0; i < arraySize; ++i)
	{
		infile >> world[i];
	}

	//Printing Start Board
	printBoard(world, arraySize, width);
	cout << endl;


	//Device arrays
	cudaMalloc((void**)&startBoard, height * width * sizeof(char));
	cudaMalloc((void**)&finalBoard, height * width * sizeof(char));

	cudaMemcpy(startBoard, world, height * width * sizeof(char), cudaMemcpyHostToDevice);


	//Number of iterations
	for(int iter = 0; iter < numIter; iter++){

		int blockSize = 1024;
		int numBlocks = (arraySize + blockSize -1) / blockSize;

		getNeighbours<<<numBlocks, blockSize>>>(startBoard, finalBoard, width, height);

		swap(startBoard,finalBoard);

		//Printing each iteration board

		if(argc == 5){
			cudaMemcpy(world, startBoard, height * width * sizeof(char), cudaMemcpyDeviceToHost);
			printBoard(world, arraySize, width);
			cout << endl;
		}

		unsigned int microseconds;
		microseconds = 100000;
		//usleep(microseconds);


	}

	//Print only final iteration
	if(argc == 4){
		cudaMemcpy(world, startBoard, height * width * sizeof(char), cudaMemcpyDeviceToHost);
		printBoard(world, arraySize, width);
	}



	cudaFree(startBoard);
	cudaFree(finalBoard);
	return 0;
}

void printBoard(char array[], int size, int width){
	int count = 0;
	for (int i = 0; i < size; ++i)
	{
		cout << array[i];
		count ++;
		if(count == width){
			cout << endl;
			count = 0;
		}
	}
}

__global__
void getNeighbours(char startBoard[], char finalBoard[], int width, int height){

	//Finding Neighbours
	int index;
	int x;
	int y;

	int currentCell = blockIdx.x * blockDim.x + threadIdx.x;

	if(currentCell < width * height){
		y = currentCell / width;
		x = currentCell - (width * y);
		int neighbours = 0;
			//Checking surrounding squares
			for (int i = y - 1; i <= y + 1; i++)
			{
				for (int j = x - 1; j <= x + 1; j++){
					if ( j == x && i == y ) {
						continue;
					}
					//Check if on board
					else if(j > -1 && j < width && i > -1 && i < height){
						index = width * i + j;
						if(startBoard[index] == 'X'){
							neighbours ++;
						}
					}
					//Handle wrap around and add neighbours
					else{
						int jTemp = j;
						int iTemp = i;

						if(j == -1){
							jTemp = width - 1;
						}
						if(j == width){
							jTemp = 0;
						}
						if(i == -1){
							iTemp = height - 1;
						}
						if(i == height){
							iTemp = 0;
						}
						index = width * iTemp + jTemp;
						if(startBoard[index] == 'X'){
							neighbours ++;
						}
					}

				}
			}
			if(neighbours == 3 || startBoard[currentCell] == 'X' && neighbours == 2){
				finalBoard[currentCell] = 'X';
			}
			else{
				finalBoard[currentCell] = '-';
			}
	}
}


