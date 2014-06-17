use t::Helper;

my $t = t::Helper->t;

$t->app->db->resultset('Artist')->create({ id => 1, url => 'http://example.com', name => 'David Lang' });

{
  $t->get_ok('/Foo/search')->status_is(404)->json_is('/message', 'No source by that name.');
  $t->get_ok('/Artist/search')->status_is(400)->json_is('/message', 'Invalid (q) query param.');
  $t->get_ok('/Artist/search?q={"name":"David Lang"}')->status_is(200)
    ->json_is('/data/0/id', 1)
    ->json_is('/data/0/name', 'David Lang')
    ;
}

{
  $t->get_ok('/Foo/search.csv')->status_is(404)->content_is('No source by that name.');
  $t->get_ok('/Artist/search.csv')->status_is(400)->content_is('Invalid (q) query param.');
  $t->get_ok('/Artist/search.csv?q={"name":"David Lang"}')
    ->status_is(200)
    ->content_is(<<"    CSV");
id,name,url
1,"David Lang",http://example.com
    CSV
}

done_testing;
