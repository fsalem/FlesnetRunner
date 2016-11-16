/*
 * Helper.cpp
 *
 *  Created on: Sep 9, 2016
 *      Author: farouk
 */

#include <cmath>
#include <sstream>
#include "Helper.hpp"

string Helper::executeCommand(const string command) {
	char buffer[128];
	std::string result = "";
	FILE* pipe = popen(command.c_str(), "r");
	if (!pipe)
		throw std::runtime_error("popen() failed!");
	try {
		while (!feof(pipe)) {
			if (fgets(buffer, 128, pipe) != NULL)
				result += buffer;
		}
	} catch (...) {
		pclose(pipe);
		throw;
	}
	pclose(pipe);
	return result;
}

bool Helper::convertStringToInteger(string str, int& num) {
	if (str[0] == ' ' || str[0] == '\n') {
		str = str.substr(1, str.length() - 1);
	}
	if (str[str.length() - 1] == ' ' || str[str.length() - 1] == '\n') {
		str = str.substr(0, str.length() - 1);
	}
	num = 0;
	for (int i = str.length() - 1; i >= 0; i--) {
		int currentDigit = (str[i] - '0') * pow(10, (str.length() - i - 1));
		num += currentDigit;
	}
	return true;
}

string Helper::integerToString(const int num) {
	ostringstream ss;
	ss << num;
	return ss.str();
}

void Helper::convertStringToArray(string str, string arr[4]) {
	int currentIndex = 0;
	for (int i = 0; i < str.length(); i++) {
		if (str[i] == ' ') {
			currentIndex++;
			continue;
		}
		arr[currentIndex] += str[i];
	}
}

void Helper::waitForJobCompletion(string jobId, bool isMsub) {
	unsigned int microseconds = 15000;
	string cmdMsg;
	while (1) {
		if (isMsub) {
			cmdMsg = "checkjob " + jobId;
		} else {
			cmdMsg = "squeue -j " + jobId;
		}
		//cout << "command to be called: " << cmdMsg << endl;
		cmdMsg = Helper::executeCommand(cmdMsg);
		//cout << "squeue output is " << cmdMsg << endl;
		if (cmdMsg.find("Invalid job") != string::npos || cmdMsg == "" || cmdMsg.find("State: Completed") != string::npos) {
			usleep(microseconds);
			break;
		} else {
			usleep(microseconds);
		}
	}
}

void Helper::getBandwidthDetails(string jobId, int inNodes,
		vector<double> *bandwidths) {

	string inputFileName, bandwidthStr, line;
	double curBandwidth;
	int bracketIndx;
	unsigned int lineIndx;
	ifstream inputFile;

	for (int i = 0; i < inNodes; i++) {
		inputFileName = "jobs/" + jobId + "/" + Helper::integerToString(i)
				+ ".input.out";
		//cout << "Try to open file: " << inputFileName << endl;
		inputFile.open(inputFileName.c_str());
		if (inputFile.is_open()) {
			while (getline(inputFile, line)) {
				if ((lineIndx = line.find(" summary: ")) != string::npos
						&& lineIndx < line.length()
						&& line[line.length() - 1] == ')') {
					bracketIndx = line.find("(");
					bandwidthStr = line.substr(bracketIndx + 1,
							line.find(" ", bracketIndx) - bracketIndx);
					//cout << "bandwidth is " << bandwidthStr << endl;
					curBandwidth = atof(bandwidthStr.c_str());
					bandwidths->push_back(curBandwidth);
				}
			}
		}
		inputFile.close();
	}
//return bandwidths;
}

string Helper::trim(string s){
	s.erase(std::remove(s.begin(), s.end(), '\n'), s.end());
	s.erase(std::remove(s.begin(), s.end(), '\t'), s.end());
	s.erase(std::remove(s.begin(), s.end(), ' '), s.end());
	return s;
}
