require Logger

defmodule ParserTest do
  use ExUnit.Case
  doctest ExoSQL.Parser
  @moduletag :capture_log

  @context %{
    "A" => {ExoSQL.Csv, path: "test/data/csv/"}
  }

  test "Lex and parse" do
    {:ok, res, _} =
      :sql_lexer.string(
        ~c"SELECT A.products.name, A.products.stock FROM A.products WHERE (A.products.price > 0) and (a.products.stock >= 1)"
      )

    Logger.debug("Lexed: #{inspect(res)}")

    {:ok, res} =
      :sql_parser.parse(res)
      |> dbg()

    Logger.debug("Parsed: #{inspect(res)}")
  end

  describe "update statements" do
    test "single col" do
      {:ok, lexed, _} =
        :sql_lexer.string(~c"""
        UPDATE TINVPAR SET col1 = 5
        """)

      {:ok,
       %{
         update: {{:table, {nil, "TINVPAR"}}, [assign: {{nil, nil, "col1"}, {:lit, 5}}]}
       }} =
        :sql_parser.parse(lexed)
    end

    test "multi col" do
      {:ok, lexed, _} =
        :sql_lexer.string(~c"""
        UPDATE TINVPAR SET col1 = 5, col2 = 'foo'
        """)

      {:ok,
       %{
         update:
           {{:table, {nil, "TINVPAR"}},
            [
              assign: {{nil, nil, "col1"}, {:lit, 5}},
              assign: {{nil, nil, "col2"}, {:lit, "foo"}}
            ]}
       }} =
        :sql_parser.parse(lexed)
    end

    test "where clause" do
      {:ok, lexed, _} =
        :sql_lexer.string(~c"""
        UPDATE TINVPAR SET col1 = 5, col2 = 'foo'
        WHERE col3 = 'potato'
        """)

      {:ok,
       %{
         update:
           {{:table, {nil, "TINVPAR"}},
            [
              assign: {{nil, nil, "col1"}, {:lit, 5}},
              assign: {{nil, nil, "col2"}, {:lit, "foo"}}
            ]}
       }} =
        :sql_parser.parse(lexed)
        |> dbg()
    end
  end

  test "Elixir parsing to proper struct" do
    {:ok, res} =
      ExoSQL.Parser.parse(
        "SELECT A.products.name, A.products.stock FROM A.products WHERE (A.products.price > 0) and (A.products.stock >= 1)",
        @context
      )

    Logger.debug("Parsed: #{inspect(res)}")
  end
end
