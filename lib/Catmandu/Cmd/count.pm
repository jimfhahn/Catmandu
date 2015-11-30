package Catmandu::Cmd::count;

use Catmandu::Sane;

our $VERSION = '0.9504';

use parent 'Catmandu::Cmd';
use Catmandu;
use Catmandu::Fix;
use namespace::clean;

sub command_opt_spec {
    (
        [ "query|q=s", "" ],
    );
}

sub command {
    my ($self, $opts, $args) = @_;

    my $from_args = [];
    my $from_opts = {};

    for (my $i = 0; $i < @$args; $i++) {
        my $arg = $args->[$i];
        if ($arg =~ s/^-+//) {
            $arg =~ s/-/_/g;
            $from_opts->{$arg} = $args->[++$i];
        } else {
            push @$from_args, $arg;
        }
    }

    my $from_bag = delete $from_opts->{bag};
    my $from = Catmandu->store($from_args->[0], $from_opts)->bag($from_bag);
    if (defined $opts->query) {
        $from = $from->searcher(query => $opts->query);
    }

    say $from->count;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Cmd::count - count the number of objects in a store

=head1 EXAMPLES

  catmandu count <STORE> <OPTIONS>

  catmandu count ElasticSearch --index-name shop --bag products \
                               --query 'brand:Acme'

  catmandu help store ElasticSearch

=cut