/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#include <string>
#include <cstring>
#include <sstream>
#include <vector>
#include <map>
#include <sys/types.h>
#include <dirent.h>
#include <errno.h>

#include "InfoCore.h"
#include "Exception.h"
#include "Parameters.h"
#include "Scenario.h"
#include "TestCase.h"

TPT::InfoCore::InfoCore(const Parameters &params)
{
	MODE mode = params.get_mode();

	switch (mode) {
	case MODE::SCENARIO:
		m_scenarios.push_back(Scenario(params.get_root(), params.get_name()));
		break;
	case MODE::TEST:
		m_testcases.push_back(TestCase(params.get_root(), params.get_name()));
		break;
	case MODE::PRINT:
		scan_scenarios(params.get_root());
		scan_testcases(params.get_root());
	case MODE::NONE:
	default:
		break;
	}
}

void TPT::InfoCore::exec(void)
{
	for (std::vector<Scenario>::iterator it = m_scenarios.begin(); it != m_scenarios.end(); ++it) {
		print_scenario(*it);
	}
	for (std::vector<TestCase>::iterator it = m_testcases.begin(); it != m_testcases.end(); ++it) {
		print_testcase(*it);
	}
}

void TPT::InfoCore::scan_scenarios(const std::string &root)
{
	std::vector<std::string> scs;
	struct dirent *ent;
	DIR *dir;

	errno = 0;
	dir = opendir(root.c_str());
	if (!dir)
		throw ExcIOAaccess("Failed to list scenarios <root> directory (%d)", errno);

	while ((ent = readdir(dir))) {
		std::string name;
		if (ent->d_type != DT_REG)
			continue;

		name = ent->d_name;
		if (name.substr(name.length() - 5, 5) == ".yaml")
			scs.push_back(name.substr(0, name.length() - 5));
    }
	closedir(dir);
	if (errno)
		throw ExcIOAaccess("Failed to get scenario <root> directory entry (%d)", errno);

	for (std::vector<std::string>::iterator sit = scs.begin(); sit != scs.end(); ++sit) {
		m_scenarios.push_back(Scenario(root, *sit));
	}
}

void TPT::InfoCore::scan_testcases(const std::string &root)
{
	std::vector<std::string> tsts;
	struct dirent *ent;
	std::string name;
	DIR *dir;

	errno = 0;
	dir = opendir((root + "/" + PARAM_TESTCASES_DIR).c_str());
	if (!dir)
		throw ExcIOAaccess("Failed to list testcases <root> directory (%d)", errno);

	while ((ent = readdir(dir))) {
		if (ent->d_type != DT_DIR)
			continue;

		if (!strncmp(".", ent->d_name, 256) || !strncmp("..", ent->d_name, 256))
			continue;

		tsts.push_back(std::string(ent->d_name));
    }
	closedir(dir);
	if (errno)
		throw ExcIOAaccess("Failed to get testcase <root> directory entry (%d)", errno);

	for (std::vector<std::string>::iterator tit = tsts.begin(); tit != tsts.end(); ++tit) {
		m_testcases.push_back(TestCase(root, *tit));
	}
}

void TPT::InfoCore::print_scenario(const Scenario &scenario)
{
	std::stringstream buf, tmp;
	size_t size, length;
	std::string line;
	int idx = 0;

	buf << "Scenario '" << scenario.get_id() << "'" << std::endl;
	buf << "  title: " << scenario.get_title() << std::endl;
	buf << "  description:" << std::endl;

	tmp.str(scenario.get_description());
	while (getline(tmp, line)) {
		buf << "    " << line << std::endl;
	}

	/* Magic algorithm of the tests info formatted printing.) */
	const std::vector<TestCase> &tests = scenario.get_testcases();
	size = tests.size();
	buf << "  tests: " << size << std::endl;
	for (std::vector<TestCase>::const_iterator tit = tests.begin(); tit != tests.end(); ++tit) {
		buf << "    (" << ++idx << "/" << size << ") " <<
			tit->get_id() << " - " << tit->get_info() << std::endl;

		const TestCase::custom_args_type &args = tit->get_custom_args();
		length = 6;
		for (TestCase::custom_args_type::const_iterator ait = args.begin(); ait != args.end(); ++ait) {
			if (length == 6)
				buf << "      ";
			buf << ait->first << ": '" << ait->second << "'";
			if (std::next(ait, 1) != args.end())
				buf << ", ";
			length += (ait->first.length() + ait->second.length() + 6);
			if (length >= 70 || std::next(ait, 1) == args.end()) {
				length = 6;
				buf << std::endl;
			}
		}
	}

	std::cout << buf.rdbuf();
}

void TPT::InfoCore::print_testcase(const TestCase &testcases)
{
	std::stringstream buf, tmp;
	std::string line;
	size_t length;
	int idx = 0;

	buf << "Testcase '" << testcases.get_id() << "'" << std::endl;
	buf << "  title: " << testcases.get_title() << std::endl;
	buf << "  description:" << std::endl;

	tmp.str(testcases.get_description());
	while (getline(tmp, line)) {
		buf << "    " << line << std::endl;
	}

	buf << "  type: " << TestCase::get_string_by_type(testcases.get_type()) << std::endl;
	buf << "  exec: " << testcases.get_exec() << std::endl;

	/* Magic algorithm of the arguments formatted printing.) */
	const TestCase::default_args_type &args = testcases.get_default_args();
	if (args.size() > 0)
		buf << "  args: " << std::endl;
	length = 4;
	for (TestCase::default_args_type::const_iterator ait = args.begin(); ait != args.end(); ++ait) {
		if (length == 4)
			buf << "    ";
		buf << "[" << ++idx << "] " << ait->first << ": '" << ait->second << "'";
		if (std::next(ait, 1) != args.end())
			buf << ", ";
		length += (ait->first.length() + ait->second.length() + 10);
		if (length >= 70 || std::next(ait, 1) == args.end()) {
			length = 4;
			buf << std::endl;
		}
	}

	buf << "  interactive: " << std::boolalpha << testcases.get_interactive() << std::endl;
	buf << "  timeout: " << testcases.get_timeout_ms() << " ms" << std::endl;
	std::cout << buf.rdbuf();
}
