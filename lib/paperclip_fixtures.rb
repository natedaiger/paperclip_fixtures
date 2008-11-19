module PaperclipFixtures

  # our strategy here is to look at each fixture to see if it has a paperclip
  # attachment, and if it does, remember the file to use and what attribute
  # to assign that file to.
  #
  # then insert the fixture normally (to get the primary key and associations)
  #
  # then load the model for the fixture that just got inserted, set the file,
  # and save it (using AR, not any fixture crapola).
  #
  # THIS DOESN'T WORK WITH:
  #  * multiple attachments
  #  * fixtures that don't validate
  #  * probably lots of other things!
  def insert_fixture_with_attachment(fixture, table_name)
    save_attachment = false
    if klass = attachment_model?(fixture)
    
      fixture          = fixture.to_hash
      key              = fixture.keys.grep(/file_for_/).first
      full_path        = fixture.delete(key)
      attachment_field = key.gsub(/file_for_(.*)/, '\1')

      # we need these to set the file attribute after inserting the fixture
      save_attachment = true      
      file            = File.new(full_path)
      temp_model      = klass.new()
      set_method      = "#{attachment_field}=".to_sym

      fixture = Fixture.new(temp_model.attributes.update(fixture), klass)
    end
    
    # regular fixture inserter for non paperclip craps
    retval = insert_fixture_without_attachment(fixture, table_name)

    if save_attachment
      # now load the model and add the file and save it
      primary_key = klass.primary_key
      id          = fixture[primary_key]
      temp_model  = klass.find(id)
      
      temp_model.send(set_method, file)
      temp_model.save
    end
    return retval
  end
  
  # This is from attachment_fu_fixtures.
  # http://github.com/mynyml/attachment_fu_fixtures/tree/master
  def attachment_model?(fixture)
    # HABTM join tables generate unnamed fixtures; skip them since they
    # will not include attachments anyway (you'd use HM:T)
    return false if fixture.nil? || fixture.class_name.nil?

    klass =
      if fixture.respond_to?(:model_class)
        fixture.model_class
      elsif fixture.class_name.is_a?(Class)
        fixture.class_name
      else
        Object.const_get(fixture.class_name)
        #fixture.class_name.camelize.constantize
      end

    # resolve real class if we have an STI model
    if k = fixture[klass.inheritance_column]
      klass = k.camelize.constantize
    end

    fixture_mising_file_for = fixture.to_hash.keys.grep(/file_for_/).empty?
    
    (klass && !fixture_mising_file_for) ? klass : nil
  end
end