# -*- encoding: utf-8 -*-
# stub: yaml_db 0.2.3 ruby lib

Gem::Specification.new do |s|
  s.name = "yaml_db"
  s.version = "0.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Adam Wiggins", "Orion Henry"]
  s.date = "2012-04-30"
  s.description = "\nYamlDb is a database-independent format for dumping and restoring data.  It complements the the database-independent schema format found in db/schema.rb.  The data is saved into db/data.yml.\nThis can be used as a replacement for mysqldump or pg_dump, but only for the databases typically used by Rails apps.  Users, permissions, schemas, triggers, and other advanced database features are not supported - by design.\nAny database that has an ActiveRecord adapter should work\n"
  s.email = "nate@ludicast.com"
  s.extra_rdoc_files = ["README.markdown"]
  s.files = [".travis.yml", "README.markdown", "Rakefile", "VERSION", "about.yml", "init.rb", "lib/csv_db.rb", "lib/serialization_helper.rb", "lib/tasks/yaml_db_tasks.rake", "lib/yaml_db.rb", "spec/base.rb", "spec/serialization_helper_base_spec.rb", "spec/serialization_helper_dump_spec.rb", "spec/serialization_helper_load_spec.rb", "spec/serialization_utils_spec.rb", "spec/yaml_dump_spec.rb", "spec/yaml_load_spec.rb", "spec/yaml_utils_spec.rb", "yaml_db.gemspec"]
  s.homepage = "http://github.com/ludicast/yaml_db"
  s.rubygems_version = "2.2.2"
  s.summary = "yaml_db allows export/import of database into/from yaml files"
end
