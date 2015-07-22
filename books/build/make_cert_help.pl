#!/usr/bin/env perl

# cert.pl build system
# Copyright (C) 2008-2014 Centaur Technology
#
# Contact:
#   Centaur Technology Formal Verification Group
#   7600-C N. Capital of Texas Highway, Suite 300, Austin, TX 78731, USA.
#   http://www.centtech.com/
#
# License: (An MIT/X11-style license)
#
#   Permission is hereby granted, free of charge, to any person obtaining a
#   copy of this software and associated documentation files (the "Software"),
#   to deal in the Software without restriction, including without limitation
#   the rights to use, copy, modify, merge, publish, distribute, sublicense,
#   and/or sell copies of the Software, and to permit persons to whom the
#   Software is furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in
#   all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#   DEALINGS IN THE SOFTWARE.
#
# Original authors: Sol Swords <sswords@centtech.com>
#                   Jared Davis <jared@centtech.com>


# make_cert_help.pl -- this is a companion file that is used by "make_cert".
# It is the core script responsible for certifying a single ACL2 book.  The
# code here is largely similar to the %.cert: %.lisp rule from
# Makefile-generic, but with several extensions.  For instance,
#
#   - We try to gracefully NFS lag
#   - We support cert-flags comments that say how to run certify-book
#   - We can certify certain books with other save-images, using .image files
#   - We support .acl2x files and two-pass certification,
#   - We support adding #PBS directives to limit memory and wall time
#   - We support running ACL2 via an external queuing mechanism.
#
# We only expect to invoke this through make_cert, so it is not especially
# user-friendly.  We rely on several environment variables that are given to us
# by make_cert.  See make_cert for the defaults and meanings of, e.g., ACL2 and
# other variables used in this script.

# Usage: make_cert_help.pl TARGET STEP
#   - TARGET is like "foo" for "foo.lisp"
#   - STEP is "cert", "acl2x", "acl2xskip", "acl2xcert", "pcert", or "convert"

# The meaning of the steps is as follows:
# "cert"      -- conventional single-pass certification
# "acl2x"     -- first pass of a two-pass certification, not skipping proofs
# "acl2xskip" -- first pass of a two-pass or provisional certification, skipping proofs
# "pcert"     -- second pass of a provisional certification
# "convert"   -- third pass of a provisional certification


use warnings;
use strict;
use File::Spec;
# problematic to get this from cpan on msys
# use File::Which qw(which);
use FindBin qw($RealBin);
use POSIX qw(strftime);
use Cwd;

(do "$RealBin/paths.pl") or die ("Error loading $RealBin/paths.pl:\n!: $!\n\@: $@\n");

sub trim
{
	my $str = shift;
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	return $str;
}

sub read_whole_file
{
    my $filename = shift;
    open (my $fh, "<", $filename) or die("Can't open $filename: $!\n");
    local $/ = undef;
    my $ret = <$fh>;
    close($fh);
    return $ret;
}

sub read_whole_file_if_exists
{
    my $filename = shift;
    return "" if (! -f $filename);
    return read_whole_file($filename);
}


# Takes a string, a nesting depth, and a starting index.  Scans the
# string for parens and keeps track of the depth.  Stops when the
# depth reaches 0.  If it reaches the end of the string, returns the
# current depth.  Returns three results: a flag which is 1 if it
# reached the end before depth 0 and 0 otherwise, the nesting depth at
# the end (only valid if it reached the end), and the index after the
# closing paren.  BOZO doesn't care about string quotes etc.
sub find_matching_parens {
    my ($str, $depth, $pos) = @_;
    while (1) {
	my $next_open = index($str, "(", $pos);
	my $next_close = index($str, ")", $pos);
	my $open_next = ($next_open != -1)
	    && (($next_close == -1) || $next_open < $next_close);
	my $close_next = ($next_close != -1)
	    && (($next_open == -1) || $next_close < $next_open);
	if ($open_next) {
	    $pos = $next_open+1;
	    $depth = $depth+1;
	} elsif ($close_next) {
	    $pos = $next_close+1;
	    $depth = $depth-1;
	    if ($depth == 0) {
		return (0, -1, $pos);
	    }
	} else {
	    # reached end of string with no more parens
	    return (1, $depth, -1);
	}
    }
}


sub skip_certify_books {
    my $str = shift;
    my $pos = 0;
    my @strs = ();
    my @match;
    while ($str =~ m/(\((?:acl2::)?certify-book)/gi) {
	my $beg = pos($str) - length($1);
	my $end = pos($str);
	push (@strs, substr($str,$pos,$beg-$pos));
	my ($done, $depth, $newpos) = find_matching_parens($str, 1, $end);
	if ($done) {
	    return join("", @strs);
	}
	$pos = $newpos;
	pos($str) = $pos;
    }
    push (@strs, substr($str, $pos));
    return join("", @strs);
}


sub read_file_except_certify {
    my $filename = shift;
    my $str = read_whole_file($filename);
    return skip_certify_books($str);
    # my @lines = ();
    # open (my $fh, "<", $filename) or die("Can't open $filename: $!\n");
    # my $line;
    # my $parens_deep = -1;
    # while (my $line = <$fh>) {
    # 	chomp($line);
    # 	if ($parens_deep == -1) {
    # 	    my $start = index($line, "(certify-book"
    # 			      $line =~ s/\(certify-book [^)]*\)//;
    # 	push (@lines, $line);
    # }
    # my $ret = join("\n", @lines);
    # return $ret;
}

sub remove_file_if_exists
{
    my $filename = shift;
    if (-f $filename) {
	unlink($filename) or die("Can't remove $filename: $!\n");
    }
}

sub nfs_file_exists
{
    # In theory, this is just -f $filename.  In practice, NFS client caching
    # may mean that -f $filename does not mean what you think it does.
    #
    # Jared's notes.  I originally tried to just use a -f $filename when
    # waiting for NFS files to come into existence.  But it appears that, at
    # least under some configurations of NFS, the NFS client (not perl or
    # something) can cache whether a file exists or not.
    #
    # This caching can last for a long time, at least several minutes, perhaps
    # indefinitely.  (I literally went down the hall and got a lesson on NFS
    # from the sysamin, and when we came back to my office my "ls" loop was
    # still running and not seeing the file.)
    #
    # For our particular network setup, the file in question was not visible
    # from fv-hpc, but was visible from the compute nodes.  We used "df" to
    # investigate which NFS servers the compute nodes and fv-hpc were connected
    # to for that particular drive, and found that some nodes using the same
    # server could see the file.  Hence, we concluded it was not a server-side
    # issue.
    #
    # We then did an "ls" in the directory, and suddenly the client got a
    # refreshed view of the directory and could see the file.  So, it seems
    # that the client was caching the individual file, but not the directory
    # list.
    #
    # So, to really try to test whether the NFS file exists, we first do an
    # "ls" which apparently seems to be sufficient to clear the NFS cache for
    # that directory, and then ask if the file exists.  This seems to be good
    # enough for our setup.  If it doesn't work for somebody else's setup,
    # maybe they can figure out a better solution.

    my $filename = shift;
    my $blah = `ls`; # hit the directory again, to try to get NFS to not cache things
    return -f $filename;

#    my $output = `test -f '$filename'`;
#    my $status = $? >> 8;
#    return $status == 0;
}

sub wait_for_nfs
{
    my $filename = shift;
    my $max_lag = shift;
    for(my $i = 0; $i < $max_lag; $i++)
    {
	print "NFS Lag?  Waited $i seconds for $filename...\n";
	sleep(1);

	return 1 if nfs_file_exists($filename);
    }
    return 0;
}

sub write_whole_file
{
    my $filename = shift;
    my $contents = shift;

    open(my $fd, ">", $filename) or die("Can't open $filename: $!\n");
    print $fd $contents;
    close($fd);
}

sub parse_max_mem_arg
{
    # Try to parse the "..." part of (set-max-mem ...), return #GB needed
    my $filename = shift;
    my $arg = shift;
    my $ret = 0;

    if ($arg =~ m/\(\* ([0-9]+) \(expt 2 30\)\)/) {
	# (* n (expt 2 30)) is n gigabytes
	$ret = $1;
    }
    elsif ($arg =~ m/\(\* \(expt 2 30\) ([0-9]+)\)/) {
	# (* (expt 2 30) n) is n gigabytes
	$ret = $1;
    }
    elsif ($arg =~ m/^\(expt 2 ([0-9]+)\)*$/) {       # Example: arg is (expt 2 36))
	my $expt  = $1;                               # 36
	my $rexpt = ($expt > 30) ? ($expt - 30) : 0;  # 6  (but at least 0 in general)
	$ret      = 2 ** $rexpt;                      # 64 (e.g., 2^6)
    }
    else {
	print "Warning in $filename: skipping unsupported set-max-mem line: $arg\n";
	print "Currently supported forms:\n";
	print "  - (set-max-mem (expt 2 k))\n";
	print "  - (set-max-mem (* n (expt 2 30)))\n";
	print "  - (set-max-mem (* (expt 2 30) n))\n";
    }
    return $ret;
}

sub scan_source_file
{
    my $filename = shift;
    my $max_mem = 0;
    my $max_time = 0;
    my @includes = ();
    open(my $fd, "<", $filename) or die("Can't open $filename: $!\n");
    while(<$fd>) {
	my $line = $_;
	chomp($line);
	if ($line =~ m/^[^;]*\((?:acl2::)?set-max-mem (.*)\)/)
	{
	    $max_mem = parse_max_mem_arg($filename, $1);
	}
	elsif ($line =~ m/^[^;]*\((?:acl2::)?set-max-time ([0-9]*)\)/)
	{
	    $max_time = $1;
	}
	elsif ($line =~ m/^[^;]*\((?:acl2::)?include-book[\s]*"([^"]*)"(?:.*:dir[\s]*:([^\s)]*))?(.*)/i)
	{
	    # We allow "no_port" in a comment after the include book to prevent
	    # us from loading this book's .port file.  Note if we ever use this
	    # collection of includes for anything other than determining what
	    # port files to load, we should revisit this.
	    my $book = $1;
	    my $dir = $2;
	    my $remainder = $3;
	    if (! ($remainder =~ m/no[_-]port/i)) {
		push (@includes, [$1, $2]);
	    }
	}
    }
    close($fd);

     return ( $max_mem, $max_time, \@includes );
}


# sub scan_for_set_max_mem
# {
#     my $filename = shift;

#     open(my $fd, "<", $filename) or die("Can't open $filename: $!\n");
#     while(<$fd>) {
# 	my $line = $_;
# 	chomp($line);
# 	if ($line =~ m/^[^;]*\((acl2::)?set-max-mem (.*)\)/)
# 	{
# 	    my $gb = parse_max_mem_arg($filename, $2);
# 	    close $fd;
# 	    return $gb;
# 	}
#     }
#     close $fd;

#     return 0;
# }

# sub scan_for_set_max_time
# {
#     my $filename = shift;

#     open(my $fd, "<", $filename) or die("Can't open $filename: $!\n");
#     while(<$fd>) {
# 	my $line = $_;
# 	chomp($line);
# 	if ($line =~ m/^[^;]*\((acl2::)?set-max-time ([0-9]*)\)/)
# 	{
# 	    my $minutes = $2;
# 	    close $fd;
# 	    return $minutes;
# 	}
#     }
#     close $fd;
#     return 0;
# }

sub parse_certify_flags
{
    my $filename = shift;  # just for error messages
    my $str = shift;       # contents of the .acl2 file as a string
    my @lines = split /^/, $str;

    # default: any number of portcullis commands are fine, and let's set the
    # compile flag to true.
    my $ret = "? t";
    my $seen = 0;
    foreach my $line (@lines) {
	chomp($line);
	if ($line =~ m/^[ \t]*;[; \t]*cert-flags: (.*)$/) {
	    die("Multiple cert-flags directives are not allowed.") if $seen;
	    $ret = $1;
	}
    }
    return $ret;
}

my $TARGET = shift;
my $STEP = shift;      # certify, acl2x, acl2xskip, pcertify, pcertifyplus, convert, or complete
my $ACL2X = shift;     # "yes" or otherwise no. use ACL2X file in certify/pcertify/pcertifyplus/convert steps
my $PREREQS = \@ARGV;

# print "Prereqs for $TARGET $STEP: \n";
# foreach my $prereq (@$PREREQS) {
#     print "$prereq\n";
# }

my $startdir = getcwd;

my $TARGETEXT;
if ($STEP eq "complete" || $STEP eq "certify") {
    $TARGETEXT = "cert";
} elsif ($STEP eq "convert" || $STEP eq "pcertifyplus") {
    $TARGETEXT = "pcert1";
} elsif ($STEP eq "pcertify") {
    $TARGETEXT = "pcert0";
} elsif ($STEP eq "acl2x" || $STEP eq "acl2xskip") {
    $TARGETEXT = "acl2x";
} else {
    die("Unrecognized step type: $STEP");
}

# normalize acl2x flag to Boolean
$ACL2X = ($ACL2X eq "yes") ? ":acl2x t" : "";

my $INHIBIT        = $ENV{"INHIBIT"} || "";
my $HEADER         = $ENV{"OUTFILE_HEADER"} || "";
my $MAX_NFS_LAG    = $ENV{"MAX_NFS_LAG"} || 100;
my $DEBUG          = $ENV{"ACL2_BOOKS_DEBUG"} ? 1 : 0;
my $TIME_CERT      = $ENV{"TIME_CERT"} ? 1 : 0;
my $STARTJOB       = $ENV{"STARTJOB"} || "";
my $ON_FAILURE_CMD = $ENV{"ON_FAILURE_CMD"} || "";
my $ACL2           = $ENV{"ACL2"} || "acl2";
# Figure out what ACL2 points to before we switch directories.

if ($ENV{"ACL2_BIN_DIR"}) {
    (my $vol, my $dir, my $file) = File::Spec->splitpath($ENV{"ACL2_BIN_DIR"});
    my $canon_bin_dir = File::Spec->canonpath(File::Spec->catpath($vol, $dir, $file));
    print "canonical bin dir: $canon_bin_dir\n" if $DEBUG;
    $ENV{"PATH"} = $ENV{"PATH"} ? "$canon_bin_dir:$ENV{'PATH'}" : $canon_bin_dir;
}
# fix up the acl2 path as in cert.pl
my $devnull = File::Spec->devnull;
$ACL2 = path_import($ACL2);
my $default_acl2 = `which $ACL2 2>$devnull`;
if (($? >> 8) != 0) {
    print "Error: failed to find \$ACL2 ($ACL2) in the PATH.\n";
    exit(1);
}
chomp($default_acl2);

my $PCERT = "";
if ($STEP eq "pcertify") {
    $PCERT = ":pcert :create";
} elsif ($STEP eq "convert") {
    $PCERT = ":pcert :convert";
} elsif ($STEP eq "pcertifyplus") {
    $PCERT = ":pcert t";
} elsif ($STEP eq "complete") {
    $PCERT = ":pcert :complete";
}


if ($DEBUG)
{
    print "-- Starting up make_cert_help.pl in debug mode.\n";
    print "-- TARGET       = $TARGET\n";
    print "-- STEP         = $STEP\n";
    print "-- TARGETEXT    = $TARGETEXT\n";
    print "-- INHIBIT      = $INHIBIT\n";
    print "-- MAX_NFS_LAG  = $MAX_NFS_LAG\n";
    print "-- PCERT        = $PCERT\n";
    print "-- ACL2X        = $ACL2X\n";
    print "-- HEADER       = $HEADER\n";
    print "-- Default ACL2 = $default_acl2\n" if $DEBUG;
}

my $full_file = File::Spec->rel2abs($TARGET);
(my $vol, my $dir, my $file) = File::Spec->splitpath($full_file);
my $goal = "$file.$TARGETEXT";
my $printgoal = path_export("$full_file.$TARGETEXT");

print "Making $printgoal on " . strftime('%d-%b-%Y %H:%M:%S',localtime) . "\n";

my $fulldir = File::Spec->canonpath(File::Spec->catpath($vol, $dir, ""));
print "-- Entering directory $fulldir\n" if $DEBUG;
chdir($fulldir) || die("Error switching to $fulldir: $!\n");

my $status;
my $timefile = "$file.$TARGETEXT.time";
my $outfile = "$file.$TARGETEXT.out";

print "-- Removing files to be generated.\n" if $DEBUG;

remove_file_if_exists($goal);
remove_file_if_exists($timefile);
remove_file_if_exists($outfile);

write_whole_file($outfile, $HEADER);



# Override ACL2 per the image file, as appropriate.
my $acl2 = read_whole_file_if_exists("$file.image");
$acl2 = read_whole_file_if_exists("cert.image") if !$acl2;
$acl2 = $default_acl2 if !$acl2;
$acl2 = trim($acl2);
$ENV{"ACL2"} = $acl2;
print "-- Image to use = $acl2\n" if $DEBUG;
die("Can't determine which ACL2 to use.") if !$acl2;

# ------------ TEMPORARY LISP FILE FOR ACL2 INSTRUCTIONS ----------------------

my $rnd = int(rand(2**30));
my $tmpbase = "workxxx.$goal.$rnd";
# upper-case .LISP so if it doesn't get deleted, we won't try to certify it
my $lisptmp = "$tmpbase.LISP";
print "-- Temporary lisp file: $lisptmp\n" if $DEBUG;

my $instrs = "";

# I think this strange :q/lp dance is needed for lispworks or something?
$instrs .= "(acl2::value :q)\n";
$instrs .= "(acl2::in-package \"ACL2\")\n";
$instrs .= "#+acl2-hons (profile-fn 'prove)\n";
$instrs .= "#+acl2-hons (profile-fn 'certify-book-fn)\n";
$instrs .= "(acl2::lp)\n";
#    $instrs .= "(set-debugger-enable :bt)\n";
$instrs .= "(acl2::in-package \"ACL2\")\n\n";
$instrs .= "(set-ld-error-action (quote (:exit 1)) state)\n";
$instrs .= "(set-write-acl2x t state)\n" if ($STEP eq "acl2x");
$instrs .= "(set-write-acl2x '(t) state)\n" if ($STEP eq "acl2xskip");
$instrs .= "$INHIBIT\n" if ($INHIBIT);
$instrs .= "\n";

# --- Scan the source file for includes (to collect the portculli) and resource limits ----
my ($max_mem, $max_time, $includes) = scan_source_file("$file.lisp");
$max_mem = $max_mem ? ($max_mem + 3) : 4;
$max_time = $max_time || 240;

# Get the certification instructions from foo.acl2 or cert.acl2, if either
# exists, or make a generic certify-book command.
my $acl2file = (-f "$file.acl2") ? "$file.acl2"
    : (-f "cert.acl2")  ? "cert.acl2"
    : "";

my $usercmds = $acl2file ? read_file_except_certify($acl2file) : "";

# Don't hideously underapproximate timings in event summaries
$instrs .= "(acl2::assign acl2::get-internal-time-as-realtime acl2::t)\n";

# Don't hide GC messages -- except for CMUCL, which dumps them to the terminal.
$instrs .= "#-cmucl (acl2::gc-verbose t)\n";

$instrs .= "; instructions from .acl2 file $acl2file:\n";
$instrs .= "$usercmds\n\n";

$instrs .= "; Prevent reset-prehistory while loading .port files\n";
# Since reset-prehistory is never redundant, this is important to
# prevent exponential growth in the number of reset-prehistory
# commands when building on a saved image that uses reset-prehistory.
$instrs .= "(acl2::assign acl2::skip-reset-prehistory acl2::t)\n";

$instrs .= "; portculli for included books:\n";
foreach my $pair (@$includes) {
    my ($incname, $incdir) = @$pair;
    if ($incdir) {
	$instrs .= "(acl2::ld \"$incname.port\" :dir :$incdir :ld-missing-input-ok t)\n"; 
    } else {
	$instrs .= "(acl2::ld \"$incname.port\" :ld-missing-input-ok t)\n"; 
    }
}

# LD'd files above may change the current package
$instrs .= "#!ACL2 (set-ld-error-action (quote :continue) state)\n";

my $cert_flags = parse_certify_flags($acl2file, $usercmds);
$instrs .= "\n; certify-book command flags: $cert_flags\n";

my $cert_cmd = "#!ACL2 (er-progn (time\$ (certify-book \"$file\" $cert_flags $PCERT $ACL2X))
                                 (value (prog2\$ #+acl2-hons (memsum)
                                                 #-acl2-hons nil
                                                 (exit 43))))\n";

$instrs .= $cert_cmd;

if ($DEBUG) {
    print "-- ACL2 Instructions: $lisptmp --\n";
    print "$instrs\n";
    print "-------------------------------------------------------\n\n";
}

write_whole_file($lisptmp, $instrs);



# ------------ TEMPORARY SHELL SCRIPT FOR RUNNING ACL2 ------------------------

# upper-case .SH to agree with upper-case .LISP
    my $shtmp = "$tmpbase.SH";
    my $shinsts = "#!/bin/sh\n\n";

# If we find a set-max-mem line, add 3 gigs of padding for the stacks and to
# allow the lisp to have some room to go over.  Default to 4 gigs.

# If we find a set-max-time line, honor it directly; otherwise default to
# 240 minutes.

    print "-- Resource limits: $max_mem gigabytes, $max_time minutes.\n\n" if $DEBUG;

    $shinsts .= "#PBS -l pmem=${max_mem}gb\n";
    $shinsts .= "#PBS -l walltime=${max_time}:00\n\n";

# $shinsts .= "echo List directories of prereqs >> $outfile\n";
# $shinsts .= "time ( ls @$prereq_dirs > /dev/null ) 2> $outfile\n";
# foreach my $prereq (@$PREREQS) {
#     $shinsts .= "echo prereq: $prereq >> $outfile\n";
#     $shinsts .= "ls -l $startdir/$prereq >> $outfile 2>&1 \n";
# }
    $shinsts .= "echo >> '$outfile'\n";
    $shinsts .= "pwd >> '$outfile'\n";
    $shinsts .= "hostname >> '$outfile'\n";
    $shinsts .= "echo >> '$outfile'\n";

    $shinsts .= "echo Environment variables: >> '$outfile'\n";
    my @relevant_env_vars = ("ACL2_CUSTOMIZATION", "ACL2_SYSTEM_BOOKS", "ACL2");
    foreach my $var (@relevant_env_vars) {
	if (exists $ENV{$var}) {
	    $shinsts .= "echo $var=$ENV{$var} >> '$outfile'\n";
	}
    }
    $shinsts .= "echo >> '$outfile'\n";

    $shinsts .= "echo Temp lisp file: >> '$outfile'\n";
    $shinsts .= "cat '$lisptmp' >> '$outfile'\n";
    $shinsts .= "echo --- End temp lisp file --- >> '$outfile'\n";
    $shinsts .= "echo >> '$outfile'\n";

    $shinsts .= "echo TARGET: $TARGET >> '$outfile'\n";
    $shinsts .= "echo STEP: $STEP >> '$outfile'\n";
    $shinsts .= "echo Start of output: >> '$outfile'\n";
    $shinsts .= "echo >> '$outfile'\n";

    $shinsts .= "export ACL2_WRITE_PORT=t\n";
    if ($TIME_CERT) {
	$shinsts .= "(time (($acl2 < '$lisptmp' 2>&1) >> '$outfile')) 2> '$timefile'\n";
    }
    else {
	$shinsts .= "($acl2 < '$lisptmp' 2>&1) >> '$outfile'\n";
    }

    $shinsts .= "EXITCODE=\$?\n";
    $shinsts .= "echo Exit code from ACL2 is \$EXITCODE >> '$outfile'\n";
    $shinsts .= "ls -l '$goal' >> '$outfile' || echo '$goal' seems to be missing >> '$outfile'\n";
    $shinsts .= "exit \$EXITCODE\n";


    if ($DEBUG) {
	print "-- Wrapper Script: $shtmp --\n";
	print "$shinsts\n";
	print "-------------------------------------------------------\n\n";
    }

    write_whole_file($shtmp, $shinsts);


# Run it!  ------------------------------------------------

my $START_TIME = time();

    # Single quotes to try to protect against file names with dollar signs and similar.
    system("$STARTJOB '$shtmp'");
    $status = $? >> 8;

my $END_TIME = time();

    unlink($lisptmp) if !$DEBUG;
    unlink($shtmp) if !$DEBUG;



# Success or Failure Detection -------------------------------

# We should know immediately whether we've succeeded or failed,
# because we should exit 43 if we succeeded and not if we don't.
# But we still want to wait for the target file to show up.
my $success = 0;

if ($status == 43) {
    if (-f $goal) {
	$success = 1;
	print "-- Immediate success detected\n" if $DEBUG;
    } else {
# if ($STEP eq "cert" && $status == 43) {
    # The exit code indicates that the file certified successfully, so why
    # doesn't it exist?  Maybe there's NFS lag.  Let's try waiting to see if
    # the file will show up.
	$success = wait_for_nfs($goal, $MAX_NFS_LAG);
	print "-- After waiting for NFS, success is $success\n" if $DEBUG;
    }
}

if ($success) {

    my $black = chr(27) . "[0m";

    my $boldred = chr(27) . "[31;1m";
    my $red = chr(27) . "[31m";

    my $boldyellow = chr(27) . "[33;1m";
    my $yellow = chr(27) . "[33m";

    my $green = chr(27) . "[32m";
    my $boldgreen = chr(27) . "[32;1m";

    my $ELAPSED = $END_TIME - $START_TIME;

    my $color = ($ELAPSED > 300) ? $boldred
	      : ($ELAPSED > 60) ? $red
	      : ($ELAPSED > 40) ? $boldyellow
              : ($ELAPSED > 20) ? $yellow
	      : ($ELAPSED > 10) ? $green
	      : $boldgreen;

    if ($ENV{"CERT_PL_NO_COLOR"}) {
	$color = "";
	$black = "";
    }

    printf("%sSuccessfully built %s (%ds)%s\n", $color, $printgoal, $ELAPSED, $black);

} else {
    my $taskname = ($STEP eq "acl2x" || $STEP eq "acl2xskip") ? "ACL2X GENERATION" :
	($STEP eq "certify")  ? "CERTIFICATION" :
	($STEP eq "pcertify") ? "PROVISIONAL CERTIFICATION" :
	($STEP eq "pcertifyplus") ? "PROVISIONAL CERTIFICATION+" :
	($STEP eq "convert")  ? "PCERT0->PCERT1 CONVERSION" :
	($STEP eq "complete") ? "PCERT1->CERT COMLETION" : "UNKNOWN";
    print "**$taskname FAILED** for $dir$file.lisp\n\n";
    system("tail -300 $outfile | sed 's/^/   | /'") if $outfile;
    print "\n\n";

    if ($ON_FAILURE_CMD) {
	system($ON_FAILURE_CMD);
    }

    print "**$taskname FAILED** for $dir$file.lisp\n\n";
    exit(1);
}

print "-- Final result appears to be success.\n" if $DEBUG;

# Else, we made it!
system("ls -l $goal");
exit(0);

