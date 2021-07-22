# TeaRESTApplication_NonFunctionalTest

Code for testing the main Tea application's reliability and memory usage.

These tests stub out the database interactions and then run messages through the flow
using an HTTP client to verify that the server does not leak memory. As these tests
rely on /proc/self/status to check memory usage, they will not run on Windows.

Assuming the work directory has been set up correctly, then these tests can be run from the
command line, Maven build, or the toolkit. If a Developer edition is used to run the tests
then the environment variable ACE_DEMO_PIPELINE_NFT_ITERATIONS must be set to a low value,
as otherwise the tests will take a long time to run die to the rate limiting applied by
default in Developer edition servers.
