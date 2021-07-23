# perf-harness testing

Scripts to allow testing using the perf-harness tool (see https://github.com/ot4i/perf-harness)
to verify that the server continues to function correctly under load. The testing uses an 
actual JDBC endpoint, which must be configured, and uses only external interfaces.

The perf-harness tool will mark any non-200 HTTP response as a failure; possible extensions
to this testing include checking memory growth and configuring the flow to use more threads
before running the tests.

Due to the Developer edition rate limiting, the default numbers of iterations and threads
is limited, but these could be increased if a different edition was used.
