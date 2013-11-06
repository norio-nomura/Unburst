Unburst ReproduceIssue branch
-----------------------------
iPhone 5s burst mode embed burst mode specific metadata. it cause problems with below APIs at least.

	-[ALAssetsLibrary writeImageDataToSavedPhotosAlbum:metadata:completionBlock:]
	-[ALAsset writeModifiedImageDataToSavedPhotosAlbum:metadata:completionBlock:]

These APIs fail without calling completion block if `metadata[@"{MakerApple}"][@"11"]` exists.

These results has been tested on iPhone 5s with iOS 7.0.3 (11B511). 2013/11/06.

Maybe other `AssetsLibrary.framework` API which taking metadata as parameter will fail, but I did not test them.

Unburst
-------
iOS Camera sets Apple specific dictionary for key`{MakerApple}` into the metadata of photo.
Burst Mode on iPhone 5s set value for key `11` into the Apple specific dictionary.
The key `11` metadata prevent some apps(e.g. Instagram) from creating new `ALAssets` into Camera Roll.

`Unburst` removes the key `11` from metadata of burst mode photo and send it to apps which support opening `public.jpeg` document type.

License
-------
	(The WTFPL)
	
	            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
	                    Version 2, December 2004
	
	 Copyright (C) 2013 Norio Nomura
	
	 Everyone is permitted to copy and distribute verbatim or modified
	 copies of this license document, and changing it is allowed as long
	 as the name is changed.
	
	            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
	   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
	
	  0. You just DO WHAT THE FUCK YOU WANT TO.
