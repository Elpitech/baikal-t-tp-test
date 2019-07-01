/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#include <iostream>
#include <unistd.h>
#include <getopt.h>

#include "Parameters.h"
#include "Exception.h"

void TPT::Parameters::usage(void)
{
	std::cout << "Usage: " << PARAM_PROG_NAME << " <command> [options]" << std::endl <<
	std::endl <<
	"  T-platforms embedded system tests framework. Mainly it is responsible for" << std::endl <<
	"  target platforms functional and hardware tests, described by means of the YAML" << std::endl <<
	"  config-files of the tests scenario and themselfs." << std::endl <<
	std::endl <<
	"Commads:" << std::endl <<
	"  run - Execute the passed scenario or test (options -s/-t are mutually exclusive)." << std::endl <<
	"    -r,--root <path>     - Path to the framework configs directory ('" << PARAM_DFLT_ROOT_PATH << "' by default)." << std::endl <<
	"    -s,--scenario <name> - Scenario name ('<root>/<name>.yaml' basename without extension)." << std::endl <<
	"    -t,--test <name>     - Individual testcase name ('<root>/" << PARAM_TESTCASES_DIR << "/<name>' directory name" << std::endl <<
	"                           with the '" << PARAM_TESTCASES_CONFIG_NAME << " test descriptor file)." << std::endl <<
	"      -a,--args <args>   - Arguments list being passed to the individual test" << std::endl <<
	"                           in YAML nested mapping syntax - '{info: \"\", arg1: \"\", ...}'." << std::endl <<
	"    -l,--log <path>      - Log-file name (<name>.log by default)." << std::endl <<
	"    -d,--debug           - Print debug messages to the log-file." << std::endl <<
	"  info - Print an info of scenario/test (options -s/-t/-p are mutually exclusive)." << std::endl <<
	"    -r,--root <path>     - Path to the framework configs directory ('" << PARAM_DFLT_ROOT_PATH << "' by default)." << std::endl <<
	"    -s,--scenario <name> - Scenario name ('<root>/<name>.yaml' basename without extension)." << std::endl <<
	"    -t,--test <name>     - Individual testcase name ('<root>/" << PARAM_TESTCASES_DIR << "/<name>' directory name" << std::endl <<
	"                           with the '" << PARAM_TESTCASES_CONFIG_NAME << " test descriptor file)." << std::endl <<
	"    -p,--print           - Print info of all scenario/tests found in the '<root>' directory" << std::endl <<
	"                           (this is also helpful for checking the config-files syntax)." << std::endl <<
	"  help - Print this help message." << std::endl <<
	std::endl;
}

TPT::Parameters::Parameters(int argc, char *argv[]): m_cmd(CMD::NONE), m_mode(MODE::NONE),
													 m_dbg(PARAM_DFLT_DBG), m_root(PARAM_DFLT_ROOT_PATH)
{
	if (argc < 2)
		throw ExcArg("Too few arguments");

	std::string cmd = argv[1];
	optind++;
	opterr = 0;
	if (cmd == "run") {
		m_cmd = CMD::RUN;
		parse_run_args(argc, argv);
	} else if (cmd == "info") {
		m_cmd = CMD::INFO;
		parse_info_args(argc, argv);
	} else if (cmd == "help") {
		m_cmd = CMD::HELP;
		if (argc != optind)
			throw ExcArg("'help' command doesn't accept any arguments");
	} else {
		throw ExcArg("Invalid command %s", cmd.c_str());
	}

	if (argc != optind)
		throw ExcArg("Too many arguments");
}

void TPT::Parameters::parse_run_args(int argc, char *argv[])
{
	const char* const short_opts = ":r:s:t:a:l:d";
	const option long_opts[] = {
		{"root", required_argument, nullptr, 'r'},
		{"scenario", required_argument, nullptr, 's'},
		{"test", required_argument, nullptr, 't'},
		{"args", required_argument, nullptr, 'a'},
		{"log", required_argument, nullptr, 'l'},
		{"debug", no_argument, nullptr, 'd'},
	};
	int opt;

	while ((opt = getopt_long(argc, argv, short_opts, long_opts, nullptr)) != -1) {
		switch (opt) {
		case 'r':
			m_root = optarg;
			break;
		case 's':
			if (m_mode != MODE::NONE)
				throw ExcArg("Command 'run' options -s/-t are mutual exclusive");

			m_mode = MODE::SCENARIO;
			m_name = optarg;
			if (m_log_path == "")
				m_log_path = m_name + ".log";
			break;
		case 't':
			if (m_mode != MODE::NONE)
				throw ExcArg("Command 'run' options -s/-t are mutual exclusive");

			m_mode = MODE::TEST;
			m_name = optarg;
			if (m_log_path == "")
				m_log_path = m_name + ".log";
			break;
		case 'a':
			m_test_args = optarg;
			break;
		case 'l':
			m_log_path = optarg;
			break;
		case 'd':
			m_dbg = true;
			break;
		case ':':
			throw ExcArg("Option -%c requires an operand", (char)optopt);
			break;
		case '?':
			throw ExcArg("Invalid argument -%c of the 'run' command", (char)optopt);
			break;
		default:
			break;
		}
	}

	if (m_mode == MODE::NONE)
		throw ExcArg("One of the -s/-t options must be specified for the 'run' command");

	if (m_mode != MODE::TEST && !m_test_args.empty())
		throw ExcArg("Option -a is supported by the direct test execution mode only");
}

void TPT::Parameters::parse_info_args(int argc, char *argv[])
{
	const char* const short_opts = ":r:s:t:p";
	const option long_opts[] = {
		{"root", required_argument, nullptr, 'r'},
		{"scenario", required_argument, nullptr, 's'},
		{"test", required_argument, nullptr, 't'},
		{"print", no_argument, nullptr, 'p'},
	};
	int opt;

	while ((opt = getopt_long(argc, argv, short_opts, long_opts, nullptr)) != -1) {
		switch (opt) {
		case 'r':
			m_root = optarg;
			break;
		case 's':
			if (m_mode != MODE::NONE)
				throw ExcArg("Command 'info' options -s/-t/-p are mutual exclusive");

			m_mode = MODE::SCENARIO;
			m_name = optarg;
			break;
		case 't':
			if (m_mode != MODE::NONE)
				throw ExcArg("Command 'info' options -s/-t/-p are mutual exclusive");

			m_mode = MODE::TEST;
			m_name = optarg;
			break;
		case 'p':
			if (m_mode != MODE::NONE)
				throw ExcArg("Command 'info' options -s/-t/-p are mutual exclusive");

			m_mode = MODE::PRINT;
			break;
		case ':':
			throw ExcArg("Option -%c requires an operand", (char)optopt);
			break;
		case '?':
			throw ExcArg("Invalid argument -%c", (char)optopt);
			break;
		default:
			break;
		}
	}

	if (m_mode == MODE::NONE)
		throw ExcArg("One of the -s/-t/-p options must be specified for the 'info' command");
}
