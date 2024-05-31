# Summary

This is a **hacky** set of Bash scripts that I use to burn downloaded video files (for example, [episodes of Mister Rogers]) onto an NTSC DVD, including a simple menu that allows selection by filename.

It makes a number of assumptions (such as 4:3 aspect ratio) and should be considered a potential starting point, not a polished product.

## Underpinnings

This project uses:

- [ffmpeg] to convert audio files to the correct format
- [dvdauthor] to create ISO images from formatted video files
- [ImageMagick] to create images for the menu
- [lame] to create an empty MP2 audio file for the menu
- [MJPEG tools] to compile the menu MPEG
- [cdrtools] to create the DVD ISO

# Usage

## Environment variables

Some settings can be overridden with environment variables. See `make-dvd.sh` for the default values.

- `DVD_TITLE` - optional disc title string
- `BITRATE` - optional ffmpeg video bitrate
- `BITRATE_MULTIPLIER` - floating point scaling factor for bitrate

## Examples

    iso=$(env DVD_TITLE="MisterRogers 1481-1485" ./make-dvd.sh ../files/*{1481..1485}*)
    hdiutil burn -nosynthesize -noverifyburn -forceclose "$iso"

[ImageMagick]: https://imagemagick.org
[MJPEG tools]: http://mjpeg.sourceforge.net
[cdrtools]: https://cdrtools.sourceforge.net/private/cdrecord.html
[dvdauthor]: https://dvdauthor.sourceforge.net/
[ffmpeg]: https://ffmpeg.org/
[lame]: https://lame.sourceforge.io/

[episodes of Mister Rogers]: https://www.misterrogers.org/watch/
