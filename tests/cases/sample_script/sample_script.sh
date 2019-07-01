#!/bin/sh

echo "$(basename $0) - $1"
cat << EOF
Hello, this is a runme.sh test script. I added some bigger
text in order to perform a simple test of the logging subsystem.
At this stage it's able to retrieve data from test' stdout/stderr
and append date/time to each line of it.
EOF

exit 0
