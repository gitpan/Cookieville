use t::Helper;
use Mojo::JSON 'j';

my $t = t::Helper->t;

$t->app->db->resultset('Artist')->create({ id => 1, name => 'David Lang' });

{
  $t->patch_ok('/Foo/1', '{INVALID}')->status_is(400)->json_is('/message', 'Invalid JSON body.');
  $t->patch_ok('/Foo/1', '{}')->status_is(404)->json_is('/message', 'No source by that name.');
  $t->patch_ok('/Artist/2', '{}')->status_is(404)->json_is('/message', 'No such record in "Artist" source.');
  $t->patch_ok('/Artist/1', j { name => 'Elvis' })->status_is(200)->json_is('/data/name', 'Elvis');
}

done_testing;
