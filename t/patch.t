use t::Helper;
use Mojo::JSON 'j';

my $t = t::Helper->t;
my $client = t::Helper->client($t);
my $res;

$t->app->db->resultset('Artist')->create({ id => 1, name => 'David Lang' });

{
  $t->patch_ok('/Foo/1', '{INVALID}')->status_is(400)->json_is('/message', 'Invalid JSON body.');
  $t->patch_ok('/Foo/1', '{}')->status_is(404)->json_is('/message', 'No source by that name.');
  $t->patch_ok('/Artist/2', '{}')->status_is(404)->json_is('/message', 'No such record in "Artist" source.');
  $t->patch_ok('/Artist/1', j { name => 'Elvis' })->status_is(200)->json_is('/data/name', 'Elvis');
}

{
  $t->app->db->resultset('Artist')->create({ id => 2, name => 'David Lang' });

  eval { $res = $client->patch(Foo => 123) };
  like $@, qr{Invalid data}, 'sync: Invalid data';

  eval { $res = $client->patch(Foo => 123, {}) };
  like $@, qr{No source by that name}, 'sync: No source by that name';

  $client->patch(Foo => 123, {}, t::Helper->client_cb);
  $client->_ua->ioloop->start;
  like $::err, qr{No source by that name}, 'async: No source by that name';

  $res = $client->patch(Artist => 2, { url => 'https://github.com/jhthorsen/cookieville' });
  is_deeply(
    $res,
    { data => { id => 2, name => "David Lang", url => "https://github.com/jhthorsen/cookieville" } },
    'sync: patch'
  ) or diag d $res;

  $client->patch(Artist => 2, { url => 'http://thorsen.pm' }, t::Helper->client_cb);
  $client->_ua->ioloop->start;
  is_deeply(
    $::res,
    { data => { id => 2, name => "David Lang", url => "http://thorsen.pm" } },
    'async: patch'
  ) or diag d $::res;
}

done_testing;
