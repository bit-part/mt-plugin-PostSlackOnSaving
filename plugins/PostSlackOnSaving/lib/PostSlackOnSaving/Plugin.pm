package PostSlackOnSaving::Plugin;

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common;
use MT::Author;
use CustomFields::Util qw( get_meta );

sub plugin {
    return MT->component('PostSlackOnSaving');
}

sub _log {
    my ($msg) = @_;
    return unless defined($msg);
    my $prefix = sprintf "%s:%s:%s: %s", caller();
    $msg = $prefix . $msg if $prefix;
    use MT::Log;
    my $log = MT::Log->new;
    $log->message($msg) ;
    $log->save or die $log->errstr;
    return;
}

sub chat_post_message {
    my ($url, $postdata) = @_;

    my $request = POST($url, $postdata);

    # Post a chat message
    $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
    my $ua = LWP::UserAgent->new;
    my $res = $ua->request($request)->as_string;
    return $res;
}

#----- Hook
sub hdlr_cms_post_save_author {
    my ($cb, $app, $obj) = @_;

    # Check the timing saved
    my $class = ref $app;
    my $changed = keys %{$obj->{changed_cols}};
    if ($class eq 'MT::Author') {
        if (defined $obj->{__meta}->{__objects}->{favorite_blogs} or
            # ==== For document.bit-part.net [start] ==== #
            defined $obj->{changed_cols}->{modified_on} or
            # ==== For document.bit-part.net [ end ] ==== #
            $changed == 0) {
            return 1;
        }
    }

    # Get plugin settings
    my $scope = 'system';
    my $config = &plugin->get_config_hash($scope);
    return 1 unless ($config->{'slack_api_url'} or $config->{'slack_token'} or $config->{'slack_channel'});


    # Movable Type Information
    my $cb_method = $cb->method;
    $cb_method =~ s/::post_save//;

    # Set author status
    my %author_status = (
        '1' => MT->translate('_USER_ENABLED'),
        '2' => MT->translate('_USER_DISABLED'),
        '3' => MT->translate('_USER_PENDING'),
    );

    my (@message_text_body, %message_obj);

    push @message_text_body, 'Posted by ' . $cb_method;
    push @message_text_body, MT->translate('A User have been updated.');

    $message_obj{name} = $obj->name || 'anonymous';
    $message_obj{status} = $author_status{ $obj->status } || 'Undefined';
    $message_obj{created_on} = $obj->created_on;
    if ($message_obj{created_on}) {
        $message_obj{created_on} =~ s/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/$1-$2-$3 $4:$5:$6/
    }

    push @message_text_body, $message_obj{name} . ' (' . $message_obj{status} . ') at ' . $message_obj{created_on}; # authorname (status) at

    # ==== For document.bit-part.net [start] ==== #
    my $author_meta = get_meta($obj);
    if (defined $author_meta->{authorexpiredate}) {
        $message_obj{authorexpiredate} = $author_meta->{authorexpiredate};
        $message_obj{authorexpiredate} =~ s/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/$1-$2-$3/;
        $message_obj{authorexpiredate} = '"Expire Date" is ' . $message_obj{authorexpiredate};
    }
    else {
        $message_obj{authorexpiredate} = 'Please set the "Expire Date".';
    }
    push @message_text_body, $message_obj{authorexpiredate};
    # ==== For document.bit-part.net [ end ] ==== #


    # Set a post data
    my %postdata;
    $postdata{channel} = $config->{'slack_channel'};
    $postdata{username} = $config->{'slack_user_name'} || 'Movable Type';
    $postdata{icon_url} = $config->{'slack_icon_url'} if ($config->{'slack_icon_url'});
    $postdata{text} = join "\n", @message_text_body;

    my $url = $config->{'slack_api_url'} . 'chat.postMessage?token=' . $config->{'slack_token'};
    chat_post_message($url, \%postdata);

    1;
}

1;
