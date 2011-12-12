use C3000;


my $meter_name = 'À¼Æº±ä%';
my $Nr_profile = 68;
my $charID     = 634;
my $fh = C3000->new();
my $st = $fh->{'UserSessions'};
my $node_return_fields = [ 'NodeID' ];
my $criteria = [ [ 'DeviceName', $meter_name ], ];
my $rs = $fh->search_ADAS_node($node_return_fields, $criteria);

while( !$rs->EOF ){
	my $NodeID = $rs->Fields('NodeID')->{Value};
	$fh->{'dbh'}->do('update ADAS.AS_DEF_NODE_ATTR_VALUE SET INTEGER_VALUE =  ? where NODEID = ? and DEF_NODE_CHARACTERISTICID = ?', {AutoCommit => 1}, ($Nr_profile, $NodeID, $charID));
	$fh->{'ADASInstanceManager'}->SyncronizeADASNode($NodeID,$st); 
	$rs->MoveNext;
}
