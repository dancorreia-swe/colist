import Sortable from "sortablejs";

let Hooks = {};

const NEST_THRESHOLD = 40; // Pixels to drag right to trigger nesting

Hooks.DragNDrop = {
  mounted() {
    this.dragStartX = 0;
    this.currentOffsetX = 0;
    this.draggedItem = null;

    // Track mouse/touch position globally during drag
    this.onMouseMove = (e) => {
      if (!this.draggedItem) return;
      const currentX = e.clientX || e.touches?.[0]?.clientX || 0;

      // Set initial X on first move
      if (this.dragStartX === 0) {
        this.dragStartX = currentX;
        return;
      }

      this.currentOffsetX = currentX - this.dragStartX;
      const isCurrentlySubtask = !!this.draggedItem.dataset.parentId;

      // Visual feedback for nesting/unnesting
      if (this.currentOffsetX > NEST_THRESHOLD) {
        // Nesting: show indent + blue border
        this.draggedItem.style.paddingLeft = "2.5rem";
        this.draggedItem.style.borderLeft = "3px solid oklch(0.7 0.15 250)";
      } else if (this.currentOffsetX < -NEST_THRESHOLD && isCurrentlySubtask) {
        // Unnesting: remove indent, show green border to indicate promotion
        this.draggedItem.style.paddingLeft = "1rem";
        this.draggedItem.style.borderLeft = "3px solid oklch(0.7 0.15 150)";
      } else {
        // Reset to original state
        this.draggedItem.style.paddingLeft = "";
        this.draggedItem.style.borderLeft = "";
      }
    };

    this.sortable = new Sortable(this.el, {
      animation: 250,
      easing: "cubic-bezier(0.25, 1, 0.5, 1)",
      ghostClass: "opacity-50",
      handle: ".drag-handle",
      direction: "vertical",
      dataIdAttr: "id",

      forceFallback: true,
      fallbackClass: "sortable-fallback",
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

      onChoose: (evt) => {
        // Store the initial mouse X when drag is chosen (before it actually starts)
        this.draggedItem = evt.item;
        this.currentOffsetX = 0;
      },

      onStart: (evt) => {
        this.dragStartX = 0; // Reset - will be set on first mouse move
        // Add global listeners to track mouse position
        document.addEventListener("mousemove", this.onMouseMove);
        document.addEventListener("touchmove", this.onMouseMove, { passive: true });
      },

      onEnd: (evt) => {
        evt.stopPropagation();

        // Remove global listeners
        document.removeEventListener("mousemove", this.onMouseMove);
        document.removeEventListener("touchmove", this.onMouseMove);

        const items = this.el.querySelectorAll("li[id^='items-']:not(#items-empty)");
        const result = [];

        items.forEach((item, index) => {
          const id = item.id.replace("items-", "");
          const currentParentId = item.dataset.parentId || null;
          const isDraggedItem = item === this.draggedItem;

          let parentId = null;

          if (isDraggedItem) {
            // The dragged item - check if it should be nested
            if (this.currentOffsetX > NEST_THRESHOLD && index > 0) {
              // Find the item above to nest under
              const itemAbove = items[index - 1];
              const itemAboveParentId = itemAbove?.dataset.parentId || null;

              if (itemAboveParentId) {
                // Item above is a subtask - nest under the same parent
                parentId = itemAboveParentId;
              } else {
                // Item above is a parent - nest under it
                parentId = itemAbove.id.replace("items-", "");
              }
              console.log("Nesting under:", parentId, "offset:", this.currentOffsetX);
            } else if (this.currentOffsetX < -NEST_THRESHOLD && currentParentId) {
              // Dragged left while being a subtask - unnest
              parentId = null;
              console.log("Unnesting, offset:", this.currentOffsetX);
            } else {
              // Keep existing nesting
              parentId = currentParentId;
            }
          } else {
            parentId = currentParentId;
          }

          result.push({ id, parent_id: parentId });
        });

        // Reset visual state
        if (this.draggedItem) {
          this.draggedItem.style.paddingLeft = "";
          this.draggedItem.style.borderLeft = "";
        }
        this.draggedItem = null;
        this.currentOffsetX = 0;

        this.pushEvent("reorder", { items: result });
      },
    });

    // Listen for server-triggered reorder
    this.handleEvent("reorder_items", ({ ids }) => {
      const newOrder = ids.map((id) => `items-${id}`);
      this.sortable.sort(newOrder, true);
    });
  },

  destroyed() {
    document.removeEventListener("mousemove", this.onMouseMove);
    document.removeEventListener("touchmove", this.onMouseMove);
    this.sortable.destroy();
  },
};

export { Hooks };
