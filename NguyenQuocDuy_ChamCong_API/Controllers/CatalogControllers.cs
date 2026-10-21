using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NguyenQuocDuy_ChamCong_API.Data;
using NguyenQuocDuy_ChamCong_API.Models;

namespace NguyenQuocDuy_ChamCong_API.Controllers;

// ======================= PHÒNG BAN =======================
public class DepartmentDto { public string Name { get; set; } public string Description { get; set; } }

[ApiController, Authorize, Route("api/[controller]")]
public class DepartmentsController : ControllerBase
{
    private readonly AppDbContext _db;
    public DepartmentsController(AppDbContext db) { _db = db; }

    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await _db.Departments.OrderBy(d => d.Id)
            .Select(d => new { d.Id, d.Name, d.Description, employeeCount = d.Employees.Count }).ToListAsync());

    [HttpPost, Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(DepartmentDto d)
    {
        if (string.IsNullOrWhiteSpace(d.Name)) return BadRequest(new { message = "Tên phòng ban không được trống" });
        var e = new Department { Name = d.Name.Trim(), Description = d.Description ?? "" };
        _db.Departments.Add(e); await _db.SaveChangesAsync();
        return Ok(new { e.Id, e.Name, e.Description });
    }

    [HttpPut("{id}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(int id, DepartmentDto d)
    {
        var e = await _db.Departments.FindAsync(id);
        if (e == null) return NotFound(new { message = "Không tìm thấy phòng ban" });
        if (string.IsNullOrWhiteSpace(d.Name)) return BadRequest(new { message = "Tên phòng ban không được trống" });
        e.Name = d.Name.Trim(); e.Description = d.Description ?? "";
        await _db.SaveChangesAsync();
        return Ok(new { e.Id, e.Name, e.Description });
    }

    [HttpDelete("{id}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var e = await _db.Departments.FindAsync(id);
        if (e == null) return NotFound(new { message = "Không tìm thấy phòng ban" });
        _db.Departments.Remove(e); await _db.SaveChangesAsync(); // nhân viên sẽ được SetNull
        return Ok(new { message = "Đã xóa phòng ban" });
    }
}

// ======================= CA LÀM VIỆC =======================
public class ShiftDto
{
    public string Name { get; set; }
    public string StartTime { get; set; }
    public string EndTime { get; set; }
    public int LateGraceMinutes { get; set; } = 10;
}

[ApiController, Authorize, Route("api/[controller]")]
public class ShiftsController : ControllerBase
{
    private readonly AppDbContext _db;
    public ShiftsController(AppDbContext db) { _db = db; }

    private static object Map(Shift s) => new
    {
        s.Id, s.Name,
        startTime = s.StartTime.ToString(@"hh\:mm"),
        endTime = s.EndTime.ToString(@"hh\:mm"),
        s.LateGraceMinutes
    };

    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok((await _db.Shifts.OrderBy(s => s.StartTime).ToListAsync()).Select(Map));

    [HttpPost, Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(ShiftDto d)
    {
        if (!TimeSpan.TryParse(d.StartTime, out var st) || !TimeSpan.TryParse(d.EndTime, out var et))
            return BadRequest(new { message = "Giờ không hợp lệ (định dạng HH:mm)" });
        var e = new Shift { Name = d.Name, StartTime = st, EndTime = et, LateGraceMinutes = d.LateGraceMinutes };
        _db.Shifts.Add(e); await _db.SaveChangesAsync();
        return Ok(Map(e));
    }

    [HttpPut("{id}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(int id, ShiftDto d)
    {
        var e = await _db.Shifts.FindAsync(id);
        if (e == null) return NotFound(new { message = "Không tìm thấy ca" });
        if (!TimeSpan.TryParse(d.StartTime, out var st) || !TimeSpan.TryParse(d.EndTime, out var et))
            return BadRequest(new { message = "Giờ không hợp lệ (định dạng HH:mm)" });
        e.Name = d.Name; e.StartTime = st; e.EndTime = et; e.LateGraceMinutes = d.LateGraceMinutes;
        await _db.SaveChangesAsync();
        return Ok(Map(e));
    }

    [HttpDelete("{id}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        if (await _db.Shifts.CountAsync() <= 1) return BadRequest(new { message = "Phải còn ít nhất 1 ca làm việc" });
        var e = await _db.Shifts.FindAsync(id);
        if (e == null) return NotFound(new { message = "Không tìm thấy ca" });
        _db.Shifts.Remove(e); await _db.SaveChangesAsync();
        return Ok(new { message = "Đã xóa ca" });
    }
}

// ======================= ĐIỂM LÀM VIỆC (GEOFENCE) =======================
public class WorkSiteDto { public string Name { get; set; } public double Latitude { get; set; } public double Longitude { get; set; } public int RadiusMeters { get; set; } = 200; }

[ApiController, Authorize, Route("api/[controller]")]
public class WorkSitesController : ControllerBase
{
    private readonly AppDbContext _db;
    public WorkSitesController(AppDbContext db) { _db = db; }

    [HttpGet]
    public async Task<IActionResult> GetAll() => Ok(await _db.WorkSites.OrderBy(s => s.Id).ToListAsync());

    [HttpPost, Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(WorkSiteDto d)
    {
        var e = new WorkSite { Name = d.Name, Latitude = d.Latitude, Longitude = d.Longitude, RadiusMeters = d.RadiusMeters };
        _db.WorkSites.Add(e); await _db.SaveChangesAsync();
        return Ok(e);
    }

    [HttpPut("{id}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(int id, WorkSiteDto d)
    {
        var e = await _db.WorkSites.FindAsync(id);
        if (e == null) return NotFound(new { message = "Không tìm thấy điểm làm việc" });
        e.Name = d.Name; e.Latitude = d.Latitude; e.Longitude = d.Longitude; e.RadiusMeters = d.RadiusMeters;
        await _db.SaveChangesAsync();
        return Ok(e);
    }

    [HttpDelete("{id}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        if (await _db.WorkSites.CountAsync() <= 1) return BadRequest(new { message = "Phải còn ít nhất 1 điểm làm việc" });
        var e = await _db.WorkSites.FindAsync(id);
        if (e == null) return NotFound(new { message = "Không tìm thấy điểm làm việc" });
        _db.WorkSites.Remove(e); await _db.SaveChangesAsync();
        return Ok(new { message = "Đã xóa điểm làm việc" });
    }
}

// ======================= NHÂN VIÊN =======================
public class EmployeeDto
{
    public string Code { get; set; }
    public string FullName { get; set; }
    public string Phone { get; set; }
    public string Position { get; set; }
    public int? DepartmentId { get; set; }
    public bool IsActive { get; set; } = true;
    // Tuỳ chọn khi tạo mới: tạo luôn tài khoản đăng nhập
    public string Username { get; set; }
    public string Email { get; set; }
    public string Password { get; set; }
}

[ApiController, Authorize, Route("api/[controller]")]
public class EmployeesController : ApiBase
{
    private readonly AppDbContext _db;
    private readonly UserManager<AppUser> _um;
    public EmployeesController(AppDbContext db, UserManager<AppUser> um) { _db = db; _um = um; }

    private static object Map(Employee e) => new
    {
        e.Id, e.Code, e.FullName, e.Phone, e.Position, e.IsActive, e.DepartmentId,
        departmentName = e.Department != null ? e.Department.Name : null,
        hasAccount = e.UserId != null
    };

    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok((await _db.Employees.Include(e => e.Department).OrderBy(e => e.Id).ToListAsync()).Select(Map));

    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var e = await _db.Employees.Include(x => x.Department).FirstOrDefaultAsync(x => x.UserId == CurrentUserId);
        return e == null ? NotFound(new { message = "Tài khoản này không phải nhân viên" }) : Ok(Map(e));
    }

    [HttpPost, Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(EmployeeDto d)
    {
        if (string.IsNullOrWhiteSpace(d.FullName)) return BadRequest(new { message = "Họ tên không được trống" });
        string userId = null;
        if (!string.IsNullOrWhiteSpace(d.Username))
        {
            if (string.IsNullOrWhiteSpace(d.Password) || string.IsNullOrWhiteSpace(d.Email))
                return BadRequest(new { message = "Tạo tài khoản cần có email và mật khẩu" });
            var u = new AppUser { UserName = d.Username.Trim(), Email = d.Email.Trim(), FullName = d.FullName, PhoneNumber = d.Phone, EmailConfirmed = true };
            var r = await _um.CreateAsync(u, d.Password);
            if (!r.Succeeded) return BadRequest(new { message = string.Join("; ", r.Errors.Select(x => x.Description)) });
            await _um.AddToRoleAsync(u, SeedData.NhanVien);
            userId = u.Id;
        }
        var next = (await _db.Employees.MaxAsync(x => (int?)x.Id) ?? 0) + 1;
        var e = new Employee
        {
            Code = string.IsNullOrWhiteSpace(d.Code) ? "NV" + next.ToString("000") : d.Code.Trim(),
            FullName = d.FullName.Trim(), Phone = d.Phone ?? "", Position = d.Position ?? "",
            DepartmentId = d.DepartmentId, IsActive = d.IsActive, UserId = userId
        };
        _db.Employees.Add(e); await _db.SaveChangesAsync();
        await _db.Entry(e).Reference(x => x.Department).LoadAsync();
        return Ok(Map(e));
    }

    [HttpPut("{id}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(int id, EmployeeDto d)
    {
        var e = await _db.Employees.FindAsync(id);
        if (e == null) return NotFound(new { message = "Không tìm thấy nhân viên" });
        if (string.IsNullOrWhiteSpace(d.FullName)) return BadRequest(new { message = "Họ tên không được trống" });
        if (!string.IsNullOrWhiteSpace(d.Code)) e.Code = d.Code.Trim();
        e.FullName = d.FullName.Trim(); e.Phone = d.Phone ?? ""; e.Position = d.Position ?? "";
        e.DepartmentId = d.DepartmentId; e.IsActive = d.IsActive;
        await _db.SaveChangesAsync();
        await _db.Entry(e).Reference(x => x.Department).LoadAsync();
        return Ok(Map(e));
    }

    [HttpDelete("{id}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var e = await _db.Employees.FindAsync(id);
        if (e == null) return NotFound(new { message = "Không tìm thấy nhân viên" });
        var userId = e.UserId;
        _db.Employees.Remove(e); await _db.SaveChangesAsync();
        if (userId != null)
        {
            var u = await _um.FindByIdAsync(userId);
            if (u != null) await _um.DeleteAsync(u);
        }
        return Ok(new { message = "Đã xóa nhân viên" });
    }
}
