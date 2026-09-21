const STYLE_PREFIXES = {
  regular: "far",
  solid: "fas",
  light: "fal",
  thin: "fat",
};

const FAMILY_PREFIXES = {
  classic: null,
  sharp: "fash",
  duotone: "fad",
  "sharp-duotone": "fashd",
};

/**
 * Maps icon ids to their Pro equivalent in the chosen family and style.
 *
 * @param {object} options
 * @param {string[]} options.proIcons - Core icons the installed Pro package provides
 * @param {Object<string, string>} options.coreReplacements - Core's named icons, e.g. `d-liked` → `heart`
 * @param {string} options.family - Value of the `fa_icon_family` setting
 * @param {string} options.style - Value of the `fa_icon_style` setting
 * @returns {Object<string, string>} Source icon id → Pro icon id
 */
export function iconReplacements({
  proIcons,
  coreReplacements,
  family,
  style,
}) {
  if (family === "classic" && style === "solid") {
    return {};
  }

  const familyPrefix = FAMILY_PREFIXES[family];
  const prefix = familyPrefix
    ? `${familyPrefix}-${STYLE_PREFIXES[style]}`
    : STYLE_PREFIXES[style];
  const available = new Set(proIcons);
  const replacements = {};

  available.forEach((icon) => {
    replacements[icon] = `${prefix}-${icon}`;
  });

  Object.entries(coreReplacements).forEach(([source, destination]) => {
    // Named icons pointing at a regular variant use the chosen style instead
    const icon = destination.replace(/^far-/, "");

    if (available.has(icon)) {
      replacements[source] = `${prefix}-${icon}`;
    }
  });

  return replacements;
}
