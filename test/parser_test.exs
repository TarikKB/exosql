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
        WHERE col3 = 'potato' and col4 = 'tomato'
        """)

      {:ok,
       %{
         update:
           {{:table, {nil, "TINVPAR"}},
            [
              assign: {{nil, nil, "col1"}, {:lit, 5}},
              assign: {{nil, nil, "col2"}, {:lit, "foo"}}
            ]},
         where:
           {:op,
            {"AND", {:op, {"=", {:column, {nil, nil, "col3"}}, {:lit, "potato"}}},
             {:op, {"=", {:column, {nil, nil, "col4"}}, {:lit, "tomato"}}}}}
       }} =
        :sql_parser.parse(lexed)
        |> dbg()
    end

    test "sub query" do
      {:ok, lexed, _} =
        :sql_lexer.string(~c"""
        UPDATE TINVPAR SET col1 = ( SELECT col4 FROM TINCNTL WHERE TINCNTL.col1 > 1 ), col2 = 'foo'
        WHERE col3 = 'potato'
        """)

      {:ok,
       %{
         update:
           {{:table, {nil, "TINVPAR"}},
            [
              assign:
                {{nil, nil, "col1"},
                 {:select,
                  %{
                    offset: nil,
                    select: {[column: {nil, nil, "col4"}], []},
                    join: [],
                    with: [],
                    where: {:op, {">", {:column, {nil, "TINCNTL", "col1"}}, {:lit, 1}}},
                    union: nil,
                    limit: nil,
                    from: [table: {nil, "TINCNTL"}],
                    groupby: nil,
                    orderby: []
                  }}},
              assign: {{nil, nil, "col2"}, {:lit, "foo"}}
            ]},
         where: {:op, {"=", {:column, {nil, nil, "col3"}}, {:lit, "potato"}}}
       }} =
        :sql_parser.parse(lexed)
        |> dbg()
    end

    test "complex update" do
      {:ok, lexed, _} =
        :sql_lexer.string(~c"""
          UPDATE TINVPAR
            SET
              CHG_ID_NBR = 'INKUP105',
              CHG_TMST = '00:00:00',
              ACTL_INV_DTE = '2024-07-25',
              SHTG_ACTL_INV_DTE = ( SELECT
                                MIN( '2024-07-25', TINCNTL.OPN_FSCL_MN_DTE )
                                FROM
                                  TINCNTL
                                WHERE
                                  TINCNTL.INV_ID = TINVPAR.INV_ID),
              LOC_DEL_RSN_TXT = COALESCE(LOC_DEL_RSN_TXT, ' ')
        """)

      {:ok,
       %{
         update:
           {{:table, {nil, "TINVPAR"}},
            [
              assign: {{nil, nil, "CHG_ID_NBR"}, {:lit, "INKUP105"}},
              assign: {{nil, nil, "CHG_TMST"}, {:lit, "00:00:00"}},
              assign: {{nil, nil, "ACTL_INV_DTE"}, {:lit, "2024-07-25"}},
              assign:
                {{nil, nil, "SHTG_ACTL_INV_DTE"},
                 {:select,
                  %{
                    offset: nil,
                    select:
                      {[
                         fn:
                           {"min",
                            [lit: "2024-07-25", column: {nil, "TINCNTL", "OPN_FSCL_MN_DTE"}]}
                       ], []},
                    join: [],
                    with: [],
                    union: nil,
                    where:
                      {:op,
                       {"=", {:column, {nil, "TINCNTL", "INV_ID"}},
                        {:column, {nil, "TINVPAR", "INV_ID"}}}},
                    limit: nil,
                    from: [table: {nil, "TINCNTL"}],
                    groupby: nil,
                    orderby: []
                  }}},
              assign:
                {{nil, nil, "LOC_DEL_RSN_TXT"},
                 {:fn, {"coalesce", [column: {nil, nil, "LOC_DEL_RSN_TXT"}, lit: " "]}}}
            ]},
         where: nil
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
