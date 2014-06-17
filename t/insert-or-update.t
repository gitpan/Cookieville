use t::Helper;
use Mojo::JSON 'j';

my $t = t::Helper->t;

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

  $t->put_ok('/Artist', j { url => 'http://example.com/' })
    ->status_is(400)
    ->json_is('/message', 'JSON body need keys matching at least one unique constraint in "Artist".')
    ;
}

done_testing;
