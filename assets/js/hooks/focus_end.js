export const Hooks = {
  FocusEnd: {
    mounted() {
      const el = this.el;
      el.focus();
      // Move cursor to end
      const len = el.value.length;
      el.setSelectionRange(len, len);
    },
  },
};
