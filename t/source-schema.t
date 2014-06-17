use t::Helper;

my $t = t::Helper->t;

{
  $t->get_ok('/Foo/schema')->status_is(404)->json_is('/message', 'No source by that name.');
  $t->get_ok('/CD/schema')
    ->json_is('/columns/id/is_auto_increment', 1)
    ->json_is('/columns/name/data_type', 'varchar')
    ->json_is('/name', 'cd')
    ->json_is('/primary_columns', ['id'])
    ;
}

done_testing;
