defmodule PrologDemoWeb.Router do
  use PrologDemoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PrologDemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PrologDemoWeb do
    pipe_through :browser

    get "/", PrologController, :index
    get "/prolog", PrologController, :index
    post "/prolog/query", PrologController, :query
  end

  scope "/api", PrologDemoWeb do
    pipe_through :api

    post "/prolog/query", PrologController, :query
  end

  # Other scopes may use custom stacks.
  # scope "/api", PrologDemoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:prolog_demo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PrologDemoWeb.Telemetry
    end
  end
end
