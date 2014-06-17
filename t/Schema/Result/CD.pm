package t::Schema::Result::CD;
use base 'DBIx::Class::Core';
__PACKAGE__->table('cd');
__PACKAGE__->add_columns(
  id => { data_type => "integer", extra => { unsigned => 1 }, is_auto_increment => 1, is_nullable => 0 },
  artist_id => { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  name => { data_type => "varchar", default_value => "", is_nullable => 0, size => 80 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(artist => 't::Schema::Result::Artist', 'id');
1;
