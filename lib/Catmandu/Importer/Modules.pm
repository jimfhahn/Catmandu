package Catmandu::Importer::Modules;

use Catmandu::Sane;

our $VERSION = '1.0306';

use Module::Info;
use File::Spec;
use File::Find::Rule;
use Moo;
use Catmandu::Util qw(array_split pod_section);
use namespace::clean;

with 'Catmandu::Importer';

has inc => (
    is      => 'ro',
    lazy    => 1,
    default => sub {[@INC]},
    coerce  => \&array_split,
);

has namespace =>
    (is => 'ro', default => sub {[""]}, coerce => \&array_split,);

has max_depth => (is => 'ro', predicate => 1,);

has pattern => (is => 'ro',);

has primary => (is => 'ro',);

sub generator {
    my ($self) = @_;

    sub {
        state $pattern = $self->pattern;
        state $files   = {};
        state $names   = {};

        # array of [ $directory => $namespace ]
        state $search = [
            map {
                my $ns = $_;
                my $parts = [map {grep length, split(/::/, $_)} $ns];
                map {[File::Spec->catdir($_, @$parts) => $ns]} @{$self->inc};
            } @{$self->namespace}
        ];

        state $cur = shift(@$search) // return;

        state $rule = do {
            my $r = File::Find::Rule->new->file->name('*.pm');
            $r->maxdepth($self->max_depth) if $self->has_max_depth;
            $r->start($cur->[0]);
        };

        while (1) {
            my ($dir, $ns) = @$cur;

            if (defined(my $file = $rule->match)) {
                my $path = File::Spec->abs2rel($file, $dir);
                my $name = join('::', File::Spec->splitdir($path));
                $name =~ s/\.pm$//;
                $name = join('::', $ns, $name) if $ns;

                next if defined $pattern && $name !~ $pattern;

                my $info = Module::Info->new_from_file($file);
                my $file = File::Spec->rel2abs($file);

                next if $files->{$file};
                $files->{$file} = 1;

                if ($self->primary) {
                    next if $names->{$name};
                    $names->{$name} = 1;
                }

                my $data = {file => $file, name => $name, path => $dir,};
                $data->{version} = "" . $info->version
                    if defined $info->version;

                my $about = pod_section($file, 'NAME');
                $about =~ s/^[^-]+(\s*-?\s*)?|\n.*$//sg;
                $data->{about} = $about if $about ne '';

                return $data;
            }
            else {
                $cur = shift(@$search) // return;
                $rule->start($cur->[0]);
            }
        }
    };
}

1;

__END__

=pod

=head1 NAME

Catmandu::Importer::Modules - list installed perl modules in a given namespace

=head1 DESCRIPTION

This L<Catmandu::Importer> list perl modules from all perl library paths with
their C<name>, C<version>, absolute C<file>, library C<path>, and short
description (C<about>).

=head1 CONFIGURATION

=over

=item file

Read input from a local file given by its path. Alternatively a scalar
reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item encoding

Binmode of the input stream C<fh>. Set to C<:utf8> by default.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to imported items.

=item namespace

Namespace(s) for the modules to list, given as array or comma-separated list

=item inc

List of library paths (defaults to C<@INC>)

=item max_depth

Maximum depth to recurse into the namespace e.g. if the namespace is
Catmandu::Fix then Catmandu::Fix::add_field has a depth of 1 and
Catmandu::Fix::Condition::exists a depth of 2

=item pattern

Filter modules by the given regex pattern

=item primary

Filter modules to the first module of each name

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are
inherited.

=head1 SEE ALSO

L<Catmandu::Importer::CPAN>, L<Catmandu::Cmd::info>

=cut
