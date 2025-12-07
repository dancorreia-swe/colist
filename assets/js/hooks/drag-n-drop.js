import Sortable from "sortablejs";

let Hooks = {};

Hooks.DragNDrop = {
  mounted() {
    this.sortable = new Sortable(this.el, {
      animation: 100,
      ghostClass: "opacity-50",
      handle: ".drag-handle",
      direction: "vertical",

      forceFallback: true,
      fallbackClass: "opacity-50",
      fallbackTolerance: 3,
      fallbackOnBody: true,
      delay: 120,
      delayOnTouchOnly: true,
      touchStartThreshold: 3,

      swapThreshold: 0.5,
      invertSwap: true,
      invertedSwapThreshold: 0.5,

      dragoverBubble: false,

      scroll: true,
      bubbleScroll: true,
      scrollSensitivity: 80,
      scrollSpeed: 12,

      onEnd: (evt) => {
        evt.stopPropagation();
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
