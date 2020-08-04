// Copyright (c) 2020 Open Technologies for Integration
// Licensed under the MIT license (see LICENSE for details)

/**
 * Java application to record messages going through a flow in an ACE application.
 * 
 * The application and flow names will be autodetected (with an error if more than
 * one is present) and recording switched on; after enough messages have been sent
 * through the flow by an external client (web UI works well for REST applications
 * but other clients would also work), the recording can be stopped and all of the
 * messages will be stored in a "test-data" directory. 
 *
 * These messages can then be injected into scaffolding flows to enable unit tests
 * of specific pieces of an application.
 * 
 */

package com.ibm.ot4i.ace.pipeline.demo.infrastructure;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.util.Base64;
import java.util.List;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ibm.integration.admin.http.HttpResponse;
import com.ibm.integration.admin.proxy.ApplicationProxy;
import com.ibm.integration.admin.proxy.IntegrationServerProxy;
import com.ibm.integration.admin.proxy.MessageFlowProxy;
import com.ibm.integration.admin.proxy.RestApiProxy;

public class RecordOneFlow
{
  public static void main(String[] args) 
  {
    try
    {
      String workDir = "/home/tdolby/tmp/tc2020-work-dir";
      if ( args.length > 1 )
        workDir = args[0];
      System.out.println("Connecting to server using work directory "+workDir);
      IntegrationServerProxy isp = new IntegrationServerProxy("*", workDir);
      MessageFlowProxy mf = null;
      String appName = "";
			
      List<ApplicationProxy> applicationsList = isp.getAllApplications(false);
      if ( applicationsList.isEmpty() )	
      {
        List<RestApiProxy> restApiList = isp.getAllRestApis(false);
        if ( restApiList.size() == 1 )
        {
          RestApiProxy app = restApiList.get(0);
          appName = app.getName();
          List <MessageFlowProxy> flowsList = app.getAllMessageFlows(false);
          if ( flowsList.size() == 1 ) { mf = flowsList.get(0); }
        }
      }
      else if ( applicationsList.size() == 1 )
      {
        ApplicationProxy app = applicationsList.get(0); 
        appName = app.getName();
        List <MessageFlowProxy> flowsList = app.getAllMessageFlows(false);
        if ( flowsList.size() == 1 ) { mf = flowsList.get(0); }
      }
      else
      {
        System.out.println("Too many applications to auto-detect");
      }
			
      System.out.println("Detected app "+appName+" and flow "+mf.getName()+"");

      HttpResponse startRecordingResp = isp.getHttpClient().postMethod("/apiv2/applications/"+appName+"/messageflows/"+mf.getName()+"/start-recording", "");
      System.out.println("startRecordingResp.getStatusCode() "+startRecordingResp.getStatusCode());

      System.out.println("Recording data; press enter to retrieve data and stop recording");
      System.in.read();
      File testDataDirectory = new File("test-data");
      testDataDirectory.mkdir();
      HttpResponse getDataResp = isp.getHttpClient().getMethod("/apiv2/data/recorded-test-data?messageFlow="+mf.getName());
      System.out.println("getDataResp.getStatusCode() "+getDataResp.getStatusCode());
      //System.out.println("getDataResp.getBody().toString() "+getDataResp.getBody().toString());
			
      JsonFactory factory = new JsonFactory();
      ObjectMapper mapper = new ObjectMapper(factory);	       
      JsonNode node = mapper.readValue(getDataResp.getBody().toString(), JsonNode.class);
      JsonNode array = node.get("recordedTestData");
      for ( JsonNode rtd: array )
      {
        JsonNode checkpoint = rtd.get("checkpoint");
        JsonNode sourceName = checkpoint.get("messageFlowData").get("nodes").get("source").get("name");
        JsonNode targetName = checkpoint.get("messageFlowData").get("nodes").get("target").get("name");
        JsonNode flowSequenceNumber = checkpoint.get("sequenceData").get("flowSequenceNumber");
        String message = new String(Base64.getDecoder().decode(rtd.get("testData").get("message").asText()));
        String filename = "test-data/"+appName+"-"+mf.getName()+"-"+flowSequenceNumber+"-"+sourceName.asText()+"-"+targetName.asText()+"-message.xml";
        System.out.println("Writing file "+filename);
        BufferedWriter writer = new BufferedWriter(new FileWriter(filename));
        writer.write(message);
        writer.close();
		    	
        String localEnvironment = new String(Base64.getDecoder().decode(rtd.get("testData").get("localEnvironment").asText()));
        filename = "test-data/"+appName+"-"+mf.getName()+"-"+flowSequenceNumber+"-"+sourceName.asText()+"-"+targetName.asText()+"-localEnvironment.xml";
        System.out.println("Writing file "+filename);
        writer = new BufferedWriter(new FileWriter(filename));
        writer.write(localEnvironment);
        writer.close();

        String environment = new String(Base64.getDecoder().decode(rtd.get("testData").get("environment").asText()));
        filename = "test-data/"+appName+"-"+mf.getName()+"-"+flowSequenceNumber+"-"+sourceName.asText()+"-"+targetName.asText()+"-environment.xml";
        System.out.println("Writing file "+filename);
        writer = new BufferedWriter(new FileWriter(filename));
        writer.write(environment);
        writer.close();

        String exceptionList = new String(Base64.getDecoder().decode(rtd.get("testData").get("exceptionList").asText()));
        filename = "test-data/"+appName+"-"+mf.getName()+"-"+flowSequenceNumber+"-"+sourceName.asText()+"-"+targetName.asText()+"-exceptionList.xml";
        System.out.println("Writing file "+filename);
        writer = new BufferedWriter(new FileWriter(filename));
        writer.write(exceptionList);
        writer.close();

      }
      HttpResponse deleteDataResp = isp.getHttpClient().deleteMethod("/apiv2/data/recorded-test-data");
      System.out.println("deleteDataResp.getStatusCode() "+deleteDataResp.getStatusCode());
			
      HttpResponse stopRecordingResp = isp.getHttpClient().postMethod("/apiv2/applications/"+appName+"/messageflows/"+mf.getName()+"/stop-recording", "");
      System.out.println("stopRecordingResp.getStatusCode() "+stopRecordingResp.getStatusCode());
    }
    catch ( java.lang.Throwable jlt )
    {
      jlt.printStackTrace();
    }
  }

}
