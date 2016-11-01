require 'rspec'
require_relative '../lib/mongo_document'
require_relative 'helpers'

describe 'With MongoDocument included' do
  include Helpers
  describe 'fields' do
    it 'an instance should have auto-generated fields accessors' do
      a_class=test_class {
        field :fieldName, String
        field :fieldName2, String
      }
      an_instance=a_class.new

      expect(an_instance).to respond_to(:fieldName, :fieldName2)
      expect(an_instance).to respond_to(:fieldName=, :fieldName2=)

      an_instance.fieldName = "valor"
      expect(an_instance.fieldName).to eq("valor")
    end
    it 'a class should return the fields list on "fields"' do
      a_class=test_class {
        field :fieldName, String
      }

      expect(a_class).to respond_to(:fields)
      expect(a_class.fields).to eq([:_id, :fieldName])
    end
    it 'an instance should check type on fields setters' do
      a_class=test_class {
        field :name, String
        field :age, Integer
      }
      an_instance=a_class.new
      expect{ an_instance.name= 1 }.to raise_error(Error::FieldTypeError)
      expect{ an_instance.age= "" }.to raise_error(Error::FieldTypeError)
    end
    it 'an instance should run validations on fields setters' do
      a_class=test_class {
        field :name, String, {:required=>true}
        field :age, Integer, {:required=>false}
      }
      an_instance=a_class.new
      an_instance.age= nil
      expect{ an_instance.name= nil }.to raise_error(Error::RequiredFieldError)
    end
  end
  describe 'collection' do
    it 'a class should use default collection_name when it´s not explicitly defined' do
      persona_class=test_class(:Persona) {}

      expect(persona_class).to respond_to(:collection_name)
      expect(persona_class.collection_name).to eq("personas")
    end
    it 'a class should use custom collection_name when it´s explicitly defined' do
      a_class = test_class(:TestClass) {
        collection :collectionName
      }

      expect(a_class).to respond_to(:collection_name)
      expect(a_class.collection_name).to eq("collectionName")
    end


  end
  describe 'hash' do
    it 'a class should return a hash representation on "to_hash"' do
      a_class=test_class() {
        field :name, String
        field :age, Integer
      }
      an_instance=a_class.new
      an_instance.name = "pepe"
      an_instance.age = 25
      expect(an_instance.to_hash).to eq({"_id" => nil, "name" => "pepe", "age" => 25})
    end
  end
  describe 'operations ( save | update | remove | count | find )' do
    it 'an instance should be inserted to db on "save"' do
      an_instance=test_instance
      before = an_instance.class.count
      an_instance.save
      after = an_instance.class.count

      expect(after).to be(before+1)
    end
    it 'an instance should be updated in db on "update"' do
      a_class=test_class { field :nombre, String }
      an_instance = a_class.new
      an_instance.nombre='pepe'
      an_instance.save
      before_update = a_class.find_by_id(an_instance._id)[0]
      expect(before_update.nombre).to eq('pepe')
      an_instance.nombre='pablo'
      an_instance.update
      after_update = a_class.find_by_id(an_instance._id)[0]
      expect(after_update.nombre).to eq('pablo')
      expect(after_update._id).to eq(before_update._id)
    end
    it 'an instance should be removed from db on "remove"' do
      an_instance=test_instance
      an_instance.save
      before = an_instance.class.count
      an_instance.remove
      after = an_instance.class.count

      expect(after).to be(before-1)
    end
    it 'a class should retrieve instances that matches with specified criteria on "find"' do
      an_instance = test_instance {}
      an_instance.save
      results = an_instance.class.find({"_id" => an_instance._id})
      expect(results.size).to be(1)
      expect(an_instance._id).to eq(results.first._id)
    end
    it 'a class should retrieve instances that matches with dynamic find method: "find_by_id_and_name"' do
      a_class = test_class {
        field :name, String
      }
      an_instance = a_class.new
      an_instance.name= 'find me'
      an_instance.save

      results = a_class.find_by_id_and_name(an_instance._id, 'find me')
      expect(results.size).to be(1)
      expect(an_instance._id).to eq(results.first._id)
    end
  end
  describe 'hooks' do
    it 'an instance should execute "before_save" before insert to db' do
      a_class = test_class() {
        def before_save
          raise Exception
        end
      }
      an_instance=a_class.new
      old_count = a_class.count
      expect { an_instance.save }.to raise_error(Exception)
      new_count = a_class.count
      expect(new_count).to eq(old_count)
    end
    it 'an instance should execute "after_save" after insert to db' do
      a_class =test_class() {
        def after_save
          @after = true
        end
      }
      an_instance=a_class.new
      expect(an_instance.instance_variable_defined?(:@after)).to be(false)
      old_count = a_class.count
      an_instance.save
      new_count = a_class.count
      expect(new_count).to eq(old_count+1)
      expect(an_instance.instance_variable_get(:@after)).to be(true)
    end
    it 'a class should execute "on_populate" on each obtained instance by "find" after populate it' do
      a_class = test_class() { on_populate { @populate_called=true } }
      instances = []
      [1..10].each { instances.push(a_class.new.save) }
      res=a_class.find()
      res.each do
      |obj|
        expect(obj.instance_variable_defined?(:@populate_called)).to be(true)
      end
    end
  end


end