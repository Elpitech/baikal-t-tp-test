cmake_minimum_required(VERSION 3.1.0)
project(tp-test
	VERSION "0.1"
	DESCRIPTION "T-platforms Test Framework"
	LANGUAGES "CXX")

# Common build cleanups
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")

# Search for the LibYAML-cpp and pthread libraries
find_package(yaml-cpp REQUIRED)
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

# List of tp-test source files
file(GLOB TP_TEST_SOURCES "src/*.cpp")
file(GLOB TP_TEST_PRIVATE_HEADERS "src/*.h")
file(GLOB TP_TEST_SCENARIOS "tests/*.yaml")
file(GLOB TP_TEST_TESTCASES "tests/cases")
file(GLOB TP_TEST_LIBS "tests/lib")

# Build tp-test binary
add_executable(tp-test ${TP_TEST_SOURCES} ${TP_TEST_PRIVATE_HEADERS})
target_link_libraries(tp-test yaml-cpp Threads::Threads)

# tp-test installation rules
install(TARGETS tp-test DESTINATION bin)
if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
	install(FILES ${TP_TEST_SCENARIOS} DESTINATION "/etc/tp-test")
	install(DIRECTORY ${TP_TEST_TESTCASES} USE_SOURCE_PERMISSIONS DESTINATION "/etc/tp-test")
	install(DIRECTORY ${TP_TEST_LIBS} USE_SOURCE_PERMISSIONS DESTINATION "/etc/tp-test")
endif()
