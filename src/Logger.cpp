/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#include <fstream>
#include <sstream>
#include <chrono>
#include <ctime>
#include <iomanip>

#include "Logger.h"
#include "Exception.h"
#include "Parameters.h"

const std::string TPT::Logger::DBGSTS = "DEBUG";
const std::string TPT::Logger::INFOSTS = "INFO";
const std::string TPT::Logger::ERRSTS = "ERROR";

TPT::Logger::Logger(const Parameters &params): m_dbg(params.get_dbg()), m_path(params.get_log_path())
{
	m_log.exceptions(std::ifstream::failbit | std::ifstream::badbit);

	try {
		m_log.open(m_path, std::fstream::trunc);
	} catch(std::ifstream::failure &e) {
		throw ExcIOAaccess("Log file creation failure");
	}
}

TPT::Logger::~Logger(void)
{
	m_log.exceptions(std::ifstream::goodbit);

	m_log.close();
}

std::string TPT::Logger::get_datestr(void)
{
	std::chrono::system_clock::time_point ct;
	std::chrono::milliseconds ctms;
	std::stringstream sstr;
	struct tm tm;
	std::time_t ctt;

	ct = std::chrono::system_clock::now();
	ctt = std::chrono::system_clock::to_time_t(ct);
	ctms = std::chrono::duration_cast<std::chrono::milliseconds>(ct.time_since_epoch());

	/* Should we check the return value here? */
	localtime_r(&ctt, &tm);

	sstr << std::put_time(&tm, "%Y-%m-%d %Z %H:%M:%S") << "." <<
		std::setfill('0') << std::setw(3) << ctms.count() % 1000;

	return sstr.str();
}
