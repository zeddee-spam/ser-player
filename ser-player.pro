# ---------------------------------------------------------------------
# Copyright (C) 2019 Chris Garry
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Variables that can be passed at qmake stage:
#
# BUILD_FOR_REPOSITORY
# Example: qmake CONFIG+=release BUILD_FOR_REPOSITORY=
# This sets options required when building for a repository.
# * Application version fixed rather than generated from GIT commands.
# * New version checking is disabled in the application.
# * 'make install' does not call display manager cache update commands.
#
# BUILD_FOR_APPIMAGE
# Example: qmake CONFIG+=release BUILD_FOR_APPIMAGE=
# This sets options required when building for a Linux AppImage
# * 'make install' does not call display manager cache update commands.
# ---------------------------------------------------------------------


defined(BUILD_FOR_REPOSITORY, var) {
    APP_VERSION="v1.7.2"
    export(APP_VERSION)
}

defined(BUILD_FOR_REPOSITORY, var) {
    DEFINES += DISABLE_NEW_VERSION_CHECK
}

!defined(APP_VERSION, var) {
    # The app version has not been explicitly defined
    # Get the version of the app from the last git tag and a few other things
    GIT_LAST_TAG=$$system(git describe --always --abbrev=0)
    GIT_VERSION=$$system(git describe --always --dirty)
    GIT_VERSION_SPLIT=$$split(GIT_VERSION, -)
    GIT_DESCRIBE_ELEMENT0=$$member(GIT_VERSION_SPLIT, 0)
    GIT_DESCRIBE_ELEMENT1=$$member(GIT_VERSION_SPLIT, 1)
    GIT_DESCRIBE_ELEMENT2=$$member(GIT_VERSION_SPLIT, 2)
    GIT_DESCRIBE_ELEMENT3=$$member(GIT_VERSION_SPLIT, 3)
    GIT_DESCRIBE_ELEMENTS=1
    isEmpty(GIT_DESCRIBE_ELEMENT0) {
        error("Could not get SER Player version using git describe")
    } else:isEmpty(GIT_DESCRIBE_ELEMENT1) {
        GIT_DESCRIBE_ELEMENTS=1
    } else:isEmpty(GIT_DESCRIBE_ELEMENT2) {
        GIT_DESCRIBE_ELEMENTS=2
    } else:isEmpty(GIT_DESCRIBE_ELEMENT3) {
        GIT_DESCRIBE_ELEMENTS=3
    } else {
        GIT_DESCRIBE_ELEMENTS=4
    }

    APP_VERSION=$${GIT_LAST_TAG}

    greaterThan(GIT_DESCRIBE_ELEMENTS, 2) {
        # There have been commits since the last tag
        GIT_COMMITS_SINCE_TAG=$$member(GIT_VERSION_SPLIT, 1)
        APP_VERSION=$${APP_VERSION}.$$GIT_COMMITS_SINCE_TAG
    }

    isEqual(GIT_DESCRIBE_ELEMENTS, 2) | isEqual(GIT_DESCRIBE_ELEMENTS, 4) {
        message("Warning: Building a dirty build")
        APP_VERSION=$${APP_VERSION}."dirty"
    }

    export(APP_VERSION)
}


message("Version: $${APP_VERSION}")
DEFINES += APP_VERSION_STRING=\\\"$${APP_VERSION}\\\"

!macx:!win32 {
    # On linux write out the application version to a file
    TEMP="export VERSION=$${APP_VERSION}"
    write_file("export_app_version.sh", TEMP);
} else:win32 {
    # On windows write out the application version to a file in the NSIS directory
    TEMP="; This file is autogenerated by QMAKE"
    write_file("ser_player_nsis/version.nsh", TEMP);
    TEMP="!define PRODUCT_VERSION \"$${APP_VERSION}\""
    write_file("ser_player_nsis/version.nsh", TEMP, append);
}

contains(DEFINES, DISABLE_NEW_VERSION_CHECK) {
    message("New app version checking disabled")
}

!macx:!win32 {
    # If not a MAC or Windows machine use the system version of libpng
    message("Using system version of libpng")
    DEFINES += USE_SYSTEM_LIBPNG
}

QT += core gui
QT += concurrent
QT += widgets
!contains(DEFINES, DISABLE_NEW_VERSION_CHECK): QT += network

DEFINES += QT_BUILD

# Comment string added to generated GIFs
DEFINES += GIF_COMMENT_STRING='"\\\"Created by SER Player\\\""'

CONFIG += c++11
CONFIG += warn_on
unix:!macx:QMAKE_CXXFLAGS += -std=gnu++0x

# Internationalisation
TRANSLATIONS = translations/ser_player_da.ts \
               translations/ser_player_fr.ts \
               translations/ser_player_de.ts \
               translations/ser_player_es.ts \
               translations/ser_player_it.ts \
               translations/ser_player_pl.ts \
               translations/ser_player_ru.ts

# Make Mac version as backwards compatible with old OS versions as possible
macx:QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.7

# Remove standard function warnings on Windows
win32:DEFINES += _CRT_SECURE_NO_WARNINGS

lessThan(QT_MAJOR_VERSION, 5): error("SER Player requires at least Qt5 to build")

TARGET = "ser-player"
TEMPLATE = app

# Main source files
SOURCES += src/main.cpp\
    src/ser_player.cpp \
    src/pipp_ser.cpp \
    src/pipp_buffer.cpp \
    src/persistent_data.cpp \
    src/pipp_timestamp.cpp \
    src/image_widget.cpp \
    src/application.cpp \
    src/frame_slider.cpp \
    src/save_frames_dialog.cpp \
    src/save_frames_progress_dialog.cpp \
    src/markers_dialog.cpp \
    src/image.cpp \
    src/histogram_thread.cpp \
    src/histogram_dialog.cpp \
    src/pipp_ser_write.cpp \
    src/header_details_dialog.cpp \
    src/utf8_validator.cpp \
    src/processing_options_dialog.cpp \
    src/icon_groupbox.cpp \
    src/gif_write.cpp \
    src/lzw_compressor.cpp \
    src/pipp_avi_write.cpp \
    src/pipp_avi_write_dib.cpp \
    src/selection_box_dialog.cpp \
    src/neuquant.c \
    src/playback_controls_widget.cpp \
    src/playback_controls_dialog.cpp \
    src/tiff_write.cpp \
    src/png_write.cpp

!contains(DEFINES, DISABLE_NEW_VERSION_CHECK): SOURCES += src/new_version_checker.cpp

macx {
    SOURCES += src/pipp_utf8_osx.cpp
} else:bsd {
    SOURCES += src/pipp_utf8_bsd.cpp
} else:linux {
    SOURCES += src/pipp_utf8_linux.cpp
} else:win32 {
    SOURCES += src/pipp_utf8.cpp
} else:gnukfreebsd {
    SOURCES += src/pipp_utf8_linux.cpp
} else {
    message("Defaulting to linux version of pipp_utf8_XXX.cpp")
    SOURCES += src/pipp_utf8_linux.cpp
}

HEADERS  += src/ser_player.h \
    src/pipp_ser.h \
    src/pipp_buffer.h \
    src/pipp_utf8.h \
    src/persistent_data.h \
    src/pipp_timestamp.h \
    src/image_widget.h \
    src/application.h \
    src/frame_slider.h \
    src/save_frames_dialog.h \
    src/save_frames_progress_dialog.h \
    src/markers_dialog.h \
    src/image.h \
    src/histogram_thread.h \
    src/histogram_dialog.h \
    src/pipp_ser_write.h \
    src/header_details_dialog.h \
    src/utf8_validator.h \
    src/processing_options_dialog.h \
    src/icon_groupbox.h \
    src/gif_write.h \
    src/lzw_compressor.h \
    src/pipp_video_write.h \
    src/pipp_avi_write.h \
    src/pipp_avi_write_dib.h \
    src/selection_box_dialog.h \
    src/neuquant.h \
    src/playback_controls_widget.h \
    src/playback_controls_dialog.h \
    src/tiff_write.h \
    src/png_write.h

!contains(DEFINES, DISABLE_NEW_VERSION_CHECK): HEADERS += src/new_version_checker.h

INCLUDEPATH += src

contains(DEFINES, USE_SYSTEM_LIBPNG) {
    # Use the system version of libpng
    LIBS += -lpng
} else {
    # Use our local copy of libpng
    SOURCES += libpng/png.c \
        libpng/pngerror.c \
        libpng/pngget.c \
        libpng/pngmem.c \
        libpng/pngpread.c \
        libpng/pngread.c \
        libpng/pngrio.c \
        libpng/pngrtran.c \
        libpng/pngrutil.c \
        libpng/pngset.c \
        libpng/pngtrans.c \
        libpng/pngwio.c \
        libpng/pngwrite.c \
        libpng/pngwtran.c \
        libpng/pngwutil.c

    # zlib source files
    SOURCES += zlib/adler32.c \
        zlib/compress.c \
        zlib/crc32.c \
        zlib/deflate.c \
        zlib/gzclose.c \
        zlib/gzlib.c \
        zlib/gzread.c \
        zlib/gzwrite.c \
        zlib/infback.c \
        zlib/inffast.c \
        zlib/inflate.c \
        zlib/inftrees.c \
        zlib/trees.c \
        zlib/uncompr.c \
        zlib/zutil.c

    HEADERS  += src/pnglibconf.h
    INCLUDEPATH += libpng
    INCLUDEPATH += zlib
}

INCLUDEPATH += src

# Build directories
contains(QT_ARCH, i386) {
    DEFINES += BUILD_32_BIT
    win32:OBJECTS_DIR = $$PWD/build/o/win32
    win32:DESTDIR = $$PWD/bin32
} else {
    DEFINES += BUILD_64_BIT
    win32:OBJECTS_DIR = $$PWD/build/o/win64
    win32:DESTDIR = $$PWD/bin64
}

MOC_DIR = $$PWD/build/moc
RCC_DIR = $$PWD/build/rcc
UI_DIR = $$PWD/build/ui
!win32:DESTDIR = $$PWD/bin
unix:!macx:OBJECTS_DIR = $$PWD/build/o/unix
macx:OBJECTS_DIR = $$PWD/build/o/mac
macx:PRO_FILE_DIR = $$PWD

# Icons
macx:ICON = platform-specific/os-x/ser_player_icon.icns
win32:RC_ICONS = platform-specific/windows/ser_player_icon.ico

RESOURCES += \
    images.qrc

# Modify generated OS X package to fix shortcomings
macx:release:QMAKE_POST_LINK = $$PWD/platform-specific/os-x/post_compile.sh

# Call windeployqt.exe to budle all DLLs and so on required to run
win32:release:QMAKE_POST_LINK = $$quote(windeployqt --force --no-translations \"$$DESTDIR/SER-Player.exe\"$$escape_expand(\n\t))

# SSL DLLs
win32 {
    contains(QT_ARCH, i386) {
        EXTRA_BINFILES += $$PWD/platform-specific/windows/openssl/win32/libeay32.dll \
                          $$PWD/platform-specific/windows/openssl/win32/ssleay32.dll \
                          $$PWD/platform-specific/windows/openssl/win32/OpenSSL_License.txt
        EXTRA_BINFILES_WIN = $${EXTRA_BINFILES}
        EXTRA_BINFILES_WIN ~= s,/,\\,g
            DESTDIR_WIN = $${DESTDIR}
        DESTDIR_WIN ~= s,/,\\,g
        for(FILE,EXTRA_BINFILES_WIN){
                    QMAKE_POST_LINK +=$$quote(cmd /c copy /y $${FILE} $${DESTDIR_WIN}$$escape_expand(\n\t))
        }
    } else {
        EXTRA_BINFILES += $$PWD/platform-specific/windows/openssl/win64/libeay32.dll \
                          $$PWD/platform-specific/windows/openssl/win64/ssleay32.dll \
                          $$PWD/platform-specific/windows/openssl/win64/OpenSSL_License.txt
        EXTRA_BINFILES_WIN = $${EXTRA_BINFILES}
        EXTRA_BINFILES_WIN ~= s,/,\\,g
            DESTDIR_WIN = $${DESTDIR}
        DESTDIR_WIN ~= s,/,\\,g
        for(FILE,EXTRA_BINFILES_WIN){
                    QMAKE_POST_LINK +=$$quote(cmd /c copy /y $${FILE} $${DESTDIR_WIN}$$escape_expand(\n\t))
        }
    }
}

unix:!macx {
    isEmpty(PREFIX) {
        PREFIX = /usr
    }

    target.path = $$PREFIX/bin

    icon256.path = $$PREFIX/share/icons/hicolor/256x256/apps
    icon256.files = platform-specific/linux/icons/256x256/ser-player.png
    
    icon128.path = $$PREFIX/share/icons/hicolor/128x128/apps
    icon128.files = platform-specific/linux/icons/128x128/ser-player.png

    icon48.path = $$PREFIX/share/icons/hicolor/48x48/apps
    icon48.files = platform-specific/linux/icons/48x48/ser-player.png

    icon32.path = $$PREFIX/share/icons/hicolor/32x32/apps
    icon32.files = platform-specific/linux/icons/32x32/ser-player.png

    icon24.path = $$PREFIX/share/icons/hicolor/24x24/apps
    icon24.files = platform-specific/linux/icons/24x24/ser-player.png

    icon16.path = $$PREFIX/share/icons/hicolor/16x16/apps
    icon16.files = platform-specific/linux/icons/16x16/ser-player.png

    mimexml.path = $$PREFIX/share/mime/packages
    mimexml.files = platform-specific/linux/ser-player.xml

    desktop.path = $$PREFIX/share/applications/
    desktop.files = platform-specific/linux/com.google.sites.ser-player.desktop

    INSTALLS = target  icon256 icon128 icon48 icon32 icon24 icon16 mimexml desktop

    defined(BUILD_FOR_REPOSITORY, var) {
        message("Not generating targets to register icons and mime type because building for Repository")
    } else : defined(BUILD_FOR_APPIMAGE, var) {
        message("Not generating targets to register icons and mime type because building for AppImage")
    } else {
        # Add extra targets to reset icon cache and register .ser mime type with system databases
        # This should not be done when making AppImages
        reset_icons.path = $$PREFIX/share/icons/
#        reset_icons.extra = which gtk-update-icon-cache && gtk-update-icon-cache $$PREFIX/share/icons/hicolor/; echo "Resetting icon cache"
        reset_icons.extra = type gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache $$PREFIX/share/icons/hicolor/ -t; echo "Resetting icon cache"

        reg_mime_types.path = $$PREFIX/share/mime/packages/
#        reg_mime_types.extra = which update-mime-database && update-mime-database $$PREFIX/share/mime/; echo "Updating mime to filetype database"
        reg_mime_types.extra = type update-mime-database >/dev/null 2>&1 && update-mime-database $$PREFIX/share/mime/; echo "Updating mime to filetype database"

        reg_mime_apps.path = $$PREFIX/share/applications/
#        reg_mime_apps.extra = which update-desktop-database && update-desktop-database $$PREFIX/share/applications/; echo "Updating mime to application database"
        reg_mime_apps.extra = type update-desktop-database >/dev/null 2>&1 && update-desktop-database $$PREFIX/share/applications/; echo "Updating mime to application database"
        INSTALLS += reset_icons reg_mime_types reg_mime_apps
    }
}

