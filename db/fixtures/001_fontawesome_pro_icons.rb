# frozen_string_literal: true

begin
  if DiscourseFontawesomePro::Icons.fetch
    puts "Downloaded Font Awesome Pro #{DiscourseFontawesomePro::Package::VERSION} icons"
  end
rescue => e
  warn "Font Awesome Pro icons couldn't be downloaded: #{e.message}"
end
