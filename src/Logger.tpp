/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#include <string>
#include <sstream>
#include <iomanip>

#include "Helpers.h"
#include "Exception.h"
#include "Logger.h"

template<typename ... Args>
void TPT::Logger::printf(const std::string &ctx, const std::string &sts, const std::string &fmt, Args && ...args) {
	std::stringstream line;
	std::string msg, date;

	msg = std_sprintf(fmt, args...);
	date = get_datestr();

	line << date << " " << std::left << std::setw(LOG_CTX_WIDTH) << ctx << " " <<
		std::setw(LOG_STS_WIDTH) << sts << " | " << msg << std::endl;

	try {
		m_log << line.rdbuf();
	} catch (std::ifstream::failure &e) {
		throw ExcIOAaccess("Log file IO failure");
	}
}

template<typename ... Args>
void TPT::Logger::printf(const std::string &ctx, const std::string &sts, const std::string &str) {
	std::stringstream line;
	std::string date;

	date = get_datestr();

	line << date << " " << std::left << std::setw(LOG_CTX_WIDTH) << ctx << " " <<
		std::setw(LOG_STS_WIDTH) << sts << " | " << str << std::endl;

	try {
		m_log << line.rdbuf();
	} catch (std::ifstream::failure &e) {
		throw ExcIOAaccess("Log file IO failure");
	}
}
