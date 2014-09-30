require File.dirname(__FILE__) + '/../test_helper'
require 'schema_controller'

# Re-raise errors caught by the controller.
class SchemaController; def rescue_action(e) raise e end; end

class SchemaControllerTest < Test::Unit::TestCase
  def setup
    @controller = SchemaController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
