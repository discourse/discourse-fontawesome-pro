# frozen_string_literal: true

RSpec.describe DiscourseFontawesomePro::Icons do
  before { enable_current_plugin }
  after { described_class.cache.clear }

  def stored_icons = DiscourseFontawesomePro::Icon.pluck(:name)

  def sprite(*icons)
    symbols =
      icons.map { |icon| %(<symbol id="#{icon}" viewBox="0 0 512 512"><path d="M1"/></symbol>) }
    %(<svg xmlns="http://www.w3.org/2000/svg" style="display: none;">#{symbols.join}</svg>)
  end

  describe ".store!" do
    it "stores each icon under the prefix of its family and style" do
      described_class.store!(
        "7.3.1",
        "solid" => sprite("dragon"),
        "sharp-light" => sprite("dragon"),
        "duotone" => sprite("dragon"),
        "unknown-style" => sprite("dragon"),
      )

      expect(stored_icons).to contain_exactly("fas-dragon", "fash-fal-dragon", "fad-fas-dragon")
    end

    it "replaces the icons of the previous version" do
      described_class.store!("7.1.0", "solid" => sprite("heart"), "light" => sprite("heart"))
      described_class.store!("7.3.1", "solid" => sprite("user"))

      expect(described_class.version).to eq("7.3.1")
      expect(stored_icons).to contain_exactly("fas-user")
    end

    it "keeps the stored icons when none of the sprites has a known style" do
      described_class.store!("7.1.0", "solid" => sprite("heart"))

      expect { described_class.store!("7.3.1", "unknown-style" => sprite("user")) }.to raise_error(
        ArgumentError,
      )
      expect(stored_icons).to contain_exactly("fas-heart")
    end

    it "makes the stored icons available to the SVG sprite" do
      SiteSetting.fa_icon_style = "light"
      described_class.store!(
        "7.3.1",
        "light" => sprite("heart", "dragon"),
        "solid" => sprite("heart"),
      )

      expect(SvgSprite.bundle).to include('id="fal-heart"')
      expect(SvgSprite.bundle).not_to include('id="fal-dragon"')
      expect(SvgSprite.search("fal-dragon")).to include('id="fal-dragon"')
    end

    it "refreshes the site data cached for anonymous users" do
      Site.json_for(Guardian.new)

      described_class.store!("7.3.1", "solid" => sprite("heart"))

      expect(JSON.parse(Site.json_for(Guardian.new))["fontawesome_pro_icons"]).to eq(%w[heart])
    end
  end

  describe ".sprite_icons" do
    before { described_class.store!("7.3.1", "solid" => sprite("heart", "user")) }

    it "returns the replaceable icons in the chosen family and style" do
      SiteSetting.fa_icon_family = "sharp-duotone"
      SiteSetting.fa_icon_style = "thin"

      expect(described_class.sprite_icons).to contain_exactly("fashd-fat-heart", "fashd-fat-user")
    end

    it "uses only the style prefix for the classic family" do
      SiteSetting.fa_icon_family = "classic"
      SiteSetting.fa_icon_style = "light"

      expect(described_class.sprite_icons).to contain_exactly("fal-heart", "fal-user")
    end

    it "is empty for classic solid, where the browser replaces nothing" do
      SiteSetting.fa_icon_family = "classic"
      SiteSetting.fa_icon_style = "solid"

      expect(described_class.sprite_icons).to eq([])
    end

    it "switches the SVG sprite to a newly chosen style" do
      described_class.store!("7.3.1", "solid" => sprite("heart"), "light" => sprite("heart"))
      SiteSetting.fa_icon_style = "regular"

      expect(SvgSprite.bundle).not_to include('id="fal-heart"')

      SiteSetting.fa_icon_style = "light"

      expect(SvgSprite.bundle).to include('id="fal-heart"')
    end
  end

  describe ".symbols" do
    it "returns the markup of the requested icons that are stored" do
      described_class.store!("7.3.1", "light" => sprite("heart", "dragon"))

      symbols = described_class.symbols(%w[fal-heart fal-missing])

      expect(symbols.keys).to eq(%w[fal-heart])
      expect(symbols["fal-heart"]).to include('<symbol id="fal-heart"')
    end
  end

  describe ".search_icon_ids" do
    before do
      described_class.store!("7.3.1", "light" => sprite("arrows", "arrow-up", "arrow_down", "user"))
    end

    it "returns matching icons in byte order" do
      expect(described_class.search_icon_ids("ARROW", limit: 10)).to eq(
        %w[fal-arrow-up fal-arrow_down fal-arrows],
      )
    end

    it "treats the keyword as plain text" do
      expect(described_class.search_icon_ids("w_", limit: 10)).to eq(%w[fal-arrow_down])
    end

    it "returns every icon up to the limit when the keyword is blank" do
      expect(described_class.search_icon_ids("", limit: 2)).to eq(%w[fal-arrow-up fal-arrow_down])
    end
  end

  describe ".replaceable" do
    it "returns the core icons that the stored solid icons provide" do
      described_class.store!("7.3.1", "solid" => sprite("user", "heart", "pro-only-icon"))

      expect(described_class.replaceable).to eq(%w[heart user])
    end

    it "includes icons registered by plugins that the stored solid icons provide" do
      original_icons = DiscoursePluginRegistry.svg_icons.dup
      DiscoursePluginRegistry.register_svg_icon "plugin-icon"
      described_class.store!("7.3.1", "solid" => sprite("plugin-icon"))

      expect(described_class.replaceable).to eq(%w[plugin-icon])
    ensure
      DiscoursePluginRegistry.svg_icons.replace(original_icons)
    end

    it "is empty when no icons are stored" do
      expect(described_class.replaceable).to eq([])
    end
  end
end
