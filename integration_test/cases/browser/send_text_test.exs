defmodule Wallaby.Integration.Browser.SendTextTest do
  use Wallaby.Integration.SessionCase, async: true

  setup %{session: session} do
    page = visit(session, "forms.html")
    {:ok, %{page: page}}
  end

  describe "send_keys/3" do
    test "accepts a query", %{page: page} do
      page
      |> send_keys(Query.text_field("Name"), ["Chris", :tab, "c@keathley.io"])

      assert page
      |> find(Query.text_field("Name"))
      |> has_value?("Chris")

      assert page
      |> find(Query.text_field("email"))
      |> has_value?("c@keathley.io")
    end
  end

  describe "send_keys/2" do
    test "allows text to be sent", %{page: page} do
      page
      |> find(Query.text_field("email"))
      |> send_keys("Example text")
      |> has_value?("Example text")
    end

    test "allows to send text to the active element", %{page: page} do
      page
      |> click(Query.text_field("Name"))
      |> send_keys(["Chris", :tab, "c@keathley.io"])

      assert page
      |> find(Query.text_field("Name"))
      |> has_value?("Chris")

      assert page
      |> find(Query.text_field("email"))
      |> has_value?("c@keathley.io")
    end
  end
end
