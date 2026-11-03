# frozen_string_literal: true

module Jobs
  module DiscourseFontawesomePro
    class FetchIcons < ::Jobs::Scheduled
      every 1.day
      sidekiq_options retry: false

      def execute(args)
        icons = ::DiscourseFontawesomePro::Icons
        icons.check_token if !icons.fetch
      end
    end
  end
end
