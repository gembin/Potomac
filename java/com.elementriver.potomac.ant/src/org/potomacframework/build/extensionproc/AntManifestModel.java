package org.potomacframework.build.extensionproc;

import java.io.File;

import com.elementriver.potomac.shared.BundleModelManager;
import com.elementriver.potomac.shared.ManifestModel;

public class AntManifestModel extends ManifestModel{
	
	private AntBundleModelManager bundleModelManager;

	public AntManifestModel(File manifest,AntBundleModelManager bundleModelManager)
	{		
		this.bundleModelManager = bundleModelManager;
		populate(manifest);
	}

	@Override
	protected BundleModelManager getBundleModelManager()
	{
		return bundleModelManager;
	}
	
}
