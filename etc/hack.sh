#!/bin/bash

ME=$(readlink -f "$0")
SCRIPTS_HOME=$(dirname "$ME")
PINTO_HACK_DEFAULT_HOME=$(readlink -f "$SCRIPTS_HOME/..")
PINTO_HACK_HOME=${PINTO_HACK_HOME:-$PINTO_HACK_DEFAULT_HOME}
PINTO_HACK_CPANM="$SCRIPTS_HOME/cpanm"
PINTO_HACK_LLIB=${PINTO_HACK_LLIB:-"$PINTO_HACK_HOME/llib"}
PINTO_REPO_URL=${PINTO_REPO_URL:-"https://repo.stratopan.com/thaljef/OpenSource/pinto-release"}
PINTO_HACK_ENVFILE="$PINTO_HACK_LLIB/etc/hack-environment.sh"
PINTO_HACK_REPOSITORY_ROOT=${PINTO_HACK_REPOSITORY_ROOT:-"$PINTO_HACK_LLIB/repo"}

die () {
   echo "$*" >&2
   exit 1
}

my_cpanm () {
   "$PINTO_HACK_CPANM" \
      --mirror "$PINTO_REPO_URL" --mirror-only \
      --local-lib-contained "$PINTO_HACK_LLIB" \
      "$@" \
   || die "Installation failed (cpanm $*)"
}

# As of version 2.007, Net::Server's test suite fails because of a
# change in some defaults in IO::Socket::SSL. We skip tests for this
# module only. See https://rt.cpan.org/Public/Bug/Display.html?id=86707
my_cpanm --notest Net::Server

# We install only dependecies for Pinto, because we're going to hack it!
my_cpanm --installdeps Pinto

echo ''

envdir=$(dirname "$PINTO_HACK_ENVFILE")
mkdir -p "$envdir"
(
   echo "export PERL5LIB=\"$PINTO_HACK_HOME/lib:$PINTO_HACK_LLIB/lib/perl5:\$PERL5LIB\""
   echo "export PATH=\"$PINTO_HACK_LLIB/bin:\$PATH\""
   echo "export PINTO_HOME='$PINTO_HACK_HOME'"
   echo "export PINTO_REPOSITORY_ROOT='$PINTO_HACK_REPOSITORY_ROOT'"
) > "$PINTO_HACK_ENVFILE"

echo "perl '$PINTO_HACK_HOME/bin/pinto' \"\$@\"" > "$PINTO_HACK_LLIB/bin/pinto"
chmod +x "$PINTO_HACK_LLIB/bin/pinto"
echo "perl '$PINTO_HACK_HOME/bin/pintod' \"\$@\"" > "$PINTO_HACK_LLIB/bin/pintod"
chmod +x "$PINTO_HACK_LLIB/bin/pintod"

envs=$(cat "$PINTO_HACK_ENVFILE" | sed 's/^/   /')
cat - <<END
Environment variables:

$envs

They are saved into $PINTO_HACK_ENVFILE, so you customize it and:

   source '$PINTO_HACK_ENVFILE'

to start hacking! You might add an alias to ease that:

   alias hack_pinto="source '$PINTO_HACK_ENVFILE'; cd '$PINTO_HACK_HOME'"

and save it where bash can load it when starting, so that you can
call it easily when you want to start hacking on Pinto.
END
