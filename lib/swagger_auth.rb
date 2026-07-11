# Protege o Swagger UI (/api-docs) com login por FORMULÁRIO, e não HTTP Basic.
# Motivo: o prompt nativo de Basic Auth do navegador não é oferecido ao gerenciador
# de senhas do Chrome, então o usuário digita a senha toda vez. Um <form> HTML normal
# (com autocomplete username/current-password) permite salvar a senha.
#
# A sessão é um cookie assinado (HMAC via secret_key_base) — não depende de
# sessão/cookies do Rails, já que o app é api_only.
class SwaggerAuth
  COOKIE         = "mf_docs_session".freeze
  MAX_AGE        = 12 * 60 * 60 # 12h
  LOGO_PATH      = "app/assets/images/logo_myfinance.png".freeze # wordmark (tela de login)
  LOGO_ICON_PATH = "app/assets/images/logo_icon.png".freeze      # ícone (header do UI)

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    path = request.path

    return @app.call(env) unless path.start_with?("/api-docs")

    if path == "/api-docs/logo"
      serve_image(self.class.logo_bytes)
    elsif path == "/api-docs/logo-icon"
      serve_image(self.class.logo_icon_bytes)
    elsif path == "/api-docs/login" && request.post?
      handle_login(request)
    elsif path == "/api-docs/logout"
      handle_logout(request)
    elsif authenticated?(request)
      @app.call(env)
    else
      login_response(request)
    end
  end

  private

    def verifier
      @verifier ||= ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base, digest: "SHA256")
    end

    def credentials_valid?(user, pass)
      expected_user = ENV.fetch("SWAGGER_USERNAME", "")
      expected_pass = ENV.fetch("SWAGGER_PASSWORD", "")
      # Hash antes do secure_compare para normalizar tamanho e evitar vazar timing.
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(user.to_s), ::Digest::SHA256.hexdigest(expected_user)) &
        ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(pass.to_s), ::Digest::SHA256.hexdigest(expected_pass))
    end

    def authenticated?(request)
      token = request.cookies[COOKIE]
      return false if token.nil? || token.empty?

      data = verifier.verified(token)
      data.present? && data["exp"].to_i > Time.now.to_i
    rescue StandardError
      false
    end

    def handle_login(request)
      if credentials_valid?(request.params["username"], request.params["password"])
        token = verifier.generate({ "exp" => Time.now.to_i + MAX_AGE })
        headers = { "Location" => "/api-docs/index.html" }
        set_cookie(headers, request, token, MAX_AGE)
        [302, headers, []]
      else
        # Reexibe o form com erro (200, não 401): o Warden do Devise intercepta 401 e,
        # como não há failure app nessa rota, quebraria. O sucesso se distingue pelo 302.
        login_response(request, error: true)
      end
    end

    def handle_logout(request)
      headers = { "Location" => "/api-docs/index.html" }
      set_cookie(headers, request, "", 0)
      [302, headers, []]
    end

    def set_cookie(headers, request, value, max_age)
      parts = ["#{COOKIE}=#{value}", "Path=/api-docs", "HttpOnly", "SameSite=Lax", "Max-Age=#{max_age}"]
      parts << "Secure" if request.ssl? || request.get_header("HTTP_X_FORWARDED_PROTO") == "https"
      headers["Set-Cookie"] = parts.join("; ")
    end

    def serve_image(body)
      return [404, { "Content-Type" => "text/plain" }, ["not found"]] if body.nil?

      [200, { "Content-Type" => "image/png", "Cache-Control" => "public, max-age=86400" }, [body]]
    end

    def self.logo_bytes
      return @logo_bytes if defined?(@logo_bytes)

      path = Rails.root.join(LOGO_PATH)
      @logo_bytes = File.exist?(path) ? File.binread(path) : nil
    end

    def self.logo_icon_bytes
      return @logo_icon_bytes if defined?(@logo_icon_bytes)

      path = Rails.root.join(LOGO_ICON_PATH)
      @logo_icon_bytes = File.exist?(path) ? File.binread(path) : nil
    end

    def login_response(request, error: false, status: 200)
      [status, { "Content-Type" => "text/html; charset=utf-8" }, [login_html(error)]]
    end

    def login_html(error)
      error_html = error ? %(<p class="mf-error">Usuário ou senha inválidos.</p>) : ""

      <<~HTML
        <!DOCTYPE html>
        <html lang="pt-BR">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>My Finance API Docs — Acesso</title>
          <link rel="icon" type="image/png" href="/api-docs/logo-icon">
          <style>
            * { box-sizing: border-box; }
            body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
                   font-family: Arial, Helvetica, sans-serif; background: #e3e1df; color: #052131; padding: 24px; }
            .mf-card { background: #ffffff; width: 100%; max-width: 380px; border-radius: 12px; padding: 36px 32px;
                       box-shadow: 0 8px 30px rgba(5, 33, 49, 0.12); }
            .mf-logo { display: block; max-width: 220px; height: auto; margin: 0 auto 24px; }
            h1 { font-size: 18px; margin: 0 0 4px; text-align: center; }
            .mf-sub { font-size: 13px; color: #5b686e; text-align: center; margin: 0 0 24px; }
            label { display: block; font-size: 13px; font-weight: bold; margin: 0 0 6px; }
            input { width: 100%; padding: 11px 12px; margin: 0 0 16px; border: 1px solid #aaa69f;
                    border-radius: 10px; font-size: 14px; color: #052131; background: #fff; }
            input:focus { outline: none; border-color: #88a15e; box-shadow: 0 0 0 3px rgba(136, 161, 94, 0.25); }
            button { width: 100%; padding: 12px; border: none; border-radius: 10px; background: #88a15e;
                     color: #fff; font-size: 15px; font-weight: bold; cursor: pointer; }
            button:hover { background: #78904f; }
            .mf-error { background: rgba(197, 48, 48, 0.1); color: #c53030; font-size: 13px; padding: 10px 12px;
                        border-radius: 10px; margin: 0 0 16px; text-align: center; }
            .mf-foot { text-align: center; font-size: 12px; color: #5b686e; margin: 24px 0 0; }
          </style>
        </head>
        <body>
          <form class="mf-card" method="post" action="/api-docs/login" autocomplete="on">
            <img class="mf-logo" src="/api-docs/logo" alt="My Finance">
            <h1>Documentação da API</h1>
            <p class="mf-sub">Acesso restrito</p>
            #{error_html}
            <label for="username">Usuário</label>
            <input id="username" name="username" type="text" autocomplete="username" autofocus required>
            <label for="password">Senha</label>
            <input id="password" name="password" type="password" autocomplete="current-password" required>
            <button type="submit">Entrar</button>
            <p class="mf-foot">© #{Time.now.year} My Finance</p>
          </form>
        </body>
        </html>
      HTML
    end
end
