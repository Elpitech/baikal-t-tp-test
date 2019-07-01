/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#ifndef TPTPARAMETERS_H
#define TPTPARAMETERS_H

#include <string>

namespace TPT {

const char * const PARAM_PROG_NAME = "tp-test";
const char * const PARAM_DFLT_ROOT_PATH = "/etc/tp-test";
const char * const PARAM_TESTCASES_DIR = "cases";
const char * const PARAM_TESTCASES_CONFIG_NAME = "descriptor.yaml";
const char * const PARAM_ENVIRON_ROOT = "TPTEST_ROOT";
const char * const PARAM_ENVIRON_DEBUG = "TPTEST_DEBUG";
const char * const PARAM_ENVIRON_INTERACTIVE = "TPTEST_INTERACTIVE";
const char * const PARAM_ENVIRON_TIMEOUT = "TPTEST_TIMEOUT";
const bool PARAM_DFLT_DBG = false;

enum class CMD {
	NONE,
	RUN,
	INFO,
	HELP
};

enum class MODE {
	NONE,
	SCENARIO,
	TEST,
	PRINT
};

class Parameters {
public:
	Parameters(int argc, char *argv[]);
	Parameters(const Parameters &) = default;

	static void usage(void);

	CMD get_cmd() const {
		return m_cmd;
	}

	MODE get_mode() const {
		return m_mode;
	}

	bool get_dbg() const {
		return m_dbg;
	}

	const std::string &get_root() const {
		return m_root;
	}

	const std::string &get_name() const {
		return m_name;
	}

	const std::string &get_log_path() const {
		return m_log_path;
	}

	const std::string &get_test_args() const {
		return m_test_args;
	}

private:
	CMD m_cmd;
	MODE m_mode;
	bool m_dbg;

	std::string m_root;
	std::string m_name;
	std::string m_log_path;
	std::string m_test_args;

	void parse_run_args(int argc, char *argv[]);
	void parse_info_args(int argc, char *argv[]);
};

} /* namespace TPT */

#endif /* TPTPARAMETERS_H */
