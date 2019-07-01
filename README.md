# T-platforms Test Framework (TP-test)

*TP-test* is a test framework for T-platforms embedded products. It consists of a
written in *C++* core tests runner and a set of programs/scripts, which are
created to cover specific test cases. The core part is designed to be
lightweight so being able to be included into the size limited *Baikal-T(1)*
bootload image. It is created to be just an external programs/scripts runner
without any other burden, while the functional tests are supposed to be supplied
in test *project*s. Each *project* consists of *testcase* descriptors optionally
together with *scripts/programs* executables and of optional *scenario*
descriptors. Each descriptor of *scenario* and *testcase* ones are supposed to be
a YAML-file with a specific structure. See the next sections for details about
the *tp-test* core, tests *project* structure and *scenario/testcase* descriptors.

## TP-test core

As mentioned before it's a *C++* program, which is a so called gate to perform
the described in the *project*s tests. Here is a typical help-message displaied
if the *help* command is passed to the *tp-test* executable:

```
root@mrbt1:~# tp-test help
Usage: tp-test <command> [options]

  T-platforms embedded system tests framework. Mainly it is responsible for
  target platforms functional and hardware tests, described by means of the YAML
  config-files of the tests scenario and themselfs.

Commads:
  run - Execute the passed scenario or test (options -s/-t are mutually exclusive).
    -r,--root <path>     - Path to the framework configs directory ('/etc/tp-test' by default).
    -s,--scenario <name> - Scenario name ('<root>/<name>.yaml' basename without extension).
    -t,--test <name>     - Individual testcase name ('<root>/cases/<name>' directory name
                           with the 'descriptor.yaml test descriptor file).
      -a,--args <args>   - Arguments list being passed to the individual test
                           in YAML nested mapping syntax - '{info: "", arg1: "", ...}'.
    -l,--log <path>      - Log-file name (<name>.log by default).
    -d,--debug           - Print debug messages to the log-file.
  info - Print an info of scenario/test (options -s/-t/-p are mutually exclusive).
    -r,--root <path>     - Path to the framework configs directory ('/etc/tp-test' by default).
    -s,--scenario <name> - Scenario name ('<root>/<name>.yaml' basename without extension).
    -t,--test <name>     - Individual testcase name ('<root>/cases/<name>' directory name
                           with the 'descriptor.yaml test descriptor file).
    -p,--print           - Print info of all scenario/tests found in the '<root>' directory
                           (this is also helpful for checking the config-files syntax).
  help - Print this help message.

```

As you can see there are three commands supported by the *tp-test* program:
* *run* performs the passed *scenario/testcase* execution with possible
customization of the tests project path, *scenario* name, individual *testcase*
name and it' arguments, log-file path and debug messages.
* *info* is responsible for printing an info regarding the test *scenario* and
it' test cases. As for the *run* a user can pass a custom path to the tests
*project*, name of *scenario* and individual test.
* *help* just prints the info test cited above.

### TP-test *run* command

This command is the most valuable, since it makes the *tp-test* executable to perform
either the whole *scenario* or a described individual *testcase* with costomized
parameters (for more details regarding the tests description see the *TP-test project*
section). By default the test *project* root directory is expected to be found
by the */etc/tp-test* path where the *tp-test* runnner tries to find a requested
*scenraio/testcase* descriptors. So in a simplest case to execute a *scenario* from
the default *project* path you just need to perform a command like this:

```
root@mrbt1:~# tp-test run -s Sample
TITLE      : Sample scenario
ROOT       : tests
LOG        : Sample.log
TESTS      : 5
 (1/5) sample_echo 'Echo-command test'                      PASS  (0.003 s)
 (2/5) sample_pass 'Always passed test'                     PASS  (0.003 s)
 (3/5) sample_fail 'Always failed test'                     FAIL  (0.003 s)
 (4/5) sample_script 'Bash sample script'                   PASS  (0.007 s)
 (5/5) sample_interactive 'Interactive sample test'         
sample_interactive>> Press any key to continue... 
sample_interactive>> 
 (5/5) sample_interactive 'Interactive sample test'         PASS  (3.756 s)
SUMMARY    : PASS 4 | ERROR 0 | FAIL 1
TESTS TIME : 3.770 s
```

The *tp-test* core runner shall make sure whether the requested *scenario* descriptor
file is correct, the *testcase*s descritors it is created for are also correct
and shall execute the *testcase*s scripts/programs one by one. Generic information
regarding the being performed *project*, requested *scenraio* and  it' *testcase*s
is printed to the console log while a detailed log is outputed to the
*\<scenraio name\>.log* file by default if the log-name isn't customized by the
*tp-test* parameter *-l \<name\>.log*. During each *testcase* execution the console
input is disabled (if a *testcase* isn't marked as interactive like
*sample_itneractive* testcase above), while the executables output is redirected to
the log-file. 

In case if you are debuging or just need to perform a single out-of-*scenario*
*testcase*, you can execute an individual *testcase* from a *project*. This is done
by passing the *-t \<testcase name\>* argument like this:

```
root@mrbt1:~# tp-test run -t sample_script -a '{info: "Sample script default parameters test"}'
TITLE      : undefined
ROOT       : tests
LOG        : sample_script.log
TESTS      : 1
 (1/1) sample_script 'Sample script default parameters test' PASS  (0.007 s)
SUMMARY    : PASS 1 | ERROR 0 | FAIL 0
TESTS TIME : 0.007 s
```

Customized *testcase* parameters are specified with *-a* program argument. It's
strongly recommended to surround it with a single quotation marks.

Sometimes you may need to execute a *scenario/testcase* from a project with custom
path. In this case you'll just need to pass the *-r <custom/path>* parameter to
the *tp-test* program. So alternatively the *scenario/testcase* above can be
run as follows:

```
root@mrbt1:~# tp-test run -r /etc/tp-test -s Sample
...
root@mrbt1:~# tp-test run -r /etc/tp-test -t sample_script
...
```

### TP-test *info* command

Normally each project *scenario*s and *testcase*s are equipped with a description
regarding their purpose and possible parameters. Such information is located
in the corresponding nodes of the YAML-description-file, but it can be printed
by means of the *tp-test* runner itself. In order to do this you can perform the
*info* command. For instance, a *scenario* description, number of tests,
*testcase*s name and their custom parameters information is requested as follows:
```
root@mrbt1:~# tp-test info -s Sample
Scenario 'Sample'
  title: Sample scenario
  description:
    This scenario' purpose is to provide a basic knowledge of the way the
    TP-test scenario files are supposed to look like. Scenario files are
    the YAML-based descriptors of the corresponding test procedures. The
    YAML documents are mappings with three members in the root of the tree
    {title: "", description: "", tests: !!omap {- test1: {arg1: "val1", ...}}}.
    Where 'title' and 'description' members are optional and will be replaced
    with 'undefined' string if not presented. The last member of the mapping
    contains the ordered map of tests being executed during the scenario
    implementation (see the 'tests' element in this file for example). Each
    sub-key of the 'tests' member is supposed to be the key of the corresponding
    test (basically it is the directory name in <root>/cases/<key> with
    'descriptor.yaml' file inside). The arguments names and their order are
    described in the corresponding test descriptor file. Test' key and info
    will be displayed during the scenario execution procedure. Needless to say
    that if 'tests' node isn't specified or empty non of the tests will be
    executed.
  tests: 5
    (1/5) sample_echo - Echo-command test
      arg1: 'Hello', arg2: ',', arg3: 'echo!'
    (2/5) sample_pass - Always passed test
    (3/5) sample_fail - Always failed test
      arg1: 'Ignored'
    (4/5) sample_script - Bash sample script
      string: 'Hi, tp-test script'
    (5/5) sample_interactive - Interactive sample test
```

Similarly a *testcase* description, executable object file-name, it' parameters
IDs, their order and default values can be requested by the next command:
```
root@mrbt1:~# tp-test info -t sample_script
Testcase 'sample_script'
  title: Sample test script
  description:
    This test is created as an example of the TP-test framework ability
    to run executable files from the test-specific directory
    '<root>/cases/<testname>/<exec>'. In this case the test 'type'
    must be 'localfile' with 'exec' member specifying the executable
    filename. The 'args' mapping element describes the script arguments,
    their order and default values. 'Interactive' boolean flag permits
    the program to access the program console to send/receive data
    to/from the user and the 'timeout' option specifies the test timeout
    in ms after which the executable is terminated. The last two parameters
    as well as 'title' and 'description' are optional. If they aren't
    specified the interactive mode will be disabled, timeout will be
    1000 ms, title and description will be initialized with 'undefined'
    string.
  type: localfile
  exec: sample_script.sh
  args: 
    [1] string: 'Sample test string'
  interactive: false
  timeout: 100 ms
```

## TP-test *project*

Root objects of TP-test *projects* are *scenario*s and *testcase*s mentioned
above. A typical project root directory looks as follows:
```
root@mrbt1:~# ls /etc/tp-test
cases/  lib/  Sample.yaml  XA1-MRBT1.yaml  XA1-MSBT2.yaml
```

where YAML-files are *scenario* descriptor files, *cases/* subdirectory consists
of *testcase*s directories with their YAML-descriptor-files, and *lib/* is
optional directory used by the *testcase*s scripts (isn't parsed and used anyhow
by the *tp-test* core).

### TP-test *testcase*

Lets start with *testcase*s description, because they are the ones responsible
for a single test execution. Root object of each test is supposed to be some
executable file (either a script or a program), which return value represents the
test status. So if an executable returns zero, then the test will be considered
as passed, while if it returns non-zero value, then the test will be marked as
failed. In order to make the *tp-test* core understanding of how a test executable
is intended to be run and where to find it, each *testcase* is described by a
YAML-description-file and placed in a subdirectory of *cases/* directory of a project
root path like this:
```
root@mrbt1:~# ls /etc/tp-test/cases/
eth_linkloop/   flash_mtdtest/  gpio_loopback/  pci_detect/  sample_echo/  sample_interactive/  sample_script/  serial_loopback/  usb_port/
eth_linkspeed/  gpio_input/     gpio_output/    rtc_access/  sample_fail/  sample_pass/         sensors_input/  storage_timings/
```
So each subdirectory above is a directory with an unique *testcase*, where directory
name is the *testcase* identifier used to be referenced in *scenario* descriptors.
Lets see what is inside the *sample_script* *testcase* directory:
```
root@mrbt1:~# ls /etc/tp-test/cases/sample_script/
descriptor.yaml  sample_script.sh*
```
It contains a mandatory *testcase* descriptor file *descriptor.yaml* and
a script *sample_script.sh*, which is refered by the descriptor file so being
executed by the *tp-test* core when it is requested. While the script itself
and it' code is specific to the *testcase* purpose (some tests may even have
no need in an external script at all), the descriptor file must be structured
in a special way:

* **title** - a single line short description of the test (optional).
* **description** - usually a multi-line text with a detailed description of the
test (optional).
* **type** - type of the test executable. It can either be *localfile* or *command*,
where a first one makes the *tp-test* core looking for the *testcase* executable
file in the *testcase* directory, while the last one executes it from the system
PATH (mandatory).
* **exec** - name of an executable file (mandatory).
* **args** - it's an optional ordered mapping of the pairs "*argument name: default value*",
where the "*argument name*" is the argument identifier, which then can be used in
a *scenario* descriptor file to customise the *testcase* executable file parameters
for a specific context. The parameters are passed to the executable file in the
order of this mapping.
* **interactive** - test interactivity flag, which is mandatory if a test
scripts/programs requires to receive an input from a user for proper execution.
* **timeout** - test timeout in milliseconds, which when expires makes the
*tp-test* core to terminate the *testcase* (optional, 100 ms by default).

For instance a YAML-descriptor-file of the *sample_script* *testcase* looks
as follows:
```
%YAML 1.1
# Sample test script for T-platforms Test framework
---
title: "Sample test script"
description: |-
    This test is created as an example of the TP-test framework ability
    to run executable files from the test-specific directory
    '<root>/cases/<testname>/<exec>'. In this case the test 'type'
    must be 'localfile' with 'exec' member specifying the executable
    filename. The 'args' mapping element describes the script arguments,
    their order and default values. 'Interactive' boolean flag permits
    the program to access the program console to send/receive data
    to/from the user and the 'timeout' option specifies the test timeout
    in ms after which the executable is terminated. The last two parameters
    as well as 'title' and 'description' are optional. If they aren't
    specified the interactive mode will be disabled, timeout will be
    1000 ms, title and description will be initialized with 'undefined'
    string.
type: "localfile"
exec: "sample_script.sh"
args: !!omap # Must be ordered map (sequence of mappings) or omitted
    - string: "Sample test string"
interactive: false
timeout: 100
```

### TP-test *scenario*

While it is nice to have a single test executed, most of the time we need to have
many aspects of a platform tested, which in particular means to execute a set of
*testcase*s with custom/platform-specific parameters. In this case the *tp-test*
core supports a special type of YAML-descriptor-files called *scenario*. For instance
the *Sample scenario* mentioned above is described with the following YAML-file:
```
%YAML 1.1
# Sample scenario for T-platforms Test framework
---
title: "Sample scenario"
description: |-
    This scenario' purpose is to provide a basic knowledge of the way the
    TP-test scenario files are supposed to look like. Scenario files are
    the YAML-based descriptors of the corresponding test procedures. The
    YAML documents are mappings with three members in the root of the tree
    {title: "", description: "", tests: !!omap {- test1: {arg1: "val1", ...}}}.
    Where 'title' and 'description' members are optional and will be replaced
    with 'undefined' string if not presented. The last member of the mapping
    contains the ordered map of tests being executed during the scenario
    implementation (see the 'tests' element in this file for example). Each
    sub-key of the 'tests' member is supposed to be the key of the corresponding
    test (basically it is the directory name in <root>/cases/<key> with
    'descriptor.yaml' file inside). The arguments names and their order are
    described in the corresponding test descriptor file. Test' key and info
    will be displayed during the scenario execution procedure. Needless to say
    that if 'tests' node isn't specified or empty non of the tests will be
    executed.
tests: !!omap # Must be ordered map (sequence of mappings) or omitted
    - sample_echo: {info: "Echo-command test", arg1: "Hello", arg2: ",", arg3: "echo!"}
    - sample_pass: {info: "Always passed test"}
    - sample_fail: {info: "Always failed test", arg1: "Ignored"}
    - sample_script: {info: "Bash sample script", string: "Hi, tp-test script"}
    - sample_interactive: {info: "Interactive sample test"}
```
As you can see it consists of a simple single-line title string, a multi-line
description text and a set of *testcase*s with custom parameters:
* **title** - a single line short description of the *scenario* (optional).
* **description** - usually a multi-line text with a detailed description of the
*scenario* (optional).
* **tests** - it's the ordered mapping of the pairs "*testcase ID: custom parameters*",
where the "*testcase ID*" is the *testcase* unique identifier (a subdirectory
name in the *cases/* directory of the *project*), "*custom parameters*" is a
mapping of pairs like {info: 'Single line Text', argument: "value"}
so the *info* is printed to the console log at the time of the test execution,
while the rest of data is the *testcase* arguments and custom *value*s passed
to the *testcase* executable file.

### TP-test execution environment

Sometimes it is necessary to have an access to the parameters passed to the
*tp-test* core program in the *testcase* executables. For instance in order to load
some additional libraries or scripts places at the non-default *project* path
(like *lib/* directory listed before in a typical *project* root directory).
This ability is implemented by means of special environment variables created
by the *tp-test* core and then passed to each *testcase* executable:
* **TPTEST_ROOT** - *project* root direcotory path.
* **TPTEST_DEBUG** - debug flag.
* **TPTEST_INTERACTIVE** - *testcase* interactive flag.
* **TPTEST_TIMEOUT** - *testcase* timeout value.

In future the list of additional environment variable may be extended. 
