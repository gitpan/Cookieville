use t::Helper;

$ENV{MOJO_CONFIG} = 't/plugin-authorize.conf';

plan skip_all => 'Cannot read MOJO_CONFIG' unless -r $ENV{MOJO_CONFIG};

my $t = t::Helper->t;
my $client = t::Helper->client($t);
my $res;

{
  diag 'Test without X-Cookieville-Auth-Id';
  $t->get_ok('/')->status_is(200)->json_is('/source', 'https://github.com/jhthorsen/cookieville');
  $t->get_ok('/sources')->status_is(401)->json_is('/message', 'Not authorized.');

  $client->id('Some-Invalid-Auth-Id');
  eval { $client->delete(Artist => 1) };
  like $@, qr{Not authorized}, 'delete: Not authorized';

  eval { $client->patch(Artist => 1 => {}) };
  like $@, qr{Not authorized}, 'patch Not authorized';

  eval { $client->put(Artist => {}) };
  like $@, qr{Not authorized}, 'put Not authorized';

  eval { $client->search(Artist => {}) };
  like $@, qr{Not authorized}, 'search: Not authorized';
}

{
  diag 'Test Artist source with X-Cookieville-Auth-Id';
  $client->id('Some-Long-Auth-Id-12b34acf274');

  $t->get_ok('/sources', { 'X-Cookieville-Auth-Id' => $client->id })->status_is(200)->json_is('/0', 'Artist');

  $res = $client->delete(Artist => 1);
  is $res->{n}, 0, 'delete Artist: Authorized';

  $res = $client->put(Artist => { name => 'Elvis' });
  is $res->{data}{id}, 1, 'put Artist: Authorized' or diag d $res;

  $res = $client->patch(Artist => 1 => { url => 'http://mojolicio.us' });
  is $res->{data}{name}, 'Elvis', 'patch Artist: Authorized' or diag d $res;

  $res = $client->search(Artist => {});
  is $res->{data}[0]{url}, 'http://mojolicio.us', 'search Artist: Authorized';
}

{
  diag 'Test CD source with X-Cookieville-Auth-Id';
  $client->id('Some-Long-Auth-Id-12b34acf274');

  eval { $client->delete(CD => 1) };
  like $@, qr{Cannot DELETE CD}, 'delete: Not authorized';

  eval { $client->put(CD => { name => 'Elvis' }) };
  like $@, qr{Cannot PUT CD}, 'Cannot PUT CD';

  eval { $client->patch(CD => 1 => { url => 'http://mojolicio.us' }) };
  like $@, qr{No such record in CD source}, 'patch CD: Authorized';

  $res = $client->search(CD => {});
  is_deeply $res->{data}, [], 'search CD: Authorized';
}

done_testing;
