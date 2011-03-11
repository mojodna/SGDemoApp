# SGDemoApp

This is a sample application that shows off many of the different components
within the `SGClient`, `SGMapKit` and `SGAREnvironment` repositories. The
`SGLocationService` is used to load records from multiple global layers. The
records are then displayed in three different avenues: `UITableView`,
`SGLayerMapView` and `SGARNavigationViewController`.

Both the `UITableView` and `SGARNavigationViewController` will only display
those records that are within 1km radius of the devices current location. The
AR environment is set to one of the standard styles. The map will load and
display records based on the displayed region of the view.

In order to run the demo, you must already possess an OAuth key and secret from
the [SimpleGeo dashboard](http://simplegeo.com). The demo application defines
a default OAuth token which will not work. You must update the file at
`Resources/Token.plist` with your personal OAuth token or else the application
will complain about the OAuth token and exit.

To access layers from SimpleGeo you must first accept the ToS that comes with
the layer.  After creating an account, layers can be accessed from the
SimpleGeo marketplace. Once you have the name of the layer you want to use, you
can add the layer as a new data source to the `SGLayerViewController`.

To update the repositories that this demo application depends on, run
`./update_sg_sdk` within the project directory. The SimpleGeo static libraries
that come packaged with the repository should not require an update but in the
case that they are out of date, the `update_sg_sdk` script should be executed.

## Build Requirements

iPhone SDK >= 4.0

Frameworks

* `CoreLocation`
* `Foundation`
* `MapKit`
* `OpenGLES`
* `CoreGraphics`
* `AudioVideo`
* `UIKit`

## Runtime Requirements

iPhone OS >= 4.0

- - - - -

Copyright (C) 2009-2011 SimpleGeo Inc. All rights reserved.
