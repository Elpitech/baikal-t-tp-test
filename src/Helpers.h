/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#ifndef TPTHELPERS_H
#define TPTHELPERS_H

#include <string>

namespace TPT {

template<typename ... Args>
const std::string std_sprintf(const std::string &fmt, Args && ...args) {
	int size = snprintf(nullptr, 0, fmt.c_str(), args...);
	std::string str;

	str.resize(size);
	snprintf(&str[0], size + 1, fmt.c_str(), args...);

	return str;
}

}

#endif /* TPTHELPERS_H */
