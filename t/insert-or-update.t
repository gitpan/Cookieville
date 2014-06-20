use t::Helper;
use Mojo::JSON 'j';

my $t = t::Helper->t;
my $client = t::Helper->client($t);
my $res;

{
  $t->put_ok('/Foo', '{INVALID}')->status_is(400)->json_is('/message', 'Invalid JSON body.');
  $t->put_ok('/Foo', '{}')->status_is(404)->json_is('/message', 'No source by that name.');

  $t->put_ok('/Artist', j { name => 'David Lang', url => 'http://davidlangmusic.com/' })
    ->status_is(200)
    ->json_is('/inserted', 1)
    ->json_is('/data/id', 1)
    ->json_is('/data/name', 'David Lang')
    ;

  $t->put_ok('/Artist', j { name => 'David Lang', url => 'http://example.com/' })
    ->status_is(200)
    ->json_is('/inserted', 0)
    ->json_is('/data/id', 1)
    ->json_is('/data/name', 'David Lang')
    ;
}

{
  eval { $res = $client->put('Foo') };
  like $@, qr{Invalid data}, 'sync: Invalid data';

  eval { $res = $client->put(Foo => {}) };
  like $@, qr{No source by that name}, 'sync: No source by that name';

  $client->put(Foo => {}, t::Helper->client_cb);
  $client->_ua->ioloop->start;
  like $::err, qr{No source by that name}, 'async: No source by that name';

  $res = $client->put(Artist => { url => 'https://github.com/jhthorsen/cookieville' });
  is_deeply(
    $res,
    {
      data => { id => 2, name => "", url => "https://github.com/jhthorsen/cookieville" },
      inserted => 1,
    },
    'sync: put'
  ) or diag d $res;

  $client->put(Artist => { id => 2, name => 'Cookie monster' }, t::Helper->client_cb);
  $client->_ua->ioloop->start;
  is_deeply(
    $::res,
    {
      data => { id => 2, name => "Cookie monster", url => "https://github.com/jhthorsen/cookieville" },
      inserted => 0,
    },
    'async: put'
  ) or diag d $::res;
}

done_testing;
