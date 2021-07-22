# Perf harness testing

Scripts to allow testing using the per harness tool (see https://github.com/ot4i/perf-harness)
to verify that the server continues to function correctly under load. The testing uses an 
actual JDBC endpoint, which must be configured, and uses only external interfaces.

Due to the Developer edition rate limiting, the default numbers of iterations and threads
is limited, but these could be increased if a different edition was used.
