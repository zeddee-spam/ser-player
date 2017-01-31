#!/bin/bash

copy_libs_for_binary()
{
    echo "Copying libs for binary $1 to $2"

    libs=$(ldd $1)

    lib=()
    mapfile -t lib <<< "$libs"
    for lib in "${lib[@]}"
    do
        #echo "lib: ${lib}"
        a=( $lib )
        count=${#a[@]}
        if ((count > 3)); then
            cp -n ${a[2]} $2
            sub_libs=$(ldd ${a[2]})
            sub_lib=()
            mapfile -t sub_lib <<< "$sub_libs"
            for lib2 in "${sub_lib[@]}"
            do
                #echo "    lib2: ${lib2}"
                a2=( $lib2 )
                count2=${#a2[@]}
                if ((count2 > 3)); then
                    cp -n ${a2[2]} $2
                fi
            done
        fi
    done
}


# Run the get_qt_details.sh script to set details of the Qt installation and the architecture
# This script is generated by qmake and sets the $QT_INSTALL_DIR and $SYS_ARCH variables.
this_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $this_dir/get_qt_details.sh

# Create temp directory to work in when creating the AppImage
rm -rf temp
mkdir temp
cd temp

# Checkout and build AppImageKit
##git clone https://github.com/probonopd/AppImageKit.git
##
##cd AppImageKit 
##./build.sh
##cd ..

# Get the AppImage script functions file
wget https://github.com/probonopd/AppImages/raw/master/functions.sh -O ./functions.sh
. ./functions.sh

# Create the AppImage directory structure
mkdir -p ser-player.AppDir/usr/bin
#mkdir -p ser-player.AppDir/usr/lib/ser-player/libs
mkdir -p ser-player.AppDir/usr/lib/ser-player/platforms
mkdir -p ser-player.AppDir/usr/lib/ser-player/plugins/imageformats
mkdir -p ser-player.AppDir/usr/share/applications
mkdir -p ser-player.AppDir/usr/share/icons
mkdir -p ser-player.AppDir/usr/share/mime/packages

# Copy ser-player executable file into place and strip it
cp ../../bin/ser-player ser-player.AppDir/usr/lib/ser-player/
strip -s ser-player.AppDir/usr/lib/ser-player/ser-player
chmod 0755 ser-player.AppDir/usr/lib/ser-player/ser-player
chrpath -d ser-player.AppDir/usr/lib/ser-player/ser-player

# Copy shell script and wrapper files
cp ../files/ser-player ser-player.AppDir/usr/bin/
cp ../files/ser-player.wrapper ser-player.AppDir/usr/bin/

# Copy files in share directories
cp ../files/share/ser-player.desktop ser-player.AppDir/usr/share/applications/
cp ../files/ser-player.png ser-player.AppDir/usr/share/icons/
cp ../files/share/ser-player.xml ser-player.AppDir/usr/share/mime/packages/

# Copy file into top level of AppDir
APP_RUN_FILE="AppRun-$SYS_ARCH"
wget https://github.com/probonopd/AppImageKit/releases/download/continuous/$APP_RUN_FILE
chmod a+x $APP_RUN_FILE
cp $APP_RUN_FILE ser-player.AppDir/AppRun
#cp ./AppImageKit/build/AppRun ser-player.AppDir/
cp ../files/ser-player.desktop ser-player.AppDir/
cp ../files/ser-player.png ser-player.AppDir/

# Copy Qt platform plugin to AppDir
cp ${QT_INSTALL_DIR}/plugins/platforms/libqxcb.* ser-player.AppDir/usr/lib/ser-player/platforms/

# Copy other Qt plugins to AppDir
cp ${QT_INSTALL_DIR}/plugins/imageformats/libqjpeg.* ser-player.AppDir/usr/lib/ser-player/plugins/imageformats/
cp ${QT_INSTALL_DIR}/plugins/imageformats/libqtiff.* ser-player.AppDir/usr/lib/ser-player/plugins/imageformats/

# Copy all required libs to AppDir
copy_libs_for_binary ../../bin/ser-player ser-player.AppDir/usr/lib/
copy_libs_for_binary ${QT_INSTALL_DIR}/plugins/platforms/libqxcb.so ser-player.AppDir/usr/lib/
copy_libs_for_binary ${QT_INSTALL_DIR}/plugins/imageformats/libqjpeg.so ser-player.AppDir/usr/lib/
copy_libs_for_binary ${QT_INSTALL_DIR}/plugins/imageformats/libqtiff.so ser-player.AppDir/usr/lib/

# Remove excluded libraries
cd ser-player.AppDir/usr/lib/
delete_blacklisted
cd ../../..

# Strip all libs and change permissions
strip -s ser-player.AppDir/usr/lib/lib*
chmod 0644 ser-player.AppDir/usr/lib/lib*

# Get the glibc version required using the glibc_need() function from the AppImageKit functions.sh 
cd ser-player.AppDir
GLIBC_NEEDED=$(glibc_needed)
cd ..

APPIMAGETOOL_FILE="appimagetool-$SYS_ARCH.AppImage"
wget https://github.com/probonopd/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod a+x $APPIMAGETOOL_FILE
./$APPIMAGETOOL_FILE ./ser-player.AppDir/ ../ser-player-x.x.x-glibc${GLIBC_NEEDED}-${SYS_ARCH}.AppImage

#./AppImageKit/build/appimagetool ./ser-player.AppDir/ ../ser-player-x.x.x-glibc${GLIBC_NEEDED}-${SYS_ARCH}.AppImage

cd ..
rm -rf temp
