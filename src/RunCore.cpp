/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#include <vector>

#include "RunCore.h"
#include "Exception.h"
#include "Parameters.h"
#include "Scenario.h"
#include "TestCase.h"

void TPT::RunCore::exec(void) {
	const std::vector<TestCase> &tcs = m_scenario.get_testcases();
	std::vector<TestCase>::const_iterator it;
	TPT::STATUS sts;

	m_prog.header(m_scenario);

	for (it = tcs.begin(); it != tcs.end(); ++it) {
		m_prog.start_test(*it);
		sts = m_ctx.launch_testcase(*it);
		m_prog.finish_test(*it, sts);
	}

	m_prog.summary();
}
