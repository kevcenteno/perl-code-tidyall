package Code::TidyAll::t::Plugin;
use Capture::Tiny qw(capture_merged);
use Code::TidyAll::Util qw(tempdir_simple);
use Code::TidyAll;
use Test::Class::Most parent => 'Code::TidyAll::Test::Class';

__PACKAGE__->SKIP_CLASS("Virtual base class");

my $Test = Test::Builder->new;

sub startup : Tests(startup => no_plan) {
    my $self = shift;
    $self->{root_dir} = tempdir_simple();
}

sub plugin_class {
    my ($self) = @_;

    return ( split( '::', ref($self) ) )[-1];
}

sub tidyall {
    my ( $self, %p ) = @_;

    my $source       = $p{source} || die "source required";
    my $plugin_class = $self->plugin_class;
    my %plugin_conf  = ( $plugin_class => { select => '*', %{ $p{conf} || {} } } );
    my $ct = Code::TidyAll->new( quiet => 1, root_dir => $self->{root_dir}, plugins => \%plugin_conf );

    $source =~ s/\\n/\n/g;
    my $result;
    my $output = capture_merged { $result = $ct->process_source( $source, 'foo.txt' ) };
    $Test->diag($output) if $ENV{TEST_VERBOSE};

    if ( my $expect_tidy = $p{expect_tidy} ) {
        $expect_tidy =~ s/\\n/\n/g;
        is( $result->state,                'tidied',           'state=tidied' );
        is( $result->new_contents, $expect_tidy, 'new contents' );
    }
    elsif ( my $expect_ok = $p{expect_ok} ) {
        is( $result->state, 'checked', 'state=checked' );
        if ( $result->new_contents ) {
            is( $result->new_contents, $source, 'same contents' );
        }
    }
    elsif ( my $expect_error = $p{expect_error} ) {
        is( $result->state, 'error', 'state=error' );
        like( $result->error, $expect_error, 'error message' );
    }
}

1;
