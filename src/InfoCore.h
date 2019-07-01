/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#ifndef TPTINFOCORE_H
#define TPTINFOCORE_H

#include <vector>

#include "Exception.h"
#include "Core.h"
#include "Parameters.h"
#include "Scenario.h"
#include "TestCase.h"

namespace TPT {

class InfoCore: public Core {
public:
	InfoCore(const Parameters &params);

	virtual void exec(void) override;

private:
	std::vector<Scenario> m_scenarios;
	std::vector<TestCase> m_testcases;

	void scan_scenarios(const std::string &root);
	void scan_testcases(const std::string &root);

	void print_scenario(const Scenario &scenario);
	void print_testcase(const TestCase &testcases);
};

} /* namespace TPT */

#endif /* TPTINFOCORE_H */
