use Mojo::Base -base;
use Test::Mojo;
use Test::More;
use Cookieville;

$ENV{MOJO_CONFIG} = 't/log.conf';
$ENV{MOJO_LOG_LEVEL} = 'error';

plan skip_all => 'Cannot read MOJO_CONFIG' unless -r $ENV{MOJO_CONFIG};

my $t = Test::Mojo->new(Cookieville->new);

unlink 'test.log';
delete $ENV{MOJO_LOG_LEVEL};

{
  is $t->app->log->path, 'test.log', 'log path is set';
  is $t->app->log->level, 'warn', 'log level is set';

  $t->app->log->warn('YIKES!');
  ok -s('test.log'), 'test.log was created';
}

done_testing;
