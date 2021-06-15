// Copyright (c) 2020 Open Technologies for Integration
// Licensed under the MIT license (see LICENSE for details)

/**
 * JavaCompute Node implementation; takes an index and reads from the database
 * 
 * Returns "null" if the tea does not exist.
 *
 * Creates database tables if they don't exist.
 */

package com.ibm.ot4i.ace.pipeline.demo.tea;

import java.net.InetAddress;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

import com.ibm.broker.javacompute.MbJavaComputeNode;
import com.ibm.broker.plugin.MbElement;
import com.ibm.broker.plugin.MbException;
import com.ibm.broker.plugin.MbMessage;
import com.ibm.broker.plugin.MbMessageAssembly;
import com.ibm.broker.plugin.MbOutputTerminal;
import com.ibm.broker.plugin.MbUserException;

public class GetIndex_JavaCompute extends MbJavaComputeNode {

  public void evaluate(MbMessageAssembly inAssembly) throws MbException {
    MbOutputTerminal out = getOutputTerminal("out");

    MbMessage inMessage = inAssembly.getMessage();
    MbMessageAssembly outAssembly = null;
    try {
      // create new message as a copy of the input
      MbMessage outMessage = new MbMessage(inMessage);
      outAssembly = new MbMessageAssembly(inAssembly, outMessage);
      // ----------------------------------------------------------
      // Add user code below

      Connection conn = getJDBCType4Connection("TEAJDBC", JDBC_TransactionType.MB_TRANSACTION_AUTO);

      // Example of using the Connection to create a java.sql.Statement  
      Statement stmt = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,
                                            ResultSet.CONCUR_READ_ONLY);
      // This would normally be done externally, but we do it here for convenience
      try {
        stmt.executeUpdate("CREATE TABLE Tea(id INTEGER, name VARCHAR(128))");
        conn.commit();
      } catch ( java.lang.Throwable jlt ) {
        //jlt.printStackTrace();
      }
	        
      String teaName = null;
      MbElement inputLE = outAssembly.getLocalEnvironment().getRootElement();
      String teaIndex = (String)(inputLE.getFirstElementByPath("HTTP/Input/Path").getLastChild().getValue());
	        
      stmt = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,
                                  ResultSet.CONCUR_READ_ONLY);
      ResultSet rs = stmt.executeQuery("SELECT name from Tea where id='"+teaIndex+"'");
      if ( rs.first() )
      {
        teaName = rs.getString(1);
      }
      MbElement rootElem = outAssembly.getMessage().getRootElement();


      rootElem.createElementAsLastChild("HTTPReplyHeader").
        createElementAsFirstChild(MbElement.TYPE_NAME_VALUE, "Server_Hostname", 
                                  InetAddress.getLocalHost().getHostName());
	        
      MbElement jsonData = rootElem.createElementAsLastChild("JSON").
        createElementAsFirstChild(MbElement.TYPE_NAME);
      jsonData.setName("Data");
      jsonData.createElementAsFirstChild(MbElement.TYPE_NAME_VALUE, "id", teaIndex);
      jsonData.createElementAsFirstChild(MbElement.TYPE_NAME_VALUE, "name", teaName);
	        
      // End of user code
      // ----------------------------------------------------------
    } catch (MbException e) {
      // Re-throw to allow Broker handling of MbException
      throw e;
    } catch (RuntimeException e) {
      // Re-throw to allow Broker handling of RuntimeException
      throw e;
    } catch (Exception e) {
      // Consider replacing Exception with type(s) thrown by user code
      // Example handling ensures all exceptions are re-thrown to be handled in the flow
      throw new MbUserException(this, "evaluate()", "", "", e.toString(),
                                null);
    }
    // The following should only be changed
    // if not propagating message to the 'out' terminal
    out.propagate(outAssembly);

  }

  /**
   * onPreSetupValidation() is called during the construction of the node
   * to allow the node configuration to be validated.  Updating the node
   * configuration or connecting to external resources should be avoided.
   *
   * @throws MbException
   */
  @Override
  public void onPreSetupValidation() throws MbException {
  }

  /**
   * onSetup() is called during the start of the message flow allowing
   * configuration to be read/cached, and endpoints to be registered.
   *
   * Calling getPolicy() within this method to retrieve a policy links this
   * node to the policy. If the policy is subsequently redeployed the message
   * flow will be torn down and reinitialized to it's state prior to the policy
   * redeploy.
   *
   * @throws MbException
   */
  @Override
  public void onSetup() throws MbException {
  }

  /**
   * onStart() is called as the message flow is started. The thread pool for
   * the message flow is running when this method is invoked.
   *
   * @throws MbException
   */
  @Override
  public void onStart() throws MbException {
  }

  /**
   * onStop() is called as the message flow is stopped. 
   *
   * The onStop method is called twice as a message flow is stopped. Initially
   * with a 'wait' value of false and subsequently with a 'wait' value of true.
   * Blocking operations should be avoided during the initial call. All thread
   * pools and external connections should be stopped by the completion of the
   * second call.
   *
   * @throws MbException
   */
  @Override
  public void onStop(boolean wait) throws MbException {
  }

  /**
   * onTearDown() is called to allow any cached data to be released and any
   * endpoints to be deregistered.
   *
   * @throws MbException
   */
  @Override
  public void onTearDown() throws MbException {
  }

}
