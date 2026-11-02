# frozen_string_literal: true

require "rubygems/package"

RSpec.describe Jobs::DiscourseFontawesomePro::FetchIcons do
  let(:version) { DiscourseFontawesomePro::Package::VERSION }
  let(:tarball_url) { DiscourseFontawesomePro::Package::TARBALL_URL }
  let(:download_url) { "https://dl.fontawesome.com/signed/fontawesome-pro.tgz" }
  let(:solid_sprite) do
    '<svg xmlns="http://www.w3.org/2000/svg"><symbol id="heart" viewBox="0 0 512 512"><path d="M1"/></symbol></svg>'
  end
  let(:symlinks) { {} }
  let(:tarball) do
    files = {
      "package/sprites/solid.svg" => solid_sprite,
      "package/sprites-full/solid.svg" => solid_sprite,
      "package/css/all.css" => "",
    }
    tar = StringIO.new
    Gem::Package::TarWriter.new(tar) do |writer|
      files.each do |path, content|
        writer.add_file_simple(path, 0o644, content.bytesize) { |file| file.write(content) }
      end
      symlinks.each { |path, target| writer.add_symlink(path, target, 0o777) }
    end
    Zlib.gzip(tar.string)
  end

  around do |example|
    integrity = "sha512-#{Digest::SHA512.base64digest(tarball)}"
    stub_const(DiscourseFontawesomePro::Package, :INTEGRITY, integrity) { example.run }
  end

  before do
    enable_current_plugin
    SiteSetting.fontawesome_auth_token = "package-token"

    stub_request(:get, tarball_url).with(
      headers: {
        "Authorization" => "Bearer package-token",
      },
    ).to_return(status: 307, headers: { "Location" => download_url })
    stub_request(:get, download_url).to_return(status: 200, body: tarball)
    stub_request(:head, tarball_url).with(
      headers: {
        "Authorization" => "Bearer package-token",
      },
    ).to_return(status: 307, headers: { "Location" => download_url })
  end

  def record_error(message)
    PluginStore.set(
      DiscourseFontawesomePro::PLUGIN_NAME,
      DiscourseFontawesomePro::Icons::FETCH_ERROR_KEY,
      message,
    )
  end

  after { DiscourseFontawesomePro::Icons.cache.clear }

  describe "#execute" do
    it "replaces the stored icons with the pinned version" do
      DiscourseFontawesomePro::Icons.store!("7.0.0", "solid" => solid_sprite.sub("heart", "user"))

      described_class.new.execute({})

      expect(DiscourseFontawesomePro::Icon.pluck(:name, :version)).to contain_exactly(
        ["fas-heart", version],
      )
    end

    it "skips the download when the pinned version is already stored" do
      DiscourseFontawesomePro::Icons.store!(version, "solid" => solid_sprite)

      described_class.new.execute({})

      expect(WebMock).not_to have_requested(:get, tarball_url)
    end

    it "keeps the stored icons when the package fails its integrity check" do
      stub_request(:get, download_url).to_return(status: 200, body: Zlib.gzip("tampered"))
      DiscourseFontawesomePro::Icons.store!("7.0.0", "solid" => solid_sprite)

      expect { described_class.new.execute({}) }.to raise_error(
        DiscourseFontawesomePro::Package::Error,
      )
      expect(DiscourseFontawesomePro::Icon.pluck(:version)).to eq(["7.0.0"])
    end

    context "when a sprite is a symlink" do
      let(:symlinks) { { "package/sprites/light.svg" => "/etc/passwd" } }

      it "stores only the regular sprite files" do
        described_class.new.execute({})

        expect(DiscourseFontawesomePro::Icon.pluck(:name)).to contain_exactly("fas-heart")
      end
    end

    it "rejects a sprite that is too large" do
      stub_const(DiscourseFontawesomePro::Package, :MAX_SPRITE_SIZE, 10) do
        expect { described_class.new.execute({}) }.to raise_error(
          DiscourseFontawesomePro::Package::Error,
          /too large/,
        )
      end
    end

    it "raises when Font Awesome rejects the package token" do
      stub_request(:get, tarball_url).to_return(status: 401)

      expect { described_class.new.execute({}) }.to raise_error(
        DiscourseFontawesomePro::Package::Error,
        "Font Awesome rejected the package token",
      )
    end

    context "when the pinned version is already stored" do
      before { DiscourseFontawesomePro::Icons.store!(version, "solid" => solid_sprite) }

      it "records a rejected token without downloading the package" do
        stub_request(:head, tarball_url).to_return(status: 401)

        described_class.new.execute({})

        expect(DiscourseFontawesomePro::Icons.fetch_error).to eq(
          "Font Awesome rejected the package token",
        )
        expect(WebMock).not_to have_requested(:get, tarball_url)
      end

      it "clears the recorded error once Font Awesome accepts the token" do
        record_error("Font Awesome rejected the package token")

        described_class.new.execute({})

        expect(DiscourseFontawesomePro::Icons.fetch_error).to be_nil
      end

      it "keeps the recorded error when Font Awesome can't check the token" do
        record_error("Font Awesome rejected the package token")
        stub_request(:head, tarball_url).to_return(status: 503)

        expect { described_class.new.execute({}) }.to raise_error(
          DiscourseFontawesomePro::Package::Error,
          /503/,
        )
        expect(DiscourseFontawesomePro::Icons.fetch_error).to eq(
          "Font Awesome rejected the package token",
        )
      end
    end

    it "does nothing without a package token" do
      SiteSetting.fontawesome_auth_token = ""

      described_class.new.execute({})

      expect(WebMock).not_to have_requested(:get, tarball_url)
      expect(WebMock).not_to have_requested(:head, tarball_url)
    end
  end

  it "is enqueued when the package token changes" do
    expect_enqueued_with(job: described_class) do
      SiteSetting.fontawesome_auth_token = "another-token"
    end
  end
end
