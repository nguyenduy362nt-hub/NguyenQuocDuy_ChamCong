using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NguyenQuocDuy_ChamCong_API.Data;
using NguyenQuocDuy_ChamCong_API.Models;
using NguyenQuocDuy_ChamCong_API.Services;

namespace NguyenQuocDuy_ChamCong_API.Controllers;

public class RegisterDto
{
    public string Username { get; set; }
    public string Email { get; set; }
    public string Password { get; set; }
    public string FullName { get; set; }
    public string Phone { get; set; }
    public string Role { get; set; } // NhanVien | KhachHang
}
public class LoginDto { public string Username { get; set; } public string Password { get; set; } }
public class VerifyOtpDto { public string Username { get; set; } public string Code { get; set; } }

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserManager<AppUser> _um;
    private readonly AppDbContext _db;
    private readonly OtpService _otp;
    private readonly TokenService _tokens;
    private readonly IEmailSender _email;
    private readonly ISmsSender _sms;
    private readonly IConfiguration _cfg;
    private readonly ILogger<AuthController> _log;

    public AuthController(UserManager<AppUser> um, AppDbContext db, OtpService otp, TokenService tokens,
        IEmailSender email, ISmsSender sms, IConfiguration cfg, ILogger<AuthController> log)
    { _um = um; _db = db; _otp = otp; _tokens = tokens; _email = email; _sms = sms; _cfg = cfg; _log = log; }

    // 1. Đăng ký tài khoản qua email
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDto d)
    {
        if (string.IsNullOrWhiteSpace(d.Username) || string.IsNullOrWhiteSpace(d.Password) || string.IsNullOrWhiteSpace(d.Email))
            return BadRequest(new { message = "Vui lòng nhập đủ tên đăng nhập, email và mật khẩu" });
        if (!new EmailAddressAttribute().IsValid(d.Email))
            return BadRequest(new { message = "Email không hợp lệ" });

        var role = d.Role == SeedData.NhanVien ? SeedData.NhanVien : SeedData.KhachHang;

        if (await _um.FindByNameAsync(d.Username) != null)
            return BadRequest(new { message = "Tên đăng nhập đã tồn tại" });
        if (await _um.FindByEmailAsync(d.Email) != null)
            return BadRequest(new { message = "Email đã được sử dụng" });

        var user = new AppUser
        {
            UserName = d.Username.Trim(),
            Email = d.Email.Trim(),
            PhoneNumber = d.Phone,
            FullName = string.IsNullOrWhiteSpace(d.FullName) ? d.Username : d.FullName.Trim(),
            EmailConfirmed = true
        };
        var r = await _um.CreateAsync(user, d.Password);
        if (!r.Succeeded)
            return BadRequest(new { message = string.Join("; ", r.Errors.Select(e => e.Description)) });
        await _um.AddToRoleAsync(user, role);

        if (role == SeedData.NhanVien)
        {
            var next = (await _db.Employees.MaxAsync(e => (int?)e.Id) ?? 0) + 1;
            _db.Employees.Add(new Employee
            {
                Code = "NV" + next.ToString("000"),
                FullName = user.FullName,
                Phone = d.Phone ?? "",
                Position = "Nhân viên",
                UserId = user.Id
            });
            await _db.SaveChangesAsync();
        }

        await _email.SendAsync(user.Email, "Chào mừng đến với Chấm Công Nguyễn Quốc Duy",
            $"Xin chào {user.FullName}, tài khoản '{user.UserName}' đã được tạo thành công.");
        return Ok(new { message = "Đăng ký thành công. Hãy đăng nhập để tiếp tục." });
    }

    // 2a. Bước 1: tên đăng nhập + mật khẩu -> gửi OTP qua email
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto d)
    {
        var user = await _um.FindByNameAsync(d.Username ?? "");
        if (user == null || !await _um.CheckPasswordAsync(user, d.Password ?? ""))
            return Unauthorized(new { message = "Sai tên đăng nhập hoặc mật khẩu" });

        var code = _otp.Generate(user.UserName);
        _log.LogWarning("[OTP] {User} -> {Code}", user.UserName, code);
        await _email.SendAsync(user.Email, "Mã OTP đăng nhập", $"Mã OTP của bạn là {code} (hiệu lực 5 phút).");
        await _sms.SendAsync(string.IsNullOrWhiteSpace(user.PhoneNumber) ? user.UserName : user.PhoneNumber,
            $"Ma OTP Cham Cong cua ban la {code}. Hieu luc 5 phut.");

        return Ok(new
        {
            requiresOtp = true,
            email = Mask(user.Email),
            devOtp = _cfg.GetValue<bool>("Otp:ExposeInResponse") ? code : null
        });
    }

    // 2b. Bước 2: nhập OTP -> nhận JWT
    [HttpPost("verify-otp")]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpDto d)
    {
        var user = await _um.FindByNameAsync(d.Username ?? "");
        if (user == null) return Unauthorized(new { message = "Tài khoản không tồn tại" });

        var (ok, err) = _otp.Verify(user.UserName, d.Code);
        if (!ok) return BadRequest(new { message = err });

        var roles = await _um.GetRolesAsync(user);
        var role = roles.FirstOrDefault() ?? SeedData.KhachHang;
        var emp = await _db.Employees.FirstOrDefaultAsync(e => e.UserId == user.Id);
        var token = _tokens.Create(user, role, emp?.Id);

        return Ok(new { token, username = user.UserName, fullName = user.FullName, role, employeeId = emp?.Id });
    }

    private static string Mask(string email)
    {
        var at = email.IndexOf('@');
        if (at <= 2) return email;
        return email.Substring(0, 2) + new string('*', at - 2) + email.Substring(at);
    }
}
