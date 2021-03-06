defmodule Modbus.Packet do
  @moduledoc """
  Handle Modbus packet creation and parsing.
  """

  # Function Codes
  @read_coils                       0x01
  @read_discrete_inputs             0x02
  @read_holding_registers           0x03
  @read_holding_registers_exception 0x83
  @read_input_registers             0x04

  # Exception codes
  exception_codes = [
    {0x01, :illegal_function},
    {0x02, :illegal_data_address},
    {0x03, :illegal_data_value},
    {0x04, :slave_device_failure},
    {0x05, :acknowledge},
    {0x06, :slave_device_busy},
    {0x07, :negative_acknowledge},
    {0x08, :memory_parity_error},
    {0x0a, :gateway_path_unavailable},
    {0x0b, :gateway_target_device_failed_to_respond}
    ]
  for {code, atom} <- exception_codes do
    defp exception_code(unquote(code)), do: unquote(atom)
  end
  defp exception_code(_unknown), do: :unknown_exception_code

  defmacrop read_multiple(function_code, starting_address, count) do
    quote do
      <<unquote(function_code), (unquote(starting_address))::size(16)-big, unquote(count)::size(16)-big>>
    end
  end

  @doc """
  Read status from a contiguous range of coils.
  `starting_address` is 0-indexed.
  """
  def read_coils(starting_address, count) do
    read_multiple(@read_coils, starting_address, count)
  end

  @doc """
  Read status from a contiguous range of discrete inputs.
  `starting_address` is 0-indexed.
  """
  def read_discrete_inputs(starting_address, count) do
    read_multiple(@read_discrete_inputs, starting_address, count)
  end

  @doc """
  Read the contents of a contiguous block of holding registers.
  `starting_address` is 0-indexed.
  """
  def read_holding_registers(starting_address, count) do
    read_multiple(@read_holding_registers, starting_address, count)
  end

  @doc """
  Read the contents of a contiguous block of input registers.
  `start_address` is 0-indexed.
  """
  def read_input_registers(starting_address, count) do
    read_multiple(@read_input_registers, starting_address, count)
  end

  @doc """
  Parse a ModbusTCP response packet
  """
  def parse_response_packet(<<@read_holding_registers, _byte_count, data::binary>>) do
    value_list = for <<value::size(16)-big <- data>>, do: value
    {:ok, {:read_holding_registers, value_list}}
  end
  def parse_response_packet(<<@read_holding_registers_exception, exception>>) do
    {:ok, {:read_holding_registers_exception, exception_code(exception)}}
  end
  def parse_response_packet(packet = <<function_code, _byte_count, _data::binary>>) do
    {:error, "Unknown function code #{function_code}, pkt = #{inspect packet}"}
  end

end

