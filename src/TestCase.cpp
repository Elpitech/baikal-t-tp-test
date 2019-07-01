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

#include "TestCase.h"
#include "Exception.h"
#include "Parameters.h"

TPT::TestCase::TestCase(const std::string &root, const std::string &id):
						m_id(id), m_title(TESTCASE_DFLT_TEXT),
						m_description(TESTCASE_DFLT_TEXT), m_type(TESTCASETYPE::NONE),
						m_exec(TESTCASE_DFLT_TEXT), m_info(TESTCASE_DFLT_TEXT),
						m_interactive(TESTCASE_DFLT_INTERACTIVE),
						m_timeout_ms(TESTCASE_DFLT_TIMEOUT),
						m_root(root)
{
	std::string path = std::string(PARAM_TESTCASES_DIR) + "/" + id + "/" + PARAM_TESTCASES_CONFIG_NAME;

	try {
		decode_testcase(root + "/" + path);
	} catch (YAML::Exception &e) {
		throw ExcTestCase("%s: %s", path.c_str(), e.what());
	}
}

int TPT::TestCase::push_custom_arg(std::string argname, std::string argval)
{
	default_args_type::iterator it;
	int idx;

	for (it = m_default_args.begin(), idx = 0; it != m_default_args.end(); ++it, ++idx) {
		if (it->first == argname) {
			m_actual_args[idx] = argval;
			m_custom_args[argname] = std::move(argval);
			return RET_SUCCESS;
		}
	}

	return RET_ERROR;
}

void TPT::TestCase::decode_testcase(const std::string &fullpath) {
	YAML::Node root = YAML::LoadFile(fullpath);
	YAML::const_iterator rit;

	if(!root.IsMap()) {
		throw YAML::ParserException(root.Mark(),
									std::string("testcase document must be a map"));
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
		} else if (option == "type") {
			if (!rit->second.IsScalar()) {
				throw YAML::ParserException(rit->second.Mark(),
											std::string("'type' value must a string"));
			}
			m_type = get_type_by_string(rit->second.as<std::string>());

			if (m_type == TPT::TESTCASETYPE::NONE) {
				throw YAML::ParserException(rit->second.Mark(),
							std::string("unsupported type '") + get_string_by_type(m_type) + "'");
			}
		} else if (option == "exec") {
			if (!rit->second.IsScalar()) {
				throw YAML::ParserException(rit->second.Mark(),
											std::string("'exec' value must a string"));
			}
			m_exec = rit->second.as<std::string>();
		} else if (option == "args") {
			if (!rit->second.IsSequence()) {
				throw YAML::ParserException(rit->second.Mark(),
											std::string("'args' node must be a sequence"));
			}
			YAML::const_iterator ait;

			for (ait = rit->second.begin(); ait != rit->second.end(); ++ait) {
				if (!ait->IsMap()) {
					throw YAML::ParserException(rit->first.Mark(),
												std::string("'args' elements must be a map"));
				}
				if (ait->size() != 1) {
					throw YAML::ParserException(rit->first.Mark(),
												std::string("'args' must be a sequence of map pairs"));
				}
				std::string argname, argval;

				argname = ait->begin()->first.as<std::string>();
				if (!ait->begin()->second.IsScalar()) {
					throw YAML::ParserException(rit->first.Mark(),
												std::string("'" + argname + "' value must be a scalar"));
				}

				argval = ait->begin()->second.as<std::string>();
				m_default_args.push_back(std::pair<std::string, std::string>(std::move(argname), std::move(argval)));
			}
		} else if (option == "interactive") {
			if (!rit->second.IsScalar()) {
				throw YAML::ParserException(rit->second.Mark(),
											std::string("'interactive' value must a boolean"));
			}
			m_interactive = rit->second.as<bool>();
		} else if (option == "timeout") {
			if (!rit->second.IsScalar()) {
				throw YAML::ParserException(rit->second.Mark(),
											std::string("'timeout' value must an integer"));
			}
			m_timeout_ms = rit->second.as<unsigned int>();
		} else {
			throw YAML::ParserException(rit->first.Mark(),
										std::string("Uknown node '") + option + "' detected");
		}
	}

	if (m_type == TPT::TESTCASETYPE::NONE) {
		throw YAML::ParserException(YAML::Mark(),
									std::string("'type' node must be specified"));
	}

	if (m_exec == TESTCASE_DFLT_TEXT) {
		throw YAML::ParserException(YAML::Mark(),
									std::string("'exec' node must be non-empty"));
	}

	/* Copy the args to the vector of actual argument pairs. */
	for (default_args_type::iterator it = m_default_args.begin(); it != m_default_args.end(); ++it) {
		m_actual_args.push_back(it->second);
	}
}
