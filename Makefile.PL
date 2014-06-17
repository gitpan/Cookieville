use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Cookieville',
  ABSTRACT_FROM => 'lib/Cookieville.pm',
  VERSION_FROM => 'lib/Cookieville.pm',
  AUTHOR => 'Jan Henning Thorsen <jhthorsen@cpan.org>',
  LICENSE => 'perl',
  PREREQ_PM => {
    'Mojolicious' => '4.03',
    'DBIx::Class' => '0.08',
  },
  BUILD_REQUIRES => {
    'DBD::SQLite' => '1.00',
    'SQL::Translator' => '0.11016',
    'Test::More' => '0.90',
  },
  META_MERGE => {
    resources => {
      license => 'http://dev.perl.org/licenses/',
      homepage => 'https://metacpan.org/release/Cookieville',
      bugtracker => 'https://github.com/jhthorsen/cookieville/issues',
      repository => 'https://github.com/jhthorsen/cookieville.git',
    },
  },
  test => {
    TESTS => 't/*.t',
  },
  EXE_FILES => ['script/cookieville'],
);
