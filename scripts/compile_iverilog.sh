# -- Compile Iverilog script

VER=8b850643413fc669cdf703b4a115bb8774261266
IVERILOG=iverilog-$VER
TAR_IVERILOG=$VER.tar.gz
REL_IVERILOG=https://github.com/steveicarus/iverilog/archive/$TAR_IVERILOG

# -- Setup
. $WORK_DIR/scripts/build_setup.sh

cd $UPSTREAM_DIR

# -- Check and download the release
test -e $TAR_IVERILOG || wget $REL_IVERILOG

# -- Unpack the release
tar zxf $TAR_IVERILOG

# -- Copy the upstream sources into the build directory
rsync -a $IVERILOG $BUILD_DIR --exclude .git

cd $BUILD_DIR/$IVERILOG

# -- Configure qemu
if [ ${ARCH:0:7} == "linux_a" ]; then
  export QEMU_LD_PREFIX=/usr/$HOST
fi

# -- Patch __strtod: https://github.com/steveicarus/iverilog/pull/148
if [ $ARCH == "windows_amd64" ]; then
  sed -i "s/___strtod/__strtod/g" aclocal.m4
fi

if [ $ARCH != "darwin" ]; then
  export CC=$HOST-gcc
  export CXX=$HOST-g++
fi

# -- Generate the new configure
sh autoconf.sh

# -- Force not to use libreadline and libhistory
if [ ${ARCH:0:5} == "linux" ]; then
  sed -i "s/ac_cv_lib_readline_readline=yes/ac_cv_lib_readline_readline=no/g" configure
  sed -i "s/ac_cv_lib_history_add_history=yes/ac_cv_lib_history_add_history=no/g" configure
  sed -i "s/ac_cv_lib_pthread_pthread_create=yes/ac_cv_lib_pthread_pthread_create=no/g" configure
fi

# -- Prepare for building
./configure --build=$BUILD --host=$HOST CFLAGS="$CONFIG_CFLAGS" CXXFLAGS="$CONFIG_CFLAGS" LDFLAGS="$CONFIG_LDFLAGS" $CONFIG_FLAGS

# -- Compile it
make -j$J

# -- Make binaries static
if [ ${ARCH:0:5} == "linux" ]; then
  make -C driver clean
  make -C driver -j$J LDFLAGS="$MAKE_LDFLAGS"
fi

# -- Test the generated executables
if [ $ARCH != "darwin" ]; then
  test_bin driver/iverilog$EXE
fi

# -- Install the programs into the package folder
make install prefix=$PACKAGE_DIR/$NAME/

# -- Copy vlib/system.v
cp -r $WORK_DIR/build-data/vlib $PACKAGE_DIR/$NAME
