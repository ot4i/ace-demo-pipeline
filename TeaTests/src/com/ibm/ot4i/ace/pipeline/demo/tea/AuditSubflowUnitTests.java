// Copyright (c) 2020 Open Technologies for Integration
// Licensed under the MIT license (see LICENSE for details)

/**
 * Unit tests for the tea application. Relies on a pre-populated server already in
 * existence at a work directory located by the TEA_TEST_WORK_DIR env var and with
 * the scaffolding application deployed.
 * 
 * Reads test data (recorded by the application in this repo) from a test-data dir
 * pointed to by TEA_TEST_RESOURCE_DIR. See scripts/build-and-ut.sh for details.
 * 
 */

package com.ibm.ot4i.ace.pipeline.demo.tea;

import static org.junit.Assert.assertEquals;

import java.nio.file.Files;
import java.nio.file.Paths;

import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathFactory;

import org.junit.BeforeClass;
import org.junit.Test;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import com.ibm.integration.admin.proxy.IntegrationServerProxy;


public class AuditSubflowUnitTests
{
  static IntegrationServerProxy isp = null;
  static String baseDirectoryForResourceFiles = "test-data"; 


  /**
   * Reads environment variables and sets up IAPI link to the server
   */
  @BeforeClass
  public static void setupTestCase()
  {
    baseDirectoryForResourceFiles = System.getenv("TEA_TEST_RESOURCE_DIR");
    if ( baseDirectoryForResourceFiles == null )
    {
      baseDirectoryForResourceFiles = "test-dir";
      System.out.println("Did not find env var TEA_TEST_RESOURCE_DIR; using test-dir as a fallback");
    }
    String workDir = System.getenv("TEA_TEST_WORK_DIR");
    if ( workDir == null )
    {
      workDir = "/home/tdolby/tmp/ut-work-dir";
      System.out.println("Did not find env var TEA_TEST_WORK_DIR; using /home/tdolby/tmp/ut-work-dir as a fallback");
    }
    System.out.println("Connecting to server using work directory "+workDir);
    isp = new IntegrationServerProxy("*", workDir);
  }

  /**
   * Validates the XML audit log generation
   */
  @Test
  public void ensureXMLIsCreated() throws Exception
  {
    String message = Util.injectMessageAndGetResponse(isp, "TeaTestsScaffold", "TestAuditXMLCreation", "HTTP%20Input", 
                                                      Files.readAllBytes(Paths.get(baseDirectoryForResourceFiles+"/TeaRESTApplication-gen.TeaRESTApplication-8-getIndex (Implementation).LogAuditData.TeaSharedLibrary.LogAuditData#InTerminal.Input-getIndex (Implementation).LogAuditData.Create XML from JSON-message.xml")));
    Element logicalTreeRoot = Util.getXMLTreeFromMessageString(message);
    String xPathAssertion = "/message/XMLNSC/logData/info/name/text()";
    XPath xPath = XPathFactory.newInstance().newXPath();
    NodeList nodes = (NodeList)xPath.evaluate(xPathAssertion, logicalTreeRoot, XPathConstants.NODESET);	   
    assertEquals("Name from JSON data used in XMLNSC", "Earl Grey", nodes.item(0).getTextContent());
  }

  /**
   * Ensures the audit logging does not destroy the JSON data
   */
  @Test
  public void ensureJSONIsNotLost() throws Exception
  {
    String message = Util.injectMessageAndGetResponse(isp, "TeaTestsScaffold", "TestAuditXMLCreation", "HTTP%20Input", 
                                                      Files.readAllBytes(Paths.get(baseDirectoryForResourceFiles+"/TeaRESTApplication-gen.TeaRESTApplication-8-getIndex (Implementation).LogAuditData.TeaSharedLibrary.LogAuditData#InTerminal.Input-getIndex (Implementation).LogAuditData.Create XML from JSON-message.xml")));
    Element logicalTreeRoot = Util.getXMLTreeFromMessageString(message);
    String xPathAssertion = "/message/JSON/Data/name/text()";
    XPath xPath = XPathFactory.newInstance().newXPath();
    NodeList nodes = (NodeList)xPath.evaluate(xPathAssertion, logicalTreeRoot, XPathConstants.NODESET);	   
    assertEquals("Name from JSON data", "Earl Grey", nodes.item(0).getTextContent());
  }

  /**
   * Ensures the audit logging cleans up after itself
   */
  @Test
  public void ensureXMLIsRemoved() throws Exception
  {
    String message = Util.injectMessageAndGetResponse(isp, "TeaTestsScaffold", "TestAuditXMLDeletion", "HTTP%20Input", 
                                                      Files.readAllBytes(Paths.get(baseDirectoryForResourceFiles+"/TeaRESTApplication-gen.TeaRESTApplication-10-getIndex (Implementation).LogAuditData.LogXMLData-getIndex (Implementation).LogAuditData.Remove XML-message.xml")));
    Element logicalTreeRoot = Util.getXMLTreeFromMessageString(message);
    String xPathAssertion = "/message/XMLNSC";
    XPath xPath = XPathFactory.newInstance().newXPath();
    NodeList nodes = (NodeList)xPath.evaluate(xPathAssertion, logicalTreeRoot, XPathConstants.NODESET);	 
    assertEquals("No XMLNSC folder should be present", 0, nodes.getLength());
  }

}
