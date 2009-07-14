module PaperclipFixtures
  # our strategy here is to look at each fixture to see if it has a paperclip
  # attachment, and if it does, remember the attachments and the files for each one.
  #
  # then insert the fixture normally (to get the primary key and associations)
  #
  # then load the model for the fixture that just got inserted, use a normal setter
  # for all the attachments, and use a normal save
  #
  # THIS DOESN'T WORK WITH:
  #  * fixtures that don't validate
  def insert_fixture_with_attachment(fixture, table_name)
    save_attachment = false
    if klass = attachment_model?(fixture)
      
      fixture = fixture.to_hash
      
      methods_and_files = {}
      fixture.keys.each do |key|
        if key =~ /file_for_/
          full_path        = fixture.delete(key)
          attachment_field = key.gsub(/file_for_(.*)/, '\1')
          save_attachment  = true
          
          method = "#{attachment_field}=".to_sym
          file   = File.new(full_path)
          
          methods_and_files[method] = file
        end
      end

      # now that the attachment data is out of the picture, make a normal fixture
      temp_model = klass.new()
      fixture = Fixture.new(temp_model.attributes.update(fixture), klass)
    end
    
    # regular fixture inserter for non paperclip craps
    retval = insert_fixture_without_attachment(fixture, table_name)

    if save_attachment
      # now load the model and add the file and save it
      primary_key = klass.primary_key
      id          = fixture[primary_key]
      temp_model  = klass.find(id)
      
      methods_and_files.each do |method, file|
        temp_model.send(method, file)
      end
      temp_model.save(false)
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