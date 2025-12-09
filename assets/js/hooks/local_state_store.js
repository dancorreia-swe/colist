let Hooks = {};

Hooks.LocalStoreData = {
  mounted() {
    this.handleEvent("store", (obj) => this.store(obj));
    this.handleEvent("clear", (obj) => this.clear(obj));
    this.handleEvent("restore", (obj) => this.restore(obj));
    this.handleEvent("focus", ({ id }) => {
      setTimeout(() => document.getElementById(id)?.focus(), 50);
    });
    // Wait for client_id to be acknowledged before checking username
    this.handleEvent("client_ready", () => this.checkUserName());

    this.initClientId();
  },

  reconnected() {
    // Re-establish client identity after socket reconnection (e.g., mobile app switch)
    this.initClientId();
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
