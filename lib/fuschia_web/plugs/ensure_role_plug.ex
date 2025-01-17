defmodule FuschiaWeb.EnsureRolePlug do
  @moduledoc """
  Esse plug certifica que um susuário possui um perfil antes de
  acessar uma rota.

  ## Example

  plug FuschiaWeb.EnsureRolePlug, :admin
  """

  import FuschiaWeb.Gettext
  import Plug.Conn

  alias Fuschia.Accounts
  alias Fuschia.Accounts.Models.UserModel
  alias FuschiaWeb.UserAuth
  alias Phoenix.Controller

  def init(config), do: config

  def call(conn, roles) do
    user_token = get_session(conn, :user_token)

    (user_token &&
       Accounts.get_user_by_session_token(user_token))
    |> has_role?(roles)
    |> maybe_halt(conn)
  end

  defp has_role?(%UserModel{} = user, roles) when is_list(roles),
    do: Enum.any?(roles, &has_role?(user, &1))

  # Essa cláusula só será exectada quando o ambos
  # os argumentos com alias `role` tiverem o mesmo valor
  defp has_role?(%UserModel{role: role}, role), do: true
  defp has_role?(_user, _role), do: false

  defp maybe_halt(true, conn), do: conn

  defp maybe_halt(_any, conn) do
    conn
    |> Controller.put_flash(:error, dgettext("errors", "Unauthorized"))
    |> Controller.redirect(to: UserAuth.signed_in_path(conn))
    |> halt()
  end
end
