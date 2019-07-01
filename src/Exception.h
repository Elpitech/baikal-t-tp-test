/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#ifndef TPTEXCEPTION_H
#define TPTEXCEPTION_H

#include <exception>
#include <iostream>
#include <string>

#include "Helpers.h"
#include "Parameters.h"

#define RET_SUCCESS			0
#define RET_ERROR			1

namespace TPT {

enum struct ERR {
	NO,
	ARG,
	IOACCESS,
	CONFIG,
	SCENARIO,
	TESTCASE,
};

class Exception: public std::runtime_error {
public:
	template<typename ... Args>
	Exception(const ERR& err, const std::string &fmt, Args && ...args)
		: std::runtime_error(std_sprintf(fmt, args...)), m_err(err) {}
	virtual ~Exception() noexcept = default;
	Exception(const Exception &) = default;

	ERR get_error() const {
		return m_err;
	}

	int get_code() const {
		return static_cast<int>(m_err);
	}

	int handle_me(void) {
		int code = static_cast<int>(m_err);
		std::cerr << "Error " << code << ": " << what() << std::endl;
		if (m_err == TPT::ERR::ARG)
			TPT::Parameters::usage();

		return code;
	}

	static int handle_std(std::exception &e) {
		std::cerr << "Exception: " << e.what() << std::endl;

		return RET_ERROR;
	}

private:
	ERR m_err;
};

class ExcArg: public Exception {
public:
	template<typename ... Args>
	ExcArg(const char *fmt, Args && ...args)
		: Exception(ERR::ARG, fmt, args...) {}
};

class ExcIOAaccess: public Exception {
public:
	template<typename ... Args>
	ExcIOAaccess(const char *fmt, Args && ...args)
		: Exception(ERR::IOACCESS, fmt, args...) {}
};

class ExcConfig: public Exception {
public:
	template<typename ... Args>
	ExcConfig(const char *fmt, Args && ...args)
		: Exception(ERR::CONFIG, fmt, args...) {}
};

class ExcScenario: public Exception {
public:
	template<typename ... Args>
	ExcScenario(const char *fmt, Args && ...args)
		: Exception(ERR::SCENARIO, fmt, args...) {}
};

class ExcTestCase: public Exception {
public:
	template<typename ... Args>
	ExcTestCase(const char *fmt, Args && ...args)
		: Exception(ERR::TESTCASE, fmt, args...) {}
};

} /* namespace TPT */

#endif /* TPTEXCEPTION_H */
