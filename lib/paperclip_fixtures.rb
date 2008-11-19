module PaperclipFixtures
  
  def insert_fixture_with_attachment(fixture, table_name)
    if klass = attachment_model?(fixture)
      # puts "klass: #{klass}"
      fixture = fixture.to_hash
      key = fixture.keys.grep(/file_for_/).first
      # puts "found key: #{key}"
      full_path = fixture.delete(key)
      # puts "full path: #{full_path}"
      attachment_field = key.gsub(/file_for_(.*)/, '\1')
      # puts "field: #{attachment_field}"
      
      file = File.new(full_path)
      
      temp_model = klass.new()
      temp_model.id = fixture['id']
      # puts "fixtures id is: #{temp_model.id}"
      set_method = "#{attachment_field}=".to_sym
      # set the data
      temp_model.send(set_method, file)
      # write out the files
      temp_model.save_attached_files
      fixture = Fixture.new(temp_model.attributes.update(fixture), klass)
    end
    insert_fixture_without_attachment(fixture, table_name)
  end
  
  
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