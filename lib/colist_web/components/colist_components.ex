defmodule ColistWeb.ColistComponents do
  @moduledoc """
  UI components specific to the Colist application.
  """
  use Phoenix.Component
  use Gettext, backend: ColistWeb.Gettext

  import ColistWeb.CoreComponents

  @doc """
  Generates a deterministic HSL color from an ID.
  Used for user avatars and item creator indicators.
  """
  def hsl_color(nil), do: nil

  def hsl_color(id) do
    hue = :erlang.phash2(id, 360)
    "hsl(#{hue}, 70%, 60%)"
  end

  attr :list, :map, required: true
  attr :presence_count, :integer, required: true
  attr :current_user, :string

  def list_header(assigns) do
    ~H"""
    <header
      class="flex items-center justify-between gap-6 pb-4"
      phx-hook="LocalStoreData"
      id="list-header"
    >
      <input
        type="text"
        name="title"
        value={@list.title}
        phx-blur="update_title"
        phx-keydown="update_title"
        phx-key="Enter"
        class="text-lg font-semibold leading-8 bg-transparent border-none outline-none w-full focus:bg-base-200 focus:px-2 focus:-mx-2 rounded transition-all"
        placeholder={gettext("Untitled")}
      />
      <div class="flex-none flex items-center gap-2">
        <button
          class="btn btn-ghost btn-sm gap-1"
          onclick="presences_modal.showModal()"
        >
          <.icon name="hero-users" class="size-4" />
          <span class="badge badge-sm">{@presence_count}</span>
        </button>
        <.button phx-hook="CopyUrl" id="copy-url-btn">
          <.icon name="hero-link" />
        </.button>
      </div>
    </header>
    """
  end

  attr :presences, :list, required: true
  attr :current_user, :string

  def presences_modal(assigns) do
    ~H"""
    <dialog id="presences_modal" class="modal">
      <div class="modal-box">
        <form method="dialog">
          <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">
            <.icon name="hero-x-mark" class="size-4" />
          </button>
        </form>
        <h3 class="text-lg font-bold mb-4">{gettext("Who's here")}</h3>
        <ul id="presences-list" phx-update="stream" class="space-y-2">
          <li
            :for={{id, presence} <- @presences}
            id={id}
            class="flex items-center gap-2"
          >
            <span
              class="w-3 h-3 rounded-full"
              style={"background-color: #{presence.color || "oklch(0.872 0.01 258.338)"}"}
            >
            </span>
            <span>{presence.user.name}</span>
            <span :if={presence.id == @current_user} class="badge badge-xs">{gettext("you")}</span>
            <button
              :if={presence.id == @current_user}
              class="btn btn-ghost btn-xs"
              onclick="presences_modal.close(); name_modal.showModal();"
            >
              <.icon name="hero-pencil-square" class="size-3" />
            </button>
          </li>
        </ul>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button class="cursor-pointer" onclick="document.getElementById('presences_modal').close()">
          {gettext("close")}
        </button>
      </form>
    </dialog>
    """
  end

  attr :current_user, :string

  def name_modal(assigns) do
    ~H"""
    <dialog id="name_modal" class="modal">
      <div class="modal-box">
        <form method="dialog">
          <button
            id="close-name-modal"
            class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
          >
            <.icon name="hero-x-mark" class="size-4" />
          </button>
        </form>
        <h3 class="text-lg font-bold">{gettext("Hello!")}</h3>
        <p class="py-4">{gettext("Enter your name:")}</p>

        <form phx-submit={
          Phoenix.LiveView.JS.push("set_presence")
          |> Phoenix.LiveView.JS.dispatch("click", to: "#close-name-modal")
        }>
          <input
            id="name-input"
            name="value"
            type="text"
            value={@current_user}
            placeholder={gettext("Enter your name")}
            class="input input-bordered w-full"
          />
          <div class="modal-action">
            <button
              type="submit"
              class="btn btn-primary"
              phx-disable-with={gettext("Joining...")}
            >
              {gettext("Set Name")}
            </button>
          </div>
        </form>
      </div>
    </dialog>
    """
  end

  attr :completed_items, :integer, required: true
  attr :total_items, :integer, required: true

  def list_stats(assigns) do
    ~H"""
    <div class="flex items-center justify-between text-sm text-base-content/60 mb-2">
      <span>
        {gettext("%{completed}/%{total} completed",
          completed: @completed_items,
          total: @total_items
        )}
      </span>
      <button
        :if={@completed_items > 0}
        phx-click="clear_completed"
        class="text-xs hover:text-error transition-colors"
      >
        {gettext("Clear completed")}
      </button>
    </div>
    """
  end

  attr :item, :map, required: true
  attr :item_id, :string, required: true
  attr :editing, :boolean, default: false

  def item_row(assigns) do
    assigns = assign(assigns, :color, hsl_color(assigns.item.creator_id))

    ~H"""
    <li
      class={["flex gap-2 py-2 px-4 sm:px-3 group", @item.completed && "opacity-50"]}
      id={@item_id}
    >
      <div class="flex items-center gap-2 shrink-0 h-6">
        <span class="drag-handle cursor-grab active:cursor-grabbing opacity-30 hover:opacity-100 touch-none p-2 -m-2 sm:p-0 sm:m-0">
          <.icon name="hero-bars-2" class="size-5 sm:size-4" />
        </span>
        <span
          class="w-2 h-2 rounded-full"
          style={"background-color: #{@color || "oklch(0.872 0.01 258.338)"}"}
        >
        </span>
        <input
          id={"complete-item-#{@item.id}"}
          type="checkbox"
          checked={@item.completed}
          phx-click={Phoenix.LiveView.JS.push("toggle_completion", value: %{id: @item.id})}
          class="checkbox checkbox-sm"
        />
      </div>
      <textarea
        :if={@editing}
        phx-blur="save_edit"
        phx-keydown="edit_keydown"
        phx-value-id={@item.id}
        phx-hook="FocusEnd"
        class="flex-1 bg-transparent border-none resize-none field-sizing-content focus:bg-base-200 focus:p-1 focus:-m-1 rounded outline-none transition-all"
        id={"edit-item-#{@item.id}"}
      >{@item.text}</textarea>
      <span
        :if={!@editing}
        class={["flex-1 cursor-text break-all", @item.completed && "line-through"]}
        phx-click={Phoenix.LiveView.JS.push("start_edit", value: %{id: @item.id})}
      >
        {@item.text}
      </span>
      <div class="shrink-0 h-6 flex items-center gap-1">
        <button
          class={[
            "btn btn-ghost btn-xs gap-1 min-h-6",
            @item.voted && "text-primary",
            !@item.voted && "opacity-50 hover:opacity-100"
          ]}
          phx-click={Phoenix.LiveView.JS.push("toggle_vote", value: %{id: @item.id})}
        >
          <.icon
            name={if @item.voted, do: "hero-chevron-up-solid", else: "hero-chevron-up"}
            class="size-4"
          />
          <span :if={@item.vote_count > 0} class="text-xs font-medium">{@item.vote_count}</span>
        </button>
        <div class="dropdown dropdown-end">
          <div
            tabindex="0"
            role="button"
            class="btn btn-ghost btn-xs btn-square min-h-6 opacity-0 group-hover:opacity-50 hover:!opacity-100"
          >
            <.icon name="hero-ellipsis-vertical" class="size-4" />
          </div>
          <ul
            tabindex="0"
            class="dropdown-content menu bg-base-200 rounded-box z-10 w-32 p-1 shadow-lg"
          >
            <li>
              <button
                class="text-error"
                phx-click={
                  Phoenix.LiveView.JS.push("delete", value: %{id: @item.id})
                  |> Phoenix.LiveView.JS.hide(to: "##{@item_id}")
                }
              >
                <.icon name="hero-trash" class="size-4" />
                {gettext("Delete")}
              </button>
            </li>
          </ul>
        </div>
      </div>
    </li>
    """
  end
end
