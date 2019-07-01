/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#include <string>
#include <vector>
#include <map>
#include <utility>
#include <yaml-cpp/yaml.h>

#include "Scenario.h"
#include "Exception.h"
#include "Parameters.h"
#include "TestCase.h"

TPT::Scenario::Scenario(const std::string &root, const std::string &id):
						m_id(id), m_title(SCENARIO_DFLT_TEXT),
						m_description(SCENARIO_DFLT_TEXT), m_root(root)
{
	std::string path = id + ".yaml";

	try {
		decode_scenario(root + "/" + path);
	} catch (YAML::Exception &e) {
		throw ExcTestCase("%s: %s", path.c_str(), e.what());
	} catch (TPT::Exception &e) {
		throw;
	}
}

TPT::Scenario::Scenario(const std::string &root, const std::string &id,
						const std::string &args):
						m_id(id), m_title(SCENARIO_DFLT_TEXT),
						m_description(SCENARIO_DFLT_TEXT), m_root(root)
{
	try {
		YAML::Node node = YAML::Load(args);

		decode_testcase(id, node);
	} catch (YAML::Exception &e) {
		throw ExcTestCase("%s: %s", args.c_str(), e.what());
	} catch (TPT::Exception &e) {
		throw;
	}
}

void TPT::Scenario::decode_scenario(const std::string &fullpath) {
	YAML::Node root = YAML::LoadFile(fullpath);
	YAML::const_iterator rit;

	if(!root.IsMap()) {
		throw YAML::ParserException(root.Mark(),
									std::string("scenario document must be a map"));
	}

	for (rit = root.begin(); rit != root.end(); ++rit) {
		std::string option = rit->first.as<std::string>();

		if (option == "title") {
			if (!rit->second.IsScalar()) {
				throw YAML::ParserException(rit->second.Mark(),
											std::string("'title' value must a string"));
			}
			m_title = rit->second.as<std::string>();
		} else if (option == "description") {
			if (!rit->second.IsScalar()) {
				throw YAML::ParserException(rit->second.Mark(),
											std::string("'description' value must a string"));
			}
			m_description = rit->second.as<std::string>();
		} else if (option == "tests") {
			if (!rit->second.IsSequence()) {
				throw YAML::ParserException(rit->second.Mark(),
											std::string("'tests' node must be a sequence"));
			}
			YAML::const_iterator tit;

			for (tit = rit->second.begin(); tit != rit->second.end(); ++tit) {
				if (!tit->IsMap()) {
					throw YAML::ParserException(rit->first.Mark(),
												std::string("'tests' elements must be a map"));
				}
				if (tit->size() != 1) {
					throw YAML::ParserException(tit->first.Mark(),
												std::string("'tests' must be a sequence of map pairs"));
				}

				decode_testcase(tit->begin()->first.as<std::string>(), tit->begin()->second);
			}
		} else {
			throw YAML::ParserException(rit->first.Mark(),
								  		std::string("Uknown node '") + option + "' detected");
		}
	}
}

void TPT::Scenario::decode_testcase(const std::string &id, const YAML::Node &args)
{
	TPT::TestCase tc(m_root, id);
	YAML::const_iterator ait;

	if (!args.IsMap() && !args.IsNull()) {
		throw YAML::ParserException(args.Mark(),
									std::string("Custom parameters list must be a map or empty"));
	}

	for (ait = args.begin(); ait != args.end(); ++ait) {
		std::string argname = ait->first.as<std::string>();

		if (argname == "info") {
			tc.set_info(ait->second.as<std::string>());
		} else {
			int ret = tc.push_custom_arg(argname, ait->second.as<std::string>());
			if (ret != RET_SUCCESS) {
				throw YAML::ParserException(ait->second.Mark(),
											std::string("Arg '") + argname + "' doesn't exist in test '" + id + "'");
			}
		}
	}
	m_testcases.push_back(std::move(tc));
}
