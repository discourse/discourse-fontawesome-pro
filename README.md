# Install font awesome pro icons for Discourse

https://meta.discourse.org/t/fontawesome-pro-icons/150871

Use Font Awesome Pro icons for Discourse - This allows you to register and use any font awesome pro icons for your site, given a font awesome package token.

After you install the plugin, turn on the `fontawesome_pro_icons_enabled` site setting and enter the package token from your Font Awesome account in the `fontawesome_auth_token` site setting. Discourse then downloads the Pro icons in the background and stores them in the database. You can also set the token with the `DISCOURSE_FONTAWESOME_AUTH_TOKEN` environment variable, which takes the place of the setting.

Each version of the plugin uses one specific version of Font Awesome Pro. When an update to the plugin changes that version, Discourse downloads the new icons while it runs the database migrations. If that fails, it tries again every day.

Discourse also checks the token every day. The admin dashboard shows a warning when a download fails or when Font Awesome rejects the token.

If your `app.yml` has an `after_code` hook that runs `scripts/install.sh`, you can remove it. The `DISCOURSE_FONTAWESOME_AUTH_TOKEN` environment variable keeps working.
