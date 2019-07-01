/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#ifndef TPTRUNCORE_H
#define TPTRUNCORE_H

#include <vector>

#include "Core.h"
#include "Parameters.h"
#include "Logger.h"
#include "Progress.h"
#include "Context.h"
#include "Scenario.h"

namespace TPT {

class RunCore: public Core {
	static Scenario scenario_initializer(const Parameters &params) {
		if (params.get_mode() == TPT::MODE::SCENARIO)
			return Scenario(params.get_root(), params.get_name());
		else /* if mode == TPT::MODE::TEST */
			return Scenario(params.get_root(), params.get_name(), params.get_test_args());
	}

public:
	RunCore(const Parameters &params): m_log(params), m_prog(params, m_log),
									   m_ctx(m_log, m_prog),
									   m_scenario(scenario_initializer(params)) {}

	virtual void exec(void) override;

private:
	Logger m_log;
	Progress m_prog;
	Context m_ctx;
	Scenario m_scenario;
};

} /* namespace TPT */

#endif /* TPTRUNCORE_H */
