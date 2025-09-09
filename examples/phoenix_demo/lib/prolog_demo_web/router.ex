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

    # Serve CauseNet demo as the root page
    live "/", CauseNetLive, :causal
    
    # Keep the old Prolog demo at /prolog
    get "/prolog", PrologController, :index
    post "/prolog/query", PrologController, :query

    # CauseNet demo routes - keep these for direct navigation
    live "/causenet", CauseNetLive, :causal
    live "/causenet/causal", CauseNetLive, :causal
    live "/causenet/constraints", CauseNetLive, :constraints
    live "/causenet/sudoku", CauseNetLive, :sudoku
    live "/causenet/playground", CauseNetLive, :playground
    live "/causenet/bidirectional", CauseNetLive, :bidirectional
    live "/causenet/adapters", CauseNetLive, :adapters
    
    # Also make constraints available at root level
    live "/constraints", CauseNetLive, :constraints
    live "/sudoku", CauseNetLive, :sudoku
    live "/playground", CauseNetLive, :playground
    live "/bidirectional", CauseNetLive, :bidirectional
    live "/adapters", CauseNetLive, :adapters

    # Monitoring dashboard
    live "/monitoring", MonitoringLive, :index
  end

  scope "/api", PrologDemoWeb do
    pipe_through :api

    post "/prolog/query", PrologController, :query

    # CauseNet API routes
    post "/causenet/causal_paths", CauseNetController, :causal_paths
    post "/causenet/medical_diagnosis", CauseNetController, :medical_diagnosis
    post "/causenet/explore_concept", CauseNetController, :explore_concept
    post "/causenet/constraint_solver", CauseNetController, :constraint_solver
    get "/causenet/search_concepts", CauseNetController, :search_concepts
    get "/causenet/domains", CauseNetController, :get_domains
    get "/causenet/domain_relationships", CauseNetController, :get_domain_relationships
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
