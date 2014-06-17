package t::Schema::Result::Artist;
use base 'DBIx::Class::Core';
__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
  id => { data_type => "integer", extra => { unsigned => 1 }, is_auto_increment => 1, is_nullable => 0 },
  name => { data_type => "varchar", default_value => "", is_nullable => 0, size => 80 },
  url => { data_type => "varchar", is_nullable => 1 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(['name']);
__PACKAGE__->has_many(cds => 't::Schema::Result::CD', 'artist_id');
1;
