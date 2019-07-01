/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#ifndef TPTCONTEXT_H
#define TPTCONTEXT_H

#include <string>
#include <thread>
#include <sys/types.h>

#include "Exception.h"
#include "Logger.h"
#include "Progress.h"
#include "TestCase.h"

namespace TPT {

enum PIPE {
	PIPE_READ = 0,
	PIPE_WRITE = 1,
	PIPE_TOTAL = 2,
	PIPE_TOTAL_INST = 4 * PIPE_TOTAL,
	PIPE_BUF_SIZE = 512
};

enum POLL {
	POLL_OUT = 0,
	POLL_ERR,
	POLL_BUFS,
	POLL_SYNC = POLL_BUFS,
	POLL_STDIN,
	POLL_TOTAL
};

class Context {
public:
	Context(Logger &log, Progress &prog);
	~Context(void);

	TPT::STATUS launch_testcase(const TestCase &tc) {
		return launch_process(tc);
	}

private:
	Logger &m_log;
	Progress &m_prog;

	std::thread m_service;
	std::string m_strbuf[POLL_BUFS];
	char m_charbuf[PIPE_BUF_SIZE];

	union {
		struct {
			int in[PIPE_TOTAL];  /* test-app stdin */
			int out[PIPE_TOTAL]; /* test-app stdout */
			int err[PIPE_TOTAL]; /* test-app stderr */
			int sync[PIPE_TOTAL];/* local pipe */
		};
		int inst[PIPE_TOTAL_INST];
	} m_pipe;

	void preinit_signals(void);
	void reinit_signals(void);
	void create_pipes(void);
	int attach_pipes(void);
	void close_pipes(void);

	int execvp_testcase(const TestCase &tc, pid_t ppid);
	TPT::STATUS waitpid_timeout(const TestCase &tc, pid_t cpid);
	TPT::STATUS launch_process(const TestCase &testcase);

	int read_appout(int fd, std::string &strbuf, const std::string &sts,
					const TestCase &tc);
	int read_stdin(const TestCase &tc);
	void flush_appout(const TestCase &testcase);
	void flush_stdin(void);
	void service(const TestCase &testcase);
	int launch_thread(const TestCase &testcase);
	void join_thread(void);
};
} /* namespace TPT */

#endif /* TPTCONTEXT_H */
