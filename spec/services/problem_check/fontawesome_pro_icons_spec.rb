# frozen_string_literal: true

RSpec.describe ProblemCheck::FontawesomeProIcons do
  subject(:check) { described_class.new }

  let(:solid_sprite) do
    '<svg xmlns="http://www.w3.org/2000/svg"><symbol id="heart" viewBox="0 0 512 512"><path d="M1"/></symbol></svg>'
  end

  before do
    enable_current_plugin
    SiteSetting.fontawesome_auth_token = "package-token"
  end

  after { DiscourseFontawesomePro::Icons.cache.clear }

  def fail_download(message)
    DiscourseFontawesomePro::Package
      .any_instance
      .stubs(:with_sprites)
      .raises(DiscourseFontawesomePro::Package::Error, message)

    expect { DiscourseFontawesomePro::Icons.fetch }.to raise_error(
      DiscourseFontawesomePro::Package::Error,
    )
  end

  it "reports the error of the last failed download" do
    fail_download("checksum mismatch")

    expect(check).to have_a_problem.with_priority("high")
    expect(check.call.message).to include("can't be downloaded: checksum mismatch")
  end

  it "points to the environment variable when it holds the token" do
    SiteSetting.shadowed_settings << :fontawesome_auth_token
    fail_download("checksum mismatch")

    expect(check.call.message).to include("DISCOURSE_FONTAWESOME_AUTH_TOKEN environment variable")
  ensure
    SiteSetting.shadowed_settings.delete(:fontawesome_auth_token)
  end

  it "reports a missing package token" do
    SiteSetting.fontawesome_auth_token = ""

    expect(check).to have_a_problem.with_priority("high")
    expect(check.call.message).to include("Enter the {{setting:fontawesome_auth_token}}")
  end

  it "is chill about it once the pinned icons are stored" do
    fail_download("checksum mismatch")
    DiscourseFontawesomePro::Package
      .any_instance
      .stubs(:with_sprites)
      .yields("solid" => solid_sprite)
    DiscourseFontawesomePro::Icons.fetch

    expect(DiscourseFontawesomePro::Icons.fetch_error).to be_nil
    expect(check).to be_chill_about_it
  end

  it "reports a rejected token while the pinned icons are stored" do
    DiscourseFontawesomePro::Icons.store!(
      DiscourseFontawesomePro::Package::VERSION,
      "solid" => solid_sprite,
    )
    DiscourseFontawesomePro::Package.any_instance.stubs(:token_accepted?).returns(false)
    DiscourseFontawesomePro::Icons.check_token

    expect(check).to have_a_problem.with_priority("high")
    expect(check.call.message).to include("Font Awesome rejected the package token")
  end

  it "is chill about a missing token once the pinned icons are stored" do
    DiscourseFontawesomePro::Icons.store!(
      DiscourseFontawesomePro::Package::VERSION,
      "solid" => solid_sprite,
    )
    SiteSetting.fontawesome_auth_token = ""

    expect(check).to be_chill_about_it
  end

  it "is chill about it while the first download hasn't finished" do
    expect(check).to be_chill_about_it
  end

  it "is chill about it when the plugin is disabled" do
    SiteSetting.fontawesome_auth_token = ""
    SiteSetting.fontawesome_pro_icons_enabled = false

    expect(check).to be_chill_about_it
  end
end
