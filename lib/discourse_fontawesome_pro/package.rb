# frozen_string_literal: true

require "rubygems/package"

module DiscourseFontawesomePro
  class Package
    class Error < StandardError
    end

    # Change both together. The integrity is the version's `dist.integrity` in the registry.
    VERSION = "7.1.0"
    INTEGRITY =
      "sha512-+UQYoUEJjsIpMFolIs/dBpy4j9L6QRrD041dL0zzHxdSXeEZqJ8EGzmW9Qsrb4bXePxOoa2vY/QSEre2flsJ3w=="

    TARBALL_URL =
      "https://npm.fontawesome.com/@fortawesome/fontawesome-pro/-/fontawesome-pro-#{VERSION}.tgz"
    MAX_TARBALL_SIZE = 500.megabytes
    SPRITE_PATH = %r{\Apackage/sprites/([a-z-]+)\.svg\z}
    MAX_SPRITE_SIZE = 20.megabytes
    TOKEN_REJECTED = "Font Awesome rejected the package token"
    REJECTED_STATUSES = %w[401 403]

    def initialize(token)
      @token = token.strip
    end

    def with_sprites
      tarball = download
      verify!(tarball)
      yield enum_for(:each_sprite, tarball.path)
    ensure
      tarball&.close!
    end

    def token_accepted?
      uri = URI(TARBALL_URL)
      response =
        FinalDestination::HTTP.start(
          uri.host,
          uri.port,
          use_ssl: true,
          open_timeout: 10,
          read_timeout: 10,
        ) { |http| http.head(uri.request_uri, authorization) }

      return false if REJECTED_STATUSES.include?(response.code)
      return true if response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)

      raise Error, "Font Awesome responded with status #{response.code}"
    end

    private

    def authorization
      { "Authorization" => "Bearer #{@token}" }
    end

    def download
      FileHelper.download(
        TARBALL_URL,
        max_file_size: MAX_TARBALL_SIZE,
        tmp_file_name: "fontawesome-pro",
        follow_redirect: true,
        read_timeout: 30,
        skip_rate_limit: true,
        extra_headers: authorization,
      ) || raise(Error, "The Font Awesome package couldn't be downloaded")
    rescue OpenURI::HTTPError => e
      raise if REJECTED_STATUSES.exclude?(e.io.status.first)
      raise Error, TOKEN_REJECTED
    end

    def verify!(tarball)
      if "sha512-#{Digest::SHA512.file(tarball.path).base64digest}" != INTEGRITY
        raise Error, "The Font Awesome package failed its integrity check"
      end
    end

    def each_sprite(path)
      Zlib::GzipReader.open(path) do |gzip|
        Gem::Package::TarReader
          .new(gzip)
          .each do |entry|
            name = entry.full_name[SPRITE_PATH, 1]
            next if !name || !entry.file?

            if entry.header.size > MAX_SPRITE_SIZE
              raise Error, "The Font Awesome package has a sprite that is too large"
            end

            yield name, entry.read.force_encoding(Encoding::UTF_8)
          end
      end
    end
  end
end
