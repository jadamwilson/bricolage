package Bric::Biz::Asset::Business::Story::DevTest;
use strict;
use warnings;
use base qw(Bric::Biz::Asset::Business::DevTest);
use Test::More;
use Bric::Biz::Asset::Business::Story;

sub class { 'Bric::Biz::Asset::Business::Story' }

##############################################################################
# Test the clone() method.
##############################################################################
sub test_clone : Test(15) {
    my $self = shift;
    ok( my $story = $self->construct( name => 'Flubber',
                                      slug => 'hugo'),
        "Construct story" );
    ok( $story->save, "Save story" );

    # Save the ID for cleanup.
    ok( my $sid = $story->get_id, "Get ID" );
    my $key = $self->class->key_name;
    push @{ $self->{$key} }, $sid;

    # Clone the story.
    ok( $story->clone, "Clone story" );
    ok( $story->save, "Save cloned story" );
    ok( my $cid = $story->get_id, "Get cloned ID" );
    push @{ $self->{$key} }, $cid;

    # Lookup the original story.
    ok( my $orig = $self->class->lookup({ id => $sid }),
        "Lookup original story" );

    # Lookup the cloned story.
    ok( my $clone = $self->class->lookup({ id => $cid }),
        "Lookup cloned story" );

    # Check that the story is really cloned!
    isnt( $sid, $cid, "Check for different IDs" );
    is( $orig->get_title, $clone->get_title, "Compare titles" );
    is( $orig->get_slug, $clone->get_slug, "Compare slugs" );
    is( $orig->get_uri, $clone->get_uri, "Compare uris" );

    # Check that the output channels are the same.
    ok( my @oocs = $orig->get_output_channels, "Get original OCs" );
    ok( my @cocs = $clone->get_output_channels, "Get cloned OCs" );
    is_deeply(\@oocs, \@cocs, "Compare OCs" );
}

1;
__END__

# Here is the original test script for reference. If there's something usable
# here, then use it. Otherwise, feel free to discard it once the tests have
# been fully written above.

#!/usr/bin/perl -w

use Bric::BC::Asset::Business::Story;
use Bric::BC::AssetType;

my $story;

eval {
my $at = Bric::BC::AssetType->lookup( { id => 1 });

my $s = Bric::BC::Asset::Business::Story->new({'element'   => $at,
					     'user__id'     => 11,
					     'source__id'   => 3});

generate_part_list($at,$s);

$s->checkin();

$s->save();

print $s->get_id() . "\n";

my $id = $s->get_id;

$story = Bric::BC::Asset::Business::Story->lookup( { id => $id });

my $title = $story->get_data('title',0);

my $url = $story->get_data('url',0);

print "These were returned by name and object index\n";
print "$title  $url \n";

print "here is everythingin order \n";
parse_container($story->get_tile, 0);

$story->checkout({user__id => 11});

$story->save();
};

die $@ if $@;

print "Checked out story is " . $story->get_id() . "\n";

sub parse_container {
	my $container = shift;
	my $index = shift;

	my $tabs = "\t" x $index;
	print "Container " . $container->get_name . "\n";

	my @tiles = $container->get_tiles();

	foreach my $tile (@tiles) {
		if ($tile->is_container) {
			parse_container($tile, $index++);
		} else {
			print $tabs . $tile->get_data() . "\n";
		}
	}
}

sub generate_part_list {
    my ($atc,$container) = @_;

    my $parts = $atc->get_data();
    my $sub_containers = $atc->get_containers();

    my $i = 0;

    my $add = {};
    foreach (@$parts) {
	$add->{$i}->{'id'} = $_->get_id();
	$add->{$i}->{'name'} = $_->get_name();
	$add->{$i}->{'obj'} = $_;
	$add->{$i}->{'data'} = 1;
	$i++;
    }

    foreach (@$sub_containers) {
	$add->{$i}->{'id'} = $_->get_id();
	$add->{$i}->{'name'} = $_->get_name();
	$add->{$i}->{'obj'} = $_;
	$add->{$i}->{'data'} = 0;
	$i++;
    }

    $add->{$i}->{'name'} = 'finish';
    $add->{$i}->{'end'} = 1;

    my $end = 0;
    while ($end != 1) {
	print "Choose From this list\n";
	
	foreach (sort { $a <=> $b} keys %$add) {
	    if (exists $add->{$_}->{'data'}) {
		print $add->{$_}->{'data'} ? 'D:  ' : 'C:  ';
	    } else {
		print '    ';
	    }

	    my $id   = $add->{$_}->{'id'} || '';
	    my $name = $add->{$_}->{'name'};

	    print "$_\t$id\t$name\n";
	}
	
	print "Enter your Choice\n";
	my $ii = <STDIN>;
	chomp $ii;
	
	my $string;
	unless (exists $add->{$ii}->{'end'}) {
	    print "Enter a value\n";
	    $string = <STDIN>;
	    chomp $string;
	}
	
	unless (exists $add->{$ii}->{'end'}) {
	    if ($add->{$ii}->{'data'}) {
		my $atd = $add->{$ii}->{'obj'};
		$container->add_data($atd, $string);
		
	    } else {
		my $nc = $container->add_container($add->{$ii}->{'obj'});
		# add the container bit here
		generate_part_list( $add->{$ii}->{'obj'}, $nc);
	    }
	} else {	
	    $end = 1;
	}
    }
}
