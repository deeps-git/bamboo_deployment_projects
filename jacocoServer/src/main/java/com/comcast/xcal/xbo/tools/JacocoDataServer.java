package com.comcast.xcal.xbo.tools;

import java.io.FileOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;

import org.jacoco.core.data.ExecutionDataWriter;
import org.jacoco.core.tools.ExecFileLoader;

/**
 * This example starts a socket server to collect coverage from agents that run
 * in output mode <code>tcpclient</code>. The collected data is dumped to a
 * local file.
 *
 * The following environment variables can be defined:
 *
 * jacoco.server.destFile - Destination file path [default: ./jacoco-it.exec]
 * jacoco.server.address  - Address to listen on [default: 0.0.0.0]
 * jacoco.server.port	  - TCP port to listen on [default: 25000]
 * jacoco.server.jmx      - true or false specifying whether to use JMX [default: false]
 * jacoco.server.jmx.endpoints - Comma separated list of server:port endpoints to connect to over JMX
 *
 * @author ramos001c
 * @since 3/2/2014
 */
public final class JacocoDataServer {

	private static final String DEFAULTDESTFILE = "jacoco-it.exec";
	private static final String DEFAULTADDRESS = "0.0.0.0";
	private static final int DEFAULTPORT = 25000;
	private static final boolean DEFAULTJMX = false;

	/**
	 * Start the server as a standalone program.
	 * 
	 * @param args
	 * @throws IOException
	 */
	public static void main(final String[] args) throws IOException {
		String destFile = (System.getProperty("jacoco.server.destFile") != null) ? System.getProperty("jacoco.server.destFile") : DEFAULTDESTFILE;
		String listenAddress = (System.getProperty("jacoco.server.address") != null) ? System.getProperty("jacoco.server.address") : DEFAULTADDRESS;
		int listenPort = (System.getProperty("jacoco.server.port") != null) ? Integer.parseInt(System.getProperty("jacoco.server.port")) : DEFAULTPORT;
		boolean jmxServer = (System.getProperty("jacoco.server.jmx") != null) ? System.getProperty("jacoco.server.jmx").equals("true") : DEFAULTJMX;

		final ExecutionDataWriter fileWriter;
		final ExecFileLoader fileLoader;
		final OutputStream fileWriterStream = new FileOutputStream(destFile);
		final File outputFile = new File(destFile);

		if(jmxServer && System.getProperty("jacoco.server.jmx.endpoints") != null) {
			String[] jmxEndpoints = System.getProperty("jacoco.server.jmx.endpoints").split(",");
			fileLoader = new ExecFileLoader();
			for(String endpointString : jmxEndpoints) {
				System.out.println("JacocoDataServer connecting to " + endpointString + " via JMX...");
				String[] splitString = endpointString.split(":");
				final JmxHandler jmxHandler = new JmxHandler(splitString[0], Integer.parseInt(splitString[1]), fileLoader, outputFile);
				new Thread(jmxHandler).start();
			}
			while(true) {
				try {
					Thread.sleep(1000);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		} else {
			final ServerSocket server = new ServerSocket(listenPort, 0, InetAddress.getByName(listenAddress));
			System.out.println("JacocoDataServer starting on " + listenAddress + ":" + Integer.toString(listenPort) + ". Outfile: " + destFile);
			fileWriter = new ExecutionDataWriter(fileWriterStream);
			while(true) {
				final ListenHandler listenHandler = new ListenHandler(server.accept(), fileWriter);
				new Thread(listenHandler).start();
			}
		}
	}
}
