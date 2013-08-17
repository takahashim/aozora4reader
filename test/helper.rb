require 'rubygems'
require 'test/unit'


$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'aozora4reader'

class Test::Unit::TestCase

  def self.context(name, &block)
    @context = name
    block.call
  end

  def self.should(name, &block)
    test_name = "test_#{@context.gsub(/\s+/,'_')}_#{name.gsub(/\s+/,'_')}".to_sym
    defined = instance_method(test_name) rescue false
    raise "#{test_name} is already defined in #{self}" if defined
    define_method(test_name, &block)
  end

end
