namespace :example_data do
  desc "Create example data for testing"
  task generate: :environment do
    if HostingEnvironment.production?
      raise "THIS TASK CANNOT BE RUN IN PRODUCTION"
    end

    if ChildrensBarredListEntry.any?
      puts "Noop as DB already contains data"
      exit
    end

    # Running `bundle exec rails db:migrate example_data:generate` can sometimes
    # use cached column information. This forces rails to reload column
    # information before attempting to generate factories
    ChildrensBarredListEntry.reset_column_information

    FactoryBot.create(:childrens_barred_list_entry, date_of_birth: Date.new(1980, 1, 1))
  end
end
