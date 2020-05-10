# frozen_string_literal: true

# name: discourse-fontawesome-pro
# about: Install fontawesome pro icons for Discourse
# version: 0.1
# authors: Jeff Wong
# transpile_js: true
# namespace_svg: true

register_svg_icon 'fal-search' if respond_to?(:register_svg_icon)
register_svg_icon 'fal-bars' if respond_to?(:register_svg_icon)

after_initialize do
end
