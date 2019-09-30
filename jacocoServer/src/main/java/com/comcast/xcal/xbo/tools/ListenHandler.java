package com.comcast.xcal.xbo.tools;

import java.io.IOException;
import java.net.Socket;

import org.jacoco.core.data.ExecutionData;
import org.jacoco.core.data.ExecutionDataWriter;
import org.jacoco.core.data.IExecutionDataVisitor;
import org.jacoco.core.data.ISessionInfoVisitor;
import org.jacoco.core.data.SessionInfo;
import org.jacoco.core.runtime.RemoteControlReader;
import org.jacoco.core.runtime.RemoteControlWriter;

public class ListenHandler implements Runnable, ISessionInfoVisitor, IExecutionDataVisitor {
	private final Socket socket;
	private final RemoteControlReader reader;
	private final ExecutionDataWriter fileWriter;
	private final RemoteControlWriter writer;

	ListenHandler(final Socket socket, final ExecutionDataWriter fileWriter) throws IOException {
		this.socket = socket;
		this.fileWriter = fileWriter;

		// Just send a valid header:
		writer = new RemoteControlWriter(socket.getOutputStream());

		reader = new RemoteControlReader(socket.getInputStream());
		reader.setSessionInfoVisitor(this);
		reader.setExecutionDataVisitor(this);
	}

	public void run() {
		try {
			while (reader.read()) {
			}
			socket.close();
			synchronized (fileWriter) {
				fileWriter.flush();
			}
		} catch (final Exception e) {
			e.printStackTrace();
		}
	}

	public void visitSessionInfo(final SessionInfo info) {
		System.out.printf("Retrieving execution data for session: %s%n", info.getId());
		synchronized (fileWriter) {
			fileWriter.visitSessionInfo(info);
		}
	}

	public void visitClassExecution(final ExecutionData data) {
		synchronized (fileWriter) {
			fileWriter.visitClassExecution(data);
		}
	}
}
