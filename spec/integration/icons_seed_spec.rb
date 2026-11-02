# frozen_string_literal: true

RSpec.describe "Font Awesome Pro icons seed" do
  let(:solid_sprite) do
    '<svg xmlns="http://www.w3.org/2000/svg"><symbol id="heart" viewBox="0 0 512 512"><path d="M1"/></symbol></svg>'
  end

  before do
    enable_current_plugin
    SiteSetting.fontawesome_auth_token = "package-token"
  end

  after { DiscourseFontawesomePro::Icons.cache.clear }

  # SeedFu runs each fixture inside a transaction.
  def run_seed
    ActiveRecord::Base.transaction do
      load File.expand_path("../../db/fixtures/001_fontawesome_pro_icons.rb", __dir__) # rubocop:disable Discourse/Plugins/UseRequireRelative
    end
  end

  it "downloads the pinned icons" do
    DiscourseFontawesomePro::Package
      .any_instance
      .stubs(:with_sprites)
      .yields("solid" => solid_sprite)

    output = capture_stdout { run_seed }

    expect(output).to include("Downloaded Font Awesome Pro")
    expect(DiscourseFontawesomePro::Icon.pluck(:name, :version)).to contain_exactly(
      ["fas-heart", DiscourseFontawesomePro::Package::VERSION],
    )
  end

  it "warns instead of failing the migration when the download fails" do
    DiscourseFontawesomePro::Package
      .any_instance
      .stubs(:with_sprites)
      .raises(DiscourseFontawesomePro::Package::Error, "checksum mismatch")

    output = capture_stderr { run_seed }

    expect(output).to include("couldn't be downloaded: checksum mismatch")
    expect(DiscourseFontawesomePro::Icon.count).to eq(0)
  end

  it "keeps the stored icons when the new ones can't be stored" do
    DiscourseFontawesomePro::Icons.store!("7.0.0", "solid" => solid_sprite)
    DiscourseFontawesomePro::Package
      .any_instance
      .stubs(:with_sprites)
      .yields("unknown-style" => solid_sprite)

    capture_stderr { run_seed }

    expect(DiscourseFontawesomePro::Icon.pluck(:version)).to eq(["7.0.0"])
  end
end
