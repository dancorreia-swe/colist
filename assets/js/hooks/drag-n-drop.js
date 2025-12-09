import Sortable from "sortablejs";

let Hooks = {};

Hooks.DragNDrop = {
  mounted() {
    this.sortable = new Sortable(this.el, {
      animation: 250,
      easing: "cubic-bezier(0.25, 1, 0.5, 1)",
      ghostClass: "opacity-50",
      handle: ".drag-handle",
      direction: "vertical",
      dataIdAttr: "id",

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
        const ids = this.sortable
          .toArray()
          .filter((id) => id !== "items-empty")
          .map((id) => id.replace("items-", ""));
        this.pushEvent("reorder", { ids });
      },
    });

    // Listen for server-triggered reorder
    this.handleEvent("reorder_items", ({ ids }) => {
      console.log("reorder_items received:", ids);
      const currentOrder = this.sortable.toArray();
      console.log("current order:", currentOrder);
      const newOrder = ids.map((id) => `items-${id}`);
      console.log("new order:", newOrder);

      // Use SortableJS's sort method which animates the reorder
      this.sortable.sort(newOrder, true);
    });
  },

  destroyed() {
    this.sortable.destroy();
  },
};

export { Hooks };
