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
package com.elementriver.potomac.sdk.app;


import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IMarker;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IProjectDescription;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.IResourceChangeEvent;
import org.eclipse.core.resources.IResourceChangeListener;
import org.eclipse.core.resources.IResourceDelta;
import org.eclipse.core.resources.IResourceVisitor;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.Path;
import org.eclipse.jface.dialogs.ErrorDialog;
import org.eclipse.jface.dialogs.IMessageProvider;
import org.eclipse.jface.dialogs.InputDialog;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.layout.GridDataFactory;
import org.eclipse.jface.layout.GridLayoutFactory;
import org.eclipse.jface.viewers.CellEditor;
import org.eclipse.jface.viewers.ColumnLabelProvider;
import org.eclipse.jface.viewers.ComboBoxCellEditor;
import org.eclipse.jface.viewers.DialogCellEditor;
import org.eclipse.jface.viewers.EditingSupport;
import org.eclipse.jface.viewers.ILabelProvider;
import org.eclipse.jface.viewers.ILabelProviderListener;
import org.eclipse.jface.viewers.IStructuredContentProvider;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.jface.viewers.TableViewerColumn;
import org.eclipse.jface.viewers.TextCellEditor;
import org.eclipse.jface.viewers.Viewer;
import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Text;
import org.eclipse.ui.IEditorInput;
import org.eclipse.ui.IEditorSite;
import org.eclipse.ui.IFileEditorInput;
import org.eclipse.ui.PartInitException;
import org.eclipse.ui.dialogs.ElementListSelectionDialog;
import org.eclipse.ui.dialogs.ListSelectionDialog;
import org.eclipse.ui.editors.text.TextEditor;
import org.eclipse.ui.forms.ManagedForm;
import org.eclipse.ui.forms.events.HyperlinkEvent;
import org.eclipse.ui.forms.events.IHyperlinkListener;
import org.eclipse.ui.forms.widgets.FormToolkit;
import org.eclipse.ui.forms.widgets.Hyperlink;
import org.eclipse.ui.forms.widgets.ScrolledForm;
import org.eclipse.ui.forms.widgets.Section;
import org.eclipse.ui.part.MultiPageEditorPart;

import com.adobe.flexbuilder.codemodel.common.CMFactory;
import com.adobe.flexbuilder.project.IClassPathEntry;
import com.adobe.flexbuilder.project.actionscript.ActionScriptCore;
import com.adobe.flexbuilder.project.actionscript.IActionScriptProject;
import com.adobe.flexbuilder.project.actionscript.internal.ActionScriptProjectSettings;
import com.elementriver.potomac.sdk.Potomac;
import com.elementriver.potomac.sdk.UpdateBuildPathJob;
import com.elementriver.potomac.sdk.bundles.BundleModel;
import com.elementriver.potomac.sdk.bundles.BundleModelManager;
import com.elementriver.potomac.sdk.bundles.PotomacBundleBuilder;

public class AppManifestEditor extends MultiPageEditorPart {

	private TextEditor editor;
	
	private IFile appManifest;
	
	private ManifestModel model;
	
	private ArrayList<String> dependencies = new ArrayList<String>();
	private ArrayList<String> preloads = new ArrayList<String>();
	private HashMap<String,String> templateProperties = new HashMap<String,String>();
	
	private boolean dirty = false;

	private boolean readOnly = false;

	private TableViewer dependenciesViewer;
	
	private ScrolledForm overviewForm;
	private ManagedForm managedForm;
	
	private IResourceChangeListener resourceListener;

	private Combo templateCombo;

	private TableViewer propertiesViewer;

	private ScrolledForm flagsForm;

	private TableViewer flagsViewer;

	private ScrolledForm airForm;

	private Text airBundlesURL;

	private Button airDisableCaching;
	
	public AppManifestEditor() {
		super();
	}


	void createPageOverview() {

		FormToolkit toolkit = new FormToolkit(getContainer().getDisplay());
		overviewForm = toolkit.createScrolledForm(getContainer());
		managedForm = new ManagedForm(toolkit,overviewForm);
		overviewForm.setText("Application Manifest");
		overviewForm.setImage(getTitleImage());
		toolkit.decorateFormHeading(overviewForm.getForm());	

		int index = addPage(overviewForm);
		setPageText(index, "Manifest");
		
		GridLayoutFactory.swtDefaults().margins(10,10).numColumns(2).equalWidth(true).applyTo(overviewForm.getBody());
		
		Section section = toolkit.createSection(overviewForm.getBody(), Section.TITLE_BAR | Section.DESCRIPTION);
		section.setText("UI Template");
		section.setDescription("Specify the UI template for the application.");
		
		GridDataFactory.fillDefaults().grab(true,true).applyTo(section);
		
		Composite c = toolkit.createComposite(section);
		section.setClient(c);
		
		GridLayoutFactory.fillDefaults().numColumns(2).extendedMargins(0, 0, 10, 0).applyTo(c);
		
		
		toolkit.createLabel(c, "Template:");
		templateCombo = new Combo(c,SWT.DROP_DOWN | SWT.READ_ONLY);
		GridData gd = new GridData();
		gd.grabExcessHorizontalSpace = true;
		gd.horizontalAlignment = SWT.FILL;
		templateCombo.setLayoutData(gd);
		
		templateCombo.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event event) {
				dirty = true;
				firePropertyChange(PROP_DIRTY);
				refreshTemplateProperties();
			}
		});
		templateCombo.setEnabled(!readOnly);
				
		dependencies.addAll(model.bundles);
		refreshTemplateChoices();
		
		if (model.templateID != null)
			templateCombo.select(templateCombo.indexOf(model.templateID));
		
		toolkit.createLabel(c,"");
		
		templateProperties = new HashMap<String,String>(model.templateProperties);
		
		
		section = toolkit.createSection(c, Section.TITLE_BAR | Section.DESCRIPTION);
		section.setText("Template Properties");
		section.setDescription("Specify the selected template's properties.");
		
		GridDataFactory.fillDefaults().span(2,1).grab(true,true).applyTo(section);
		
		c = toolkit.createComposite(section);
		section.setClient(c);
		
		GridLayoutFactory.fillDefaults().numColumns(1).extendedMargins(0, 0, 10, 0).applyTo(c);
		
		
		propertiesViewer = new TableViewer(toolkit.createTable(c, SWT.FULL_SELECTION));
		GridDataFactory.fillDefaults().grab(true,true).span(2,1).applyTo(propertiesViewer.getTable());
		propertiesViewer.getTable().setHeaderVisible(true);
		
		TableViewerColumn nameCol = new TableViewerColumn(propertiesViewer,SWT.NONE);
		nameCol.getColumn().setText("Property");
		nameCol.getColumn().setWidth(150);
		nameCol.setLabelProvider(new ColumnLabelProvider() {
			public String getText(Object element) {
				return (String)element;
			}			
		});

		TableViewerColumn valCol = new TableViewerColumn(propertiesViewer,SWT.NONE);
		valCol.getColumn().setText("Value");
		valCol.getColumn().setWidth(150);
		valCol.setLabelProvider(new ColumnLabelProvider() {
			public String getText(Object element)
			{
				return (String)templateProperties.get(element);
			}
		});
		
		final TextCellEditor textCellEditor = new TextCellEditor(propertiesViewer.getTable());
		final ComboBoxCellEditor comboCellEditor = new ComboBoxCellEditor(propertiesViewer.getTable(),new String[]{"false","true"});
		final DialogCellEditor dialogCellEditor = new DialogCellEditor(propertiesViewer.getTable()) {
			protected Object openDialogBox(Control cellEditorWindow) {
			 	ElementListSelectionDialog dialog =
					new ElementListSelectionDialog(getSite().getShell(),new ILabelProvider() {
						public void removeListener(ILabelProviderListener listener) {}
						public boolean isLabelProperty(Object element, String property) {
							return false;
						}
						public void dispose() {}
						public void addListener(ILabelProviderListener listener) {}
						public String getText(Object element) {
							return ((IResource)element).getProjectRelativePath().toString();
						}
						public Image getImage(Object element) {
							return null;
						}
					});
			 	
			 	final ArrayList<IResource> elements = new ArrayList<IResource>();
			 	try {
					appManifest.getProject().accept(new IResourceVisitor() {
						public boolean visit(IResource resource) throws CoreException {
							if (resource.getType() == IResource.FILE && (
								resource.getFileExtension().equalsIgnoreCase("png") || resource.getFileExtension().equalsIgnoreCase("gif") || resource.getFileExtension().equalsIgnoreCase("jpg")))
							{
								elements.add(resource);
							}
							
							return !resource.isDerived();
						}
					});
				} catch (CoreException e) {
		
					e.printStackTrace();
				}
			 
				dialog.setElements(elements.toArray());
				dialog.setHelpAvailable(false);
				dialog.setTitle("Select Image");
				dialog.setMessage("Specify an image in this project.");
				dialog.setFilter("*.*");
				dialog.open();
				if (dialog.getResult() == null) return null;
				IResource res = (IResource) dialog.getResult()[0];
				return res.getProjectRelativePath().toString();
			}
		};
		
		valCol.setEditingSupport(new EditingSupport(propertiesViewer) {
			protected void setValue(Object element, Object value) {
				if (value == null) return;
				String type = ((HashMap<String,String>)propertiesViewer.getInput()).get(element);
				String val = value.toString();
				if (type.equals("boolean"))
				{
					val = "false";
					if (value.equals(1))
					{
						val = "true";
					}
				}
				
				if (val.equals(templateProperties.get(element)))
					return;
				templateProperties.put(element.toString(),val);
				getViewer().update(element, null);
				dirty = true;
				firePropertyChange(PROP_DIRTY);
			}
			protected Object getValue(Object element) {
				String type = ((HashMap<String,String>)propertiesViewer.getInput()).get(element);
				if (type.equals("boolean"))
				{
					if (templateProperties.get(element) != null && templateProperties.get(element).equals("true")) return 1;
					return 0;
				}
				return templateProperties.get(element);
			}
			protected CellEditor getCellEditor(Object element) {
				String type = ((HashMap<String,String>)propertiesViewer.getInput()).get(element);
				if (type.equals("boolean")) return comboCellEditor;
				if (type.equals("image")) return dialogCellEditor;
				return textCellEditor;
			}
			protected boolean canEdit(Object element) {
				return true;
			}
		});
		
		propertiesViewer.setContentProvider(new IStructuredContentProvider() {
			public void inputChanged(Viewer viewer, Object oldInput, Object newInput) {
			}
			public void dispose() {
			}
			public Object[] getElements(Object inputElement) {
				if (inputElement == null) return new Object[]{};
				return ((HashMap)inputElement).keySet().toArray();
			}
		});

		
		refreshTemplateProperties();
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		section = toolkit.createSection(overviewForm.getBody(), Section.TITLE_BAR | Section.DESCRIPTION);
		section.setText("Bundles");
		section.setDescription("Specify the bundles that make up the payload for this application.");
		
		GridDataFactory.fillDefaults().grab(true,true).applyTo(section);
		
		c = toolkit.createComposite(section);
		section.setClient(c);
		
		GridLayoutFactory.fillDefaults().numColumns(2).extendedMargins(0, 0, 10, 0).applyTo(c);
		
		
		preloads.addAll(model.preloads);
		
		dependenciesViewer = new TableViewer(toolkit.createTable(c, SWT.NONE));
		dependenciesViewer.setContentProvider(new IStructuredContentProvider() {		
			public void inputChanged(Viewer viewer, Object oldInput, Object newInput) {
			}
			public void dispose() {
			}
			public Object[] getElements(Object inputElement) {
				return dependencies.toArray(new String[]{});
			}
		});
		dependenciesViewer.setLabelProvider(new ILabelProvider() {
			public void removeListener(ILabelProviderListener listener) {
			}
			public boolean isLabelProperty(Object element, String property) {
				return false;
			}
			public void dispose() {
			}
			public void addListener(ILabelProviderListener listener) {
			}
			public Image getImage(Object element) {
				return getTitleImage();
			}
			public String getText(Object element) {
				String bundle = (String) element;
				if (preloads.contains(bundle) && bundle.equals("potomac_core"))
					return bundle + " (Preload/RSL)";
				if (preloads.contains(bundle))
					return bundle + " (Preload)";
				return bundle;
			}
		});
		dependenciesViewer.setInput(dependencies);
		
		GridDataFactory.fillDefaults().grab(true,true).span(1,7).applyTo(dependenciesViewer.getTable());
		
		Button add = toolkit.createButton(c,"Add...",SWT.PUSH);
		GridDataFactory.swtDefaults().align(SWT.FILL,SWT.TOP).applyTo(add);
		add.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event event) {
				try {
					addBundles();
				} catch (CoreException e) {
					e.printStackTrace();
					MessageDialog.openError(getSite().getShell(),"Error retrieving bundles.",e.getMessage());
				}
			}
		});
		add.setEnabled(!readOnly);
		
		Button remove = toolkit.createButton(c,"Remove",SWT.PUSH);
		GridDataFactory.swtDefaults().align(SWT.FILL,SWT.TOP).applyTo(remove);
		remove.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event event) {
				IStructuredSelection sel = ((IStructuredSelection)dependenciesViewer.getSelection());
				if (!sel.isEmpty())
				{
					String bundle = (String) sel.getFirstElement();
					if (preloads.contains(bundle))
						preloads.remove(bundle);
					dependencies.remove(bundle);
					dependenciesViewer.remove(bundle);
					dirty = true;
					firePropertyChange(PROP_DIRTY);
					refreshTemplateChoices();
				}
			}
		});
		remove.setEnabled(!readOnly);
		
		Label spacer = toolkit.createLabel(c,"");
		GridDataFactory.swtDefaults().align(SWT.FILL,SWT.TOP).hint(1, 50).applyTo(spacer);
		
		Button toggleRSL = toolkit.createButton(c,"Toggle Preload",SWT.PUSH);
		GridDataFactory.swtDefaults().align(SWT.FILL,SWT.TOP).applyTo(toggleRSL);
		toggleRSL.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event event) {
				IStructuredSelection sel = ((IStructuredSelection)dependenciesViewer.getSelection());
				if (!sel.isEmpty())
				{
					String bundle = (String) sel.getFirstElement();
					if (preloads.contains(bundle))
					{
						preloads.remove(bundle);
					}
					else
					{
						preloads.add(bundle);
					}
					dependenciesViewer.refresh(bundle);
					dirty = true;
					firePropertyChange(PROP_DIRTY);
				}
			}
		});
		toggleRSL.setEnabled(!readOnly);	
		
		spacer = toolkit.createLabel(c,"");
		GridDataFactory.swtDefaults().align(SWT.FILL,SWT.TOP).hint(1, 10).applyTo(spacer);
		
		Button moveUp = toolkit.createButton(c,"Move Up",SWT.PUSH);
		GridDataFactory.swtDefaults().align(SWT.FILL,SWT.TOP).applyTo(moveUp);
		moveUp.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event event) {
				IStructuredSelection sel = ((IStructuredSelection)dependenciesViewer.getSelection());
				if (!sel.isEmpty())
				{
					String bundle = (String) sel.getFirstElement();
					
					int index = dependencies.indexOf(bundle);
					if (index == 0)
						return;
					
					String otherBundle = dependencies.set(index -1, bundle);
					dependencies.set(index, otherBundle);
					
					dependenciesViewer.refresh();
					dirty = true;
					firePropertyChange(PROP_DIRTY);
				}
			}
		});
		moveUp.setEnabled(!readOnly);
		
		
		Button moveDown = toolkit.createButton(c,"Move Down",SWT.PUSH);
		GridDataFactory.swtDefaults().align(SWT.FILL,SWT.TOP).applyTo(moveDown);
		moveDown.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event event) {
				IStructuredSelection sel = ((IStructuredSelection)dependenciesViewer.getSelection());
				if (!sel.isEmpty())
				{
					String bundle = (String) sel.getFirstElement();
					
					int index = dependencies.indexOf(bundle);
					if (index == dependencies.size() -1)
						return;
					
					String otherBundle = dependencies.set(index +1, bundle);
					dependencies.set(index, otherBundle);
					
					dependenciesViewer.refresh();
					dirty = true;
					firePropertyChange(PROP_DIRTY);
				}
			}
		});
		moveDown.setEnabled(!readOnly);
		
		Hyperlink updateBP = toolkit.createHyperlink(c, "Update Build Path Locations...",SWT.NONE);
		GridDataFactory.fillDefaults().span(2,1).applyTo(updateBP);
		updateBP.addHyperlinkListener(new IHyperlinkListener() {
			public void linkExited(HyperlinkEvent e) {}
			public void linkEntered(HyperlinkEvent e) {}
			public void linkActivated(HyperlinkEvent e) {
				if (!MessageDialog.openConfirm(null,"Update Build Path Locations","When projects are moved or the target platform directory is updated, it may be necessary to update the locations of SWC files in your build path.\r\n\r\nUpdate build path now?"))
					return;
				if (dirty)
					MessageDialog.openInformation(null,"Update Build Path Locations","Please save your changes before updating the build path.");				
				Potomac.updateBuidPath(appManifest.getProject(),preloads);
			}
		});
	}
	
	void createPageFlags() {

		FormToolkit toolkit = new FormToolkit(getContainer().getDisplay());
		flagsForm = toolkit.createScrolledForm(getContainer());
		ManagedForm flagsManagedForm = new ManagedForm(toolkit,flagsForm);
		flagsForm.setText("Application Manifest");
		flagsForm.setImage(getTitleImage());
		toolkit.decorateFormHeading(flagsForm.getForm());	

		int index = addPage(flagsForm);
		setPageText(index, "Flags");
		
		GridLayoutFactory.swtDefaults().margins(10,10).numColumns(2).equalWidth(true).applyTo(flagsForm.getBody());
		
		Section section = toolkit.createSection(flagsForm.getBody(), Section.TITLE_BAR | Section.DESCRIPTION);
		section.setText("Extension Enablement Flags");
		section.setDescription("Enablement flags are processed when an extension includes an 'enablesFor' attribute.");
		
		GridDataFactory.fillDefaults().grab(true,true).applyTo(section);
		
		Composite c = toolkit.createComposite(section);
		section.setClient(c);
		
		GridLayoutFactory.fillDefaults().numColumns(2).extendedMargins(0, 0, 10, 0).applyTo(c);

		
		flagsViewer = new TableViewer(toolkit.createTable(c, SWT.NONE));
		flagsViewer.setContentProvider(new IStructuredContentProvider() {		
			public void inputChanged(Viewer viewer, Object oldInput, Object newInput) {
			}
			public void dispose() {
			}
			public Object[] getElements(Object inputElement) {
				return model.enablesForFlags.toArray(new String[]{});
			}
		});
		flagsViewer.setLabelProvider(new ILabelProvider() {
			public void removeListener(ILabelProviderListener listener) {
			}
			public boolean isLabelProperty(Object element, String property) {
				return false;
			}
			public void dispose() {
			}
			public void addListener(ILabelProviderListener listener) {
			}
			public Image getImage(Object element) {
				return null;
			}
			public String getText(Object element) {
				return (String) element;
			}
		});
		flagsViewer.setInput(new Object());
		
		GridDataFactory.fillDefaults().grab(true,true).span(1,2).applyTo(flagsViewer.getTable());
		
		Button add = toolkit.createButton(c,"Add...",SWT.PUSH);
		GridDataFactory.swtDefaults().align(SWT.FILL,SWT.TOP).applyTo(add);
		add.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event event) {
				InputDialog dlg = new InputDialog(null,"Enter Flag","Please specify the new flag.",null,null);
				if (dlg.open() == InputDialog.OK)
				{
					model.enablesForFlags.add(dlg.getValue());
					flagsViewer.add(dlg.getValue());
					dirty = true;
					firePropertyChange(PROP_DIRTY);
				}
			}
		});
		add.setEnabled(!readOnly);
		
		Button remove = toolkit.createButton(c,"Remove",SWT.PUSH);
		GridDataFactory.swtDefaults().align(SWT.FILL,SWT.TOP).applyTo(remove);
		remove.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event event) {
				IStructuredSelection sel = ((IStructuredSelection)flagsViewer.getSelection());
				if (!sel.isEmpty())
				{
					String flag = (String) sel.getFirstElement();
					model.enablesForFlags.remove(flag);
					flagsViewer.remove(flag);
					dirty = true;
					firePropertyChange(PROP_DIRTY);
				}
			}
		});
		remove.setEnabled(!readOnly);		
		
	}
	
	void createPageAIR() {

		FormToolkit toolkit = new FormToolkit(getContainer().getDisplay());
		airForm = toolkit.createScrolledForm(getContainer());
		new ManagedForm(toolkit,airForm);
		airForm.setText("Application Manifest");
		airForm.setImage(getTitleImage());
		toolkit.decorateFormHeading(airForm.getForm());	

		int index = addPage(airForm);
		setPageText(index, "AIR");
		
		GridLayoutFactory.swtDefaults().margins(10,10).numColumns(1).equalWidth(true).applyTo(airForm.getBody());
		
		Section section = toolkit.createSection(airForm.getBody(), Section.TITLE_BAR | Section.DESCRIPTION);
		section.setText("Adobe Integrated Runtime");
		section.setDescription("When running in AIR, Potomac will download bundles remotely from the URL specified below.");
		
		GridDataFactory.fillDefaults().grab(true,true).applyTo(section);
		
		Composite c = toolkit.createComposite(section);
		section.setClient(c);
		
		GridLayoutFactory.fillDefaults().numColumns(2).extendedMargins(0, 0, 10, 0).applyTo(c);

		
		toolkit.createLabel(c, "URL to Remote Bundles Directory:");
		airBundlesURL = toolkit.createText(c, model.airBundlesURL);
		GridData gd = new GridData();
		gd.grabExcessHorizontalSpace = true;
		gd.horizontalAlignment = SWT.FILL;
		airBundlesURL.setLayoutData(gd);
		
		airBundlesURL.addListener(SWT.Modify, new Listener() {
			public void handleEvent(Event event) {
				dirty = true;
				firePropertyChange(PROP_DIRTY);
			}
		});
		airBundlesURL.setEnabled(!readOnly);		
		Label l = toolkit.createLabel(c,"(Ex. 'http://www.example.com/application/bundles')");
		
		gd = new GridData();
		gd.horizontalSpan = 2;
		gd.horizontalAlignment = SWT.RIGHT;
		l.setLayoutData(gd);
		l.setForeground(l.getDisplay().getSystemColor(SWT.COLOR_WIDGET_DARK_SHADOW));
		
		
		
		airDisableCaching = toolkit.createButton(c, "Disable Bundle Caching", SWT.CHECK);
		gd = new GridData();
		gd.grabExcessHorizontalSpace = true;
		gd.horizontalAlignment = SWT.FILL;
		gd.horizontalSpan = 2;
		airDisableCaching.setLayoutData(gd);
		
		airDisableCaching.setSelection(model.airDisableCaching);
		
		airDisableCaching.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event event) {
				dirty = true;
				firePropertyChange(PROP_DIRTY);
			}
		});
		
	}
	
	/**
	 * Creates the pages of the multi-page editor.
	 */
	protected void createPages() {

		if (appManifest.getParent() != appManifest.getProject())
		{
			getSite().getShell().getDisplay().asyncExec(new Runnable() {
				public void run() {
					MessageDialog.openWarning(getSite().getShell(),"Derived/Additional appManifest.xml","This appManifest.xml file is not the main appManifest.xml.  It is either a derived or copied version and therefore is read-only.");
				}
			});
			
			createPageText();
		}
		else
		{
			createPageOverview();
			
			try {
				if (appManifest.getProject().hasNature("com.adobe.flexbuilder.apollo.apollonature") ||
					appManifest.getProject().hasNature("com.adobe.flexbuilder.project.apollonature"))
				{
					createPageAIR();
				}
			} catch (CoreException e) {
				e.printStackTrace();
			}
			
			createPageFlags();
			
			updateMessages();			
		}
	}


	public void doSave(IProgressMonitor monitor) {

		
		//set project references (determines build order)
		ArrayList<IProject> projRefs = new ArrayList<IProject>();
		for (String depend : dependencies)
		{
			IProject proj = ResourcesPlugin.getWorkspace().getRoot().getProject(depend);
			projRefs.add(proj);
		}
		try {
			IProjectDescription projDesc = appManifest.getProject().getDescription();
			projDesc.setReferencedProjects(projRefs.toArray(new IProject[]{}));
			appManifest.getProject().setDescription(projDesc,null);
		} catch (CoreException e) {
			MessageDialog.openError(getSite().getShell(), "Error while updating project references.",e.getMessage());
		}
		
		
		model.bundles.clear();
		model.bundles.addAll(dependencies);
		model.preloads.clear();
		model.preloads.addAll(preloads);
		model.templateID = templateCombo.getText();
		model.templateProperties = templateProperties;
		
		if (airBundlesURL != null)
		{
			model.airBundlesURL = airBundlesURL.getText();
			model.airDisableCaching = airDisableCaching.getSelection();			
		}
		
		
		
		model.save(appManifest);
		dirty = false;
		firePropertyChange(PROP_DIRTY);		
		
	}



	public void init(IEditorSite site, IEditorInput editorInput)
		throws PartInitException {
		if (!(editorInput instanceof IFileEditorInput))
			throw new PartInitException("Invalid Input: Must be IFileEditorInput");
		super.init(site, editorInput);
		appManifest = (IFile) editorInput.getAdapter(IResource.class);

		readOnly = appManifest.isReadOnly();
		
		if (readOnly)
		{
			setPartName(appManifest.getFullPath().toString().substring(1) + " (read-only)");
		}
		else
		{
			setPartName(appManifest.getFullPath().toString().substring(1));	
		}		
		
		model = new ManifestModel(appManifest);
		
		resourceListener = new IResourceChangeListener() {
			public void resourceChanged(IResourceChangeEvent event) {
				IResourceDelta delta = event.getDelta().findMember(new Path(appManifest.getProject().getName() +"/appManifest.xml"));
				if (delta != null && delta.getMarkerDeltas().length > 0)
				{
					dependenciesViewer.getControl().getDisplay().asyncExec(new Runnable() {
						public void run() {
							updateMessages();
						}
					});					
				}
			}
		};
		appManifest.getWorkspace().addResourceChangeListener(resourceListener);
	}
	
	@Override 
	public void dispose()
	{
		appManifest.getWorkspace().removeResourceChangeListener(resourceListener);
	}
	
	/* (non-Javadoc)
	 * Method declared on IEditorPart.
	 */
	public boolean isSaveAsAllowed() {
		return false;
	}


	private void addBundles() throws CoreException
	{
		ArrayList<String> bundles = Potomac.getBundles();
		bundles.removeAll(dependencies);
		
		ListSelectionDialog dlg =
			   new ListSelectionDialog(
			       getSite().getShell(),
			       bundles,
			       new IStructuredContentProvider() {
						public void inputChanged(Viewer viewer, Object oldInput, Object newInput) {
						}
						public void dispose() {
						}
						public Object[] getElements(Object inputElement) {
							return ((ArrayList)inputElement).toArray();
						}
			       },
					new ILabelProvider() {
						public void removeListener(ILabelProviderListener listener) {
						}
						public boolean isLabelProperty(Object element, String property) {
							return false;
						}
						public void dispose() {
						}
						public void addListener(ILabelProviderListener listener) {
						}
						public String getText(Object element) {
							return (String)element;
						}
						public Image getImage(Object element) {
							return getTitleImage();
						}
					},
					 "Select one or more bundles:");

		dlg.setTitle("Add Bundles");
		dlg.setHelpAvailable(false);
		
		dlg.open();

		Object result[] = dlg.getResult();
		
		if (result == null)
			return;
		
		for (int i = 0; i < result.length; i++) {
			dependencies.add((String) result[i]);
			dependenciesViewer.add(result[i]);
		}
		
		dirty = true;
		firePropertyChange(PROP_DIRTY);
		refreshTemplateChoices();
	}

	@Override
	public boolean isDirty() {
		return dirty;
	}


	@Override
	public void doSaveAs() {
	}

	void createPageText() {
		try {
			editor = new TextEditor();
			//((StyledText)editor.getAdapter(Control.class)).setEditable(false);
			int index = addPage(editor, getEditorInput());
			setPageText(index, editor.getTitle());
		} catch (PartInitException e) {
			ErrorDialog.openError(
				getSite().getShell(),
				"Error creating nested text editor",
				null,
				e.getStatus());
		}
	}
	
	private void updateMessages()
	{
		IMarker markers[] = null;
		try {
			markers = appManifest.findMarkers(PotomacBundleBuilder.MARKER_TYPE,true,IResource.DEPTH_INFINITE);
		} catch (CoreException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		managedForm.getMessageManager().removeAllMessages();
		int i = 0;
		for (IMarker mark : markers)
		{
			i++;
			
			int type = IMessageProvider.ERROR;
			Integer markType = mark.getAttribute(IMarker.SEVERITY,IMarker.SEVERITY_ERROR);
			if (markType == IMarker.SEVERITY_INFO)
			{
				type = IMessageProvider.INFORMATION;
			}
			else if (markType == IMarker.SEVERITY_WARNING)
			{
				type = IMessageProvider.WARNING;
			}
			
			try {
				managedForm.getMessageManager().addMessage(i, mark.getAttribute(IMarker.MESSAGE)+"", null, type);
			} catch (CoreException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	}
	
	private void refreshTemplateChoices()
	{
		String sel = templateCombo.getText();
		templateCombo.removeAll();
		for(String bundle : dependencies)
		{
			try {
				BundleModel model = BundleModelManager.getInstance().getModel(bundle);
				for (HashMap<String,String> ext : model.extensions)
				{
					if (ext.get("point").equals("Template"))
					{
						templateCombo.add(ext.get("id"));
					}
				}
			} catch (Exception e) {
				//ignore - likely caused by an invalid/non-existent bundle
			}
		}
		if (templateCombo.indexOf(sel) >= 0)
		{
			templateCombo.setText(sel);
		}
		else
		{
			refreshTemplateProperties();
		}
			
	}
	
	private void refreshTemplateProperties()
	{
		HashMap<String,String> props = model.getTemplateParameters(templateCombo.getText(), dependencies);
		if (propertiesViewer != null)
			propertiesViewer.setInput(props);
	}
}
