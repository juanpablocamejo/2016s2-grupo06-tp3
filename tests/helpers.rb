module Helpers
  def test_class(name=nil, &bk)
    a_class = Class.new
    if name.nil?
      Object.const_set("TestClass#{(Time.now.to_f*1000).to_i}", a_class)
    else
      if Object.const_defined?(name)
        Object.send(:remove_const, name)
      end
      Object.const_set(name, a_class)
    end
    a_class.include MongoDocument
    a_class.class_eval &bk
    a_class
  end

  def test_instance
    a_class=test_class {
      field :field_name, String
    }
    an_instance=a_class.new
    an_instance.field_name= "value"
    an_instance
  end
end