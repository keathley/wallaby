defmodule Wallaby.Integration.QueryTest do
  use Wallaby.Integration.SessionCase, async: true

  test "the driver can execute queries", %{session: session} do
    elements =
      session
      |> Browser.visit("/")
      |> Browser.find(Query.css("#child"))

    assert elements != "Failure"
  end

  test "disregards elements that don't match all filters", %{session: session} do
    elements =
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(Query.css(".conflicting", count: 2, text: "Visible", visible: true))

    assert Enum.count(elements) == 2
  end

  describe "filtering queries by visibility" do
    test "finds elements that are invisible", %{session: session} do
      assert_raise Wallaby.QueryError, fn ->
        session
        |> Browser.visit("/page_1.html")
        |> Browser.find(Query.css(".invisible-elements", count: 3))
      end

      elements =
        session
        |> Browser.visit("/page_1.html")
        |> Browser.find(Query.css(".invisible-elements", count: 3, visible: false))

      assert Enum.count(elements) == 3
    end

    test "doesn't error if the count is 'any' and some elements are visible", %{session: session} do
      element =
        session
        |> Browser.visit("/page_1.html")
        |> Browser.find(Query.css("#same-selectors-with-different-visibilities"))
        |> Browser.find(Query.css("span", text: "Visible", count: :any))

      assert Enum.count(element) == 2
    end
  end

  test "queries can check the number of elements", %{session: session} do
    assert_raise Wallaby.QueryError, fn ->
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(Query.css(".user"))
    end

    elements =
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(Query.css(".user", count: 5))

    assert Enum.count(elements) == 5
  end

  test "queries can select one element from a list", %{session: session} do
    element =
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(Query.css(".user", count: 5, at: 1))

    assert Element.text(element) == "Grace H."
  end

  test "queries can not select an element off the start of the list", %{session: session} do
    assert_raise Wallaby.QueryError, fn ->
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(Query.css(".user", count: 5, at: -1))
    end
  end

  test "queries can not select an element off the end of the list", %{session: session} do
    assert_raise Wallaby.QueryError, fn ->
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(Query.css(".user", count: 5, at: 5))
    end
  end

  test "queries can specify element text", %{session: session} do
    assert_raise Wallaby.QueryError, fn ->
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(Query.css(".user", text: "Some fake text"))
    end

    element =
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(Query.css(".user", text: "Chris K."))

    assert element
  end

  test "trying to set a text when visible is false throws an error", %{session: session} do
    assert_raise Wallaby.QueryError, fn ->
      session
      |> Browser.find(Query.css(".some-css", text: "test", visible: false))
    end
  end

  test "queries can be retried", %{session: session} do
    element =
      session
      |> Browser.visit("/wait.html")
      |> Browser.find(Query.css(".main"))

    assert element

    elements =
      session
      |> Browser.find(Query.css(".orange", count: 5))

    assert Enum.count(elements) == 5
  end

  test "queries can find an element by only text", %{session: session} do
    element =
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(Query.text("Chris K."))

    assert element
  end

  test "queries can find an element by only value", %{session: session} do
    element =
      session
      |> Browser.visit("/forms.html")
      |> Browser.find(Query.value("an-input-value"))

    assert element
  end

  test "queries can find an element by its attribute and value pair", %{session: session} do
    element =
      session
      |> Browser.visit("/page_1.html")
      |> Browser.find(Query.attribute("an-attribute", "an-attribute-value"))

    assert element
  end

  test "all returns an empty list if nothing is found", %{session: session} do
    elements =
      session
      |> Browser.visit("/page_1.html")
      |> Browser.all(Query.css(".not_there"))

    assert Enum.count(elements) == 0
  end
end
