use t::Helper;

my $t = t::Helper->t;

{
  $t->get_ok('/sources')->content_is(qq(["Artist","CD"]));
  $t->get_ok('/sources.csv')->content_is(qq(Artist,CD));
  $t->get_ok('/sources.txt')->content_is(qq(Artist\nCD\n));
}

done_testing;
