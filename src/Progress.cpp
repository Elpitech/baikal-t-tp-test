/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#include <iostream>
#include <sstream>
#include <chrono>
#include <iomanip>
#include <climits>

#include <termios.h>
#include <unistd.h>

#include "Progress.h"
#include "Exception.h"
#include "Parameters.h"
#include "Logger.h"
#include "Scenario.h"
#include "TestCase.h"

TPT::Progress::Progress(const Parameters &params, Logger &log):
						m_total(0), m_tidx(1), m_tcnt(UINT_MAX),
						m_passes(0), m_errors(0), m_failures(0),
						m_printed(false), m_log(log)
{
	disable_echo();

	std::cin.exceptions(std::ifstream::failbit | std::ifstream::badbit);
}

TPT::Progress::~Progress(void)
{
	std::cin.exceptions(std::ifstream::goodbit);

	enable_echo();
}

void TPT::Progress::header(const Scenario &sc)
{
	std::stringstream line;
	m_tcnt = sc.get_testcases().size();

	line << std::left << std::setw(PROG_INTRO_WIDTH) << "TITLE" << ": " << sc.get_title();
	std::cout << line.rdbuf() << std::endl;
	m_log.sysinfo(line.str());

	line.str(std::string());
	line << std::left << std::setw(PROG_INTRO_WIDTH) << "ROOT" << ": " << sc.get_root();
	std::cout << line.rdbuf() << std::endl;
	m_log.sysinfo(line.str());

	line.str(std::string());
	line << std::setw(PROG_INTRO_WIDTH) << "LOG" << ": " << m_log.get_path();
	std::cout << line.rdbuf() << std::endl;
	m_log.sysinfo(line.str());

	line.str(std::string());
	line << std::setw(PROG_INTRO_WIDTH) << "TESTS" << ": " << m_tcnt;
	std::cout << line.rdbuf() << std::endl << std::flush;
	m_log.sysinfo(line.str());
}

void TPT::Progress::testinfo(const TestCase &tc, std::stringstream &line)
{
	std::stringstream buf;

	buf << " (" << m_tidx << "/" << m_tcnt << ")" << " " << tc.get_id() << " '" << tc.get_info() << "' ";
	line << std::left << std::setw(PROG_INFO_WIDTH) << buf.str();
}

void TPT::Progress::start_test(const TestCase &tc)
{
	std::stringstream line;

	testinfo(tc, line);

	std::cout << line.rdbuf() << std::flush;
	m_log.sysinfo(line.str());

	/* We don't warry about the races, since there is only a single thread
	 * using the progress interface at the moment.
	 */
	m_printed = false;

	m_start = std::chrono::system_clock::now();
}

void TPT::Progress::printst(const TestCase &tc, const std::string &str)
{
	if (!m_printed)
		println(tc, "");

	std::cout << str << std::flush;

	m_printed = true;
}

void TPT::Progress::println(const TestCase &tc, const std::string &str)
{
	std::stringstream line;

	line << str << std::endl << tc.get_id() << ">> " << std::flush;

	std::cout << line.rdbuf() << std::flush;

	m_printed = true;
}

void TPT::Progress::finish_test(const TestCase &tc, const STATUS sts)
{
	std::stringstream pline, lline, pbuf, lbuf;
	std::chrono::duration<float> fsec;

	m_end = std::chrono::system_clock::now();
	fsec = m_end - m_start;
	m_total += fsec;

	if (m_printed) {
		pline << std::endl;
		testinfo(tc, pline);
	}
	testinfo(tc, lline);

	switch (sts) {
	case STATUS::PASS:
		pbuf << GREEN << "PASS" << NOCOLOR;
		lbuf << "PASS";
		++m_passes;
		break;
	case STATUS::ERROR:
		pbuf << RED << "ERROR" << NOCOLOR;
		lbuf << "ERROR";
		++m_errors;
		break;
	case STATUS::FAIL:
		pbuf << RED << "FAIL" << NOCOLOR;
		lbuf << "FAIL";
		++m_failures;
		break;
	}

	pline << std::left << std::setw(PROG_CSTATUS_WIDTH) << pbuf.str();
	pline.precision(PROG_TIME_PRECISION);
	pline << " (" << std::fixed << fsec.count() << " s)" << std::endl;

	lline << std::left << std::setw(PROG_NCSTATUS_WIDTH) << lbuf.str();
	lline.precision(PROG_TIME_PRECISION);
	lline << " (" << std::fixed << fsec.count() << " s)";

	std::cout << pline.rdbuf() << std::flush;
	m_log.sysinfo(lline.str());
	++m_tidx;
}

void TPT::Progress::summary(void)
{
	std::stringstream pline, lline;

	pline << std::left << std::setw(PROG_INTRO_WIDTH) << "SUMMARY" << ": " <<
		GREEN << "PASS "  << NOCOLOR << m_passes << " | " <<
		RED   << "ERROR " << NOCOLOR << m_errors << " | " <<
		RED   << "FAIL "  << NOCOLOR << m_failures;
	lline << std::left << std::setw(PROG_INTRO_WIDTH) << "SUMMARY" << ": " <<
				 "PASS "  <<			m_passes << " | " <<
				 "ERROR " <<			m_errors << " | " <<
				 "FAIL "  << 			m_failures;
	std::cout << pline.rdbuf() << std::endl;
	m_log.sysinfo(lline.str());

	lline.str(std::string());
	lline.precision(PROG_TIME_PRECISION);
	lline << std::setw(PROG_INTRO_WIDTH) << "TESTS TIME" << ": " << std::fixed << m_total.count() << " s";
	std::cout << lline.rdbuf() << std::endl << std::endl << std::flush;
	m_log.sysinfo(lline.str());
}

void TPT::Progress::enable_input_echo(bool on)
{
	struct termios TermConf;
	int sts;

	if (on)
		m_log.sysdebug("Enable console echo");
	else
		m_log.sysdebug("Disable console echo");

	sts = tcgetattr(STDIN_FILENO, &TermConf);
	if (sts)
		throw ExcIOAaccess("Couldn't get the terminal attributes");

	if(on)
		TermConf.c_lflag |= (ICANON | ECHO);
	else
		TermConf.c_lflag &= ~(ICANON | ECHO);

	/* Remove garbage from stdin. */
	m_log.sysdebug("Flush garbage from stdin");
	tcdrain(STDIN_FILENO);
	tcflush(STDIN_FILENO, TCIFLUSH);

	sts = tcsetattr(STDIN_FILENO, TCSANOW, &TermConf);
	if (sts)
		throw ExcIOAaccess("Couldn't set the terminal attributes");
}
