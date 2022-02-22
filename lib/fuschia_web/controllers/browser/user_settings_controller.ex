defmodule FuschiaWeb.UserSettingsController do
  use FuschiaWeb, :controller

  import FuschiaWeb.Gettext

  alias Fuschia.Accounts
  alias FuschiaWeb.UserAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "contato" => contact_params} = params
    user = conn.assigns.current_user

    case Accounts.apply_user_email(user, password, contact_params) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(
          applied_user,
          user.contato.email,
          &Routes.user_settings_url(conn, :confirm_email, user.id, &1)
        )

        conn
        |> put_flash(
          :info,
          dgettext(
            "infos",
            "A link to confirm your email change has been sent to the new address."
          )
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit, user.id))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, dgettext("infos", "Password updated successfully."))
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit, user.id))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    user = conn.assigns.current_user

    case Accounts.update_user_email(user, token) do
      :ok ->
        conn
        |> put_flash(:info, dgettext("infos", "Email changed successfully."))
        |> redirect(to: Routes.user_settings_path(conn, :edit, user.id))

      :error ->
        conn
        |> put_flash(
          :error,
          dgettext("errors", "Email change link is invalid or it has expired.")
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit, user.id))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end