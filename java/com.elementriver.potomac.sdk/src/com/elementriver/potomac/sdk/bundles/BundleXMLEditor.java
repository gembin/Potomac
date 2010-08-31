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
package com.elementriver.potomac.sdk.bundles;


import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IMarker;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IProjectDescription;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.IResourceChangeEvent;
import org.eclipse.core.resources.IResourceChangeListener;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.Path;
import org.eclipse.jface.action.ControlContribution;
import org.eclipse.jface.dialogs.ErrorDialog;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.layout.GridDataFactory;
import org.eclipse.jface.layout.GridLayoutFactory;
import org.eclipse.jface.viewers.DoubleClickEvent;
import org.eclipse.jface.viewers.IDoubleClickListener;
import org.eclipse.jface.viewers.ILabelProvider;
import org.eclipse.jface.viewers.ILabelProviderListener;
import org.eclipse.jface.viewers.ISelectionChangedListener;
import org.eclipse.jface.viewers.IStructuredContentProvider;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.jface.viewers.ITableLabelProvider;
import org.eclipse.jface.viewers.ITreeContentProvider;
import org.eclipse.jface.viewers.SelectionChangedEvent;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.jface.viewers.TreeViewer;
import org.eclipse.jface.viewers.Viewer;
import org.eclipse.jface.viewers.ViewerFilter;
import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.Text;
import org.eclipse.ui.IEditorInput;
import org.eclipse.ui.IEditorPart;
import org.eclipse.ui.IEditorSite;
import org.eclipse.ui.IFileEditorInput;
import org.eclipse.ui.IWorkbenchPage;
import org.eclipse.ui.PartInitException;
import org.eclipse.ui.dialogs.ListDialog;
import org.eclipse.ui.dialogs.ListSelectionDialog;
import org.eclipse.ui.editors.text.TextEditor;
import org.eclipse.ui.forms.events.HyperlinkAdapter;
import org.eclipse.ui.forms.events.HyperlinkEvent;
import org.eclipse.ui.forms.events.IHyperlinkListener;
import org.eclipse.ui.forms.widgets.Form;
import org.eclipse.ui.forms.widgets.FormToolkit;
import org.eclipse.ui.forms.widgets.Hyperlink;
import org.eclipse.ui.forms.widgets.Section;
import org.eclipse.ui.ide.IDE;
import org.eclipse.ui.part.FileEditorInput;
import org.eclipse.ui.part.MultiPageEditorPart;
import org.eclipse.ui.texteditor.MarkerUtilities;

import com.adobe.flexbuilder.codemodel.common.CMFactory;
import com.adobe.flexbuilder.codemodel.definitions.IClass;
import com.adobe.flexbuilder.project.ClassPathEntryFactory;
import com.adobe.flexbuilder.project.IClassPathEntry;
import com.adobe.flexbuilder.project.actionscript.ActionScriptCore;
import com.adobe.flexbuilder.project.actionscript.IActionScriptProject;
import com.adobe.flexbuilder.project.actionscript.internal.ActionScriptProjectSettings;
import com.elementriver.potomac.sdk.Activator;
import com.elementriver.potomac.sdk.Potomac;
import com.elementriver.potomac.sdk.UpdateBuildPathJob;

public class BundleXMLEditor extends MultiPageEditorPart implements IResourceChangeListener, Listener{

	private TextEditor editor;

	private IFile bundlexml;
	private BundleModel model;
	private ArrayList<String> dependencies = new ArrayList<String>();
	
	private TableViewer dependenciesViewer;
	
	private boolean dirty = false;

	private Text versionText;

	private Text nameText;

	private TreeViewer extensionsViewer;

	private TreeViewer pointsViewer;
	
	private boolean readOnly = false;

	private Text activatorText;
	

	public BundleXMLEditor() {
		super();
	}


	void createPageOverview() {

		FormToolkit toolkit = new FormToolkit(getContainer().getDisplay());
		Form form = toolkit.createForm(getContainer());
		form.setText("Overview");
		form.setImage(getTitleImage());
		toolkit.decorateFormHeading(form);


		int index = addPage(form);
		setPageText(index, "Overview");
		
		GridLayoutFactory.swtDefaults().margins(10,10).numColumns(2).applyTo(form.getBody());
		
		Section section = toolkit.createSection(form.getBody(), Section.TITLE_BAR | Section.DESCRIPTION);
		section.setText("Bundle Properties");
		section.setDescription("Specify the general bundle properties.");
		
		GridDataFactory.fillDefaults().grab(true,true).applyTo(section);
		
		Composite c = toolkit.createComposite(section);
		section.setClient(c);
		
		GridLayoutFactory.fillDefaults().numColumns(3).extendedMargins(0, 0, 10, 0).applyTo(c);
		
		toolkit.createLabel(c, "ID:");
		
		Label id = toolkit.createLabel(c,model.id);
		GridData gd = new GridData();
		gd.horizontalSpan = 2;
		gd.grabExcessHorizontalSpace = true;
		gd.horizontalAlignment = SWT.FILL;
		id.setLayoutData(gd);		
		
		toolkit.createLabel(c, "Version:");		
		versionText = toolkit.createText(c,model.version);
		gd = new GridData();
		gd.horizontalSpan = 2;
		gd.grabExcessHorizontalSpace = true;
		gd.horizontalAlignment = SWT.FILL;
		versionText.setLayoutData(gd);
		
		versionText.addListener(SWT.Modify, new Listener() {
			public void handleEvent(Event event) {
				dirty = true;
				firePropertyChange(PROP_DIRTY);
			}
		});
		versionText.setEditable(!readOnly);
		
		toolkit.createLabel(c, "Name:");
		
		nameText = toolkit.createText(c,model.name);
		gd = new GridData();
		gd.horizontalSpan = 2;
		gd.grabExcessHorizontalSpace = true;
		gd.horizontalAlignment = SWT.FILL;
		nameText.setLayoutData(gd);
		nameText.addListener(SWT.Modify, new Listener() {
			public void handleEvent(Event event) {
				dirty = true;
				firePropertyChange(PROP_DIRTY);
			}
		});
		nameText.setEditable(!readOnly);
		
		
		Hyperlink activatorHyper = toolkit.createHyperlink(c, "Activator:", SWT.NONE);
		activatorHyper.addHyperlinkListener(new IHyperlinkListener() {
			public void linkExited(HyperlinkEvent e) {
			}
			public void linkEntered(HyperlinkEvent e) {
			}
			public void linkActivated(HyperlinkEvent e1) {
				if (activatorText.getText().equals("")) return;
				IFile file = Potomac.getFileFromFlexClassName(activatorText.getText(), bundlexml.getProject());
				if (file == null)
				{
					MessageDialog.openError(getSite().getShell(), "Error opening editor", "Activator is not a valid fully qualified class name.");
					return;
				}
				try {
					IDE.openEditor(getSite().getPage(), file);
				} catch (PartInitException e) {
					e.printStackTrace();
					MessageDialog.openError(getSite().getShell(), "Error opening editor", e.getMessage());
				}
			}
		});
		
		activatorText = toolkit.createText(c,model.activator);
		gd = new GridData();
		gd.grabExcessHorizontalSpace = true;
		gd.horizontalAlignment = SWT.FILL;
		activatorText.setLayoutData(gd);
		activatorText.addListener(SWT.Modify, new Listener() {
			public void handleEvent(Event event) {
				dirty = true;
				firePropertyChange(PROP_DIRTY);
			}
		});
		activatorText.setEditable(!readOnly);
		
		Button browseActivator = toolkit.createButton(c,"Browse",SWT.PUSH);
		browseActivator.addListener(SWT.Selection,new Listener() {
			public void handleEvent(Event event) {
				// TODO Auto-generated method stub
		
				ListDialog lDialog = new ListDialog(null);
				lDialog.setContentProvider(new IStructuredContentProvider() {
					public void inputChanged(Viewer viewer, Object oldInput, Object newInput) {
					}
					public void dispose() {
					}
					public Object[] getElements(Object inputElement) {
						try {
							return Potomac.getAllClassesInProject(bundlexml.getProject(),"flash.events.IEventDispatcher").toArray();
						} catch (CoreException e) {
							e.printStackTrace();
							MessageDialog.openError(null, "Error Retrieving Classes", e.getMessage());
						}
						return new Object[]{};
					}
				});
				lDialog.setLabelProvider(new ILabelProvider() {
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
						return ((IClass)element).getQualifiedName();
					}
					public Image getImage(Object element) {
						return Activator.getDefault().classImage;
					}
				});
				lDialog.setInput(new Object());
				lDialog.setHelpAvailable(false);
				lDialog.setTitle("Select Activator Class");
				lDialog.setMessage("Specify an instance to receive bundle lifecycle events (must implement IEventDispatcher).");
						
				lDialog.open();
				
				Object result[] = lDialog.getResult();
				if (result != null)
				{
					activatorText.setText(((IClass)result[0]).getQualifiedName());
				}
				
			}
		});
		
		section = toolkit.createSection(form.getBody(), Section.TITLE_BAR | Section.DESCRIPTION);
		section.setText("Dependencies");
		section.setDescription("Specify the required bundles.");
		
		GridDataFactory.fillDefaults().grab(true,true).applyTo(section);
		
		c = toolkit.createComposite(section);
		section.setClient(c);
		
		GridLayoutFactory.fillDefaults().numColumns(2).extendedMargins(0, 0, 10, 0).applyTo(c);
		
		dependencies.addAll(model.dependencies);
		
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
				return (String)element;
			}
		});
		dependenciesViewer.setInput(dependencies);
		
		GridDataFactory.fillDefaults().grab(true,true).span(1,2).applyTo(dependenciesViewer.getTable());
		
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
					dependencies.remove(sel.getFirstElement());
					dependenciesViewer.remove(sel.getFirstElement());
					dirty = true;
					firePropertyChange(PROP_DIRTY);
				}
			}
		});
		remove.setEnabled(!readOnly);
		
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
				Potomac.updateBuidPath(bundlexml.getProject(),dependencies);
			}
		});
	}


	void createPageExtensions() {
		FormToolkit toolkit = new FormToolkit(getContainer().getDisplay());
		Form form = toolkit.createForm(getContainer());
		form.setText("Extensions");
		form.setImage(getTitleImage());
		toolkit.decorateFormHeading(form);


		int index = addPage(form);
		setPageText(index, "Extensions");
		
		GridLayoutFactory.swtDefaults().margins(10,10).numColumns(2).applyTo(form.getBody());
		
		Section section = toolkit.createSection(form.getBody(), Section.TITLE_BAR | Section.DESCRIPTION);
		section.setText("Extensions");
		section.setDescription("Browse the list of extensions contributed by this bundle.");
		
		GridDataFactory.fillDefaults().grab(true,true).applyTo(section);
		
		Composite c = toolkit.createComposite(section);
		section.setClient(c);
		
		GridLayoutFactory.fillDefaults().numColumns(1).extendedMargins(0, 0, 10, 0).applyTo(c);
		
		
		extensionsViewer = new TreeViewer(toolkit.createTree(c,SWT.NONE));
		extensionsViewer.setContentProvider(new ITreeContentProvider() {
			public void inputChanged(Viewer viewer, Object oldInput, Object newInput) {
			}
			public void dispose() {
			}
			public Object[] getElements(Object inputElement) {
				ArrayList pointsExtended = new ArrayList();
				for (HashMap<String,String> ext : model.extensions) {
					if (!pointsExtended.contains(ext.get("point")))
							pointsExtended.add(ext.get("point"));
				}
				return pointsExtended.toArray();
			}
		
			
			public boolean hasChildren(Object element) {
				return (element instanceof String);
			}
			public Object getParent(Object element) {
				return null;
			}
			public Object[] getChildren(Object parentElement) {
				ArrayList kids = new ArrayList();
				for (HashMap<String,String> ext : model.extensions) {
					if (ext.get("point").equals(parentElement))
					{
						kids.add(ext);
					}
				}
				return kids.toArray();
			}
		});
		extensionsViewer.setLabelProvider(new ILabelProvider() {
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
				if (element instanceof String) return (String) element;
				HashMap<String,String> ext = (HashMap<String,String>) element;
				if (ext.containsKey("id"))
					return ext.get("id");
				
				String text = ext.get("class");
				text = text.substring(text.lastIndexOf('.') + 1);
				if (ext.containsKey("variable"))
				{
					text += "#" + ext.get("variable");
				}
				else if (ext.containsKey("function"))
				{
					text += "#" + ext.get("function");
				}
				return text;
			}
			public Image getImage(Object element) {
				if (element instanceof String) return Activator.getDefault().extensionPointImage;
				return Activator.getDefault().extensionImage;
			}
		});
		extensionsViewer.setInput(new Object());
		
		GridDataFactory.fillDefaults().grab(true,true).applyTo(extensionsViewer.getTree());
		
		
		
		section = toolkit.createSection(form.getBody(), Section.TITLE_BAR | Section.DESCRIPTION);
		section.setText("Extension Details");
		section.setDescription("Details for the selected extension.");
		
		GridDataFactory.fillDefaults().grab(true,true).applyTo(section);
		
		c = toolkit.createComposite(section);
		section.setClient(c);
		
		GridLayoutFactory.fillDefaults().numColumns(2).extendedMargins(0, 0, 10, 0).applyTo(c);
			
		toolkit.createLabel(c,"ID:");
		final Label idLabel = toolkit.createLabel(c,"");
		GridDataFactory.fillDefaults().grab(true,false).applyTo(idLabel);

		toolkit.createLabel(c,"Found in:");
		final Hyperlink classHyper = toolkit.createHyperlink(c,"",SWT.NONE);
		GridDataFactory.fillDefaults().grab(true,false).applyTo(classHyper);
		classHyper.setEnabled(false);
		
		
		final TableViewer detailsViewer = new TableViewer(toolkit.createTable(c, SWT.FULL_SELECTION));
		GridDataFactory.fillDefaults().grab(true,true).span(2,1).applyTo(detailsViewer.getTable());
		detailsViewer.getTable().setHeaderVisible(true);
		
		TableColumn nameCol = new TableColumn(detailsViewer.getTable(),SWT.NONE);
		nameCol.setText("Attribute");
		nameCol.setWidth(150);

		
		TableColumn valCol = new TableColumn(detailsViewer.getTable(),SWT.NONE);
		valCol.setText("Value");
		valCol.setWidth(150);
		
		detailsViewer.setContentProvider(new IStructuredContentProvider() {
			public void inputChanged(Viewer viewer, Object oldInput, Object newInput) {
			}
			public void dispose() {
			}
			public Object[] getElements(Object inputElement) {
				if (inputElement == null) return new Object[]{};
				return ((HashMap)inputElement).keySet().toArray();
			}
		});
		detailsViewer.setFilters(new ViewerFilter[]{new ViewerFilter() {
			public boolean select(Viewer viewer, Object parentElement, Object element) {
				if (element.equals("point")) return false;
				if (element.equals("id")) return false;
				if (element.equals("class")) return false;
				if (element.equals("bundle")) return false;
				if (element.equals("codeStart")) return false;
				if (element.equals("codeEnd")) return false;
				if (element.equals("function")) return false;
				if (element.equals("functionSignature")) return false;
				if (element.equals("variable")) return false;
				if (element.equals("variableType")) return false;
				return true;
			}
		}});
		
		detailsViewer.setLabelProvider(new ITableLabelProvider() {
			public void removeListener(ILabelProviderListener listener) {
			}
			public boolean isLabelProperty(Object element, String property) {
				return false;
			}
			public void dispose() {
			}
			public void addListener(ILabelProviderListener listener) {
			}
			public String getColumnText(Object element, int columnIndex) {
				if (columnIndex == 0)
				{
					return (String) element;
				}
				else
				{
					return (String) ((HashMap)detailsViewer.getInput()).get(element);
				}
			}
			public Image getColumnImage(Object element, int columnIndex) {
				return null;
			}
		});
		
		extensionsViewer.addSelectionChangedListener(new ISelectionChangedListener() {
			public void selectionChanged(SelectionChangedEvent event) {
				if (event.getSelection().isEmpty())
				{
					clearDetails();
					return;
				}
				IStructuredSelection sel = (IStructuredSelection) event.getSelection();
				if (sel.getFirstElement() instanceof String)
				{
					clearDetails();
					return;
				}
				detailsViewer.setInput(sel.getFirstElement());
				HashMap ext = ((HashMap)sel.getFirstElement());
				classHyper.setText((String) ext.get("class"));
				classHyper.setToolTipText(classHyper.getText());
				classHyper.setEnabled(true);
				if (ext.containsKey("id"))
				{
					idLabel.setText((String) ext.get("id"));	
				}
				else
				{
					idLabel.setText("");
				}
			}
			
			private void clearDetails()
			{
				detailsViewer.setInput(null);
				classHyper.setText("");
				classHyper.setToolTipText("");
				idLabel.setText("");
				classHyper.setEnabled(false);
			}
		});
		
		classHyper.addHyperlinkListener(new HyperlinkAdapter() {
			public void linkActivated(HyperlinkEvent e) {
				HashMap<String,String> ext = (HashMap) detailsViewer.getInput();
				gotoMetadata(ext);
			}			
		});
		
		extensionsViewer.addDoubleClickListener(new IDoubleClickListener() {
			public void doubleClick(DoubleClickEvent event) {
				if (event.getSelection().isEmpty()) return;
				HashMap<String,String> ext = ((HashMap)((IStructuredSelection)event.getSelection()).getFirstElement());
				gotoMetadata(ext);
			}
		});
		
	}
	
	void createPageExtensionPoints() {
		FormToolkit toolkit = new FormToolkit(getContainer().getDisplay());
		Form form = toolkit.createForm(getContainer());
		form.setText("Extension Points");
		form.setImage(getTitleImage());
		toolkit.decorateFormHeading(form);


		int index = addPage(form);
		setPageText(index, "Extension Points");
		
		GridLayoutFactory.swtDefaults().margins(10,10).numColumns(2).applyTo(form.getBody());
		
		final Section masterSection = toolkit.createSection(form.getBody(), Section.TITLE_BAR | Section.DESCRIPTION);
		masterSection.setText("Extension Points");
		masterSection.setDescription("Browse the list of extension points declared by this bundle.");
		
		GridDataFactory.fillDefaults().grab(true,true).applyTo(masterSection);
		
		Composite c = toolkit.createComposite(masterSection);
		masterSection.setClient(c);
		
		GridLayoutFactory.fillDefaults().numColumns(1).extendedMargins(0, 0, 10, 0).applyTo(c);
		
		pointsViewer = new TreeViewer(toolkit.createTree(c,SWT.NONE));
		pointsViewer.setContentProvider(new ITreeContentProvider() {
			public void inputChanged(Viewer viewer, Object oldInput, Object newInput) {
			}
			public void dispose() {
			}
			public Object[] getElements(Object inputElement) {
				if (inputElement == model.extensionPoints)
					return model.extensionPoints.toArray();

				ArrayList<String> elements = new ArrayList<String>(model.dependencies);
				elements.add(model.id);
				return elements.toArray();
			}
			public Object[] getChildren(Object parentElement) {
				if (!(parentElement instanceof String)) return null;
				BundleModel model = BundleModelManager.getInstance().getModel((String) parentElement);
				return model.extensionPoints.toArray();
			}
			public Object getParent(Object element) {
				return null;
			}
			public boolean hasChildren(Object element) {
				if (element instanceof String) return true;
				return false;
			}
		});
		pointsViewer.setLabelProvider(new ILabelProvider() {
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
				if (element instanceof String) return (String) element;
				return (String) ((HashMap)element).get("id");
			}
			public Image getImage(Object element) {
				if (element instanceof String) return getTitleImage();
				return Activator.getDefault().extensionPointImage;
			}
		});
		pointsViewer.setInput(model.extensionPoints);
		
		GridDataFactory.fillDefaults().grab(true,true).applyTo(pointsViewer.getTree());
		
		
		
		Section section = toolkit.createSection(form.getBody(), Section.TITLE_BAR | Section.DESCRIPTION);
		section.setText("Extension Point Details");
		section.setDescription("Details for the selected extension point.");
		
		GridDataFactory.fillDefaults().grab(true,true).applyTo(section);
		
		c = toolkit.createComposite(section);
		section.setClient(c);
		
		GridLayoutFactory.fillDefaults().numColumns(2).extendedMargins(0, 0, 10, 0).applyTo(c);
			
		toolkit.createLabel(c,"ID:");
		final Label idLabel = toolkit.createLabel(c,"");
		GridDataFactory.fillDefaults().grab(true,false).applyTo(idLabel);

		toolkit.createLabel(c,"Found in:");
		final Hyperlink classHyper = toolkit.createHyperlink(c,"",SWT.NONE);
		GridDataFactory.fillDefaults().grab(true,false).applyTo(classHyper);
		classHyper.setEnabled(false);

		
		final TableViewer detailsViewer = new TableViewer(toolkit.createTable(c, SWT.FULL_SELECTION));
		GridDataFactory.fillDefaults().grab(true,true).span(2,1).applyTo(detailsViewer.getTable());
		detailsViewer.getTable().setHeaderVisible(true);
		
		TableColumn nameCol = new TableColumn(detailsViewer.getTable(),SWT.NONE);
		nameCol.setText("Attribute");
		nameCol.setWidth(150);

		
		TableColumn valCol = new TableColumn(detailsViewer.getTable(),SWT.NONE);
		valCol.setText("Type");
		valCol.setWidth(150);
		
		detailsViewer.setContentProvider(new IStructuredContentProvider() {
			public void inputChanged(Viewer viewer, Object oldInput, Object newInput) {
			}
			public void dispose() {
			}
			public Object[] getElements(Object inputElement) {
				if (inputElement == null) return new Object[]{};
				return ((HashMap)inputElement).keySet().toArray();
			}
		});
		detailsViewer.setFilters(new ViewerFilter[]{new ViewerFilter() {
			public boolean select(Viewer viewer, Object parentElement, Object element) {
				if (element.equals("bundle")) return false;
				if (element.equals("id")) return false;
				if (element.equals("declaredBy")) return false;
				if (element.equals("codeStart")) return false;
				if (element.equals("codeEnd")) return false;
				return true;
			}
		}});
		
		detailsViewer.setLabelProvider(new ITableLabelProvider() {
			public void removeListener(ILabelProviderListener listener) {
			}
			public boolean isLabelProperty(Object element, String property) {
				return false;
			}
			public void dispose() {
			}
			public void addListener(ILabelProviderListener listener) {
			}
			public String getColumnText(Object element, int columnIndex) {
				if (columnIndex == 0)
				{
					return (String) element;
				}
				else
				{
					return (String) ((HashMap)detailsViewer.getInput()).get(element);
				}
			}
			public Image getColumnImage(Object element, int columnIndex) {
				return null;
			}
		});
		
		pointsViewer.addSelectionChangedListener(new ISelectionChangedListener() {
			public void selectionChanged(SelectionChangedEvent event) {
				if (event.getSelection().isEmpty())
				{
					clearDetails();
					return;
				}
				IStructuredSelection sel = (IStructuredSelection) event.getSelection();
				if (sel.getFirstElement() instanceof String)
				{
					clearDetails();
					return;
				}
				detailsViewer.setInput(sel.getFirstElement());
				HashMap ext = ((HashMap)sel.getFirstElement());
				classHyper.setText((String) ext.get("declaredBy"));
				classHyper.setToolTipText(classHyper.getText());
				classHyper.setEnabled(true);
				idLabel.setText((String) ext.get("id"));				
			}
			
			private void clearDetails()
			{
				detailsViewer.setInput(null);
				classHyper.setText("");
				classHyper.setToolTipText("");
				idLabel.setText("");
				classHyper.setEnabled(false);
			}
		});
		
		classHyper.addHyperlinkListener(new HyperlinkAdapter() {
			public void linkActivated(HyperlinkEvent e) {
				HashMap<String,String> ext = (HashMap) detailsViewer.getInput();
				gotoMetadata(ext);
			}			
		});
		
		pointsViewer.addDoubleClickListener(new IDoubleClickListener() {
			public void doubleClick(DoubleClickEvent event) {
				if (event.getSelection().isEmpty()) return;
				HashMap<String,String> ext = ((HashMap)((IStructuredSelection)event.getSelection()).getFirstElement());
				gotoMetadata(ext);
			}
		});
		
		
		ControlContribution heading = new ControlContribution("") {
			protected Control createControl(Composite parent) {
				Composite c = new Composite (parent,SWT.NONE);
				GridLayoutFactory.swtDefaults().numColumns(2).applyTo(c);
				Label l = new Label(c,SWT.NONE);
				GridData gd= new GridData();
				gd.widthHint = 20;
				l.setLayoutData(gd);
				final Button b = new Button(c,SWT.CHECK);
				b.setText("Show Extension Points in Required Bundles");
				b.addListener(SWT.Selection,new Listener() {
					public void handleEvent(Event event) {
						if (b.getSelection())
						{
							pointsViewer.setInput(new Object());
							masterSection.setDescription("Browse the list of extension points declared by this bundle and all its dependencies.");
							masterSection.getParent().layout();
						}
						else 
						{
							pointsViewer.setInput(model.extensionPoints);
							masterSection.setDescription("Browse the list of extension points declared by this bundle.");
							masterSection.getParent().layout();
						}
					}
				});
				return c;
			}
		};
		
		form.getToolBarManager().add(heading);

		form.getToolBarManager().update(true);	// NEW LINE
		form.setToolBarVerticalAlignment(SWT.RIGHT);
	}
	
	void createPageText() {
		try {
			editor = new TextEditor();
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
	

	protected void createPages() {

		//createPageText();
		if (bundlexml.getParent() != bundlexml.getProject())
		{
			getSite().getShell().getDisplay().asyncExec(new Runnable() {
				public void run() {
					MessageDialog.openError(getSite().getShell(),"Derived/Additional Bundle.xml","Only the primary bundle.xml defined in the project root can be edited by the Bundle Manifest Editor.");
				}
			});
			
			createPageText();
		}
		else
		{
			createPageOverview();
			createPageExtensions();
			createPageExtensionPoints();
		}
	}


	public void dispose() {
		ResourcesPlugin.getWorkspace().removeResourceChangeListener(this);
		BundleModelManager.getInstance().removeListener(this);
		super.dispose();
	}


	public void doSave(IProgressMonitor monitor) {
		model.version = versionText.getText();
		model.name = nameText.getText();
		model.activator = activatorText.getText();
		
		ActionScriptProjectSettings flexProjectSettings = null;

		if (!CMFactory.getRegistrar().isProjectRegistered(bundlexml.getProject()))
		{
			CMFactory.getRegistrar().registerProject(bundlexml.getProject(),null);
		}
		
		synchronized (CMFactory.getLockObject())
   	 	{	
			IActionScriptProject proj = ActionScriptCore.getProject(bundlexml);
			
			flexProjectSettings = ( ActionScriptProjectSettings ) proj.getProjectSettings();
			ArrayList<IClassPathEntry> libraryPaths = new ArrayList<IClassPathEntry>(Arrays.asList(flexProjectSettings.getLibraryPath()));

			
			//remove older entries
			for (Iterator iterator = model.dependencies.iterator(); iterator.hasNext();) {
				String dependency = (String) iterator.next();
				if (!dependencies.contains(dependency))
				{
					//remove it
					for (Iterator iterator2 = libraryPaths.iterator(); iterator2.hasNext();) {
						IClassPathEntry classPathEntry = (IClassPathEntry) iterator2.next();
						if (classPathEntry.getKind() != IClassPathEntry.KIND_LIBRARY_FILE)
							continue;
						
						String name = classPathEntry.getValue();			
						if (name.contains(dependency + ".swc"))
						{
							libraryPaths.remove(classPathEntry);
							break;
						}
					}
				}				
			}
			
			//create new entries
			for (Iterator iterator = dependencies.iterator(); iterator.hasNext();) {
				String dependency = (String) iterator.next();
				if (!model.dependencies.contains(dependency))
				{
					String swcPath = Potomac.getSWCPath(dependency);
					IClassPathEntry classPathEntry = ClassPathEntryFactory.newEntry(IClassPathEntry.KIND_LIBRARY_FILE,swcPath, flexProjectSettings );
					classPathEntry.setLinkType(IClassPathEntry.LINK_TYPE_EXTERNAL);
					libraryPaths.add( classPathEntry );					
				}
			}
			
			flexProjectSettings.setLibraryPath( libraryPaths.toArray( new IClassPathEntry[ libraryPaths.size() ] ) );
			//flexProjectSettings.saveDescription(bundlexml.getProject(), new NullProgressMonitor());
   	 	}
		
		//set project references (determines build order)
		ArrayList<IProject> projRefs = new ArrayList<IProject>();
		for (String depend : dependencies)
		{
			IProject proj = ResourcesPlugin.getWorkspace().getRoot().getProject(depend);
			projRefs.add(proj);
		}
		try {
			IProjectDescription projDesc = bundlexml.getProject().getDescription();
			projDesc.setReferencedProjects(projRefs.toArray(new IProject[]{}));
			bundlexml.getProject().setDescription(projDesc,null);
		} catch (CoreException e) {
			MessageDialog.openError(getSite().getShell(), "Error while updating project references.",e.getMessage());
		}
		
		model.dependencies.clear();
		model.dependencies.addAll(dependencies);
		model.dirty = true;
		BundleModelManager.getInstance().saveModel(model.id,false);
		dirty = false;
		firePropertyChange(PROP_DIRTY);		
		
		UpdateBuildPathJob job = new UpdateBuildPathJob();
		job.project = bundlexml.getProject();
		job.settings = flexProjectSettings;
		job.setRule(UpdateBuildPathJob.getRule(bundlexml.getProject()));
		job.schedule();
	}

	/* (non-Javadoc)
	 * Method declared on IEditorPart
	 */
	public void gotoMarker(IMarker marker) {
		setActivePage(0);
		IDE.gotoMarker(getEditor(0), marker);
	}


	public void init(IEditorSite site, IEditorInput editorInput)
		throws PartInitException {
		if (!(editorInput instanceof IFileEditorInput))
			throw new PartInitException("Invalid Input: Must be IFileEditorInput");
		super.init(site, editorInput);
		bundlexml = (IFile) editorInput.getAdapter(IResource.class);
		model = BundleModelManager.getInstance().getModel(bundlexml.getProject().getName());
		
		readOnly = bundlexml.isReadOnly();
		
		if (readOnly)
		{
			setPartName(bundlexml.getFullPath().toString().substring(1) + " (read-only)");
		}
		else
		{
			setPartName(bundlexml.getFullPath().toString().substring(1));	
		}		
		
		BundleModelManager.getInstance().addListener(this);
	}
	/* (non-Javadoc)
	 * Method declared on IEditorPart.
	 */
	public boolean isSaveAsAllowed() {
		return false;
	}

	/**
	 * Closes all project files on project close.
	 */
	public void resourceChanged(final IResourceChangeEvent event){
		if(event.getType() == IResourceChangeEvent.PRE_CLOSE){
			Display.getDefault().asyncExec(new Runnable(){
				public void run(){
					IWorkbenchPage[] pages = getSite().getWorkbenchWindow().getPages();
					for (int i = 0; i<pages.length; i++){
						if(((FileEditorInput)editor.getEditorInput()).getFile().getProject().equals(event.getResource())){
							IEditorPart editorPart = pages[i].findEditor(editor.getEditorInput());
							pages[i].closeEditor(editorPart,true);
						}
					}
				}            
			});
		}
	}

	private void addBundles() throws CoreException
	{
		ArrayList<String> bundles = Potomac.getBundles();
		bundles.remove(model.id);
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

		dlg.setTitle("Add Dependencies");
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
	}

	private void gotoMetadata(HashMap<String,String> extOrPt) 
	{
		String bundle = extOrPt.get("bundle");
		String className = null;
		if (extOrPt.containsKey("declaredBy"))
		{
			className = extOrPt.get("declaredBy");
		}
		else
		{
			className = extOrPt.get("class");
		}
		
		if (!ResourcesPlugin.getWorkspace().getRoot().exists(new Path(bundle)))
		{
			MessageDialog.openError(getSite().getShell(), "External Bundle" , "Can't open a class defined in an external bundle.  The bundle must exist in the workspace.");
			return;
		}
		
		IProject proj = ResourcesPlugin.getWorkspace().getRoot().getProject(bundle);
		
		int charStart = Integer.parseInt(extOrPt.get("codeStart"));
		int charEnd = Integer.parseInt(extOrPt.get("codeEnd"));
		
		IFile file = Potomac.getFileFromFlexClassName(className, proj);
		
		if (!file.exists())
		{
			MessageDialog.openError(getSite().getShell(), "Class Not Found", "Can't find the specified class file.");
		}
		
        try {
			IMarker marker = file.createMarker(IMarker.MARKER);
			MarkerUtilities.setCharStart(marker, charStart);
			MarkerUtilities.setCharEnd(marker, charEnd);			
			IDE.openEditor(getSite().getPage(), marker);
			marker.delete();
		} catch (PartInitException e) {
			e.printStackTrace();
			MessageDialog.openError(getSite().getShell(), "Error opening editor",e.getMessage());
		} catch (CoreException e) {
			e.printStackTrace();
			MessageDialog.openError(getSite().getShell(), "Error opening editor", e.getMessage());
		}

		return;
	}


	@Override
	public boolean isDirty() {
		return dirty;
	}


	@Override
	public void doSaveAs() {
	}


	//When a bundle change event comes
	public void handleEvent(Event event) {
		if (event.data.equals(model.id)){
			getContainer().getDisplay().asyncExec(new Runnable() {
				public void run() {
					if (extensionsViewer != null)
					{
						extensionsViewer.refresh(true);
						pointsViewer.refresh(true);
					}
				}
			});
		}
		
	}

}
