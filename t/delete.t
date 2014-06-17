use t::Helper;

my $t = t::Helper->t;

$t->app->db->resultset('Artist')->create({ id => 1, name => 'David Lang' });

{
  $t->delete_ok('/Foo/1')->status_is(404)->json_is('/message', 'No source by that name.');
  $t->delete_ok('/Artist/1')->status_is(200)->json_is('/n', 1);
  $t->delete_ok('/Artist/1')->status_is(200)->json_is('/n', 0);
}

done_testing;
