/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#ifndef TPTTESTCASE_H
#define TPTTESTCASE_H

#include <string>
#include <vector>
#include <map>
#include <utility>

#include "Exception.h"
#include "Parameters.h"

namespace TPT {

const char * const TESTCASE_DFLT_TEXT = "undefined";
const bool TESTCASE_DFLT_INTERACTIVE = false;
const int TESTCASE_DFLT_TIMEOUT = 1000;

enum class TESTCASETYPE {
	NONE,
	LOCALFILE,
	COMMAND
};

class TestCase {
public:
	typedef std::map<std::string, std::string> custom_args_type;
	typedef std::vector<std::pair<std::string, std::string>> default_args_type;
	typedef std::vector<std::string> actual_args_type;

	TestCase(const std::string &root, const std::string &id);

	std::string get_id(void) const {
		return m_id;
	}

	std::string get_title(void) const {
		return m_title;
	}

	std::string get_description(void) const {
		return m_description;
	}

	void set_description(std::string description) {
		m_description = std::move(description);
	}

	TESTCASETYPE get_type(void) const {
		return m_type;
	}

	static std::string get_string_by_type(TESTCASETYPE type) {
		if (type == TESTCASETYPE::LOCALFILE)
			return "localfile";
		else if (type == TESTCASETYPE::COMMAND)
			return "command";

		return "unknown";
	}

	static TESTCASETYPE get_type_by_string(std::string type) {
		if (type == "localfile")
			return TESTCASETYPE::LOCALFILE;
		else if (type == "command")
			return TESTCASETYPE::COMMAND;
		
		return TESTCASETYPE::NONE;
	}

	std::string get_exec(void) const {
		return m_exec;
	}

	std::string get_exec_path(void) const {
		if (m_type == TESTCASETYPE::LOCALFILE)
			return m_root + "/" + std::string(PARAM_TESTCASES_DIR) + "/" + m_id + "/" + m_exec;

		return m_exec;
	}

	std::string get_root(void) const {
		return m_root;
	}

	std::string get_info(void) const {
		return m_info;
	}

	void set_info(std::string info) {
		m_info = std::move(info);
	}

	bool get_interactive(void) const {
		return m_interactive;
	}

	unsigned int get_timeout_ms(void) const {
		return m_timeout_ms;
	}

	int push_custom_arg(std::string argname, std::string argval);

	/* Yeah, I should have created something cleverer... */
	const custom_args_type &get_custom_args(void) const {
		return m_custom_args;
	}

	const default_args_type &get_default_args(void) const {
		return m_default_args;
	}

	const actual_args_type &get_actual_args(void) const {
		return m_actual_args;
	}

private:
	std::string m_id;
	std::string m_title;
	std::string m_description;
	TESTCASETYPE m_type;
	std::string m_exec;

	std::string m_info;
	std::string m_dir;

	custom_args_type m_custom_args;
	default_args_type m_default_args;
	actual_args_type m_actual_args;

	bool m_interactive;
	unsigned int m_timeout_ms;

	std::string m_root;

	void decode_testcase(const std::string &fullpath);
};

} /* namespace TPT */

#endif /* TPTTESTCASE_H */
