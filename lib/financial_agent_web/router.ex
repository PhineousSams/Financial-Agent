defmodule FinancialAgentWeb.Router do
  use FinancialAgentWeb, :router
  import FinancialAgentWeb.Plugs.{AddToConn, UserAuth}

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug FinancialAgentWeb.Plugs.BrowserCookie
    plug :put_secure_browser_headers
    plug :put_client_ip
    plug :fetch_current_user
  end

  pipeline :root do
    plug :put_root_layout, html: {FinancialAgentWeb.Layouts, :root}
  end

  pipeline :login do
    plug :put_root_layout, html: {FinancialAgentWeb.Layouts, :login}
  end

  pipeline :auth do
    plug FinancialAgentWeb.Plugs.RequireAuth
    plug FinancialAgentWeb.Plugs.EnforcePasswordPolicy
  end

  pipeline :no_layout do
    plug :put_layout, false
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :basic_auth do
    plug FinancialAgentWeb.Plugs.BasicAuth
  end


  pipeline :authenticated_api do
    plug FinancialAgentWeb.Plugs.AuthPlug
  end


  pipeline :csrf do
    plug :protect_from_forgery
  end


  # ================ WEB ROUTES ==============================

  scope "/", FinancialAgentWeb do
    pipe_through([:browser, :csrf, :login])

    get "/", SessionController, :new
    post "/users/log_in", SessionController, :create

    post "/login", SessionController, :login
    get("/signout", SessionController, :signout)

    live "/forgot/password", ForgotPasswordLive.Index
    live "/forgot/password/reset/:token", ForgotPasswordLive.Reset

    scope "/user", SessionLive do
      live "/login", Index, :index
      live "/", Index, :new

      live_session :resets, on_mount: FinancialAgentWeb.UserLiveAuth do
        live "/change/password", Reset, :index
      end
    end
  end

  # =================== AI CHAT ROUTES ==================
  # scope "/", FinancialAgentWeb do
  #   pipe_through([:browser, :csrf, :root, :auth])

  #   live "/chat", ChatLive, :index
  #   live "/chat/:conversation_id", ChatLive, :show
  # end

  # =================== OAUTH ROUTES ==================
  scope "/auth", FinancialAgentWeb do
    pipe_through [:browser]

    get "/:provider", OAuthController, :request
    get "/:provider/callback", OAuthController, :callback
  end

  live_session :admins, on_mount: [FinancialAgentWeb.UserLiveAuth, FinancialAgentWeb.Plugs.Authorizer] do
    # =================== ADMIN ==================
    scope "/Admin", FinancialAgentWeb do
      pipe_through([:browser, :csrf, :root, :auth])

      live "/dashboard", DashboardLive.Index, :index
      live "/profile", DashboardLive.Index, :profile
      get "/dashboard/stats", ReportController, :dash_stats

      # ============== Chat ======================
      scope "/chats", ChatLive do
        live "/", Index, :index
        live "/:conversation_id", Index, :show
      end

      # ============= SYSTEM NOTIFICATIONS ============
      live "/sms/logs", NotificationsLive.Sms, :index
      live "/emails/logs", NotificationsLive.Emails, :index
      live "/banks", NotificationsLive.Emails, :index

      # ============= SYSTEM NOTIFICATIONS ============
      live "/sms/logs", NotificationsLive.Sms, :index
      live "/emails/logs", NotificationsLive.Emails, :index

      scope "/Configs", ConfigsLive do
        live "/management", Index, :index
        live "/new", Index, :new
        live "/:id/edit", Index, :edit
      end

      scope "/sms", SmsConfigurationsLive do
        live "/configurations", Index, :index
        live "/new", Index, :new
        live "/:id/edit", Index, :edit
      end


      scope "/api_integrators", ApiIntegratorsLive do
        live "/", Index, :index
        live "/new", Index, :new
        live "/:id/edit", Index, :edit
      end

      # =========== USER MANAGEMENT =========

      scope "/admin/users", UserLive do
        live "/management", Index, :index
        live "/blocked", Blocked, :index
        live "/new", Index, :new
        live "/:id/edit", Index, :edit
        live "/:id/view", Index, :view
      end

      # ========================  Permission Groups ===========================
      live "/permission_groups", PermissionGroupsLive.Index, :index
      live "/permission_groups/new", PermissionGroupsLive.Index, :new
      live "/permission_groups/:id/edit", PermissionGroupsLive.Index, :edit
      live "/permission_groups/:id", PermissionGroupsLive.Index, :view
      live "/permission_groups/:id/show/edit", PermissionGroupsLive.Show, :edit

      # ========================= Permissions =================================
      live "/permissions", PermissionsLive.Index, :index
      live "/permissions/new", PermissionsLive.Index, :new
      live "/permissions/:id/edit", PermissionsLive.Index, :edit

      live "/permissions/:id", PermissionsLive.Show, :show
      live "/permissions/:id/show/edit", PermissionsLive.Show, :edit

      # ========================== Logs =======================================
      live "/logs", UserLogsLive.Index, :index
      live "/session/logs", SessionLogsLive.Index, :index
      live "/audit/trail", AuditTrailsLive.Index, :index
      live "/api/logs", ApiLogsLive.Index, :index
      live "/service/logs", ServiceLogsLive.Index, :index
      live "/logs/user/:user_id/session", UserSessionLogsLive.Index, :index

      # ========================= USER ROLES =================================
      live "/roles", RoleLive.Index, :index
      live "/roles/new", RoleLive.Index, :new
      live "/roles/:id/edit", RoleLive.Index, :edit

      live "/roles/:id", RoleLive.Show, :show
      live "/roles/:id/show/edit", RoleLive.Show, :edit

      live "/roles/:role/access", AccessLive.Index, :index

      # =========================== PASSWORD GENERATION ================================
      live "/password_format", PasswordFormatLive.Index, :index

    end
  end


  scope "/", FinancialAgentWeb do

    # ------------------------WRONG ROUTES ------------
    get "/*any", ErrorController, :invalid_endpoint
    post "/*any", ErrorController, :invalid_endpoint
    put "/*any", ErrorController, :invalid_endpoint
    delete "/*any", ErrorController, :invalid_endpoint
    patch "/*any", ErrorController, :invalid_endpoint
    options "/*any", ErrorController, :invalid_endpoint
    head "/*any", ErrorController, :invalid_endpoint
  end
end
