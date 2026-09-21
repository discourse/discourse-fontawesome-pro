# frozen_string_literal: true

RSpec.describe RegisterIcons do
  describe ".icon_replacements" do
    let(:sprite_path) { Pathname.new(Dir.mktmpdir).join("solid.svg") }

    after { FileUtils.rm_rf(sprite_path.dirname) }

    it "returns the core icons that the Pro sprite provides" do
      sprite_path.write(<<~XML)
        <svg xmlns="http://www.w3.org/2000/svg" style="display: none;">
        <symbol id="user" viewBox="0 0 448 512"><path d="M1"/></symbol>
        <symbol id="heart" viewBox="0 0 512 512"><path d="M2"/></symbol>
        <symbol id="pro-only-icon" viewBox="0 0 512 512"><path d="M3"/></symbol>
        </svg>
      XML

      expect(described_class.icon_replacements(sprite_path.to_s)).to eq(%w[heart user])
    end

    it "includes icons registered by plugins that the Pro sprite provides" do
      original_icons = DiscoursePluginRegistry.svg_icons.dup
      DiscoursePluginRegistry.register_svg_icon "plugin-icon"
      sprite_path.write(<<~XML)
        <svg xmlns="http://www.w3.org/2000/svg" style="display: none;">
        <symbol id="plugin-icon" viewBox="0 0 512 512"><path d="M1"/></symbol>
        </svg>
      XML

      expect(described_class.icon_replacements(sprite_path.to_s)).to eq(%w[plugin-icon])
    ensure
      DiscoursePluginRegistry.svg_icons.replace(original_icons)
    end

    it "returns no icons when the Pro package isn't installed" do
      expect(described_class.icon_replacements(sprite_path.to_s)).to eq([])
    end
  end
end
