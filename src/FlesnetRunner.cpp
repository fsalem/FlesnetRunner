//============================================================================
// Name        : FlesnetRunner.cpp
// Author      : Farouk
// Version     :
// Copyright   : Zib.de
// Description : Hello World in C++, Ansi-style
//============================================================================

#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <iostream>
#include <fstream>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <numeric>
#include "Helper.hpp"

using namespace std;

int main(int argc, char* argv[]) {
	clock_t t1, t2;
	t1 = clock();

	int maxNodes, minStartNodes, nodesInc, timesliceSize, inbufferSize,
			compbufferSize;
	string hugePages;
	if (argc < 2) { // # of nodes
		maxNodes = 2;
	} else {
		Helper::convertStringToInteger(string(argv[1]), maxNodes);
	}

	if (argc < 3) { // min number of nodes for input and compute
		minStartNodes = 1;
	} else {
		Helper::convertStringToInteger(string(argv[2]), minStartNodes);
	}

	if (argc < 4) { // Incremental of # of input and output nodes
		nodesInc = 1;
	} else {
		Helper::convertStringToInteger(string(argv[3]), nodesInc);
	}

	if (argc < 5) { // Timeslice-size
		timesliceSize = 100;
	} else {
		Helper::convertStringToInteger(string(argv[4]), timesliceSize);
	}

	if (argc < 6) { // Input Buffer size
		inbufferSize = 25;
	} else {
		Helper::convertStringToInteger(string(argv[5]), inbufferSize);
	}

	if (argc < 7) { // Output Buffer size
		compbufferSize = 25;
	} else {
		Helper::convertStringToInteger(string(argv[6]), compbufferSize);
	}

	if (argc < 8) { // Huge pages in mb
		hugePages = "2M";
	} else {
		hugePages = argv[7];
	}

	ofstream statFile, errorFile;
	statFile.open("benchmark.xls");
	errorFile.open("jobs/error.txt");
	statFile
			<< "Input Nodes\tCompute Nodes\tAgg bandwidth\tAvg bandwidth\tMedian bandwidth\tMin bandwidth\tMax Bandwidth\tTimeslice Size\tInput Buffer Size\tCompute Buffer Size\t Huge Pages\n";
	string cmdMsg, cmdRes, bandwidthStr, jobId;
	int basePort = 2000, basePortIncremental = 1;

	bool isMsub = false;
	double medianBandwidth, totalBandwidth;

	vector<double> bandwidths;
	int numFail = 0;
	for (int inbuf = inbufferSize; inbuf < 33; inbuf += 2) {
		for (int compbuf = compbufferSize; compbuf < 33; compbuf += 2) {
			for (int ts = timesliceSize; ts < 100000; ts *= 10) {
				// try all the permutations for input and compute nodes
				for (int inNodes = minStartNodes; inNodes < maxNodes;
						inNodes += nodesInc) {
					bandwidths.clear();
					string tokens[4];
					basePort += basePortIncremental;
					if (basePort > 65535 - basePortIncremental - 1) {
						basePort = 2000;
					}
					//cout << "Run sbatch with " << inNodes << " input nodes and "
					//	<< compNodes << " Compute nodes\n";
					cmdMsg = "NODES=" + Helper::integerToString(maxNodes)
							+ " INPUT=" + Helper::integerToString(inNodes)
							+ " COMPUTE="
							+ Helper::integerToString(maxNodes - inNodes)
							+ " BASE_PORT=" + Helper::integerToString(basePort)
							+ " TIMESLICE_SIZE=" + Helper::integerToString(ts)
							+ " IN_BUF_SIZE=" + Helper::integerToString(inbuf)
							+ " CN_BUF_SIZE=" + Helper::integerToString(compbuf)
							+ " HUGE_PAGES=" + hugePages + " SRUN=";

					cmdRes = Helper::executeCommand("./checkCommand.sh msub");
					if (cmdRes[0] == '1') {
						cmdMsg += "0";
						isMsub = true;
					} else {
						cmdMsg += "1";
					}
					cmdMsg += " ./flesnetStarter.sh";
					cout << "\nCommand to be called: " << cmdMsg;
					cmdRes = Helper::executeCommand(cmdMsg);
					if (isMsub) {
						jobId = Helper::trim(cmdRes);
					} else {
						Helper::convertStringToArray(cmdRes, tokens);
						jobId = tokens[3];
					}
					cout << " with ID = '" << jobId << "'\n";

					//cout << "tokens = '" << tokens[0] << "','" << tokens[1] << "','"
					//	<< tokens[2] << "','" << tokens[3] << "'" << endl;

					//cout << "A job is started with ID = " << jobId << endl;
					// check that the job is finished
					Helper::waitForJobCompletion(jobId, isMsub);

					//get the bandwidth from each input file
					Helper::getBandwidthDetails(jobId, inNodes, &bandwidths);

					if (bandwidths.size() == inNodes) {

						sort(bandwidths.begin(),
								bandwidths.begin() + bandwidths.size());
						if (inNodes % 2 == 0) {
							medianBandwidth = (bandwidths[bandwidths.size() / 2]
									+ bandwidths[(bandwidths.size() / 2) - 1])
									/ 2.0;
						} else {
							medianBandwidth = bandwidths[bandwidths.size() / 2];
						}
						totalBandwidth = accumulate(bandwidths.begin(),
								bandwidths.end(), 0);
						statFile << inNodes << "\t" << (maxNodes - inNodes)
								<< "\t" << totalBandwidth << "\t"
								<< (totalBandwidth / (inNodes * 1.0)) << "\t"
								<< medianBandwidth << "\t" << bandwidths[0]
								<< "\t" << bandwidths[bandwidths.size() - 1]
								<< "\t" << ts << "\t" << inbuf << "\t"
								<< compbuf << "\t" << hugePages << "\n";
						statFile.flush();
						cmdMsg = "rm -Rf job" + jobId + ".out job" + jobId
								+ ".err jobs/" + jobId + "/";
						cmdMsg = Helper::executeCommand(cmdMsg);
						numFail = 0;
					} else {
						errorFile << jobId << endl;
						cout << "Error happened while getting files\n";
						if (numFail < 1) { // try one more time when failure is happened
							inNodes -= nodesInc;
							numFail++;
						} else {
							numFail = 0;
							statFile << inNodes << "\t" << (maxNodes - inNodes)
									<< "\t" << 0 << "\t" << 0 << "\t" << 0
									<< "\t" << 0 << "\t" << 0 << "\t" << ts
									<< "\t" << inbuf << "\t" << compbuf << "\t"
									<< hugePages << "\t" << jobId << "\n";
							statFile.flush();
						}
					}
					if (isMsub) {
						cmdMsg = "canceljob " + jobId;
					} else {
						cmdMsg = "scancel " + jobId;
					}
					//cout << "command to be called: " << cmdMsg << endl;
					cmdMsg = Helper::executeCommand(cmdMsg);
					//cout << "scancel output is " << cmdMsg << endl;

				}
			}
		}
	}
	statFile.flush();
	errorFile.flush();
	statFile.close();
	errorFile.close();

	t2 = clock();
	double elapsed = (double) (t2 - t1) * 1000.0 / CLOCKS_PER_SEC;
	printf("Time elapsed in ms: %f", elapsed);

	return 0;
}
