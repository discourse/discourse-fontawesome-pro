import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import { iconReplacements } from "discourse/plugins/discourse-fontawesome-pro/lib/icon-replacements";

module("Fontawesome Pro | Unit | Lib | icon-replacements", function (hooks) {
  setupTest(hooks);

  test("prefixes provided icons with the chosen family and style", function (assert) {
    const options = { proIcons: ["heart", "user"], coreReplacements: {} };

    assert.deepEqual(
      iconReplacements({ ...options, family: "classic", style: "light" }),
      { heart: "fal-heart", user: "fal-user" },
      "classic icons use the style prefix only"
    );

    assert.deepEqual(
      iconReplacements({ ...options, family: "sharp", style: "thin" }),
      { heart: "fash-fat-heart", user: "fash-fat-user" },
      "other families prefix the family before the style"
    );
  });

  test("restyles core's named icons whose base icon is provided", function (assert) {
    const replacements = iconReplacements({
      proIcons: ["heart"],
      coreReplacements: {
        "d-liked": "heart",
        "d-unliked": "far-heart",
        "d-muted": "discourse-bell-slash",
      },
      family: "classic",
      style: "light",
    });

    assert.deepEqual(
      replacements,
      { heart: "fal-heart", "d-liked": "fal-heart", "d-unliked": "fal-heart" },
      "named icons without a Pro counterpart keep their core icon"
    );
  });

  test("replaces nothing for the classic solid style", function (assert) {
    const replacements = iconReplacements({
      proIcons: ["heart"],
      coreReplacements: { "d-liked": "heart" },
      family: "classic",
      style: "solid",
    });

    assert.deepEqual(replacements, {}, "core's solid icons are used as-is");
  });
});
