let Hooks = {};

Hooks.KeepFocus = {
  mounted() {
    this.el.addEventListener("submit", (e) => {
      e.preventDefault();
      const input = this.el.querySelector("input[type=text]");
      const formData = new FormData(this.el);
      const params = Object.fromEntries(formData.entries());

      this.pushEvent("save", { item: params }, () => {
        if (input) {
          input.value = "";
          input.focus();
        }
      });
    });
  }
};

Hooks.LocalStoreData = {
  mounted() {
    this.handleEvent("store", (obj) => this.store(obj));
    this.handleEvent("clear", (obj) => this.clear(obj));
    this.handleEvent("restore", (obj) => this.restore(obj));

    this.initClientId();
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

  initClientId() {
    let clientId = localStorage.getItem("client_id");

    if (!clientId) {
      clientId = crypto.randomUUID();
      localStorage.setItem("client_id", clientId);
    }

    this.pushEvent("set_client_id", { client_id: clientId });
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
