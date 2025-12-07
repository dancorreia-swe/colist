import Sortable from "sortablejs";

let Hooks = {};

Hooks.DragNDrop = {
  mounted() {
    this.sortable = new Sortable(this.el, {
      animation: 150,
      ghostClass: "opacity-50",
      handle: ".drag-handle",
      // Mobile/touch support
      forceFallback: true,
      fallbackClass: "opacity-50",
      delay: 150,
      delayOnTouchOnly: true,
      touchStartThreshold: 5,
      onEnd: () => {
        const ids = Array.from(this.el.children)
          .map((el) => el.id.replace("items-", ""))
          .filter((id) => id !== "empty");
        this.pushEvent("reorder", { ids });
      },
    });
  },

  destroyed() {
    this.sortable.destroy();
  },
};

export { Hooks };
