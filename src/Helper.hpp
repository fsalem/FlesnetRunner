/*
 * Helper.hpp
 *
 *  Created on: Sep 9, 2016
 *      Author: farouk
 */

#ifndef HELPER_HPP_
#define HELPER_HPP_

#include <iostream>
#include <fstream>
#include <string.h>
#include <stdexcept>
#include <stdio.h>
#include <vector>
#include <stdlib.h>
#include <unistd.h>
#include <algorithm>
#include <functional>
#include <cctype>
#include <locale>
using namespace std;

class Helper {
public:
	static string executeCommand(const string command);
	static bool convertStringToInteger(string str, int& num);
	static string integerToString(const int num);
	static void convertStringToArray(string str, string arr[4]);
	static string trim(string s);
	static void waitForJobCompletion(string jobId, bool isMsub);
	static void getBandwidthDetails(string jobId, int inNodes,
			vector<double> *bandwidths);
};

#endif /* HELPER_HPP_ */
