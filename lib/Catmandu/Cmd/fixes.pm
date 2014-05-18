package Catmandu::Cmd::fixes;
use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Catmandu::Importer::Fixes;

sub command_opt_spec {
    (
        ["inc|i=s@","override included directories (defaults to \@INC)",{ default => [@INC] }],
        ["add_inc=s@","add lookup directories",{ default => [] }],
        ["verbose|v","include package information"]

    );
}
sub description {
    <<EOS;
examples:

catmandu fixes -v

options:
EOS
}
sub print_simple {
    my $record = $_[0];

    my @p = map { 
        "$_: ".$record->{$_}; 
    } grep { 
        defined($record->{$_}); 
    } qw(name file version);
   
    say join(', ',@p);


}
sub command {
    my ($self, $opts, $args) = @_;

    my $verbose = $opts->verbose;

    Catmandu::Importer::Fixes->new(
        inc => $opts->inc,
        add_inc => $opts->add_inc
    )->each(sub{
        my $record = shift;

        unless($verbose){
            say $record->{name};
        }else{
            print_simple($record);
        }
    });
}

1;

=head1 NAME

Catmandu::Cmd::fixes - list available Catmandu fixes

=head1 AUTHOR

    Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=cut
