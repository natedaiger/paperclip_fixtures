module PaperclipFixtures
  
  def insert_fixture_with_attachment(fixture, table_name)
    if klass = attachment_model?(fixture)
      fixture = fixture.to_hash
      key = fixture.keys.grep(/file_for_/)
      full_path = fixture.delete(key)
      attachment_field = key.gsub(/file_for_(.*)/, '\1')
      
      file = File.new(full_path)
      
      temp_model = klass.new
      set_method = "#{attachment_field}=".to_sym
      temp_model.send(set_method, file)
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

    fixture_includes_file_for = fixture.keys.grep(/file_for_/)

    (klass && fixture_includes_file_for) ? klass : nil
  end
  
end