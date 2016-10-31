require 'rspec'
require '../lib/mongo_document'
require '../tests/helpers'

describe 'MongoDocument specs' do
  include Helpers
  describe 'a class with MongoDocument' do

    describe 'with fields definitions' do
      it 'should auto-generate fields accessors' do
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
      it 'should return the fields list on "fields"' do
        a_class=test_class {
          field :fieldName, String
        }

        expect(a_class).to respond_to(:fields)
        expect(a_class.fields).to eq([:_id, :fieldName])
      end

    end
    describe 'with explicit collection definition' do
      it 'should return the name on "collection_name"' do
        a_class = test_class(:TestClass) {
          collection :collectionName
        }

        expect(a_class).to respond_to(:collection_name)
        expect(a_class.collection_name).to eq("collectionName")
      end
    end
    describe 'without explicit collection definition' do
      it 'should return the default collection name on "collection_name"' do
        personaClass=test_class(:Persona) {}

        expect(personaClass).to respond_to(:collection_name)
        expect(personaClass.collection_name).to eq("personas")
      end
    end

    it 'should retrieve instances that matches with specified criteria on "find"' do
      an_instance = test_instance {}
      an_instance.save
      results = an_instance.class.find({"_id" => an_instance._id})
      expect(results.size).to be(1)
      expect(an_instance._id).to eq(results.first._id)
    end
    it 'should retrieve instances that matches with dynamic find method: "find_by_id_and_name"' do
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
    it 'should execute "on_populate" on each obtained instance by "find" after populate it' do
      an_instance = test_class(:OnPopulate){
        on_populate {@populate_called=true}
      }.new
      an_instance.save
      res=OnPopulate.find()
      res.each do
        |obj| expect(obj.instance_variable_defined?(:@populate_called)).to be(true)
      end
    end
  end
  describe 'an instance of any class with MongoDocument' do
    it 'should return a hash representation on "to_hash"' do
      a_class=test_class() {
        field :name, String
        field :age, Integer
      }
      p=a_class.new
      p.name = "pepe"
      p.age = 25
      expect(p.to_hash).to eq({"_id" => nil, "name" => "pepe", "age" => 25})
    end
    it 'should be persisted on "save"' do
      an_inst=test_instance
      before = an_inst.class.count
      an_inst.save
      after = an_inst.class.count

      expect(after).to be(before+1)
    end
    it 'should be removed from db on "remove"' do
      an_instance=test_instance
      an_instance.save
      before = an_instance.class.count
      an_instance.remove
      after = an_instance.class.count

      expect(after).to be(before-1)
    end
    it 'should execute "before_save" before persist to db' do
      an_instance=test_class(:BeforeSave) {}.new
      class BeforeSave
        def before_save
          raise Exception
        end
      end
      old_count = BeforeSave.count
      expect { an_instance.save }.to raise_error(Exception)
      new_count = BeforeSave.count
      expect(new_count).to eq(old_count)
    end
    it 'should execute "after_save" after persist to db' do
      an_instance=test_class(:AfterSave) {}.new
      class AfterSave
        def after_save
          @after = true
        end
      end
      expect(an_instance.instance_variable_defined?(:@after)).to be(false)
      old_count = AfterSave.count
      an_instance.save
      new_count = AfterSave.count
      expect(new_count).to eq(old_count+1)
      expect(an_instance.instance_variable_get(:@after)).to be(true)
    end
  end

  after :each do
    MongoDB.client.database.collections.each { |c| c.drop }
  end
end


