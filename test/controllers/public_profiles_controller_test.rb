require "test_helper"

class PublicProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @event_type = event_types(:one)
  end

  test "show renders user profile and event types" do
    get public_profile_path(slug: @user.slug)
    assert_response :success
    assert_select "h1", text: @user.name
    assert_select "a", text: /Randevu Al/
  end

  test "show with unknown slug returns not found" do
    get public_profile_path(slug: "non-existent-user-slug")
    assert_response :not_found
    assert_select "h1", text: "Randevu Bulunamadı"
  end
end
