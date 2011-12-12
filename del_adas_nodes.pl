#!/usr/bin/perl 
#===============================================================================
#
#         FILE: del_path.pl
#
#        USAGE: ./del_path.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
#      COMPANY: 
#      VERSION: 1.0
#      CREATED: 11/2/2011 9:41:43 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use C3000;
if( 0 == @ARGV ){
	print "usage: del_nodes.exe sub_string: \n";
	print "example: del_nodes.exe %ÆÕ¼ª%   # delete nodes with ÆÕ¼ªstring\n";
	print "or: del_nodes.exe %ÆÕ¼ª% %ÓñÏª%  # ditto, with ÆÕ¼ª£¬ ÓñÏª \n";
}
else{
my $hs = C3000->new();
for (@ARGV){
$hs->del_paths($_);
$hs->del_meters($_);
$hs->del_VMs($_);
}
}
