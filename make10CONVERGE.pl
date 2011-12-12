#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  make10CONVERGE.pl
#
#        USAGE:  ./make10CONVERGE.pl  
#
#  DESCRIPTION:  create oracle database 
#
#      OPTIONS:  ---
# REQUIREMENTS:  make10converge.sql, ora, ini, passwd files.
#         BUGS:  ---
#        NOTES:  This is a very DANGEROUS script for deleting all datafile in
#        some directories and no any warnings.
#       AUTHOR:  Andy Xiao (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  05/21/2011 06:59:36 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Carp;
use Data::Dump qw/dump/;

use File::Path qw/make_path/;
use File::Remove qw/remove/;
use File::Copy  qw/mv/;
use Config::Tiny;
use Template;
#use Expect;
use Cwd;

# Checking required environment variables ...
Config::Tiny->new();
my $Config = Config::Tiny->read( 'make10CONVERGE.ini' );
err_msg() if    $Config->{_}->{'ORACLE_SID'}    eq "" or
                $Config->{_}->{'ORACLE_HOME'}   eq "" or
                $Config->{_}->{'ORACLE_BASE'}   eq "" or
                $Config->{_}->{'CONVERGE_LOCATION_1'}  eq "" or
                $Config->{_}->{'CONVERGE_LOCATION_2'}  eq "" or
                $Config->{_}->{'CONVERGE_LOCATION_3'}  eq "" or
                $Config->{_}->{'ORACLE_SIZE'}          eq ""; 


my @paths  = (
"$Config->{_}->{'ORACLE_BASE'}/admin/$Config->{_}->{'ORACLE_SID'}",
"$Config->{_}->{'ORACLE_BASE'}/admin/$Config->{_}->{'ORACLE_SID'}/bdump",
"$Config->{_}->{'ORACLE_BASE'}/admin/$Config->{_}->{'ORACLE_SID'}/cdump",
"$Config->{_}->{'ORACLE_BASE'}/admin/$Config->{_}->{'ORACLE_SID'}/create",
"$Config->{_}->{'ORACLE_BASE'}/admin/$Config->{_}->{'ORACLE_SID'}/pfile",
"$Config->{_}->{'ORACLE_BASE'}/admin/$Config->{_}->{'ORACLE_SID'}/udump",
"$Config->{_}->{'ORACLE_BASE'}/admin/$Config->{_}->{'ORACLE_SID'}/scripts",
"$Config->{_}->{'ORACLE_HOME'}/database", 
"$Config->{_}->{'CONVERGE_LOCATION_1'}",
"$Config->{_}->{'CONVERGE_LOCATION_2'}",
"$Config->{_}->{'CONVERGE_LOCATION_3'}",
);

remove(\1, @paths);
make_path(@paths, { verbose => 1,
                     mode    => 0777,
                     });


my $pars = $Config->{_};
$pars->{'SYS_PWD'} = "CONVERGESYS";
$pars->{'SYSTEM_PWD'} = "MANAGER";


if ($pars->{'ORACLE_SIZE'} eq "LARGE"){
    $pars->{'JAVA_POOL_SIZE'} = 0;
    $pars->{'SHARED_POOL_SIZE'} = 0;
    $pars->{'LARGE_POOL_SIZE'} = 0;
    $pars->{'DB_CACHE_SIZE'}  = 0;
    $pars->{'SGA_MAX_SIZE'}  = "2048M";
    $pars->{'SGA_TARGET_SIZE'}  = "2048M";
    $pars->{'SGA_TARGET_SIZE'}  = 500000000;
 }
elsif ($pars->{'ORACLE_SIZE'} eq "MEDIUM"){
;
}
elsif ($pars->{'ORACLE_SIZE'} eq "SMALL"){
}
else {
;
}

#test_orainst();

#template sql
my $template = Template->new({ 
        START_TAG => quotemeta('%'),
        END_TAG   => quotemeta('%'),
    });

`psed -e 's/\\\\/\\//gp' init10CONVERGE.ora > init10CONVERGE.ora_for_unix`;
$template->process('init10CONVERGE.ora_for_unix', $pars,"$Config->{_}->{'ORACLE_BASE'}/admin/$Config->{_}->{'ORACLE_SID'}/pfile/init10CONVERGE.ora") || die $template->error(), "\n";

`psed -e 's/\\\\/\\//gp' make10CONVERGE1.sql > make10CONVERGE1.sql_for_unix`;
$template->process('make10CONVERGE1.sql_for_unix', $pars,"/tmp/make10CONVERGE1.sql") || die $template->error(), "\n";
`sqlplus /nolog @/tmp/make10CONVERGE1.sql >/tmp/converge1.log`;

`psed -e 's/\\\\/\\//gp' make10CONVERGE2.sql > make10CONVERGE2.sql_for_unix`;
$template->process('make10CONVERGE2.sql_for_unix', $pars,"/tmp/make10CONVERGE2.sql") || die $template->error(), "\n";
`sqlplus /nolog @/tmp/make10CONVERGE2.sql >/tmp/converge2.log`;

`psed -e 's/\\\\/\\//gp' make10CONVERGE3.sql > make10CONVERGE3.sql_for_unix`;
$template->process('make10CONVERGE3.sql_for_unix', $pars,"/tmp/make10CONVERGE3.sql") || die $template->error(), "\n";
`sqlplus /nolog @/tmp/make10CONVERGE3.sql >/tmp/converge3.log`;

`psed -e 's/\\\\/\\//gp' make10CONVERGE4.sql > make10CONVERGE4.sql_for_unix`;
$template->process('make10CONVERGE4.sql_for_unix', $pars,"/tmp/make10CONVERGE4.sql") || die $template->error(), "\n";
`sqlplus /nolog @/tmp/make10CONVERGE4.sql >/tmp/converge4.log`;

`psed -e 's/\\\\/\\//gp' make10CONVERGE5.sql > make10CONVERGE5.sql_for_unix`;
$template->process('make10CONVERGE5.sql_for_unix', $pars,"/tmp/make10CONVERGE5.sql") || die $template->error(), "\n";
`sqlplus /nolog @/tmp/make10CONVERGE5.sql >/tmp/converge5.log`;








sub test_orainst{
my $command = "sqlplus";
my @params  = ("/nolog");
my $exp = Expect->spawn($command, @params)
    or croak "Cannot spawn $command: $!\n";

$exp->send("connect sys/convergesys as sysdba;\n") or croak "can't connect to database!!\n";
 $exp->send("exit \n");
 $exp->soft_close();

}



sub err_msg{

    print <<'EOF';
ECHO ** variables ORACLE_BASE or ORACLE_HOME are not defined
ECHO ** 
ECHO ** Please set follwing  variable in ini file according to your oracle installation:
ECHO **   ORACLE_BASE		
ECHO **   ORACLE_HOME	
ECHO ** 
ECHO **   ORACLE_SID   
ECHO **   ORACLE_SIZE 
ECHO **   CONVERGE_LOCATION_1 
ECHO **   CONVERGE_LOCATION_2 
ECHO **   CONVERGE_LOCATION_3 
ECHO **
ECHO ** File distribution matrix:
ECHO **                         location 1  2  3
ECHO **   redo01/02/03.log               x  x  x
ECHO **   system01.dbf                   x
ECHO **   rbs01.dbf                      x
ECHO **   users01.dbf                    x
ECHO **   temp01.dbf                     x
ECHO **   tools01.dbf                    x
ECHO **   indx01.dbf                     x
ECHO **   undotbs01.dbf                  x
ECHO **   adas_def.dbf                      x
ECHO **   adas_def_ind.dbf                     x
ECHO **   adas_dat.dbf                         x
ECHO **   adas_dat_ind.dbf                  x
ECHO **   adpc_dat.dbf                      x
ECHO **   adpc_ind.dbf                         x

EOF
exit;
}
