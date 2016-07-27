# -- Compile Iverilog script

IVERILOG=iverilog-10_1
REL_IVERILOG=https://github.com/steveicarus/iverilog/archive/v10_1.tar.gz

EXT=""
if [ $ARCH == "windows" ]; then
  EXT=".exe"
fi

if [ $ARCH == "darwin" ]; then
  J=$(($(sysctl -n hw.ncpu)-1))
else
  J=$(($(nproc)-1))
fi

cd $UPSTREAM_DIR

# -- Check and download the release
test -e v10_1.tar.gz || wget $REL_IVERILOG

# -- Unpack the release
tar vzxf v10_1.tar.gz

# -- Copy the upstream sources into the build directory
rsync -a $IVERILOG $BUILD_DIR --exclude .git

cd $BUILD_DIR/$IVERILOG

if [ $ARCH == "linux_x86_64" ]; then
  #-- Generate the new configure
  autoconf

  # Prepare for building
  ./configure LDFLAGS="-static-libstdc++"

  # -- Compile it
  make -j$J

  # Make iverilog static
  cd driver
  make clean
  make -j$J LDFLAGS="-static"
  cd ..
fi

if [ $ARCH == "linux_i686" ]; then
  #-- Generate the new configure
  autoconf

  # Prepare for building
  ./configure --with-m32 LDFLAGS="-static-libstdc++"

  # -- Compile it
  make -j$J

  # Make iverilog static
  cd driver
  make clean
  make -j$J LDFLAGS="-m32 -static"
  cd ..
fi

if [ $ARCH == "windows" ]; then
  #-- Generate the new configure
  autoconf

  # Prepare for building
  ./configure --host="i686-w64-mingw32" LDFLAGS="-static"

  # -- Compile it
  make -j$J
fi

if [ $ARCH == "darwin" ]; then
  #-- Generate the new configure
  sh autoconf.sh

  # Prepare for building
  ./configure

  # -- Compile it
  make -j$J
fi

# -- Test the generated executables
if [ $ARCH != "darwin" ]; then
  test_bin driver/iverilog$EXT
fi

# -- Install the programs into the package folder
make install prefix=$PACKAGE_DIR/$NAME/

# -- Copy vlib/system.v
cp -r $WORK_DIR/build-data/vlib $PACKAGE_DIR/$NAME