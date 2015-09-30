# PRGalleryView

A subclass of UIView that will load most common media formats and display in the
appropriate view. This is helpful when implementing a gallery of media in tiles
when the type of media can be mixed or is unknown.

The following formats are implemented:

* Static images (UIImageView)
* Animated GIF (FLAnimatedImage)
* Video (AVPlayer)

## Usage

Include `PRGalleryView.swift` and use the `PRGalleryView` UIView in a storyboard
or in code. Media can be loaded via an `NSURL` using the `media` attribute:

```
let gallery: PRGalleryView = PRGalleryView(frame: CGRectMake(0, 0, 250, 250))
gallery.media = NSURL(string: "http://raphaelschaad.com/static/nyan.gif")
```

The type of media object will be determined and displayed in the view.

## Customization

Access to each of the view layers is available at `imageView` and
`videoController` for further customization of the view behavior. This can be
used to, among other things, set view clipping and background colors to ensure
the gallery display matches your requirements.

The type of loaded media can be accessed at `PRGalleryView.type`. This will
return a `PRGalleryType` of either `Video`, `Animated`, or `Image`.

Lastly, control over playback of animated GIF and Video files are available
with `play()`, `pause()`, and `stop()`. By default, animated GIF images will be
loaded in a playing state.

Video and GIF files can be locked to a static representation by setting the
`shouldAllowPlayback` value to `false`. For videos, this will display a static
frame from the video file. This is useful for a gallery of thumbnails where
playback is not necessary. You can start and stop playback from the static state
using the methods above. In this case, when `stop()` is called on a Video where
`shouldAllowPlayback` is `false`, the video is replaced with the static frame.
