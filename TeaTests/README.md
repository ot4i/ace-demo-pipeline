# TeaTests

JUnit tests for the code used by TeaRESTApplication. 

The tests in this project run against the TeaTestsScaffold applications using the Integration API message injection technology, where recorded messages from a live run of the real application are played back through a test flow; the output from the test flow is then checked against the expectations of the test to ensure the code is workign as designed.

test-data contains the recorded messages from the live run, using the application in demo-infrastructure/src/com/ibm/ot4i/ace/pipeline/demo/infrastructure in this repo. The files have rather long names, being named for the transition between each node during the live run.

Running the tests requires a server with the scaffold and shared library both deployed already; see scripts/build-and-ut.sh for details.
