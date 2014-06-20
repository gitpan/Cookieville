use t::Helper;

my $t = t::Helper->t;
my $client = t::Helper->client($t);
my $res;

{
  $t->app->db->resultset('Artist')->create({ id => 1, name => 'David Lang' });

  $t->delete_ok('/Foo/1')->status_is(404)->json_is('/message', 'No source by that name.');
  $t->delete_ok('/Artist/1')->status_is(200)->json_is('/n', 1);
  $t->delete_ok('/Artist/1')->status_is(200)->json_is('/n', 0);
}

{
  $t->app->db->resultset('Artist')->create({ id => 2, name => 'David Lang' });

  eval { $res = $client->delete(Foo => 123) };
  like $@, qr{No source by that name.}, 'sync: No source by that name.';

  $client->delete(Foo => 123, t::Helper->client_cb);
  $client->_ua->ioloop->start;
  like $::err, qr{No source by that name.}, 'async: No source by that name.';

  $res = $client->delete(Artist => 2);
  is_deeply $res, { n => 1 }, 'sync: delete';

  $client->delete(Artist => 2, t::Helper->client_cb);
  $client->_ua->ioloop->start;
  is_deeply $::res, { n => 0 }, 'async: delete';
}

done_testing;
