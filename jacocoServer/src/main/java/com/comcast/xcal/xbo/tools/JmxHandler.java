package com.comcast.xcal.xbo.tools;

import java.io.IOException;
import java.io.File;
import java.io.InputStream;
import java.io.ByteArrayInputStream;

import org.jacoco.core.tools.ExecFileLoader;
import org.jacoco.agent.rt.IAgent;

import javax.management.remote.JMXConnector;
import javax.management.remote.JMXConnectorFactory;
import javax.management.remote.JMXServiceURL;
import javax.management.JMX;
import javax.management.MBeanServerConnection;
import javax.management.ObjectName;

public class JmxHandler implements Runnable {
	private final String hostname;
	private final int port;
	private File outputFile;
	private final ExecFileLoader fileLoader;
	private IAgent jacocoAgent;
	private JMXConnector jmxConnector;

	JmxHandler(final String hostname, final int port, final ExecFileLoader fileLoader, final File outputFile) throws IOException {
		this.hostname = hostname;
		this.port = port;
		this.outputFile = outputFile;
		this.fileLoader = fileLoader;
	}

	public void run() {
		try {
			String jmxUrl = "service:jmx:rmi:///jndi/rmi://" + this.hostname + ":" + this.port + "/jmxrmi";
			JMXServiceURL serviceUrl = new JMXServiceURL(jmxUrl);
			jmxConnector = JMXConnectorFactory.connect(serviceUrl, null);

			System.out.println("Connected to server " + hostname + ":" + port + " via JMX");

			MBeanServerConnection mbeanConn = jmxConnector.getMBeanServerConnection();
			ObjectName jacocoObject = new ObjectName("org.jacoco:type=Runtime");

			if(mbeanConn.isRegistered(jacocoObject)) {
				jacocoAgent = JMX.newMBeanProxy(mbeanConn, jacocoObject, IAgent.class);
				jacocoAgent.reset();
			} else {
				System.out.println("JMX at " + hostname + ":" + Integer.toString(port) + " does not have required MBean.");
				return;
			}

			while(true) {
				Thread.sleep(1000);
				byte[] dumpData = jacocoAgent.getExecutionData(true);
				if(dumpData.length > 0) {
					InputStream execData = new ByteArrayInputStream(dumpData);
					synchronized(fileLoader) {
						fileLoader.load(execData);
						fileLoader.save(outputFile, false);
					}
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			try {
				jmxConnector.close();
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}
}
