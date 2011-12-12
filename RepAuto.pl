#!/usr/bin/perl 
#===============================================================================
#
#         FILE: RepAuto.pl
#
#        USAGE: ./RepAuto.pl
#
#  DESCRIPTION: a simple template system for C3000 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Andy (),
#      COMPANY:
#      VERSION: 0.7 
#      CREATED: 9/9/2011 2:43:41 PM
#      REVISION: 10/12/2011 10:00 AM    add GetOpt::Long for FromTime and ToTime
#                12/12/2011 13:00       change it overhaul, see ini for details.
#===============================================================================

use strict;
use warnings;
use C3000::RepUtils;
use DateTime::Format::Oracle;
our $VERSION = 0.7;
$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI';

my ($c3000_h, $config_h, $dt_parser, $dt_from, $dt_to, @excel_hs) = init();

for my $xls_h (@excel_hs){
	my $Sheet = $xls_h->open_sheet('report');
    my $templ_name = substr $xls_h->{book_handle}->Name,0,-4;


	# below is make a excel loop for substitute. ;)
	for ( my $row = 1 ; $row <= $Sheet->get_last_row ; $row++ ) {
    	for ( my $col = 1 ; $col <= $Sheet->get_last_col ; $col++ ) {
        	next if !defined $$Sheet->Cells( $row, $col )->{Value};
        	if ( $$Sheet->Cells( $row, $col )->{Value} =~ /^~~~/ ) {
            	my @a =
              	split( /__/, substr( $$Sheet->Cells( $row, $col )->{Value}, 3 ) );  #grab useful string
		       print "\n"; 	   
				if( scalar @a == 1){                                                # time function
            		$$Sheet->Cells( $row, $col )->{Value} =
              	     DateTime::Format::Oracle->format_datetime($dt_parser->parse_datetime($a[0]));	
			  	}
                

			  	if( scalar @a == 3 && $a[-1] !~ /^@/){                                       #get single LP
					$a[-1] = $dt_parser->parse_datetime($a[-1]);
            		$$Sheet->Cells( $row, $col )->{Value} =
              		$c3000_h->get_single_LP( 'ADAS_VAL_RAW', @a );
			  	}
			  	

				if( scalar @a == 4 && $a[2] =~ /^\[.+\]$/ ){                                 #get single LP with meter proxy filter
                    	$a[-1] = $dt_parser->parse_datetime($a[-1]);
						@a[-2,-1] = @a[-1,-2];
					$$Sheet->Cells( $row, $col )->{Value} =
			  		$c3000_h->get_single_LP( 'ADAS_VAL_RAW', @a );
			  	}
                 
				if( scalar @a == 4 && $a[2] !~ /^\[.+\]$/ ){                                #get accu LP
                    	$a[-1] = $dt_parser->parse_datetime($a[-1]);
						$a[-2] = $dt_parser->parse_datetime($a[-2]);
					$$Sheet->Cells( $row, $col )->{Value} =
			  		$c3000_h->accu_LP( 'ADAS_VAL_NORM', @a );
			  	}
                 
				if( scalar @a == 5 && $a[2] =~ /^\[.+\]$/ ){                                #get accu LP with meter proxy filter
                    	$a[-1] = $dt_parser->parse_datetime($a[-1]);
						$a[-2] = $dt_parser->parse_datetime($a[-2]);
						@a[-3, -2, -1] = @a[-2, -1, -3];
					$$Sheet->Cells( $row, $col )->{Value} =
			  		$c3000_h->accu_LP( 'ADAS_VAL_NORM', @a );
			  	}

               if( scalar @a == 6 && $a[-1] =~ /^\@/ ) {				   # built-in func
                        $a[-2] = $dt_parser->parse_datetime($a[-2]);
					   	$a[-3] = $dt_parser->parse_datetime($a[-3]);
						@a[-4, -3, -2] = @a[-3, -2, -4];  

					if ( $a[-1] eq '@status') {
								$$Sheet->Cells( $row, $col )->{Value} = $c3000_h->accu_LP('ADAS_STATUS', @a); 

			   		} 
			   }
		   }
    	}
	}


		$$Sheet->protect();


		my $abs_rep = make_rep_name($config_h->{report_name}, $config_h->{report_path}, $templ_name, $dt_from, $dt_to); 
		$xls_h->saveas_excel($abs_rep);
}
