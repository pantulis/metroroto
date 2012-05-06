desc 'Dump a database to yaml fixtures. '
task :dump_fixtures => :environment do
  path = ENV['FIXTURE_DIR'] || "#{Rails.root}/data"

  ActiveRecord::Base.establish_connection(Rails.env.to_sym)
  ActiveRecord::Base.connection.
             select_values('show tables').each do |table_name|
    i = 0
    puts "Dumping #{table_name}"
    File.open("#{path}/#{table_name}.yml", 'wb') do |file|
      file.write ActiveRecord::Base.connection.
          select_all("SELECT * FROM .#{table_name}").inject({}) { |hash, record|
      hash["#{table_name}_#{i += 1}"] = record
        hash
      }.to_yaml
    end
  end
end

desc "Reset Database data to that in fixtures that were dumped"
task :load_dumped_fixtures => :environment do
  require 'active_record/fixtures'
  ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
  path = ENV['FIXTURE_DIR'] || "#{RAILS_ROOT}/data"
  Dir.glob("#{path}/*.{yml}").each do |fixture_file|
    Fixtures.create_fixtures(path, File.basename(fixture_file, '.*'))
  end
end
