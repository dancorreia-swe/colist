import Sortable from "sortablejs";

let Hooks = {};

Hooks.DragNDrop = {
  mounted() {
    this.sortable = new Sortable(this.el, {
      animation: 150,
      ghostClass: "opacity-50",
      handle: ".drag-handle",
      direction: "vertical",

      // Mobile/touch support
      forceFallback: true,
      fallbackClass: "opacity-50",
      fallbackTolerance: 3,
      fallbackOnBody: true,
      delay: 150,
      delayOnTouchOnly: true,
      touchStartThreshold: 3,

      // Swap thresholds - critical for smooth mobile dragging
      // Lower swapThreshold means items swap sooner (easier to drag past multiple items)
      swapThreshold: 0.65,
      // invertSwap allows dragging over multiple items smoothly
      invertSwap: true,
      invertedSwapThreshold: 0.65,

      // Prevent dragover from bubbling to parent sortables
      dragoverBubble: false,

      // Scrolling support
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
