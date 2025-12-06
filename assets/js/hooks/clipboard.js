/**
 * @type {import("phoenix_live_view").HooksOptions}
 */
let Hooks = {};

Hooks.CopyUrl = {
  mounted() {
    this.el.addEventListener("click", (ev) => {
      ev.preventDefault();

      const url = window.location.href;
      navigator.clipboard.writeText(url);

      this.pushEvent("copied_url");
    });
  },
};

export { Hooks };
