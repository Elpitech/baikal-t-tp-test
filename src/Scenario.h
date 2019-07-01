/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#ifndef TPTSCENARIO_H
#define TPTSCENARIO_H

#include <string>
#include <vector>
#include <yaml-cpp/yaml.h>

#include "Exception.h"
#include "Parameters.h"
#include "TestCase.h"

namespace TPT {

const char * const SCENARIO_DFLT_TEXT = "undefined";

class Scenario {
public:
	Scenario(const std::string &root, const std::string &id);
	Scenario(const std::string &root, const std::string &id, const std::string &args);
	//Scenario(const Scenario &) = default;

	std::string get_id(void) const {
		return m_id;
	}

	std::string get_title(void) const {
		return m_title;
	}

	std::string get_description(void) const {
		return m_description;
	}

	const std::vector<TestCase> &get_testcases(void) const {
		return m_testcases;
	}

	std::string get_root(void) const {
		return m_root;
	}

private:
	std::string m_id;
	std::string m_title;
	std::string m_description;

	std::vector<TestCase> m_testcases;

	std::string m_root;

	void decode_scenario(const std::string &fullpath);
	void decode_testcase(const std::string &id, const YAML::Node &args);
};

} /* namespace TPT */

#endif /* TPTSCENARIO_H */
