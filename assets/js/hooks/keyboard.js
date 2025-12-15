export const Hooks = {
  KeyboardEvents: {
    mounted() {
      // Focus and move cursor to end (like FocusEnd hook)
      this.el.focus();
      const len = this.el.value.length;
      this.el.setSelectionRange(len, len);

      this.el.addEventListener("keydown", (e) => {
        const id = this.el.dataset.itemId;
        const value = this.el.value;

        if (e.key === "Enter") {
          e.preventDefault();

          this.pushEvent("edit_keydown", {
            key: e.key,
            shiftKey: e.shiftKey,
            id: id,
            value: value
          });
        } else if (e.key === "Escape") {
          this.pushEvent("edit_keydown", {
            key: e.key,
            shiftKey: false,
            id: id,
            value: value
          });
        } else if (e.key === "Backspace" && (e.metaKey || e.ctrlKey) && value.trim() === "") {
          // CMD+Backspace (Mac) or CTRL+Backspace (Windows) on empty item = delete
          e.preventDefault();
          this.pushEvent("delete_empty_item", { id: id });
        }
      });
    }
  },

  MainInputKeyboard: {
    mounted() {
      const input = this.el.querySelector("input");
      if (!input) return;

      input.addEventListener("keydown", (e) => {
        if (e.key === "Enter" && e.shiftKey) {
          e.preventDefault();

          this.pushEvent("main_input_keydown", {
            key: e.key,
            shiftKey: true,
            value: input.value
          });
        }
      });
    }
  }
};
