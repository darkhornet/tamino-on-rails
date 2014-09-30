# = ActiveTamino
#
# ActiveTamino enables developers to access Tamino data in a pseudo object-oriented way.
# By using class and instance methods of the ActiveTamino::Base class developers can
# create, find, update and delete objects which represent data in a Tamino XML data store.
# 
# ActiveTamino depends on the Ruby Tamino API which is distributed with this package.
# It has to be loaded, e.g. using <tt>require 'tamino_api.rb'</tt>. This can be done
# in <tt>config/environment.rb</tt>. Please see the Tamino API documentation as well.
# 
# <em>Note: ActiveTamino was tested using Edge Rails on revision 6236.
# If you experience problems, try to switch back to this revision by issuing</em>
#  rake rails:freeze:edge REVISION=6236
# <em>on the command line in the Rails project.</em>
# 
# ==Example
# <em>Note: the Tamino schema which this example is bases upon can be found in <tt>doc/examples/schema.myAddresses.utf-8.tsd</tt>.</em>
#  
# Define a Ruby class which inherits from ActiveTamino::Base like so:
#  class Person < ActiveTamino::Base 
#    self.doctype = "person"
#    self.collection = "people"
#    self.credentials = {:host => "localhost", 
#                        :port => 80,
#                        :database => "welcome_4_4_1",
#                        :username => "john.doe",
#                        :password => "secret"
#                       }
#  end
#  
#  
# Create a <tt>person</tt> object and set some data
#  
#  john = Person.create :name => {
#      :firstName => "John",
#      :lastName => "Doe"},
#    :address => {
#      :city => "San Francisco",
#      :street => {
#        :name => "14th Street",
#        :number => 718
#      }   
#  }
# 
# You will see the corresponding XML as a new node in Tamino. Now, let's change some data!
# 
#  john.address.city = "New York"
#  john.address.street.name = "5th Ave"
#  john.address.street.number = 725
#  
# The changes won't be reflected in Tamino directly. You will need to call the <tt>save!</tt>
# method to update the object in the Tamino database.
# 
#  john.save!
#  
# To remove the entry, you could call the object's <tt>destroy</tt> method.
# 
#  john.destroy
#  
# ==Installation
# 
# ActiveTamino can be used in other Ruby on Rails projects by following these steps.
# 1. Set up the Tamino API in your new project as described in the Tamino API documentation.
# 2. Copy <tt>vendor/plugins/active_tamino</tt> to your new project.
#
# == License
# Copyright 2007 Software AG, Authored by: Jan Schulz-Hofen
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module ActiveTamino
  
  class Base
    
    # Class stuff from here
    class << self
      
      attr_accessor :collection #:nodoc:
      attr_accessor :credentials #:nodoc:
      attr_accessor :doctype #:nodoc:
      
      
      # Discovers object(s) in the Tamino database.
      # 
      # The first argument can either be one of the following:
      # 
      # <tt>:all</tt>:: finds all matching entries and returns an Array of objects representing them
      # <tt>:first</tt>:: finds the first matching entry and returns an object representing it
      # a primary key value:: finds an entry by its primary key value (denoted as <tt>ino:id</tt> attribute)
      # 
      # When used with <tt>:all</tt> or <tt>:first</tt>, <tt>:condition</tt> as second argument will 
      # limit results. It has to be an X-Query passed as a string value.
      # 
      # Example:
      # 
      #  Person.find(:all, :condition => "name/firstName=\"John\"") # finds all Johns
      #  Person.find(42) # find element with an ino:id attribute value of 42
      #  
      def find(*arguments)
        scope   = arguments.slice!(0)
        options = arguments.slice!(0) || {}
        
        case scope
        when :all   then find_every(options)
        when :first then find_every(options).first
        else             find_single(scope, options)
        end
      end
      
      # Creates a new record.
      # 
      # Example:
      # 
      #  john = Person.create :name => {
      #      :firstName => "John",
      #      :lastName => "Doe"},
      #    :address => {
      #      :city => "San Francisco",
      #      :street => {
      #        :name => "14th Street",
      #        :number => 718
      #      }   
      #  }
      #  
      def create(attributes = {}, prefix_options = {})
        returning(self.new(attributes, prefix_options)) { |res| res.save }        
      end
      
      # Deletes record whose <tt>ino:id</tt> attribute equals +id+.
      def delete(id)
        connection.delete("/#{@doctype}[@ino:id=#{id}]")
      end
      
      # Evalutes to <tt>true</tt> if the resource is found.
      def exists?(id, options = {})
        id && !find_single(id, options).nil?
      rescue ActiveResource::ResourceNotFound
        false
      end
      
      # Sets the connection parameters and instanciates a new Tamino API object if
      # no connection parameters have been given to that class before or if the +refresh+ parameter is set to +true+.
      def connection(refresh = false)
        @connection = TAMINO if @credentials.nil? && @connection.nil?
        @connection = TaminoApi.new(@credentials[:host], @credentials[:port], @credentials[:database], @credentials[:username], @credentials[:password]) if refresh || @connection.nil?
        @connection.setHttpRequestMethod("POST")
        @connection.setCollection(@collection)
        @connection
      end     
      private
      
      # Finds every resource.
      def find_every(options)
        
        query = "/#{@doctype}"
        query << "[#{options[:condition]}]" if options[:condition]
        
        if result = connection.query(query)
          connection.getResultDomNode
          if xml = connection.getResultDomNode 
            result = REXML::XPath.first(xml, "//a:result", {"a" => "http://metalab.unc.edu/xql/"}).children
            
            result.collect do |elem|
              new(Hash.from_xml(elem.to_s).values.first)
            end
          else
            []
          end
        else
          raise "Query failed."
        end
      end
      
      # Finds a single resource.
      def find_single(scope, options)
        query = "/#{@doctype}[@ino:id=#{scope}]" 
        
        if result = connection.query(query)
          connection.getResultDomNode
          xml = connection.getResultDomNode
          if (result = REXML::XPath.first(xml, "//a:result", {"a" => "http://metalab.unc.edu/xql/"}) rescue false)
            new(Hash.from_xml(result.children.first.to_s).values.first)
          else
            nil
          end
        else
          raise "Query failed."
        end
      end
      
      
      
      
      def from_xml_data(data)
        case data
        when Hash
          if data.keys.size == 1
            case data.values.first
            when Hash  then [ from_xml_data(data.values.first) ]
            when Array then from_xml_data(data.values.first)
            else       data
            end
          else
            data.each_key { |key| data[key] = from_xml_data(data[key]) }
            data
          end
        when Array then data.collect { |val| from_xml_data(val) }
        else data
        end
      end
      
      
    end
    # Instance stuff from here
    
    
    attr_accessor :attributes #:nodoc:
    
    def initialize(attributes = {}, prefix_options = {})
      @attributes = {}
      self.load attributes
      @prefix_options = prefix_options
    end
    
    # Loads an attribute hash and creates object structure accordingly.
    def load(attributes)
      raise ArgumentError, "expected an attributes Hash, got #{attributes.inspect}" unless attributes.is_a?(Hash)
      attributes.each do |key, value|
        @attributes[key.to_s] =
        case value
        when Array
          resource = find_or_create_resource_for_collection(key)
          value.map { |attrs| resource.new(attrs) }
        when Hash
          resource = find_or_create_resource_for(key)
          resource.new(value)
        when ActiveTamino::Base
          value.class.new(value.attributes, value.prefix_options)
        else
          value.dup rescue value
        end
      end
      self
    end
    
    # Returns +true+ if the record has just been created and is not yet saved to Tamino.
    def new?
      id.nil?
    end
    
    # Delegates to <tt>new?</tt>.
    def new_record?
      new?
    end
    
    # Returns the object's +id+, i.e. the element's <tt>ino:id</tt> attribute value.
    def id
      attributes["ino:id"].nil? ? nil : attributes["ino:id"].to_i
    end
    
    # Sets the object's +id+, i.e. the element's <tt>ino:id</tt> attribute value.
    def id=(id)
      attributes["ino:id"]=id.to_s
    end
    
    # True if and only if +other+ is the same object or is an instance of the same class, is not <tt>new?</tt>, and has the same +id+.
    def ==(other)
      other.equal?(self) || (other.instance_of?(self.class) && !other.new? && other.id == id)
    end
    
    # Delegates to ==
    def eql?(other)
      self == other
    end
    
    # Deletes the resource.
    def destroy
      self.class.delete id
    end
    
    # Delegates to id in order to allow two resources of the same type and id to work with something like:
    #   [Person.find(1), Person.find(2)] & [Person.find(1), Person.find(4)] # => [Person.find(1)]
    def hash
      id.hash
    end
    
    # Stores the local representation in the Tamino database. Will simply return +false+ if an error occured during save.
    def save
      new? ? create : update
    end
    
    
    
    # Stores the local representation in the Tamino database. Will throw an exception if an error occured during save.    
    def save!
      throw "Update of Tamino XML database failed." unless save
    end
    
    
    
    # Evaluates to <tt>true</tt> if this resource is found.
    def exists?
      !new? && self.class.exists?(id, prefix_options)
    end
    
    # Returns an XML representation.
    def to_xml(options={})
      a = attributes.clone
      a.delete("ino:id")
      a.to_xml({:root => self.class.doctype}.merge(options))
    end
    
    # Reloads the record from Tamino and updates the object.
    def reload
      self.load self.class.find(id, @prefix_options).attributes
    end
    
    def method_missing(method_symbol, *arguments) #:nodoc:
      method_name = method_symbol.to_s
      
      case method_name.last
      when "="
        attributes[method_name.first(-1)] = arguments.first
      when "?"
        attributes[method_name.first(-1)] == true
      else
        attributes.has_key?(method_name) ? attributes[method_name] : super
      end
    end
    
    protected
    def connection(refresh = false)
      self.class.connection(refresh)
    end
    
    def update
      updates = {}
      root = REXML::Document.new(to_xml({:skip_instruct => true})).root
      REXML::XPath.match(root, "//text()").each do |e| 
        updates[e.parent.xpath] =  e.to_s unless e.to_s.gsub(/\W/, '').empty?
      end
      
      query =  "declare namespace tf = \"http://namespaces.softwareag.com/tamino/TaminoFunction\" "
      query << "update for $q in input()/#{self.class.doctype} "
      
      updates.each_key do |xpath|
        var = xpath.gsub(/\//, '_')
        rel_path = xpath[self.class.doctype.length+1..xpath.length]
        query << "let $#{var} := $q#{rel_path}/text() "
      end
      
      query << "where tf:getInoId($q) = #{id} do ( "
      
      updates.each do |xpath, value|
        query << "replace $#{xpath.gsub(/\//, '_')} with tf:createTextNode(\"#{value}\") "      
      end
      
      query << ")"
      
      
      return self.class.connection.xquery(query)
      
      
    end
    
    def create
      self.class.connection.process(to_xml(:skip_instruct => true, :skip_types => true))
      result = self.class.connection.getFullResultHeader
      attributes["ino:id"] = result["x-ino-id"].first.to_i
      
      self
    end
    
    private
    
    # Tries to find a resource for a given collection name; if it fails, then the resource is created
    def find_or_create_resource_for_collection(name)
      find_or_create_resource_for(name.to_s.singularize)
    end
    
    # Tries to find a resource for a given name; if it fails, then the resource is created
    def find_or_create_resource_for(name)
      resource_name = name.to_s.camelize
      resource_name.constantize
    rescue NameError
      resource = self.class.const_set(resource_name, Class.new(ActiveTamino::Base))
      resource.collection = self.class.collection
      resource.credentials   = self.class.credentials
      resource.doctype   = self.class.doctype
      resource
    end
  end
end