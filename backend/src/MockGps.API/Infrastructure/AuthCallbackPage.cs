using System.Net;
using System.Text.RegularExpressions;

namespace MockGps.API.Infrastructure;

/// <summary>
/// Landing page for the sign-up confirmation email (Supabase redirects here after verifying the address).
/// The address is already confirmed when this page loads, so it works from any device: on the phone a
/// button hands the one-time code to the app (mockgps://auth-callback) to sign in, elsewhere it says to
/// return to the app. No script; the only inline content is the stylesheet.
/// </summary>
public static partial class AuthCallbackPage
{
    public const string Path = "/auth/callback";
    private const string AppLink = "mockgps://auth-callback";

    [GeneratedRegex("^[A-Za-z0-9-]{1,128}$")]
    private static partial Regex SafeCode();

    public static IResult Render(HttpContext http)
    {
        var q = http.Request.Query;
        var tr = http.Request.Headers.AcceptLanguage.ToString().StartsWith("tr", StringComparison.OrdinalIgnoreCase);
        var failed = q.ContainsKey("error") || q.ContainsKey("error_code");
        var code = q["code"].ToString();
        var appHref = SafeCode().IsMatch(code) ? $"{AppLink}?code={code}" : AppLink;
        var isMobile = http.Request.Headers.UserAgent.ToString().Contains("Android", StringComparison.OrdinalIgnoreCase);

        var (title, body) = (failed, tr) switch
        {
            (true, true) => ("Bağlantı geçersiz", "Bu onay bağlantısının süresi dolmuş ya da daha önce kullanılmış. Uygulamada giriş yapmayı dene; gerekirse onay e-postasını yeniden gönder."),
            (true, false) => ("Link no longer valid", "This confirmation link has expired or was already used. Try signing in in the app; resend the confirmation email if needed."),
            (false, true) => ("E-posta adresin onaylandı", isMobile ? "Hesabın hazır. Uygulamaya dönüp devam edebilirsin." : "Hesabın hazır. Telefonunda Mock GPS uygulamasını açıp e-posta ve şifrenle giriş yap."),
            (false, false) => ("Email confirmed", isMobile ? "Your account is ready. Return to the app to continue." : "Your account is ready. Open the Mock GPS app on your phone and sign in with your email and password."),
        };
        var button = !failed && isMobile
            ? $"<a class=\"btn\" href=\"{WebUtility.HtmlEncode(appHref)}\">{(tr ? "Uygulamayı aç" : "Open the app")}</a>"
            : string.Empty;

        var html = $$"""
            <!doctype html>
            <html lang="{{(tr ? "tr" : "en")}}">
            <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <meta name="robots" content="noindex">
            <title>{{title}} · Mock GPS</title>
            <style>
              :root { color-scheme: light dark; }
              body { margin: 0; min-height: 100vh; display: grid; place-items: center; font-family: system-ui, sans-serif;
                     background: Canvas; color: CanvasText; }
              main { max-width: 26rem; padding: 2rem; text-align: center; }
              .mark { width: 3.5rem; height: 3.5rem; border-radius: 50%; display: grid; place-items: center; margin: 0 auto 1.25rem;
                      font-size: 1.75rem; color: #fff; background: {{(failed ? "#c2410c" : "#2563eb")}}; }
              h1 { font-size: 1.4rem; margin: 0 0 .75rem; }
              p { line-height: 1.5; opacity: .8; margin: 0 0 1.5rem; }
              .btn { display: inline-block; padding: .8rem 1.6rem; border-radius: 999px; background: #2563eb; color: #fff;
                     text-decoration: none; font-weight: 600; }
            </style>
            </head>
            <body><main>
              <div class="mark">{{(failed ? "!" : "✓")}}</div>
              <h1>{{title}}</h1>
              <p>{{body}}</p>
              {{button}}
            </main></body>
            </html>
            """;

        // The global policy is default-src 'none'; this page additionally needs its inline stylesheet.
        http.Response.Headers.ContentSecurityPolicy = "default-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'";
        http.Response.Headers.CacheControl = "no-store";
        return Results.Content(html, "text/html; charset=utf-8");
    }
}
