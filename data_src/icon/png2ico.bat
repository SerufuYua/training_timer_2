@echo off
echo Using ImageMagick (https://imagemagick.org) to convert PNGs to ICO
magick icon_256.png icon_128.png icon_064.png icon_048.png icon_032.png icon_024.png -define icon icon.ico
pause
