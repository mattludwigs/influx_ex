defmodule InfluxEx.ConflictError do
  @moduledoc """
  Exception for when an entity already exists in the database
  """

  @type t() :: %__MODULE__{}

  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule InfluxEx.InvalidPayloadError do
  @type t() :: %__MODULE__{}

  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule InfluxEx.GenericError do
  @moduledoc """
  Generic Error
  """

  @type t() :: %__MODULE__{}

  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule InfluxEx.NotFoundError do
  @moduledoc """
  Error for when the resource is not found
  """

  @type t() :: %__MODULE__{}

  defexception [:message]

  def exception(resource_name) do
    message = "the resource #{resource_name} is not found"
    %__MODULE__{message: message}
  end
end
