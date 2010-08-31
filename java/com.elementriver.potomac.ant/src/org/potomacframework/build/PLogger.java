package org.potomacframework.build;

import flex2.tools.oem.Logger;
import flex2.tools.oem.Message;

public class PLogger implements Logger {

	@Override
	public void log(Message msg, int arg1, String src) {
		if (src != null)
			System.out.println("[" + msg.getPath() +":"+msg.getLine()+"] "+msg.toString());
		
		System.out.println(msg.toString());

	}

}
