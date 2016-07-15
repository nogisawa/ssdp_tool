#!/usr/bin/perl


# Server mode
if( $ARGV[0] eq 'server' ){ &server_mode(); }
if( $ARGV[0] eq 'search' ){ &search_mode(); }

exit 1;


sub search_mode(){

	print "Starting Search mode\n";

	&ssdp_send('239.255.255.250');

        use strict;
        use warnings;
        use IO::Socket::Multicast;

        my $param;
        $param->{my_ssdp_group}   = '239.255.255.250';
        $param->{my_ssdp_port}    = '1900';

        #Create UDP Multicast Socket;
        $param->{ssdp_socket} = IO::Socket::Multicast->new( Proto=>'udp',
                                                      LocalPort=>$param->{my_ssdp_port});


        $param->{ssdp_socket}->mcast_add($param->{my_ssdp_group}) || die "SSDP IO::Socket: $!\n";

        my $ssdp_recieve_sock = $param->{ssdp_socket};

        # Turn off loopbacking
        $ssdp_recieve_sock->mcast_loopback(0);

        # SSDPのパケットを待ち伏せる。
        # もしSSDPのパケットが来たらVPNの先にUDP Unicastで飛ばす
        while ( 1 ) {

                my $msg;

                if( my $ca = $ssdp_recieve_sock->recv($msg,256) ){

                        # recvの結果から送信元IPアドレスを抽出する
                        my($from_port, $from_addr) = unpack_sockaddr_in($ca);
                        my($from_ip, $from_host) = (inet_ntoa($from_addr), gethostbyaddr($from_addr, AF_INET));

                        if( $msg =~ /NOTIFY/m ){

                                print "RECIEVE NOTIFY from $from_ip:$from_port\n";
				print $msg;

                        }

                }

        }


	return;

}

sub server_mode(){

	print "Starting Server Mode\n";

	use strict;
	use warnings;
	use IO::Socket::Multicast;

        my $param;
        $param->{my_ssdp_group}   = '239.255.255.250';
        $param->{my_ssdp_port}    = '1900';

        #Create UDP Multicast Socket;
        $param->{ssdp_socket} = IO::Socket::Multicast->new( Proto=>'udp',
                                                      LocalPort=>$param->{my_ssdp_port});


        $param->{ssdp_socket}->mcast_add($param->{my_ssdp_group}) || die "SSDP IO::Socket: $!\n";

        my $ssdp_recieve_sock = $param->{ssdp_socket};

        # Turn off loopbacking
        $ssdp_recieve_sock->mcast_loopback(0);

        # SSDPのパケットを待ち伏せる。
        # もしSSDPのパケットが来たらVPNの先にUDP Unicastで飛ばす
        while ( 1 ) {

                my $msg;

                if( my $ca = $ssdp_recieve_sock->recv($msg,256) ){

			# recvの結果から送信元IPアドレスを抽出する
			my($from_port, $from_addr) = unpack_sockaddr_in($ca);
			my($from_ip, $from_host) = (inet_ntoa($from_addr), gethostbyaddr($from_addr, AF_INET));

                        if( $msg =~ /M\-SEARCH/m ){

				print "RECIEVE M-SEARCH from $from_ip:$from_port\n";
				&ssdp_send($from_ip);

                        }

                }

        }

	return;

}

sub ssdp_send(){

        use strict;
        use Socket;
	use IO::Socket;
	use IO::Socket::Multicast;

        my $dest_ip   = $_[0];
        my $dest_port = 1900;

	# 宛先がSSDPのアドレスならマルチキャストで送信する
	if( $dest_ip eq '239.255.255.250' ){

		# 探索用のデータはsearch.txt
                open(FILE, "< search.txt") or die "$1";

                my $msg;

                while(my $line = <FILE>){
                        chomp($line);
                        $msg .= "$line\r\n";
                }

                $msg =~ s/\r?\n/\r\n/g;

                my $sock = IO::Socket::Multicast->new(Proto=>'udp',LocalPort=>"50500");

		$sock->mcast_add($dest_ip) || die "Couldn't set group: $!\n";

		$sock->mcast_send($msg,"$dest_ip:$dest_port") || die "Couldn't send: $!";

		print "M-SEARCH sent for $dest_ip:$dest_port\n";

		while ( 1 ) {

			my $data;
			next unless $sock->recv($data,256);
			print "$data\n";
			sleep 1;
 
		}


	# 宛先がSSDPのマルチキャストアドレスでなければ通常のユニキャストで送信する
	}else{

	        open(FILE, "< packet.txt") or die "$1";

	        my $msg;

	        while(my $line = <FILE>){
	                chomp($line);
	                $msg .= "$line\r\n";
	        }


	        $msg =~ s/\r?\n/\r\n/g;

	        my $sock = IO::Socket::INET->new(
			PeerAddr => $dest_ip,
			PeerPort => $dest_port,
			Proto    => "udp"
		) or die "IO::Socket::INET Error : $!";

		$sock->send($msg);
		$sock->close;

	        print "NOTIFIY sent for $dest_ip:$dest_port\n";

	}

	return;

}


