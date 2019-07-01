/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#include <string>
#include <thread>
#include <errno.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/prctl.h>
#include <poll.h>
#include <signal.h>
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>

#include "Context.h"
#include "Exception.h"
#include "Logger.h"
#include "Progress.h"

TPT::Context::Context(Logger &log, Progress &prog): m_log(log), m_prog(prog)
{
	preinit_signals();

	create_pipes();
}

TPT::Context::~Context(void)
{
	close_pipes();

	reinit_signals();
}

void TPT::Context::preinit_signals(void)
{
	sigset_t mask;

	m_log.sysdebug("Disable SIGCHLD signal default handler");
 
	/* Block SIGCHLD so it' handler wouldn't interfere with sigtimedwait(). */
	sigemptyset(&mask);
	sigaddset(&mask, SIGCHLD);

	if (sigprocmask(SIG_BLOCK, &mask, nullptr) < 0)
		throw ExcConfig("Couldn't mask the SIGCHLD signal");
}

void TPT::Context::reinit_signals(void)
{
	sigset_t mask;
 
	m_log.sysdebug("Enable SIGCHLD signal default handler");

	sigemptyset(&mask);
	sigaddset(&mask, SIGCHLD);

	(void)sigprocmask(SIG_UNBLOCK, &mask, nullptr);
}

void TPT::Context::create_pipes(void)
{
	int idx, ret;

	m_log.sysdebug("Create stdin/stdout/stderr pipes");

	for (idx = 0; idx < PIPE_TOTAL_INST; idx += PIPE_TOTAL) {
		ret = pipe(&m_pipe.inst[idx]);
		if (ret)
			goto err_close;
	}

	ret = fcntl(m_pipe.out[PIPE_READ], F_SETFL, O_NONBLOCK);
	if (ret < 0)
		goto err_close;

	ret = fcntl(m_pipe.err[PIPE_READ], F_SETFL, O_NONBLOCK);
	if (ret < 0)
		goto err_close;

	ret = fcntl(STDIN_FILENO, F_GETFL);
	if (ret < 0)
		goto err_close;
	ret = fcntl(STDIN_FILENO, F_SETFL, ret | O_NONBLOCK);
	if (ret < 0)
		goto err_close;

	return;

	/* Should have come up with something better, like a smart-pointer with
	 * deallocator... */
err_close:
	for (--idx; idx >= 0; --idx)
		close(m_pipe.inst[idx]);

	throw ExcConfig("Context pipes creation failed");
}

int TPT::Context::attach_pipes(void)
{
	int ret;

	m_log.sysdebug("Attach stdin/stdout/stderr pipes");

	/* Read-side is attached to the test' stdin, so we could send user'
	 * input data there. */
	if (m_pipe.in[PIPE_READ] != STDIN_FILENO) {
		ret = dup2(m_pipe.in[PIPE_READ], STDIN_FILENO);
		if (ret < 0)
			return errno;
	}

	/* Write-side is attached to the test' stdout, so we could poll the data
	 * on the read-side absorbing everithing test prints. */
	if (m_pipe.out[PIPE_WRITE] != STDOUT_FILENO) {
		ret = dup2(m_pipe.out[PIPE_WRITE], STDOUT_FILENO);
		if (ret < 0)
			return errno;
	}

	/* The same as for stdout. */
	if (m_pipe.err[PIPE_WRITE] != STDERR_FILENO) {
		ret = dup2(m_pipe.err[PIPE_WRITE], STDERR_FILENO);
		if (ret < 0)
			return errno;
	}

	return 0;
}

void TPT::Context::close_pipes(void)
{
	int idx, ret;

	m_log.sysdebug("Close stdin/stdout/stderr pipes");

	ret = fcntl(STDIN_FILENO, F_GETFL);
	if (ret >= 0)
		fcntl(STDIN_FILENO, F_SETFL, ret & ~O_NONBLOCK);

	for (idx = 0; idx < PIPE_TOTAL_INST; ++idx)
		close(m_pipe.inst[idx]);
}

int TPT::Context::read_appout(int fd, std::string &strbuf, const std::string &sts,
							  const TestCase &tc)
{
	int start, end;
	ssize_t ret;

	while ((ret = read(fd, m_charbuf, PIPE_BUF_SIZE)) > 0) {
		for (start = 0, end = 0; end < ret; ++end) {
			if (m_charbuf[end] == '\n') {
				std::string line(&m_charbuf[start], (end - start));

				m_log.printf(tc.get_id(), sts, strbuf + line);
				if (tc.get_interactive())
					m_prog.println(tc, line);
				start = end + 1;
				strbuf.clear();
			}
		}
		if (start < end) {
			std::string leftover(&m_charbuf[start], (end - start));
			strbuf += leftover;

			if (tc.get_interactive())
				m_prog.printst(tc, leftover);
		}
	}
	if (ret < 0 && (errno != EAGAIN && errno != EWOULDBLOCK)) {
		m_log.syserror("Failed to read from std-stream");
		return errno;
	}

	return RET_SUCCESS;
}

int TPT::Context::read_stdin(const TestCase &tc)
{
	ssize_t ret, len;
	int start, end;

	while ((ret = read(STDIN_FILENO, m_charbuf, PIPE_BUF_SIZE)) > 0) {
		for (start = 0, end = 0; end < ret; ++end) {
			if (m_charbuf[end] == '\n') {
				len = (end - start);
				std::string line(&m_charbuf[start], len);

				m_prog.println(tc, line);
				ret = write(m_pipe.in[PIPE_WRITE], &m_charbuf[start], len + 1);
				if (ret != (len + 1))
					m_log.syserror("Failed to pass text to test (%zd)", ret);
				start = end + 1;
			}
		}
		if (start < end) {
			len = (end - start);
			m_prog.printst(tc, std::string(&m_charbuf[start], len));
			ret = write(m_pipe.in[PIPE_WRITE], &m_charbuf[start], len);
			if (ret != len)
				m_log.syserror("Failed to pass text to test (%zd)", ret);
		}
	}
	if (ret < 0 && (errno != EAGAIN && errno != EWOULDBLOCK)) {
		m_log.syserror("Failed to read from stdin");
		return errno;
	}

	return RET_SUCCESS;
}

void TPT::Context::flush_stdin(void)
{
	m_log.sysdebug("Flush garbage from stdin");

	tcdrain(STDIN_FILENO);
	tcflush(STDIN_FILENO, TCIFLUSH);
}

void TPT::Context::flush_appout(const TestCase &tc)
{
	m_log.sysdebug("Flush stdout/stderr log-buffers");

	for (int idx = 0; idx < POLL_BUFS; ++idx) {
		if (!m_strbuf[idx].empty()) {
			const std::string &sts = (idx == POLL_OUT ?
									  TPT::Logger::INFOSTS : TPT::Logger::ERRSTS);

			m_log.printf(tc.get_id(), sts, m_strbuf[idx]);
			m_strbuf[idx].clear();
		}
	}
}

void TPT::Context::service(const TestCase &tc)
{
	struct pollfd pfds[POLL_TOTAL] = {0};
	int ret, fds_count = POLL_TOTAL - 1;

	pfds[POLL_OUT].fd = m_pipe.out[PIPE_READ];
	pfds[POLL_OUT].events = POLLIN | POLLPRI;
	pfds[POLL_ERR].fd = m_pipe.err[PIPE_READ];
	pfds[POLL_ERR].events = POLLIN | POLLPRI;
	pfds[POLL_SYNC].fd = m_pipe.sync[PIPE_READ];
	pfds[POLL_SYNC].events = POLLIN | POLLPRI;
	if (tc.get_interactive()) {
		pfds[POLL_STDIN].fd = STDIN_FILENO;
		pfds[POLL_STDIN].events = POLLIN | POLLPRI;
		fds_count = POLL_TOTAL;
		flush_stdin();
	}

	m_log.sysdebug("Start stdin/stdout/stderr polling");

	do {
		ret = poll(pfds, fds_count, -1);
		if (ret < 0 && errno != EINTR) {
			m_log.syserror("Failed to poll test output streams");
			break;
		}
		if (pfds[POLL_OUT].revents & POLLIN || pfds[POLL_OUT].revents & POLLPRI) {
			ret = read_appout(pfds[POLL_OUT].fd, m_strbuf[POLL_OUT], TPT::Logger::INFOSTS, tc);
			if (ret != RET_SUCCESS)
				break;
		}
		if (pfds[POLL_ERR].revents & POLLIN || pfds[POLL_ERR].revents & POLLPRI) {
			ret = read_appout(pfds[POLL_ERR].fd, m_strbuf[POLL_ERR], TPT::Logger::ERRSTS, tc);
			if (ret != RET_SUCCESS)
				break;
		}
		if (pfds[POLL_STDIN].revents & POLLIN || pfds[POLL_STDIN].revents & POLLPRI) {
			ret = read_stdin(tc);
			if (ret != RET_SUCCESS)
				break;
		}
		if (pfds[POLL_SYNC].revents & POLLIN || pfds[POLL_SYNC].revents & POLLPRI) {
			(void)read(m_pipe.sync[PIPE_READ], m_charbuf, PIPE_BUF_SIZE);
			flush_appout(tc);
			break;
		}
	} while (true);
}

int TPT::Context::launch_thread(const TestCase &tc)
{
	m_log.sysdebug("Launch service thread for '%s' test", tc.get_id().c_str());

	/* If thread is still joinable the new context setting shall cause an
	 * exception so return an error. */
	if (m_service.joinable()) {
		m_log.syserror("Failed to launch context thread");
		return RET_ERROR;
	}

	m_service = std::thread(&Context::service, this, tc);

	return 0;
}

void TPT::Context::join_thread(void)
{
	char c = 's';
	ssize_t ret;

	m_log.sysdebug("Join service thread");

	ret = write(m_pipe.sync[PIPE_WRITE], &c, 1);
	if (ret != 1)
		m_log.syserror("Failed to send a 'term' key to the service thread (%zd)", ret);

	m_service.join();
}

TPT::STATUS TPT::Context::launch_process(const TestCase &tc)
{
	pid_t cpid, ppid;
	TPT::STATUS sts;
	int ret = 0;

	ppid = getpid();

	ret = launch_thread(tc);
	if (ret)
		return TPT::STATUS::ERROR;

	m_log.sysdebug("Launch test '%s' process", tc.get_id().c_str());

	cpid = fork();
	if (cpid == -1) {
		m_log.syserror("Failed to fork '%s' testcase process", tc.get_id().c_str());
		goto err_clear_contex;
	} else if (cpid == 0) {

		reinit_signals();

		ret = attach_pipes();
		if (!ret)
			ret = execvp_testcase(tc, ppid);

		/* Child should never reach the next line. */
		_exit(ret);
	}

	sts = waitpid_timeout(tc, cpid);

err_clear_contex:
	join_thread();

	return sts;
}

int TPT::Context::execvp_testcase(const TestCase &tc, pid_t ppid)
{
	const TestCase::actual_args_type sargs = tc.get_actual_args();
	std::unique_ptr<char*[]> cargs(new char*[sargs.size() + 2]);
	std::string path = tc.get_exec_path();
	unsigned int idx;
	char cstr[16];
	int ret;

	ret = prctl(PR_SET_PDEATHSIG, SIGTERM);
	if (ret == -1)
		return errno;

	if (getppid() != ppid)
		return RET_ERROR;

	if (setenv(TPT::PARAM_ENVIRON_ROOT, tc.get_root().c_str(), true))
		return errno;

	if (setenv(TPT::PARAM_ENVIRON_DEBUG, m_log.get_dbg() ? "y" : "n", true))
		return errno;

	snprintf(cstr, 16, "%u", tc.get_interactive());
	if (setenv(TPT::PARAM_ENVIRON_INTERACTIVE, cstr, true))
		return errno;

	snprintf(cstr, 16, "%u", tc.get_timeout_ms());
	if (setenv(TPT::PARAM_ENVIRON_TIMEOUT, cstr, true))
		return errno;

	/* Discard const qualifier, execvp will make it const again. */
	cargs[0] = const_cast<char *>(path.c_str());
	for (idx = 0; idx < sargs.size(); ++idx) {
		cargs[idx + 1] = const_cast<char *>(sargs[idx].c_str());
	}
	cargs[idx + 1] = nullptr;

	(void)execvp(cargs[0], cargs.get());

	return errno;
}

TPT::STATUS TPT::Context::waitpid_timeout(const TestCase &tc, pid_t cpid)
{
    struct timespec timeout;
	TPT::STATUS sts;
	sigset_t mask;
	int ret = 0;

	m_log.sysdebug("Wait for the test '%s' to complete with timeout %u ms",
				tc.get_id().c_str(), tc.get_timeout_ms());

	sigemptyset(&mask);
    sigaddset(&mask, SIGCHLD);

	timeout.tv_sec = tc.get_timeout_ms() / 1000;
    timeout.tv_nsec = (tc.get_timeout_ms() % 1000) * 1000000;

	/* Wait for SIGCHLD being raised by the child testcase process. */
	do {
		ret = sigtimedwait(&mask, NULL, &timeout);
		if (ret < 0 && errno == EINTR) {
			/* Woke up by some other signal, so just continue. */
			continue;
		} else if (ret < 0 && errno == EAGAIN) {
			m_log.sysinfo("Test '%s' got timeout of %u ms. Terminating it",
						  tc.get_id().c_str(), tc.get_timeout_ms());
			kill(cpid, SIGTERM);
			sts = TPT::STATUS::FAIL;
			break;
		} else if (ret < 0) {
			m_log.syserror("Invalid waittest config (%d)", errno);
			sts = TPT::STATUS::ERROR;
			break;
		} else /* Got SIGCHLD. */ {
			ret = 0;
			sts = TPT::STATUS::PASS;
			break;
		}
    } while (1);

    if (waitpid(cpid, &ret, 0) < 0) {
		m_log.syserror("Failed to perform waittest");
        return TPT::STATUS::ERROR;
    }

	m_log.sysdebug("Test process exit value 0x%04x", ret);

	/* Set FAIL status if test returned a non-zero value. */
	if (sts == TPT::STATUS::PASS) {
		ret = WEXITSTATUS(ret);
		if (ret) {
			sts = TPT::STATUS::FAIL;
			m_log.sysinfo("Test '%s' exited with status %d", tc.get_id().c_str(), ret);
		} else {
			sts = TPT::STATUS::PASS;
		}
	}

	return sts;
}
