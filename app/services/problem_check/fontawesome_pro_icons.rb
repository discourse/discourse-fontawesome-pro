# frozen_string_literal: true

class ProblemCheck::FontawesomeProIcons < ProblemCheck
  self.priority = "high"

  def call
    return no_problem if !SiteSetting.fontawesome_pro_icons_enabled

    if SiteSetting.fontawesome_auth_token.blank?
      if DiscourseFontawesomePro::Icons.version == DiscourseFontawesomePro::Package::VERSION
        return no_problem
      end
      return problem(override_key: "dashboard.problem.fontawesome_auth_token_missing")
    end

    error = DiscourseFontawesomePro::Icons.fetch_error
    return no_problem if error.blank?

    if SiteSetting.shadowed_settings.include?(:fontawesome_auth_token)
      problem(
        override_key: "dashboard.problem.fontawesome_pro_icons_env_token",
        override_data: {
          error:,
        },
      )
    else
      problem(override_data: { error: })
    end
  end
end
