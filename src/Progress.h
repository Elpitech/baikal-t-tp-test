/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#ifndef TPTPROGRESS_H
#define TPTPROGRESS_H

#include <string>
#include <chrono>

#include "Exception.h"
#include "Parameters.h"
#include "Logger.h"
#include "Scenario.h"
#include "TestCase.h"

namespace TPT {

#define PROG_INTRO_WIDTH		11
#define PROG_TIDX_WIDTH			7
#define PROG_INFO_WIDTH			60
#define PROG_CSTATUS_WIDTH		16
#define PROG_NCSTATUS_WIDTH		(PROG_CSTATUS_WIDTH - 11)
#define PROG_TIME_PRECISION		3

const char * const RED = "\e[31;1m";
const char * const GREEN = "\e[32;1m";
const char * const NOCOLOR = "\e[0m";

enum class STATUS {
	PASS,
	ERROR,
	FAIL
};

class Progress {
public:
	Progress(const Parameters &params, Logger &log);
	~Progress(void);

	void header(const Scenario &scenario);

	void start_test(const TestCase &testcase);

	void printst(const TestCase &testcase, const std::string &str);
	void println(const TestCase &testcase, const std::string &str);

	void finish_test(const TestCase &testcase, const STATUS sts);

	void summary(void);

	void disable_echo(void) {
		enable_input_echo(false);
	}

	void enable_echo(void) {
		enable_input_echo(true);
	}

private:
	std::chrono::system_clock::time_point m_start;
	std::chrono::system_clock::time_point m_end;
	std::chrono::duration<float> m_total;

	unsigned int m_tidx;
	unsigned int m_tcnt;

	unsigned int m_passes;
	unsigned int m_errors;
	unsigned int m_failures;

	bool m_printed;
	Logger &m_log;

	void testinfo(const TestCase &tc, std::stringstream &line);
	void enable_input_echo(bool enable);
};

} /* namespace TPT */

#endif /* TPTPROGRESS_H */
