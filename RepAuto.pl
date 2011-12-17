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
our $VERSION = 0.8;
$ENV{'NLS_DATE_FORMAT'} = 'YYYY-MM-DD HH24:MI';

my ($c3000_h, $config_h, $dt_parser, $dt_from, $dt_to, @excel_hs) = init();

for my $xls_h (@excel_hs){
	my $Sheet = $xls_h->open_sheet('report');
    my $templ_name = substr $xls_h->{book_handle}->Name,0,-4;


	# below is make a excel loop for substitute. ;)
	for ( my $row = 1 ; $row <= $Sheet->get_last_row ; $row++ ) {
    	for ( my $col = 1 ; $col <= $Sheet->get_last_col ; $col++ ) {
        	next if !defined $Sheet->read_cell( $row, $col );
        	if ( $Sheet->read_cell( $row, $col ) =~ /^~~~/ ) {
            	my @a =
              	split( /__/, substr( $Sheet->read_cell( $row,$col ), 3 ) );  #grab useful string
				my $auto_ext = '';
				$auto_ext = pop @a if index($a[-1], '~extend') >= 0;
                my ($interval_unit, $interval, $last_date) = ('days', 0, $dt_parser->parse_datetime('1970-1-1'));  #init
				 if($auto_ext =~ m/\(\s?(.+),\s?(.+),\s?(.+)\s?\)/){
					 ($interval_unit, $interval, $last_date, ) = ($1, $2, $dt_parser->parse_datetime($3));

				 }
				 my @results;
				if( scalar @a == 1){					# time function
				     	 
            		if ($a[0] eq 'from'){
					
							my $i = $dt_from;
							do{
						 		push @results, DateTime::Format::Oracle->format_datetime($i);
								$i->add($interval_unit => $interval);
					 		}while( $i <= $last_date );
						$Sheet->write_col( $row, $col,\@results ); 
              	    			 
					}
                    elsif($a[0] eq 'to'){
						my $i = $dt_to;
						do{
						 push @results, DateTime::Format::Oracle->format_datetime($i);
							$i->add($interval_unit => $interval);
					 }while( $i <= $last_date );
						$Sheet->write_col( $row, $col, \@results); 
					}
					else{
						my $i =$dt_parser->parse_datetime($a[0]);
							do{
						 push @results, DateTime::Format::Oracle->format_datetime($i);
							$i->add($interval_unit => $interval);
					 }while( $i <= $last_date );
					
						$Sheet->write_col( $row, $col, \@results); 
					}
			  	}
                

			  	if( scalar @a == 3 && $a[-1] !~ /^~/){					#get single LP
							my $i = $dt_parser->parse_datetime($a[-1]);
							do{
								$a[-1] = $i;
						 		push @results,$c3000_h->get_single_LP( 'ADAS_VAL_RAW', @a );
								$i->add($interval_unit => $interval);
					        }while( $i <= $last_date );
							$Sheet->write_col( $row, $col, \@results); 
			  	}
			  	

				if( scalar @a == 4 && $a[2] =~ /^\[.+\]$/ ){                                 #get single LP with meter proxy filter

					my $i = $dt_parser->parse_datetime($a[-1]);
							do{
								$a[-1] = $i;
								@a[-2,-1] = @a[-1,-2];
						 		push @results,$c3000_h->get_single_LP( 'ADAS_VAL_RAW', @a );
								$i->add($interval_unit => $interval);
					        }while( $i <= $last_date );
							$Sheet->write_col( $row, $col, \@results); 

			  	}
                 
				if( scalar @a == 4 && $a[2] !~ /^\[.+\]$/ ){                                #get accu LP
						my $i1 = $dt_parser->parse_datetime($a[-1]);
						my $i2 = $dt_parser->parse_datetime($a[-2]);
							do{
								$a[-1] = $i1;
								$a[-2] = $i2;
						 		push @results,$c3000_h->accu_LP( 'ADAS_VAL_NORM', @a );
								$i1->add($interval_unit => $interval);
								$i2->add($interval_unit => $interval);
					        }while( $i1 <= $last_date );
							$Sheet->write_col( $row, $col, \@results); 	
			  	}

                 
				if( scalar @a == 5 && $a[2] =~ /^\[.+\]$/ ){                                #get accu LP with meter proxy filter
						my $i1 = $dt_parser->parse_datetime($a[-1]);
						my $i2 = $dt_parser->parse_datetime($a[-2]);
							do{
								$a[-1] = $i1;
								$a[-2] = $i2;
								@a[-3, -2, -1] = @a[-2, -1, -3];
						 		push @results,$c3000_h->accu_LP( 'ADAS_VAL_NORM', @a );
								$i1->add($interval_unit => $interval);
								$i2->add($interval_unit => $interval);
					        }while( $i1 <= $last_date );
							$Sheet->write_col( $row, $col, \@results); 
			  	}

               if( scalar @a == 6 && $a[-1] =~ /^~/ ) {				   # built-in func
				   		my $i1 = $dt_parser->parse_datetime($a[-2]);
						my $i2 = $dt_parser->parse_datetime($a[-3]);
						
							do{
								$a[-2] = $i1;
								$a[-3] = $i2;
								@a[-4, -3, -2] = @a[-3, -2, -4];
								if( $a[-1] eq '~status'){
						 		push @results,$c3000_h->accu_LP( 'ADAS_STATUS', @a );
								}
								if( $a[-1] eq '~billing'){
									push @results, $c3000_h->get_billing('ADAS_VAL_RAW', @a);
								}
								$i1->add($interval_unit => $interval);
								$i2->add($interval_unit => $interval);
					        }while( $i1 <= $last_date );
							$Sheet->write_col( $row, $col, \@results);                     

						}

			   		} 
			   }
		   }
	


		$$Sheet->protect();


		my $abs_rep = make_rep_name($config_h->{report_name}, $config_h->{report_path}, $templ_name, $dt_from, $dt_to); 
		$xls_h->saveas_excel($abs_rep);
}
