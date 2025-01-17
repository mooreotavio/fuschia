defmodule Fuschia.ModuloPesquisa.Models.PesquisadorModel do
  @moduledoc """
  Pesquisador Schema
  """

  use Fuschia.Schema
  import Ecto.Changeset

  alias Fuschia.Accounts.Models.UserModel
  alias Fuschia.ModuloPesquisa.Models.{CampusModel, MidiaModel, PesquisadorModel, RelatorioModel}
  alias Fuschia.Types.{CapitalizedString, TrimmedString}

  @required_fields ~w(
    minibiografia
    tipo_bolsa
    link_lattes
    campus_nome
  )a

  @optional_fields ~w(orientador_cpf)a

  @tipos_bolsa ~w(ic pesquisa voluntario)

  @primary_key {:usuario_cpf, TrimmedString, autogenerate: false}
  schema "pesquisador" do
    field :id, :string
    field :minibiografia, TrimmedString
    field :tipo_bolsa, TrimmedString
    field :link_lattes, TrimmedString

    has_many :orientandos, PesquisadorModel, foreign_key: :orientador_cpf

    has_many :midias, MidiaModel, foreign_key: :pesquisador_cpf

    has_many :relatorios, RelatorioModel, foreign_key: :pesquisador_cpf

    belongs_to :usuario, UserModel,
      references: :cpf,
      foreign_key: :usuario_cpf,
      type: TrimmedString,
      primary_key: true,
      define_field: false,
      on_replace: :update

    belongs_to :campus, CampusModel,
      foreign_key: :campus_nome,
      references: :nome,
      type: CapitalizedString

    belongs_to :orientador, PesquisadorModel,
      references: :usuario_cpf,
      foreign_key: :orientador_cpf,
      type: TrimmedString,
      on_replace: :update

    timestamps()
  end

  @doc false
  @spec changeset(%__MODULE__{}, map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:minibiografia, max: 280)
    |> validate_inclusion(:tipo_bolsa, @tipos_bolsa)
    |> cast_assoc(:usuario, required: true, with: &UserModel.registration_changeset/2)
    |> foreign_key_constraint(:orientador_cpf)
    |> foreign_key_constraint(:campus_nome)
    |> put_change(:id, Nanoid.generate())
  end

  @spec update_changeset(%__MODULE__{}, map) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required([:minibiografia, :link_lattes, :campus_nome])
    |> validate_length(:minibiografia, max: 280)
    |> validate_inclusion(:tipo_bolsa, @tipos_bolsa)
    |> put_assoc(:usuario, attrs["usuario"])
    |> foreign_key_constraint(:orientador_cpf)
    |> foreign_key_constraint(:campus_nome)
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    alias Fuschia.ModuloPesquisa.Adapters.PesquisadorAdapter

    @spec encode(Pesquisador.t(), map) :: map
    def encode(struct, opts) do
      struct
      |> PesquisadorAdapter.to_map()
      |> Fuschia.Encoder.encode(opts)
    end
  end
end
