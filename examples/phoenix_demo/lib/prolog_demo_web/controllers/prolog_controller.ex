defmodule PrologDemoWeb.PrologController do
  use PrologDemoWeb, :controller
  alias Swiex.MQI

  def index(conn, _params) do
    render(conn, :index)
  end

  def query(conn, %{"query" => query_text, "setupCode" => setup_code}) do
    case execute_complex_query(query_text, setup_code) do
      {:ok, results} ->
        json(conn, %{
          success: true,
          results: results,
          query: query_text
        })

      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(%{
          success: false,
          error: reason,
          query: query_text
        })
    end
  end

  def query(conn, %{"query" => query_text}) do
    case execute_query(query_text) do
      {:ok, results} ->
        json(conn, %{
          success: true,
          results: results,
          query: query_text
        })

      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(%{
          success: false,
          error: reason,
          query: query_text
        })
    end
  end

  def execute_query(query_text) do
    # For simple queries, use one-shot mode
    case MQI.query(query_text) do
      {:ok, results} ->
        {:ok, results}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def execute_complex_query(query_text, setup_code) do
    # For complex queries that need setup, use a session
    case MQI.start_session() do
      {:ok, session} ->
        try do
          # Load any setup code
          if setup_code && setup_code != "" do
            case MQI.consult_string(session, setup_code) do
              {:ok, _} -> :ok
              {:error, reason} -> {:error, "Setup failed: #{reason}"}
            end
          end

          # Execute the main query
          case MQI.query(session, query_text) do
            {:ok, results} -> {:ok, results}
            {:error, reason} -> {:error, reason}
          end
        after
          MQI.stop_session(session)
        end

      {:error, reason} ->
        {:error, "Failed to start session: #{reason}"}
    end
  end
end
