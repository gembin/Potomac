/*******************************************************************************
 *  Copyright (c) 2009 ElementRiver, LLC.
 *  All rights reserved. This program and the accompanying materials
 *  are made available under the terms of the Eclipse Public License v1.0
 *  which accompanies this distribution, and is available at
 *  http://www.eclipse.org/legal/epl-v10.html
 * 
 *  Contributors:
 *     ElementRiver, LLC. - initial API and implementation
 *******************************************************************************/
package com.elementriver.potomac.sdk;

import org.eclipse.core.runtime.Platform;
import org.eclipse.jface.preference.*;
import org.eclipse.swt.SWT;
import org.eclipse.swt.program.Program;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Link;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.ui.IWorkbenchPreferencePage;
import org.eclipse.ui.IWorkbench;



public class PrefPage
	extends FieldEditorPreferencePage
	implements IWorkbenchPreferencePage {

	public PrefPage() {
		super(GRID);
		setPreferenceStore(Activator.getDefault().getPreferenceStore());
		setDescription("Potomac Framework Preferences");
	}
	

	public void createFieldEditors() {
		addField(new DirectoryFieldEditor(PreferenceConstants.TARGET_PLATFORM, 
				"&Target Platform:", getFieldEditorParent()));
		addField(new BooleanFieldEditor(PreferenceConstants.LOGGING, "Activate Logging/Tracing", getFieldEditorParent()));
		
		Link link = new Link(getFieldEditorParent(),SWT.NONE);
		link.setText("(<a>view log file</a>)");
		link.addListener(SWT.Selection, new Listener()
		{			
			public void handleEvent(Event event)
			{
				String logFile = Platform.getLogFileLocation().toOSString();
			    Program.launch(logFile);
			}
		});
		
	}

	/* (non-Javadoc)
	 * @see org.eclipse.ui.IWorkbenchPreferencePage#init(org.eclipse.ui.IWorkbench)
	 */
	public void init(IWorkbench workbench) {
	}
	
}