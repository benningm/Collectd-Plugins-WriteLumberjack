package Collectd::Plugins::WriteLumberjack;

use strict;
use warnings;
use Collectd qw( :all );
use threads::shared;

use Net::Lumberjack::Client;
use Sys::Hostname;
use Time::Piece;

# ABSTRACT: sends collectd metrics to a lumberjack/beats server
# VERSION

=head1 SYNOPSIS

This is a collectd plugin for sending collectd metrics to lumberjack
or beats server like logstash or saftpresse.

In your collectd config:

    <LoadPlugin "perl">
    	Globals true
    </LoadPlugin>

    <Plugin "perl">
      BaseName "Collectd::Plugins"
      LoadPlugin "WriteLumberjack"

    	<Plugin "WriteLumberjack">
        host "127.0.0.1"
        port "5044"
        # keepalive "0"
        # frame_format "json"
        # max_window_size "2048"
        # use_ssl 1
        # ssl_verify 1
        # ssl_ca_file "/path/to/ca-bundle.crt"
        # ssl_ca_path "/path/to/ca-dir"
        # ssl_version "TLSv1_2" # see IO::Socket:SSL/SSL_version
        # ssl_hostname
        # ssl_cert
        # ssl_key
    	</Plugin>
    </Plugin>

=cut

my $config = {
  host => '127.0.0.1',
  port => 5044,
  keepalive => 0,
  frame_format => 'json',
  max_window_size => 2048,
  use_ssl => 0,
  ssl_verify => 1,
};

my @supported_options = (
  'host', 'port', 'keepalive', 'frame_format', 'max_window_size',
  'use_ssl', 'ssl_verify', 'ssl_ca_file', 'ssl_ca_path', 'ssl_version',
  'ssl_hostname', 'ssl_cert', 'ssl_file'
);

my $client;

sub write_lumberjack_config {
    my ($ci) = @_;
    foreach my $item (@{$ci->{'children'}}) {
        my $key = lc($item->{'key'});
        my $val = $item->{'values'}->[0];

        if( grep { $key eq $_ } @supported_options ) {
          $config->{$key} = $val;
        }
    }

    return 1;
}

sub write_lumberjack_init {
    $client = Net::Lumberjack::Client->new( %$config );

    return 1;
}

sub write_lumberjack_write {
    my ($type, $ds, $vl) = @_;

    my $plugin_str = $vl->{'plugin'};
    my $type_str   = $vl->{'type'};   
    if ( defined $vl->{'plugin_instance'} ) {
        $plugin_str .=  "-" . $vl->{'plugin_instance'};
    }
    if ( defined $vl->{'type_instance'} ) {
        $type_str .= "-" . $vl->{'type_instance'};
    }
    my $time = Time::Piece->new( $vl->{'time'} );

    my $log = {
      '@timestamp' => $time->datetime,
      'type' => 'collectd',
      'collectd_plugin' => $plugin_str,
      'collectd_type' => $type_str,
      'beat' => {
        'hostname' => hostname(),
      },
    };

    for (my $i = 0; $i < scalar (@$ds); ++$i) {
      my $name = $ds->[$i]->{'name'};
      $name =~ s/\s+/_/g;
      $log->{$name} = $vl->{'values'}->[$i],
    }

    eval { $client->send_data( $log ); };
    if( $@ ) {
      plugin_log( LOG_ERR, "WriteLumberjack: error sending data: ".$@ );
    }

    return 1;
}

plugin_register (TYPE_CONFIG, "WriteLumberjack", "write_lumberjack_config");
plugin_register (TYPE_WRITE, "WriteLumberjack", "write_lumberjack_write");
plugin_register (TYPE_INIT, "WriteLumberjack", "write_lumberjack_init");

1;
