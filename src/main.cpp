/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#include <iostream>
#include <chrono>
#include <thread>

#include "Exception.h"
#include "Parameters.h"
#include "InfoCore.h"
#include "RunCore.h"

int main(int argc, char *argv[], char *env[])
{
	try {
		TPT::Parameters params(argc, argv);
		TPT::CMD cmd = params.get_cmd();

		if (cmd == TPT::CMD::HELP) {
			TPT::Parameters::usage();
		} else if (cmd == TPT::CMD::INFO) {
			TPT::InfoCore info(params);
			info.exec();
		} else /* if (cmd == TPT::CMD::RUN) */ {
			TPT::RunCore run(params);
			run.exec();
		}
	} catch (TPT::Exception &e) {
		return e.handle_me();
	} catch (std::exception &e) {
		return TPT::Exception::handle_std(e);
	}

	return static_cast<int>(TPT::ERR::NO);
}
