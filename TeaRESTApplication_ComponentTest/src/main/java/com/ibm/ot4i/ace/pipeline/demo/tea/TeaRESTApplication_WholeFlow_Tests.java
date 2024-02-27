package com.ibm.ot4i.ace.pipeline.demo.tea;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import com.ibm.integration.test.v1.NodeSpy;
import com.ibm.integration.test.v1.SpyObjectReference;
import com.ibm.integration.test.v1.TestMessageAssembly;
import com.ibm.integration.test.v1.TestSetup;
import com.ibm.integration.test.v1.exception.TestException;

import static com.ibm.integration.test.v1.Matchers.*;
import static net.javacrumbs.jsonunit.JsonMatchers.jsonEquals;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;

public class TeaRESTApplication_WholeFlow_Tests {

        /*
         * TeaRESTApplication_getIndex_subflow_0001_Test
         * Test generated by IBM App Connect Enterprise Toolkit 12.0.1.0 on 10-Jun-2021 12:48:56
         */

        @AfterEach
        public void cleanupTest() throws TestException {
                // Ensure any mocks created by a test are cleared after the test runs 
                TestSetup.restoreAllMocks();
        }

        @Test
        public void TeaRESTApplication_WholeFlow_Get_Test() throws TestException {


    		// Define the SpyObjectReference objects
    		SpyObjectReference httpInputObjRef = new SpyObjectReference().application("TeaRESTApplication")
    				.messageFlow("gen.TeaRESTApplication").node("HTTP Input");
    		SpyObjectReference httpReplyObjRef = new SpyObjectReference().application("TeaRESTApplication")
    				.messageFlow("gen.TeaRESTApplication").node("HTTP Reply");

    		// Initialise NodeSpy objects
    		NodeSpy httpInputSpy = new NodeSpy(httpInputObjRef);
    		NodeSpy httpReplySpy = new NodeSpy(httpReplyObjRef);
    		
            // Declare a new TestMessageAssembly object for the message being sent into the node
            TestMessageAssembly inputMessageAssembly = new TestMessageAssembly();
            InputStream inputMessage = Thread.currentThread().getContextClassLoader().getResourceAsStream("00003CC8-65DDFF90-00000001-0.mxml");
            inputMessageAssembly.buildFromRecordedMessageAssembly(inputMessage);

    		// Configure the "in" terminal on the HTTP Reply node not to propagate.
    		// If we don't do this, then the reply node will throw exceptions when it  
    		// realises we haven't actually used the HTTP transport.
    		httpReplySpy.setStopAtInputTerminal("in");

    		// Now call propagate on the "out" terminal of the HTTP Input node.
    		// This takes the place of an actual HTTP message: we simple hand the node
    		// the message assembly and tell it to propagate that as if it came from an
    		// actual client. This line is where the flow is actually run.
    		httpInputSpy.propagate(inputMessageAssembly, "out");
    		
    		// Note that any exceptions would cause this test to fail, so if we reach 
    		// the next lines then the flow has completed successfully.
    		
    		// Validate the results from the flow execution
            // We will now pick up the message that is propagated into the "HttpReply" node and validate it
    		TestMessageAssembly replyMessageAssembly = httpReplySpy.receivedMessageAssembly("in", 1);

			// Assert output message body data
			// Get the TestMessageAssembly object for the expected propagated message
    		TestMessageAssembly expectedMessageAssembly = new TestMessageAssembly();
            InputStream expectedMessage = Thread.currentThread().getContextClassLoader().getResourceAsStream("00003CC8-65DDFF90-00000001-12.mxml");
            expectedMessageAssembly.buildFromRecordedMessageAssembly(expectedMessage);

            // Check the reply is as expected
            assertThat(replyMessageAssembly, equalsMessage(expectedMessageAssembly));
    }
}