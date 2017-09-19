defmodule Wallaby.HTTPClient do

  @type method :: :post | :get | :delete
  @type url :: String.t
  @type params :: map | String.t
  @type request_opts :: {:encode_json, boolean}
  
  @status_obscured 13

  @doc """
  Sends a request to the webdriver API and parses the
  response.
  """
  @spec request(method, url, params, [request_opts]) :: {:ok, any}
                                                      | {:error, :invalid_selector}
                                                      | {:error, :stale_reference}
                                                      | {:error, :httpoison}

  def request(method, url, params \\ %{}, opts \\ [])
  def request(method, url, params, _opts) when map_size(params) == 0 do
    make_request(method, url, "")
  end
  def request(method, url, params, [{:encode_json, false} | _]) do
    make_request(method, url, params)
  end
  def request(method, url, params, [{:max_try, max} | _]) do
    make_request(method, url, params, {0, max})
  end
  def request(method, url, params, _opts) do
    make_request(method, url, Poison.encode!(params))
  end

  defp make_request(method, url, body, _ \\ {0, 5})
  defp make_request(_, _, _, {m, m}), do: raise "Wallaby had an internal issue with HTTPoison; all #{m} tries failed."
  defp make_request(method, url, body, {retry_count, max}) do
    HTTPoison.request(method, url, body, headers(), request_opts())
    |> handle_response
    |> case do
         {:error, :httpoison} ->
           :timer.sleep(500 * (retry_count + 1))
           make_request(method, url, body, {retry_count + 1, max})
         result ->
           result
    end
  end

  defp handle_response(resp) do
    case resp do
      {:error, %HTTPoison.Error{}} ->
        {:error, :httpoison}

      {:ok, %HTTPoison.Response{status_code: 204}} ->
        {:ok, %{"value" => nil}}

      {:ok, %HTTPoison.Response{body: body}} ->
        with {:ok, decoded} <- Poison.decode(body),
             {:ok, response} <- check_status(decoded),
             {:ok, validated} <- check_for_response_errors(response),
          do: {:ok, validated}

      {:ok, _} ->
        raise "Received unexpected HTTPoison response."
    end
  end

  defp check_status(response) do
    case Map.get(response, "status") do
      @status_obscured ->
        {:error, :obscured}
      _  ->
        {:ok, response}
    end
  end

  defp check_for_response_errors(response) do
    case Map.get(response, "value") do
      %{"class" => "org.openqa.selenium.StaleElementReferenceException"} ->
        {:error, :stale_reference}
      %{"message" => "stale element reference" <> _} ->
        {:error, :stale_reference}
      %{"class" => "org.openqa.selenium.InvalidSelectorException"} ->
        {:error, :invalid_selector}
      %{"class" => "org.openqa.selenium.InvalidElementStateException"} ->
        {:error, :invalid_selector}
      _ ->
        {:ok, response}
    end
  end

  defp request_opts do
    Application.get_env(:wallaby, :hackney_options, [])
  end

  defp headers do
    [{"Accept", "application/json"},
      {"Content-Type", "application/json"}]
  end

  def to_params({:xpath, xpath}) do
    %{using: "xpath", value: xpath}
  end
  def to_params({:css, css}) do
    %{using: "css selector", value: css}
  end
end
