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

import java.util.ArrayList;
import java.util.Iterator;

import org.eclipse.jface.dialogs.IInputValidator;
import org.eclipse.jface.dialogs.InputDialog;
import org.eclipse.jface.layout.GridDataFactory;
import org.eclipse.jface.layout.GridLayoutFactory;
import org.eclipse.jface.preference.PreferencePage;
import org.eclipse.jface.viewers.DoubleClickEvent;
import org.eclipse.jface.viewers.IDoubleClickListener;
import org.eclipse.jface.viewers.IStructuredContentProvider;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.jface.viewers.Viewer;
import org.eclipse.jface.viewers.ViewerSorter;
import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.ui.IWorkbench;
import org.eclipse.ui.IWorkbenchPreferencePage;

import com.adobe.flexbuilder.codemodel.common.CMFactory;

public class IgnoredMetadataPrefPage extends PreferencePage implements
		IWorkbenchPreferencePage {
	
	private ArrayList<String> tags;
	private TableViewer viewer;

	public IgnoredMetadataPrefPage() {
		setPreferenceStore(Activator.getDefault().getPreferenceStore());
	}

	@Override
	protected Control createContents(Composite parent) {
		Composite composite = new Composite(parent,SWT.NONE);
		GridLayoutFactory.swtDefaults().numColumns(2).equalWidth(false).applyTo(composite);
		
		Label l = new Label(composite,SWT.WRAP);
		l.setText("The following list of metadata is ignored by the Potomac builder.  Any metadata tags not in this list and not representing valid extension points will be marked as unknown.");
		GridDataFactory.swtDefaults().span(3,1).align(SWT.FILL,SWT.FILL).grab(false,false).hint(200,SWT.DEFAULT).applyTo(l);
		
		viewer = new TableViewer(composite,SWT.BORDER | SWT.MULTI | SWT.V_SCROLL);
		GridDataFactory.fillDefaults().span(1,3).grab(true,true).hint(100,400).applyTo(viewer.getTable());
		
		viewer.setContentProvider(new IStructuredContentProvider() {
			public void inputChanged(Viewer viewer, Object oldInput, Object newInput) {
			}		
			public void dispose() {
			}
			public Object[] getElements(Object inputElement) {
				return tags.toArray();
			}
		});
		
		tags = (ArrayList<String>) IgnoredMetadata.getTags().clone();
		
		viewer.setInput(tags);
		
		viewer.addDoubleClickListener(new IDoubleClickListener() {
			public void doubleClick(DoubleClickEvent event) {
				edit();
			}
		});
		
		viewer.setSorter(new ViewerSorter());
		
		Button add = new Button(composite,SWT.PUSH);
		add.setText("Add");
		setButtonLayoutData(add);
		add.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event event) {
				InputDialog input = new InputDialog(getShell(), "Add Metadata Tag", "Tag name (no brackets):", "", new IInputValidator() {
					public String isValid(String newText) {
						if (!CMFactory.getASIdentifierAnalyzer().isValidIdentifierName(newText))
							return "The specified name is not a valid metadata tag name.";
						return null;
					}
				});
				
				input.setErrorMessage("");
				
				if (input.open() == InputDialog.OK)
				{
					String newTag = input.getValue();
					tags.add(newTag);
					viewer.add(newTag);
				}
			}
		});
		
		Button edit = new Button(composite,SWT.PUSH);
		edit.setText("Edit...");
		setButtonLayoutData(edit);
		edit.addListener(SWT.Selection,new Listener() {
			public void handleEvent(Event event) {
				edit();
			}
		});
		
		Button remove = new Button(composite,SWT.PUSH);
		remove.setText("Remove");
		setButtonLayoutData(remove).verticalAlignment = SWT.TOP;
		remove.addListener(SWT.Selection,new Listener() {
			public void handleEvent(Event event) {
				if (viewer.getSelection().isEmpty())
					return;
				
				IStructuredSelection sel = (IStructuredSelection) viewer.getSelection();
				for (Iterator iterator = sel.iterator(); iterator.hasNext();) 
				{
					Object element = iterator.next();
					viewer.remove(element);
					tags.remove(element);
				}
			}
		});
		
		return composite;
	}
	
	@Override
	protected void performDefaults() {
		tags = IgnoredMetadata.getDefaults();
		viewer.refresh();
		super.performDefaults();
	}

	private void edit()
	{
		if (viewer.getSelection().isEmpty())
			return;
		
		IStructuredSelection sel = (IStructuredSelection) viewer.getSelection();

		InputDialog input = new InputDialog(getShell(), "Edit Metadata Tag", "Tag name (no brackets):", (String) sel.getFirstElement(), new IInputValidator() {
			public String isValid(String newText) {
				if (!CMFactory.getASIdentifierAnalyzer().isValidIdentifierName(newText))
					return "The specified name is not a valid metadata tag name.";
				return null;
			}
		});
		
		if (input.open() == InputDialog.OK)
		{
			String newTag = input.getValue();
			viewer.remove(sel.getFirstElement());
			viewer.add(newTag);
			tags.remove(sel.getFirstElement());
			tags.add(newTag);
		}	
	}

	public void init(IWorkbench workbench) {
		
	}
	
	@Override
	public boolean performOk()
	{
		IgnoredMetadata.saveTags(tags);

		return true;
	}

}
