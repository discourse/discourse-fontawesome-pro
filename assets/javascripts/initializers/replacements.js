import { REPLACEMENTS } from "discourse/lib/icon-library";
import { withPluginApi } from "discourse/lib/plugin-api";
import { iconReplacements } from "discourse/plugins/discourse-fontawesome-pro/lib/icon-replacements";

export default {
  name: "replace-icons",

  initialize(owner) {
    const siteSettings = owner.lookup("service:site-settings");

    const replacements = iconReplacements({
      proIcons: owner.lookup("service:site").fontawesome_pro_icons ?? [],
      coreReplacements: REPLACEMENTS,
      family: siteSettings.fa_icon_family,
      style: siteSettings.fa_icon_style,
    });

    withPluginApi((api) => {
      Object.entries(replacements).forEach(([source, destination]) => {
        api.replaceIcon(source, destination);
      });
    });
  },
};
