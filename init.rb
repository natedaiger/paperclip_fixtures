require 'paperclip_fixtures'

# i can haz fixturs too!
ActiveRecord::ConnectionAdapters::AbstractAdapter.module_eval do
  include PaperclipFixtures
  alias_method_chain :insert_fixture, :attachment
end
