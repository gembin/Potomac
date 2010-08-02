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

import org.eclipse.core.resources.IPathVariableManager;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.Path;
import org.eclipse.core.runtime.Status;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.resource.ImageDescriptor;
import org.eclipse.jface.util.IPropertyChangeListener;
import org.eclipse.jface.util.PropertyChangeEvent;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.widgets.Display;
import org.eclipse.ui.plugin.AbstractUIPlugin;
import org.eclipse.ui.statushandlers.StatusManager;
import org.osgi.framework.BundleContext;

/**
 * The activator class controls the plug-in life cycle
 */
public class Activator extends AbstractUIPlugin {

	// The plug-in ID
	public static final String PLUGIN_ID = "com.elementriver.potomac.sdk";
	
	public static final String TARGETPLAT_PATHVAR = "PotomacTargetPlatform";

	// The shared instance
	private static Activator plugin;
	
	public Image extensionImage;
	public Image extensionPointImage;
	public Image classImage;
	
	/**
	 * The constructor
	 */
	public Activator() {
	}

	/*
	 * (non-Javadoc)
	 * @see org.eclipse.ui.plugin.AbstractUIPlugin#start(org.osgi.framework.BundleContext)
	 */
	public void start(BundleContext context) throws Exception {
		super.start(context);
		plugin = this;
		extensionImage = getImageDescriptor("icons/ext.gif").createImage();
		extensionPointImage = getImageDescriptor("icons/extpoint.gif").createImage();
		classImage = getImageDescriptor("icons/class.gif").createImage();
		
		setupTargetPlatPathVar();
		getDefault().getPreferenceStore().addPropertyChangeListener(new IPropertyChangeListener() {
			public void propertyChange(PropertyChangeEvent event) {
				if (event.getProperty().equals(PreferenceConstants.TARGET_PLATFORM))
				{
					setupTargetPlatPathVar();
				}
			}
		});

	}

	/*
	 * (non-Javadoc)
	 * @see org.eclipse.ui.plugin.AbstractUIPlugin#stop(org.osgi.framework.BundleContext)
	 */
	public void stop(BundleContext context) throws Exception {
		plugin = null;
		super.stop(context);
		extensionImage.dispose();
		extensionPointImage.dispose();
		classImage.dispose();
	}

	/**
	 * Returns the shared instance
	 *
	 * @return the shared instance
	 */
	public static Activator getDefault() {
		return plugin;
	}

	/**
	 * Returns an image descriptor for the image file at the given
	 * plug-in relative path
	 *
	 * @param path the path
	 * @return the image descriptor
	 */
	public static ImageDescriptor getImageDescriptor(String path) {
		return imageDescriptorFromPlugin(PLUGIN_ID, path);
	}
	
    public static void setupTargetPlatPathVar()
    {
        IPathVariableManager varManager = ResourcesPlugin.getWorkspace().getPathVariableManager();
        IPath value = new Path(getDefault().getPreferenceStore().getString(com.elementriver.potomac.sdk.PreferenceConstants.TARGET_PLATFORM));
        
        if (varManager.validateValue(value).isOK())
        {
        	try {
				varManager.setValue(TARGETPLAT_PATHVAR, value);
			} catch (CoreException e) {
				e.printStackTrace();
				MessageDialog.openError(Display.getDefault().getActiveShell(), "Path Variable Error", e.getMessage());
			}
        }
    }
    
    public static void handleCoreException(String title, CoreException e)
    {
        StatusManager.getManager().handle(
                new Status(IStatus.ERROR, PLUGIN_ID,
                        title, e));
    }
}
