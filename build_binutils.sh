#!/bin/sh

# building binutils from source

# This binutils build script is free software; you can redistribute it and/or modify
# it under the terms of the MIT license.


#======================================================================
# User configuration
#======================================================================

# Additional makefile options.  E.g., "-j 4" for parallel builds.  Parallel
# builds are faster, however it can cause a build to fail if the project
# makefile does not support parallel build.
make_flags="-j 2"

# Target linux/gnu
build_target=x86_64-linux-gnu

# what version of binutils to use
binutils_version=2.36

# File locations.  Use 'install_dir' to specify where gcc will be installed.
# The other directories are used only during the build process, and can later be
# deleted.
#
# WARNING: do not make 'source_dir' and 'build_dir' the same, or
# subdirectory of each other! It will cause build problems.
install_dir=${HOME}/opt/binutils-${binutils_version}
build_dir=/var/tmp/$(whoami)/binutils-${binutils_version}_build
source_dir=/var/tmp/$(whoami)/binutils-${binutils_version}_source
tarfile_dir=/var/tmp/$(whoami)/binutils-${binutils_version}_taballs

# String which gets embedded into gcc version info, can be accessed at
# runtime. Use to indicate who/what/when has built this compiler.
packageversion="$(whoami)-$(hostname -s)"

#======================================================================
# Support functions
#======================================================================


__die()
{
    echo $*
    exit 1
}


__banner()
{
    echo "============================================================"
    echo $*
    echo "============================================================"
}


__untar()
{
    dir="$1";
    file="$2"
    case $file in
        *xz)
            tar xJ -C "$dir" -f "$file"
            ;;
        *bz2)
            tar xj -C "$dir" -f "$file"
            ;;
        *gz)
            tar xz -C "$dir" -f "$file"
            ;;
        *)
            __die "don't know how to unzip $file"
            ;;
    esac
}


__abort()
{
        cat <<EOF
***************
*** ABORTED ***
***************
An error occurred. Exiting...
EOF
        exit 1
}


__wget()
{
    urlroot=$1; shift
    tarfile=$1; shift

    if [ ! -e "$tarfile_dir/$tarfile" ]; then
        wget --verbose ${urlroot}/$tarfile --directory-prefix="$tarfile_dir"
    else
        echo "already downloaded: $tarfile  '$tarfile_dir/$tarfile'"
    fi
}


# Set script to abort on any command that results an error status
trap '__abort' 0
set -e


#======================================================================
# Directory creation
#======================================================================


__banner Creating directories

# ensure workspace directories don't already exist
for d in  "$build_dir" "$source_dir" ; do
    if [ -d  "$d" ]; then
        __die "directory already exists - please remove and try again: $d"
    fi
done

for d in "$install_dir" "$build_dir" "$source_dir" "$tarfile_dir" ;
do
    test  -d "$d" || mkdir --verbose -p $d
done


#======================================================================
# Download source code
#======================================================================


# This step requires internet access.  If you dont have internet access, then
# obtain the tarfiles via an alternative manner, and place in the
# "$tarfile_dir"

__banner Downloading source code

binutils_tarfile=binutils-${binutils_version}.tar.gz

__wget ftp://ftp.gnu.org/gnu/binutils               $binutils_tarfile

# Check tarfiles are found, if not found, dont proceed
for f in $binutils_tarfile
do
    if [ ! -f "$tarfile_dir/$f" ]; then
        __die tarfile not found: $tarfile_dir/$f
    fi
done


#======================================================================
# Unpack source tarfiles
#======================================================================

__banner Unpacking source code

echo __untar  "$source_dir"  "$tarfile_dir/$binutils_tarfile"
__untar  "$source_dir"  "$tarfile_dir/$binutils_tarfile"

#======================================================================
# Clean environment
#======================================================================


# Before beginning the configuration and build, clean the current shell of all
# environment variables, and set only the minimum that should be required. This
# prevents all sorts of unintended interactions between environment variables
# and the build process.

__banner Cleaning environment

# store USER, HOME and then completely clear environment
U=$USER
H=$HOME

for i in $(env | awk -F"=" '{print $1}') ;
do
    unset $i || true   # ignore unset fails
done

# restore
export USER=$U
export HOME=$H
export PATH=/usr/local/bin:/usr/bin:/bin:/sbin:/usr/sbin

echo shell environment follows:
env


#======================================================================
# Configure
#======================================================================


__banner Configuring source code

cd "${build_dir}"
echo ${build_dir}
echo $source_dir/binutils-${binutils_version}/configure --target=${build_target} --prefix=${install_dir} \
    --disable-nls --enable-interwork --enable-multilib --disable-werror

$source_dir/binutils-${binutils_version}/configure \
    --target=${build_target} \
    --prefix=${install_dir}\
    --disable-nls \
    --enable-interwork \
    --enable-multilib \
    --disable-werror

#======================================================================
# Compiling
#======================================================================


cd "$build_dir"

make all 

#======================================================================
# Install
#======================================================================

__banner Installing

make install

__banner Complete

trap : 0

#end
