import Sortable from "sortablejs";

let Hooks = {};

Hooks.DragNDrop = {
  mounted() {
    this.sortable = new Sortable(this.el, {
      animation: 150,
      ghostClass: "opacity-50",
      handle: ".drag-handle",
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
