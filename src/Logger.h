/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#ifndef TPTLOGGER_H
#define TPTLOGGER_H

#include <string>
#include <fstream>

#include "Exception.h"
#include "Parameters.h"

namespace TPT {

#define LOG_CTX_WIDTH		18
#define LOG_STS_WIDTH		5

class Logger {
public:
	static const std::string DBGSTS;
	static const std::string INFOSTS;
	static const std::string ERRSTS;

	Logger(const Parameters &params);
	virtual ~Logger(void) noexcept;

	template<typename ... Args>
	void sysdebug(const std::string &fmt, Args && ...args) {
		if (m_dbg)
			printf("system", DBGSTS, fmt, args...);
	}

	template<typename ... Args>
	void sysinfo(const std::string &fmt, Args && ...args) {
		printf("system", INFOSTS, fmt, args...);
	}

	template<typename ... Args>
	void syserror(const std::string &fmt, Args && ...args) {
		printf("system", ERRSTS, fmt, args...);
	}

	template<typename ... Args>
	void printf(const std::string &ctx, const std::string &sts, const std::string &fmt, Args && ...args);

	template<typename ... Args>
	void printf(const std::string &ctx, const std::string &sts, const std::string &fmt);

	std::string get_path(void) const {
		return m_path;
	}

	bool get_dbg(void) const {
		return m_dbg;
	}

private:
	bool m_dbg;
	std::string m_path;
	std::ofstream m_log;

	std::string get_datestr(void);
};

} /* namespace TPT */

#include "Logger.tpp"

#endif /* TPTLOGGER_H */
