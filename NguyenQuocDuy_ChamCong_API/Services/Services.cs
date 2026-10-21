using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Mail;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.IdentityModel.Tokens;
using NguyenQuocDuy_ChamCong_API.Models;

namespace NguyenQuocDuy_ChamCong_API.Services;

// ---------- Gửi email (nếu chưa cấu hình SMTP thì in ra console của API) ----------
public interface IEmailSender { Task SendAsync(string to, string subject, string body); }

public class EmailSender : IEmailSender
{
    private readonly IConfiguration _cfg;
    private readonly ILogger<EmailSender> _log;
    public EmailSender(IConfiguration cfg, ILogger<EmailSender> log) { _cfg = cfg; _log = log; }

    public async Task SendAsync(string to, string subject, string body)
    {
        var host = _cfg["Smtp:Host"];
        if (string.IsNullOrWhiteSpace(host))
        {
            _log.LogWarning("[EMAIL-DEV] To: {To} | {Subject} | {Body}", to, subject, body);
            return;
        }
        try
        {
            var from = string.IsNullOrWhiteSpace(_cfg["Smtp:From"]) ? _cfg["Smtp:User"] : _cfg["Smtp:From"];
            using var client = new SmtpClient(host, _cfg.GetValue<int>("Smtp:Port"))
            {
                EnableSsl = true,
                Credentials = new NetworkCredential(_cfg["Smtp:User"], _cfg["Smtp:Password"])
            };
            await client.SendMailAsync(new MailMessage(from, to, subject, body));
        }
        catch (Exception ex)
        {
            _log.LogWarning("Gửi email thất bại: {Msg}", ex.Message);
        }
    }
}

// ---------- OTP ----------
public class OtpService
{
    private class Entry { public string Code; public DateTime Expires; public int Tries; }
    private readonly IMemoryCache _cache;
    public OtpService(IMemoryCache cache) { _cache = cache; }

    public string Generate(string username)
    {
        var code = RandomNumberGenerator.GetInt32(0, 1000000).ToString("D6");
        _cache.Set("otp:" + username.ToLower(), new Entry { Code = code, Expires = DateTime.Now.AddMinutes(5) },
            TimeSpan.FromMinutes(5));
        return code;
    }

    public (bool ok, string error) Verify(string username, string code)
    {
        var key = "otp:" + username.ToLower();
        if (!_cache.TryGetValue(key, out Entry e)) return (false, "Mã OTP đã hết hạn, vui lòng đăng nhập lại");
        if (e.Tries >= 5) { _cache.Remove(key); return (false, "Nhập sai quá 5 lần, vui lòng đăng nhập lại"); }
        e.Tries++;
        if (e.Expires < DateTime.Now) { _cache.Remove(key); return (false, "Mã OTP đã hết hạn"); }
        if (e.Code != (code ?? "").Trim()) return (false, $"Mã OTP không đúng (còn {5 - e.Tries} lần thử)");
        _cache.Remove(key);
        return (true, null);
    }
}

// ---------- JWT ----------
public class TokenService
{
    private readonly IConfiguration _cfg;
    public TokenService(IConfiguration cfg) { _cfg = cfg; }

    public string Create(AppUser user, string role, int? employeeId)
    {
        var claims = new List<Claim>
        {
            new Claim("unique_name", user.UserName),
            new Claim("uid", user.Id),
            new Claim("full_name", user.FullName ?? ""),
            new Claim("role", role),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };
        if (employeeId.HasValue) claims.Add(new Claim("eid", employeeId.Value.ToString()));

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_cfg["JWTKey:Secret"]));
        var token = new JwtSecurityToken(
            issuer: _cfg["JWTKey:ValidIssuer"],
            audience: _cfg["JWTKey:ValidAudience"],
            expires: DateTime.UtcNow.AddHours(_cfg.GetValue<double>("JWTKey:TokenExpiryTimeInHour")),
            claims: claims,
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

// ---------- QR động xoay vòng mỗi 30 giây ----------
public class QrTokenService
{
    public const int WindowSeconds = 30;
    private readonly byte[] _key;
    public QrTokenService(IConfiguration cfg) { _key = Encoding.UTF8.GetBytes(cfg["Qr:Secret"] ?? "qr"); }

    private static long Window(DateTime utc) => new DateTimeOffset(utc).ToUnixTimeSeconds() / WindowSeconds;

    private string Sign(string payload)
    {
        using var h = new HMACSHA256(_key);
        return Convert.ToHexString(h.ComputeHash(Encoding.UTF8.GetBytes(payload))).Substring(0, 16);
    }

    public (string token, int expiresIn) Create(int siteId)
    {
        var w = Window(DateTime.UtcNow);
        var payload = $"{siteId}|{w}";
        var remain = WindowSeconds - (int)(new DateTimeOffset(DateTime.UtcNow).ToUnixTimeSeconds() % WindowSeconds);
        return ($"CC1.{payload}.{Sign(payload)}", remain);
    }

    /// <summary>Trả về siteId nếu hợp lệ, ngược lại null (chấp nhận cửa sổ hiện tại và 1 cửa sổ trước).</summary>
    public int? Validate(string token)
    {
        if (string.IsNullOrWhiteSpace(token)) return null;
        var parts = token.Trim().Split('.');
        if (parts.Length != 3 || parts[0] != "CC1") return null;
        if (Sign(parts[1]) != parts[2]) return null;
        var p = parts[1].Split('|');
        if (p.Length != 2 || !int.TryParse(p[0], out var siteId) || !long.TryParse(p[1], out var w)) return null;
        var now = Window(DateTime.UtcNow);
        return (w == now || w == now - 1) ? siteId : null;
    }
}

public static class Geo
{
    public static double DistanceMeters(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371000;
        double ToRad(double d) => d * Math.PI / 180;
        var dLat = ToRad(lat2 - lat1);
        var dLon = ToRad(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRad(lat1)) * Math.Cos(ToRad(lat2)) * Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        return R * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
    }
}

// ---------- SMS (chưa nối nhà mạng: "gửi SMS" = in mã ra log của API, giống bài trước) ----------
public interface ISmsSender { Task SendAsync(string to, string message); }

public class ConsoleSmsSender : ISmsSender
{
    private readonly ILogger<ConsoleSmsSender> _log;
    public ConsoleSmsSender(ILogger<ConsoleSmsSender> log) { _log = log; }
    public Task SendAsync(string to, string message)
    {
        _log.LogWarning("[SMS] gửi tới {To}: {Msg}", to, message);
        return Task.CompletedTask;
    }
}
