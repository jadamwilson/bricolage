package Bric::Biz::Category::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Bric::Biz::Category;
use Bric::Util::Grp::CategorySet;

my %cat = ( name        => 'Testing',
            site_id     => 100,
            description => 'Description',
            parent_id   => 0,
            directory   => 'testing',
          );

sub table { 'category' }

##############################################################################
# Test constructors.
##############################################################################
# Test the lookup() method.
sub test_lookup : Test(9) {
    my $self = shift;

    ok (my $cat = Bric::Biz::Category->new(\%cat), "Create $cat{name}");
    ok ($cat->set_ad_string('foo'),                'Set the ad string');
    ok ($cat->save,                                "Save $cat{name}");
    ok (my $id = $cat->get_id,                     "Check for ID" );

    # Save the ID for deleting.
    $self->add_del_ids([$id]);
    $self->add_del_ids([$cat->get_asset_grp_id], 'grp');

    # Look up the ID in the database.
    ok ($cat = Bric::Biz::Category->lookup({id => $id}), "Look up $cat{name}");
    is ($cat->get_id, $id,                        'Check that ID is the same');

    # Look up on site and uri
    ok ($cat = Bric::Biz::Category->lookup({uri => '/testing', site__id => 100}),
        "Look up $cat{name} on URI and Site");
    is ($cat->get_id, $id,                        'Check that ID is the same');

    # Make sure we've got the ad string.
    is ($cat->get_ad_string, 'foo', 'Check adstring');
}

##############################################################################
# Test the list() method.
sub test_list : Test(30) {
    my $self = shift;

    # Create a new category group.
    ok( my $grp = Bric::Util::Grp::CategorySet->new
        ({ name => 'Test CatSet' }),
        "Create group" );

    # Create some test records.
    for my $n (1..5) {
        my %args = %cat;
        # Make sure the directory name is unique.
        $args{directory} .= $n;
        $args{name} .= $n if $n % 2;
        ok( my $cat = Bric::Biz::Category->new(\%args), "Create $args{name}" );
        ok( $cat->save, "Save $args{name}" );
        # Save the ID for deleting.
        $self->add_del_ids([$cat->get_id]);
        $self->add_del_ids([$cat->get_asset_grp_id], 'grp');
        $grp->add_member({ obj => $cat }) if $n % 2;
    }

    ok( $grp->save, "Save group" );
    ok( my $grp_id = $grp->get_id, "Get group ID" );
    $self->add_del_ids([$grp_id], 'grp');

    # Try name.
    ok( my @cats = Bric::Biz::Category->list({ name => $cat{name} }),
        "Look up name $cat{name}" );
    is( scalar @cats, 2, "Check for 2 categories" );

    # Try name + wildcard.
    ok( @cats = Bric::Biz::Category->list({ name => "$cat{name}%" }),
        "Look up name $cat{name}%" );
    is( scalar @cats, 5, "Check for 5 categories" );

    # Try site_id
    ok( @cats = Bric::Biz::Category->list({site__id => 100}),
        'Look up site with ID 100');
    # We get 6 because of the default category
    is( scalar @cats, 6, "Check for 6 categories" );

    # Try grp_id.
    ok( @cats = Bric::Biz::Category->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id'" );
    is( scalar @cats, 3, "Check for 3 categories" );

    # Make sure we've got all the Group IDs we think we should have.
    my $all_grp_id = Bric::Biz::Category::INSTANCE_GROUP_ID;
    foreach my $cat (@cats) {
        my %grp_ids = map { $_ => 1 } @{ $cat->get_grp_ids };
        ok( $grp_ids{$all_grp_id} && $grp_ids{$grp_id},
          "Check for both IDs" );

    }

    # Try deactivating one group membership.
    ok( my $mem = $grp->has_member({ obj => $cats[0] }), "Get member" );
    ok( $mem->deactivate->save, "Deactivate and save member" );

    # Now there should only be two using grp_id.
    ok( @cats = Bric::Biz::Category->list({ grp_id => $grp_id }),
        "Look up grp_id '$grp_id' again" );
    is( scalar @cats, 2, "Check for 2 categories" );

    # Try parent_id. The root category shouldn't return itself, but should
    # return all of its children, of course.
    ok( @cats = Bric::Biz::Category->list({ parent_id => 0 }),
        "Look up parent_id 0" );
    is( scalar @cats, 5, "Check for 5 categories" );

}

1;
__END__
