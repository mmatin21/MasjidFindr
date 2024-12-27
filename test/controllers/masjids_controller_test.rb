require "test_helper"

class MasjidsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get masjids_index_url
    assert_response :success
  end
end
