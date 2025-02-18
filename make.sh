# Variables
PYTHON_VER=3.13
SUPPORT_VER=b3

# CURRENT WORK PLACE
WORK_PLACE=$PWD

# SOURCE SUPPORT
SUPPORT_RELEASE_PATH=$WORK_PLACE/Python-Apple-support-Releases/$PYTHON_VER-$SUPPORT_VER
SUPPORT_FILENAME_IOS=Python-$PYTHON_VER-iOS-support.$SUPPORT_VER
SUPPORT_FILENAME_MACOS=Python-$PYTHON_VER-macOS-support.$SUPPORT_VER

# PATCH
PATCH_PATH=$WORK_PLACE/patch

# PACKAGE RESULT
PACKAGE_NAME=PythonModules
PACKAGE_PATH=$WORK_PLACE/$PACKAGE_NAME
PACKAGE_SOURCES_PATH=$PACKAGE_PATH/Sources

ORG_BUNDLE_ID=org.python

# MODULE_NAME.cxframework
get_XCFRAMEWORK_PATH() {
    MODULE_NAME="$1"
    XCFRAMEWORK_PATH=$PACKAGE_SOURCES_PATH/$MODULE_NAME/$MODULE_NAME.xcframework
    
    # MODULE_NAME.cxframework
    if [[ ! -d "$XCFRAMEWORK_PATH" ]]; then
        mkdir -p $XCFRAMEWORK_PATH
    fi

    echo $XCFRAMEWORK_PATH
}

# MODULE_NAME.framework
get_FRAMEWORK_PATH() {
    MODULE_NAME="$1"
    PLATFORM="$2"

    XCFRAMEWORK_PATH=$(get_XCFRAMEWORK_PATH $MODULE_NAME)
    FRAMEWORK_PATH=$XCFRAMEWORK_PATH/$PLATFORM/$MODULE_NAME.framework

    # MODULE_NAME.framework
    if [[ ! -d "$FRAMEWORK_PATH" ]]; then
        mkdir -p $FRAMEWORK_PATH
    fi

    echo $FRAMEWORK_PATH
}

define_framework() {
    MODULE_NAME="$1"
    PLATFORM="$2"

    XCFRAMEWORK_PATH=$(get_XCFRAMEWORK_PATH $MODULE_NAME)
    FRAMEWORK_PATH=$(get_FRAMEWORK_PATH $MODULE_NAME $PLATFORM)

    echo "[START]==== Define Framework for $MODULE_NAME ($PLATFORM) ===="
    # A bundle identifier; not actually used, but required by Xcode framework packaging
    BUNDLE_ID=$(echo $ORG_BUNDLE_ID.$MODULE_NAME | tr _ -)

    # MODULE_NAME.xcframework/Info.plist
    if [[ $MODULE_NAME == "Python" ]]; then 
        echo Creating $XCFRAMEWORK_PATH/Info.plist
        cp $PATCH_PATH/dylib-Info-template-xcframework-python.plist $XCFRAMEWORK_PATH/Info.plist
        sed -i "" s/modulename/$MODULE_NAME/g $XCFRAMEWORK_PATH/Info.plist
        plutil -replace CFBundleIdentifier -string $BUNDLE_ID $XCFRAMEWORK_PATH/Info.plist
    elif [[ ! -f "$XCFRAMEWORK_PATH/Info.plist" ]]; then
        echo Creating $XCFRAMEWORK_PATH/Info.plist
        cp $PATCH_PATH/dylib-Info-template-xcframework-dylib.plist $XCFRAMEWORK_PATH/Info.plist
        sed -i "" s/modulename/$MODULE_NAME/g $XCFRAMEWORK_PATH/Info.plist
        plutil -replace CFBundleIdentifier -string $BUNDLE_ID $XCFRAMEWORK_PATH/Info.plist
    fi

    # MODULE_NAME.framework/Resources
    RESOURCES_PATH=$FRAMEWORK_PATH/Resources
    if [[ ! -d "$RESOURCES_PATH" ]]; then
        echo Creating $RESOURCES_PATH
        mkdir -p $RESOURCES_PATH
    fi

    # MODULE_NAME.framework/Info.plist
    if [[ -f "$FRAMEWORK_PATH/Info.plist" ]]; then
        mv $FRAMEWORK_PATH/Info.plist $RESOURCES_PATH/Info.plist
    fi

    if [[ ! -f "$RESOURCES_PATH/Info.plist" ]]; then
        echo Creating $RESOURCES_PATH/Info.plist
        cp $PATCH_PATH/dylib-Info-template.plist $RESOURCES_PATH/Info.plist
        plutil -replace CFBundleExecutable -string $MODULE_NAME $RESOURCES_PATH/Info.plist
        plutil -replace CFBundleIdentifier -string $BUNDLE_ID $RESOURCES_PATH/Info.plist
    fi

    echo "[END]==== Define Framework for $MODULE_NAME ($PLATFORM) ===="
}

install_python_xcframework_for_platform() {
    PLATFORM=$1
    
    MODULE_NAME=Python
    XCFRAMEWORK_PATH=$(get_XCFRAMEWORK_PATH $MODULE_NAME)

    if [[ $PLATFORM == ios* ]]; then
        ORIGINAL_XCFRAMEWORK_PATH=$SUPPORT_RELEASE_PATH/$SUPPORT_FILENAME_IOS/$MODULE_NAME.xcframework
    elif [[ $PLATFORM == macos* ]]; then
        ORIGINAL_XCFRAMEWORK_PATH=$SUPPORT_RELEASE_PATH/$SUPPORT_FILENAME_MACOS/$MODULE_NAME.xcframework
    else
        return 1
    fi

    mkdir -p $XCFRAMEWORK_PATH/$PLATFORM
    echo Copy $ORIGINAL_XCFRAMEWORK_PATH/$PLATFORM to $XCFRAMEWORK_PATH/$PLATFORM
    rsync -au --delete $ORIGINAL_XCFRAMEWORK_PATH/$PLATFORM $XCFRAMEWORK_PATH/

    define_framework $MODULE_NAME $PLATFORM

    #FRAMEWORK_PATH=$(get_FRAMEWORK_PATH $MODULE_NAME $PLATFORM)
    #RESOURCES_PATH=$FRAMEWORK_PATH/Resource

    #VERSIONS
    #if [[ $PLATFORM == macos* ]]; then
        # VERSIONS_PATH=$FRAMEWORK_PATH/Versions
        # ln -s $PYTHON_VER $VERSIONS_PATH/A
        # ln -s $PYTHON_VER $VERSIONS_PATH/Current
    #fi

    #copy to Python.framework/Modules/module.modulemap
    MODULES_PATH=$FRAMEWORK_PATH/Modules
    mkdir -p $MODULES_PATH
    cp $PATCH_PATH/module.modulemap $MODULES_PATH/module.modulemap

    #copy to Python.framework/Headers
    HEADERS_PATH=$FRAMEWORK_PATH/Headers

    #patch on cypthon/pyatomic.h #include "cpython/*.h" replative path issue
    cp $PATCH_PATH/fixed_cpython_pyatomic.h $HEADERS_PATH/cpython/pyatomic.h

    #patch on py_curses.h NCURSES_OPAQUE redeine issue
    cp $PATCH_PATH/fixed_py_curses.h $HEADERS_PATH/py_curses.h

    #patch on py_curses.h NCURSES_OPAQUE WINDOW type
    if [[ $PLATFORM == ios* ]]; then
        sed -i "" s/WINDOW/void/g $HEADERS_PATH/py_curses.h
    fi

    #  iOS: Python.framework/Resource/python/ - lib/python3.13
    #macOS: Python.framework/Verions/3.13/    - lib/python3.13
    if [[ $PLATFORM == ios* ]]; then
        mkdir -p $RESOURCES_PATH/python
        rsync -au --delete $FRAMEWORK_PATH/../lib $RESOURCES_PATH/python/
    

        #lib-dynload for $PLATFORM
        echo "[START]==== Install dylib $PLATFORM ===="
        LIB_DYNLOAD=$RESOURCES_PATH/python/lib/python$PYTHON_VER/lib-dynload 
        
        find $LIB_DYNLOAD -name *.so | while read SO_PATH; do
            # The location of the dylib file, relative to lib_dyload
            LIB_SO_PATH=${SO_PATH#$LIB_DYNLOAD/}    

            # The full dotted name of the dylib module, constructed from the file path.
            MODULE_NAME=$(echo $LIB_SO_PATH | cut -d . -f 1 | tr / .);
            
            define_framework $MODULE_NAME $PLATFORM

            #install to @rpath/modulename.framework/modulename
            echo "[StART]===Installing binary for $MODULE_NAME"

            BINARY_PATH=$FRAMEWORK_PATH/$MODULE_NAME
            RPATH=Frameworks/$MODULE_NAME.framework/$MODULE_NAME

            #install the dylib framework location
            mv $SO_PATH $BINARY_PATH

            #patch on dylib install id
            install_name_tool -id @rpath/$RPATH $BINARY_PATH
            
            # Create a placeholder .fwork file where the .so was
            echo $RPATH > ${SO_PATH%.so}.fwork
        
            # Create a back reference to the .so file location in the framework
            # echo ${LIB_SO_PATH%.so}.fwork > $BINARY_PATH.origin
            echo "[END]===Installing binary for $MODULE_NAME"
        done
        echo "[END]==== Install dylib $PLATFORM ===="
    fi
}

download_python_apple_support() {
    rm -rf $SUPPORT_RELEASE_PATH
    mkdir -p $SUPPORT_RELEASE_PATH

    pushd /desired/directory > /dev/null
    cd $SUPPORT_RELEASE_PATH

    curl https://github.com/beeware/Python-Apple-support/releases/download/$PYTHON_VER-$SUPPORT_VER/$SUPPORT_FILENAME_IOS.tar.gz -L -o $SUPPORT_FILENAME_IOS.tar.gz
    mkdir -p $SUPPORT_FILENAME_IOS/
    tar -xvzf $SUPPORT_FILENAME_IOS.tar.gz -C $SUPPORT_FILENAME_IOS/
    rm $SUPPORT_FILENAME_IOS.tar.gz

    curl https://github.com/beeware/Python-Apple-support/releases/download/$PYTHON_VER-$SUPPORT_VER/$SUPPORT_FILENAME_MACOS.tar.gz -L -o $SUPPORT_FILENAME_MACOS.tar.gz
    mkdir -p $SUPPORT_FILENAME_MACOS
    tar -xvzf $SUPPORT_FILENAME_MACOS.tar.gz -C $SUPPORT_FILENAME_MACOS/ && 
    rm $SUPPORT_FILENAME_MACOS.tar.gz

    popd > /dev/null
}

init_swift_pacakge() {
    echo     Init Swift Package
    rm -rf $PACKAGE_PATH
    mkdir -p $PACKAGE_PATH
    (cd $PACKAGE_PATH && swift package init --disable-swift-testing)
    echo  Copy $PATCH_PATH/PackageTemplate.swift to $PACKAGE_PATH/Package.swift
    cp $PATCH_PATH/PackageTemplate.swift $PACKAGE_PATH/Package.swift
    sed -i "" s/PACKAGE_NAME/$PACKAGE_NAME/g $PACKAGE_PATH/Package.swift
    mkdir -p $PACKAGE_SOURCES_PATH/$PACKAGE_NAME
    touch $PACKAGE_SOURCES_PATH/$PACKAGE_NAME/$PACKAGE_NAME.swift
}

download_python_apple_support
init_swift_pacakge
for PLATFORM in ios-arm64 ios-arm64_x86_64-simulator macos-arm64_x86_64; do
    install_python_xcframework_for_platform $PLATFORM
done
