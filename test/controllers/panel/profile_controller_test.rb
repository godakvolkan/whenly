require "test_helper"

class Panel::ProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "should get edit profile page" do
    get edit_panel_profile_path
    assert_response :success
    assert_includes response.body, "Profil ve Hesap Ayarları"
    assert_includes response.body, @user.slug
  end

  test "should update name and slug" do
    patch panel_profile_path, params: {
      user: {
        name: "Yeni Uzman Adi",
        slug: "yeni-doktor-slug"
      }
    }

    assert_redirected_to edit_panel_profile_path
    @user.reload
    assert_equal "Yeni Uzman Adi", @user.name
    assert_equal "yeni-doktor-slug", @user.slug
  end

  test "should update password" do
    patch panel_profile_path, params: {
      user: {
        password: "newsecretpassword123",
        password_confirmation: "newsecretpassword123"
      }
    }

    assert_redirected_to edit_panel_profile_path
    assert @user.reload.authenticate("newsecretpassword123")
  end
end
