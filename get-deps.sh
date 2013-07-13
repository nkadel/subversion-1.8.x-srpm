#!/bin/sh
#
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
#
#
# get-deps.sh -- download the dependencies useful for building Subversion
#

# If changing this file please take care to try to make your changes as
# portable as possible.  That means at a minimum only use POSIX supported
# features and functions.  However, it may be desirable to use an even
# more narrow set of features than POSIX, e.g. Solaris /bin/sh only has
# a subset of the POSIX shell features.  If in doubt, limit yourself to
# features already used in the file.  Reviewing the history of changes
# may be useful as well.

# Base URL for packages, update as needed
APACHE_MIRROR=http://archive.apache.org/dist
GTEST_MIRROR=http://googletest.googlecode.com/files
SERF_MIRROR=http://serf.googlecode.com/files
SQLITE_MIRROR=http://www.sqlite.org/2013
ZLIB_MIRROR=http://www.zlib.net

APR_ICONV_VERSION=${APR_ICONV_VERSION:-"1.2.6"}
APR_VERSION=${APR_VERSION:-"1.4.6"}
APU_VERSION=${APU_VERSION:-"1.5.1"}
GTEST_VERSION=${GTEST_VERSION:-"1.6.0"}
HTTPD_VERSION=${HTTPD_VERSION:-"2.4.3"}
SERF_VERSION=${SERF_VERSION:-"1.2.1"}
SQLITE_VERSION=${SQLITE_VERSION:-"3.7.17"}
SQLITE_VERSION_LIST=`echo $SQLITE_VERSION | sed -e 's/\./ /g'`
ZLIB_VERSION=${ZLIB_VERSION:-"1.2.8"}

APR=apr-${APR_VERSION}
APR_UTIL=apr-util-${APU_VERSION}
GTEST=gtest-${GTEST_VERSION}
SERF=serf-${SERF_VERSION}
SQLITE=sqlite-autoconf-$(printf %u%02u%02u%02u $(echo $SQLITE_VERSION | sed -e "s/\./ /g"))
ZLIB=zlib-${ZLIB_VERSION}

# Not normally downloaded
HTTPD=httpd-${HTTPD_VERSION}
APR_ICONV=apr-iconv-${APR_ICONV_VERSION}

BASEDIR=`pwd`
TEMPDIR=$BASEDIR/temp

HTTP_FETCH=
[ -z "$HTTP_FETCH" ] && type wget  >/dev/null 2>&1 && HTTP_FETCH="wget -q -nc"
[ -z "$HTTP_FETCH" ] && type curl  >/dev/null 2>&1 && HTTP_FETCH="curl -sO"
[ -z "$HTTP_FETCH" ] && type fetch >/dev/null 2>&1 && HTTP_FETCH="fetch -q"

# helpers
usage() {
    echo "Usage: $0"
    echo "Usage: $0 [ apr | gtest | serf | sqlite | zlib ] ..."
    exit $1
}

# getters - these all check for local source directory. If one doesn't
#	exist, they then "get" a reference tarball reference tarball,
#	and expand the tarball into that local source directory where
#	autoconf can detect them.
get_apr() {
    test -d $BASEDIR/apr && return

    cd $TEMPDIR || return 1
    $HTTP_FETCH $APACHE_MIRROR/apr/$APR.tar.bz2
    cd $BASEDIR || return 1

    rm -rf apr && \
        bzip2 -dc $TEMPDIR/$APR.tar.bz2 | tar -xf - && \
	mv $APR apr || return 1

    # Include this in get_apr, makes it easier to match components
    get_apr_util
}

get_apr_util() {
    test -d $BASEDIR/apr-util && return

    cd $TEMPDIR || return 1
    $HTTP_FETCH $APACHE_MIRROR/apr/$APR_UTIL.tar.bz2
    cd $BASEDIR || return 1

    rm -rf apr-util && \
	bzip2 -dc $TEMPDIR/$APR_UTIL.tar.bz2 | tar -xf - && \
	mv $APR_UTIL apr-util || return 1
}

get_gtest() {
    test -d $BASEDIR/gtest && return

    cd $TEMPDIR || return 1
    $HTTP_FETCH ${GTEST_MIRROR}/${GTEST}.zip
    cd $BASEDIR || return 1

    rm -rf gtest && \
        unzip -q $TEMPDIR/$GTEST.zip
	mv $GTEST gtest || return 1
}

get_serf() {
    test -d $BASEDIR/serf && return

    cd $TEMPDIR || return 1
    $HTTP_FETCH $SERF_MIRROR/$SERF.tar.bz2
    cd $BASEDIR || return 1

    rm -rf serf && \
	bzip2 -dc $TEMPDIR/$SERF.tar.bz2 | tar -xf - && \
	mv $SERF serf || return 1
}

get_sqlite() {
    test -d $BASEDIR/sqlite-amalgamation && return

    cd $TEMPDIR || return 1
    $HTTP_FETCH $SQLITE_MIRROR/$SQLITE.tar.gz
    cd $BASEDIR || return 1

    rm -rf sqlite-amalgamation && \
	gzip -dc $TEMPDIR/$SQLITE.tar.gz | tar -xf - && \
       	mv $SQLITE sqlite-amalgamation || return 1
}

get_zlib() {
    test -d $BASEDIR/zlib && return

    cd $TEMPDIR || return 1
    $HTTP_FETCH $ZLIB_MIRROR/$ZLIB.tar.gz
    cd $BASEDIR || return 1

    rm -rf zlib && \
	gzip -dc  $TEMPDIR/$ZLIB.tar.gz | tar -xf - && \
	mv $ZLIB zlib || return 1
}

# main()
get_deps() {
    mkdir -p $TEMPDIR

    for i in apr apr-util gtest serf sqlite-amalgamation zlib; do
      if test -d $i; then
        echo "Local directory '$i' already exists, skipping" >&2
      fi
    done

    if [ $# -gt 0 ]; then
      for target in "$@"; do
        if [ "$target" != "deps" ]; then
          get_$target || usage
        else
          usage
        fi
      done
    else
      get_apr
      #get_apr_util # included as part of get_apr
      get_gtest
      get_serf
      get_sqlite
      get_zlib

      echo
      echo "If you require mod_dav_svn, the recommended version of httpd is:"
      echo "   $APACHE_MIRROR/httpd/$HTTPD.tar.bz2"

      echo
      echo "If you require apr-iconv, its recommended version is:"
      echo "   $APACHE_MIRROR/apr/$APR_ICONV.tar.bz2"
    fi

    rm -rf $TEMPDIR
}

get_deps "$@"
