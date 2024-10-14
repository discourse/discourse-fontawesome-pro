# Install font awesome pro icons for Discourse

https://meta.discourse.org/t/fontawesome-pro-icons/150871

Use Font Awesome Pro icons for Discourse - This allows you to register and use any font awesome pro icons for your site, given a font awesome auth token.

This requires a few extra step to enable:

First, you will need to set up an additional env var containing your font awesome pro license key: `DISCOURSE_FONTAWESOME_AUTH_TOKEN`

`pnpm install` also needs to be called during initialization, as an additional "after_code" hook. This downloads and adds the fontawesome pro SVGs on build.

Here is an example install in `app.yml`:

```
env:
  DISCOURSE_FONTAWESOME_AUTH_TOKEN: 123456
  
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/discourse/discourse-fontawesome-pro.git
    - exec:
        cd: $home/plugins/discourse-fontawesome-pro
        cmd:
          - $home/plugins/discourse-fontawesome-pro/scripts/install.sh
```
