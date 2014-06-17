use Mojo::Base -base;
use Test::Mojo;
use Test::More;
use Cookieville;

my $t = Test::Mojo->new(Cookieville->new);

{
  delete $ENV{COOKIEVILLE_INFO};
  $t->get_ok('/')
    ->json_is('/source', 'https://github.com/jhthorsen/cookieville')
    ->json_is('/resources/schema_source_list/0', 'GET')
    ->json_is('/resources/schema_source_list/1', '/sources')
    ->json_is('/version', Cookieville->VERSION)
    ;
}

{
  $ENV{COOKIEVILLE_INFO} = 'source';

  $t->get_ok('/')
    ->json_is('/resources', undef)
    ->json_is('/source', 'https://github.com/jhthorsen/cookieville')
    ->json_is('/version', undef)
    ;
}

{
  $ENV{COOKIEVILLE_INFO} = '';
  $t->get_ok('/')->content_is('{}');
}

done_testing;
