// Copyright (c) 2020 Open Technologies for Integration
// Licensed under the MIT license (see LICENSE for details)

/**
 * Utilities for interacting with message injection and response reading.
 *
 */

package com.ibm.ot4i.ace.pipeline.demo.tea;

import static org.junit.Assert.assertEquals;

import java.io.ByteArrayInputStream;
import java.util.Base64;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ibm.integration.admin.http.HttpResponse;
import com.ibm.integration.admin.proxy.IntegrationServerProxy;

public class Util 
{
  /**
   * Injects one message into a given flow (TeaTestsScaffold flows in this demo) and 
   * retrieves the Message response as an XML string.
   *
   * @param isp     A live connection to a server with the scaffold applications deployed
   * @param app     The application name into which the message should be injected
   * @param mf      The flow name into which the message should be injected
   * @param node    The node name into which the message should be injected
   * @param message A byte array containing the serialised Message tree
   *
   * @return An XML string representing the serialised Message tree
   * @throws Exception if API calls fail
   */
  public static String injectMessageAndGetResponse(IntegrationServerProxy isp, String app, String mf, String node, byte [] message) throws Exception
  {
    //System.out.println("Using app "+app+" and flow "+mf+"");

    HttpResponse startRecordingResp = isp.getHttpClient().postMethod("/apiv2/applications/"+app+"/messageflows/"+mf+"/start-recording", "");
    assertEquals("start recording", 200, startRecordingResp.getStatusCode());
    HttpResponse startInjectionResp = isp.getHttpClient().postMethod("/apiv2/applications/"+app+"/messageflows/"+mf+"/start-injection", "");
    assertEquals("start injection", 200, startInjectionResp.getStatusCode());

    // Clear up any leftover data
    HttpResponse deleteDataResp = isp.getHttpClient().deleteMethod("/apiv2/data/recorded-test-data");
    assertEquals("delete leftover data", 204, deleteDataResp.getStatusCode());

    String encodedMessage = Base64.getEncoder().encodeToString(message);
    String testData = "{\"testData\":{\"message\":\""+encodedMessage+"\",\"localEnvironment\":\"\",\"environment\":\"\",\"exceptionList\":\"\"}}";			
    HttpResponse injectDataResp = isp.getHttpClient().postMethod("/apiv2/applications/"+app+"/messageflows/"+mf+"/nodes/HTTP%20Input/inject", testData, false); // false needed to avoid multiple URL encoding steps
    assertEquals("inject data", 200, injectDataResp.getStatusCode());
    HttpResponse getDataResp = isp.getHttpClient().getMethod("/apiv2/data/recorded-test-data?messageFlow="+mf);
    assertEquals("get data", 200, getDataResp.getStatusCode());
    //System.out.println("getDataResp.getBody().toString() "+getDataResp.getBody().toString());
			
    JsonFactory factory = new JsonFactory();
    ObjectMapper mapper = new ObjectMapper(factory);	       
    JsonNode jNode = mapper.readValue(getDataResp.getBody().toString(), JsonNode.class);
    JsonNode rtd = jNode.get("recordedTestData").get(1);
    String responseMessage = new String(Base64.getDecoder().decode(rtd.get("testData").get("message").asText()));

    // Clean up after ourselves 
    deleteDataResp = isp.getHttpClient().deleteMethod("/apiv2/data/recorded-test-data");
    assertEquals("delete data", 204, deleteDataResp.getStatusCode());
		
    HttpResponse stopInjectionResp = isp.getHttpClient().postMethod("/apiv2/applications/"+app+"/messageflows/"+mf+"/stop-injection", "");
    assertEquals("stop injection", 200, stopInjectionResp.getStatusCode());
    HttpResponse stopRecordingResp = isp.getHttpClient().postMethod("/apiv2/applications/"+app+"/messageflows/"+mf+"/stop-recording", "");
    assertEquals("stop recording", 200, stopRecordingResp.getStatusCode());

    return responseMessage;
  }

  /**
   * Converts the serialised XML format into a dom tree.
   *
   * @param message A string containing the serialised Message tree
   *
   * @return An XML element pointing to the root element of the Message
   * @throws Exception if API calls fail
   */
  public static Element getXMLTreeFromMessageString(String message) throws Exception
  {
    DocumentBuilderFactory docBuilderFactory = DocumentBuilderFactory.newInstance();
    DocumentBuilder builder = docBuilderFactory.newDocumentBuilder();	       
    StringBuilder xmlStringBuilder = new StringBuilder();
    xmlStringBuilder.append(message);
    ByteArrayInputStream input = new ByteArrayInputStream(xmlStringBuilder.toString().getBytes("UTF-8"));
    Document logicalTree = builder.parse(input);
    Element  logicalTreeRoot  = logicalTree.getDocumentElement();	        

    return logicalTreeRoot;
  }

}
