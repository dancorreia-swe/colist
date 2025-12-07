let Hooks = {};

Hooks.LocalStoreData = {
  mounted() {
    this.handleEvent("store", (obj) => this.store(obj));
    this.handleEvent("clear", (obj) => this.clear(obj));
    this.handleEvent("restore", (obj) => this.restore(obj));

    this.checkUserName();
  },

  store(obj) {
    localStorage.setItem(obj.key, obj.data);
  },

  restore(obj) {
    const data = localStorage.getItem(obj.key);
    this.pushEvent("restored", { key: obj.key, data: data });
  },

  clear(obj) {
    localStorage.removeItem(obj.key);
  },

  checkUserName() {
    const username = localStorage.getItem("username");

    if (username) {
      this.pushEvent("set_presence", { value: username });
      return;
    }

    name_modal.showModal();
  },
};

export { Hooks };
