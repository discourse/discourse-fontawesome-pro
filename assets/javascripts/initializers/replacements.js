import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "replace-icons",
  initialize() {
    withPluginApi("0.8.14", api => {
      console.log(Discourse.SiteSettings.fa_icon_style);
      let style = Discourse.SiteSettings.fa_icon_style;
      if (style == "regular") {
        return;
      }
      let prefixMap = { solid: "fas", light: "fal", duotone: "fad" };
      let prefix = prefixMap[style];
      console.log(prefix);
      ["bars", "search"].forEach(icon => {
        api.replaceIcon(`${icon}`, `${prefix}-${icon}`);
      });
    });
  }
};
