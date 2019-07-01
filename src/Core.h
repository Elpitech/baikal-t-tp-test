/* vi: set ts=4 sw=4 cindent :
 *
 * $Id$
 *
 * Copyright (C) 2019, T-Platforms JSC (fancer.lancer@gmail.com)
 */
#ifndef TPTCORE_H
#define TPTCORE_H

namespace TPT {

class Core {
public:
	virtual void exec(void) = 0;
};

} /* namespace TPT */

#endif /* TPTCORE_H */
