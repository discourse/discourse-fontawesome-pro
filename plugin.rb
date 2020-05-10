# frozen_string_literal: true

# name: discourse-fontawesome-pro
# about: Install fontawesome pro icons for Discourse
# version: 0.1
# authors: Jeff Wong
# transpile_js: true

register_asset 'stylesheets/common/discourse-fontawesome-pro.scss'

after_initialize do
  prefix_mapping = { 'brands' => 'fab',
                     'light' => 'fal',
                     'regular' => 'far',
                     'duotone' => 'fad',
                     'solid' => 'fas' }
  sprite_source = "#{Rails.root}/plugins/discourse-fontawesome-pro/node_modules/@fortawesome/fontawesome-pro/sprites/"
  sprite_dest = "#{Rails.root}/plugins/discourse-fontawesome-pro/svg-icons/"
  prefix_mapping.each do |style, prefix|
    fsource = "#{sprite_source}/#{style}.svg"
    fname = "#{sprite_dest}/#{style}.svg"
    File.open(fsource) do |source_file|
      contents = source_file.read
      contents.gsub!(/<symbol id="(?<id>.*)"/, "<symbol id=\"#{prefix}-\\k<id>\"")
      File.open(fname, 'w+') { |f| f.write(contents) }
    end
  end
end
