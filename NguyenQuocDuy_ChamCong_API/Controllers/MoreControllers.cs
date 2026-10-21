using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NguyenQuocDuy_ChamCong_API.Data;
using NguyenQuocDuy_ChamCong_API.Models;
using NguyenQuocDuy_ChamCong_API.Services;

namespace NguyenQuocDuy_ChamCong_API.Controllers;

// ======================= NGHỈ PHÉP =======================
public class LeaveDto { public string FromDate { get; set; } public string ToDate { get; set; } public string Reason { get; set; } }
public class LeaveStatusDto { public string Status { get; set; } public string AdminNote { get; set; } }

[ApiController, Authorize, Route("api/[controller]")]
public class LeavesController : ApiBase
{
    private readonly AppDbContext _db;
    public LeavesController(AppDbContext db) { _db = db; }

    private static object Map(LeaveRequest l) => new
    {
        l.Id, l.EmployeeId,
        employeeName = l.Employee != null ? l.Employee.FullName : null,
        fromDate = l.FromDate.ToString("yyyy-MM-dd"), toDate = l.ToDate.ToString("yyyy-MM-dd"),
        l.Reason, l.Status, l.AdminNote, l.CreatedAt
    };

    private Task<Employee> MyEmployee() => _db.Employees.FirstOrDefaultAsync(e => e.UserId == CurrentUserId);

    [HttpGet("mine"), Authorize(Roles = "NhanVien")]
    public async Task<IActionResult> Mine()
    {
        var emp = await MyEmployee();
        if (emp == null) return BadRequest(new { message = "Không tìm thấy hồ sơ nhân viên" });
        var list = await _db.LeaveRequests.Include(l => l.Employee).Where(l => l.EmployeeId == emp.Id)
            .OrderByDescending(l => l.CreatedAt).ToListAsync();
        return Ok(list.Select(Map));
    }

    [HttpGet, Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll()
    {
        var list = await _db.LeaveRequests.Include(l => l.Employee).OrderByDescending(l => l.CreatedAt).ToListAsync();
        return Ok(list.Select(Map));
    }

    [HttpPost, Authorize(Roles = "NhanVien")]
    public async Task<IActionResult> Create(LeaveDto d)
    {
        var emp = await MyEmployee();
        if (emp == null) return BadRequest(new { message = "Không tìm thấy hồ sơ nhân viên" });
        if (!DateTime.TryParse(d.FromDate, out var f) || !DateTime.TryParse(d.ToDate, out var t))
            return BadRequest(new { message = "Ngày không hợp lệ (yyyy-MM-dd)" });
        if (t.Date < f.Date) return BadRequest(new { message = "Ngày kết thúc phải sau ngày bắt đầu" });
        if (string.IsNullOrWhiteSpace(d.Reason)) return BadRequest(new { message = "Vui lòng nhập lý do" });
        var l = new LeaveRequest { EmployeeId = emp.Id, FromDate = f.Date, ToDate = t.Date, Reason = d.Reason.Trim() };
        _db.LeaveRequests.Add(l); await _db.SaveChangesAsync();
        l.Employee = emp;
        return Ok(Map(l));
    }

    [HttpPut("{id}"), Authorize(Roles = "NhanVien")]
    public async Task<IActionResult> Update(int id, LeaveDto d)
    {
        var emp = await MyEmployee();
        var l = await _db.LeaveRequests.Include(x => x.Employee).FirstOrDefaultAsync(x => x.Id == id);
        if (l == null || emp == null || l.EmployeeId != emp.Id) return NotFound(new { message = "Không tìm thấy đơn" });
        if (l.Status != "ChoDuyet") return BadRequest(new { message = "Đơn đã được xử lý, không thể sửa" });
        if (!DateTime.TryParse(d.FromDate, out var f) || !DateTime.TryParse(d.ToDate, out var t))
            return BadRequest(new { message = "Ngày không hợp lệ (yyyy-MM-dd)" });
        if (t.Date < f.Date) return BadRequest(new { message = "Ngày kết thúc phải sau ngày bắt đầu" });
        l.FromDate = f.Date; l.ToDate = t.Date; l.Reason = d.Reason ?? "";
        await _db.SaveChangesAsync();
        return Ok(Map(l));
    }

    [HttpPut("{id}/status"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> SetStatus(int id, LeaveStatusDto d)
    {
        var l = await _db.LeaveRequests.Include(x => x.Employee).FirstOrDefaultAsync(x => x.Id == id);
        if (l == null) return NotFound(new { message = "Không tìm thấy đơn" });
        if (d.Status != "DaDuyet" && d.Status != "TuChoi" && d.Status != "ChoDuyet")
            return BadRequest(new { message = "Trạng thái không hợp lệ" });
        l.Status = d.Status; l.AdminNote = d.AdminNote ?? "";
        await _db.SaveChangesAsync();
        return Ok(Map(l));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var l = await _db.LeaveRequests.FindAsync(id);
        if (l == null) return NotFound(new { message = "Không tìm thấy đơn" });
        if (!User.IsInRole("Admin"))
        {
            var emp = await MyEmployee();
            if (emp == null || l.EmployeeId != emp.Id) return Forbid();
            if (l.Status != "ChoDuyet") return BadRequest(new { message = "Đơn đã được xử lý, không thể xóa" });
        }
        _db.LeaveRequests.Remove(l); await _db.SaveChangesAsync();
        return Ok(new { message = "Đã xóa đơn nghỉ phép" });
    }
}

// ======================= CHIA SẺ VỊ TRÍ =======================
public class LocationDto { public double Latitude { get; set; } public double Longitude { get; set; } }

[ApiController, Authorize, Route("api/[controller]")]
public class LocationsController : ApiBase
{
    private readonly AppDbContext _db;
    public LocationsController(AppDbContext db) { _db = db; }

    [HttpPost, Authorize(Roles = "NhanVien")]
    public async Task<IActionResult> Share(LocationDto d)
    {
        var emp = await _db.Employees.FirstOrDefaultAsync(e => e.UserId == CurrentUserId);
        if (emp == null) return BadRequest(new { message = "Không tìm thấy hồ sơ nhân viên" });
        var l = await _db.LocationShares.FirstOrDefaultAsync(x => x.EmployeeId == emp.Id);
        if (l == null) { l = new LocationShare { EmployeeId = emp.Id }; _db.LocationShares.Add(l); }
        l.Latitude = d.Latitude; l.Longitude = d.Longitude; l.UpdatedAt = DateTime.Now; l.IsSharing = true;
        await _db.SaveChangesAsync();
        return Ok(new { message = "Đã cập nhật vị trí" });
    }

    [HttpDelete("mine"), Authorize(Roles = "NhanVien")]
    public async Task<IActionResult> Stop()
    {
        var emp = await _db.Employees.FirstOrDefaultAsync(e => e.UserId == CurrentUserId);
        if (emp == null) return BadRequest(new { message = "Không tìm thấy hồ sơ nhân viên" });
        var l = await _db.LocationShares.FirstOrDefaultAsync(x => x.EmployeeId == emp.Id);
        if (l != null) { l.IsSharing = false; await _db.SaveChangesAsync(); }
        return Ok(new { message = "Đã dừng chia sẻ vị trí" });
    }

    // Admin xem tất cả nhân viên đang chia sẻ (cập nhật trong 10 phút gần nhất)
    [HttpGet, Authorize(Roles = "Admin")]
    public async Task<IActionResult> Active()
    {
        var since = DateTime.Now.AddMinutes(-10);
        var list = await _db.LocationShares.Include(l => l.Employee)
            .Where(l => l.IsSharing && l.UpdatedAt >= since).ToListAsync();
        var site = await _db.WorkSites.OrderBy(s => s.Id).FirstOrDefaultAsync();
        return Ok(new
        {
            site,
            people = list.Select(l => new
            {
                l.EmployeeId, name = l.Employee.FullName, code = l.Employee.Code,
                l.Latitude, l.Longitude, l.UpdatedAt,
                distanceToSite = site == null ? (double?)null : Math.Round(Geo.DistanceMeters(l.Latitude, l.Longitude, site.Latitude, site.Longitude))
            })
        });
    }
}

// ======================= QR ĐỘNG =======================
[ApiController, Route("api/[controller]")]
public class QrController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly QrTokenService _qr;
    public QrController(AppDbContext db, QrTokenService qr) { _db = db; _qr = qr; }

    [HttpGet("current"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Current()
    {
        var site = await _db.WorkSites.OrderBy(s => s.Id).FirstOrDefaultAsync();
        if (site == null) return BadRequest(new { message = "Chưa cấu hình điểm làm việc" });
        var (token, expiresIn) = _qr.Create(site.Id);
        return Ok(new { token, expiresIn, siteName = site.Name, windowSeconds = QrTokenService.WindowSeconds });
    }
}

// ======================= THỐNG KÊ & XẾP HẠNG CHUYÊN CẦN =======================
[ApiController, Authorize, Route("api/[controller]")]
public class StatsController : ApiBase
{
    private readonly AppDbContext _db;
    public StatsController(AppDbContext db) { _db = db; }

    [HttpGet("summary"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Summary()
    {
        var today = DateTime.Today;
        var total = await _db.Employees.CountAsync(e => e.IsActive);
        var present = await _db.Attendances.CountAsync(a => a.WorkDate == today);
        var late = await _db.Attendances.CountAsync(a => a.WorkDate == today && a.Status == "DiTre");
        var onLeave = await _db.LeaveRequests.CountAsync(l => l.Status == "DaDuyet" && l.FromDate <= today && l.ToDate >= today);
        var pending = await _db.LeaveRequests.CountAsync(l => l.Status == "ChoDuyet");
        var sharing = await _db.LocationShares.CountAsync(l => l.IsSharing && l.UpdatedAt >= DateTime.Now.AddMinutes(-10));
        var absent = Math.Max(0, total - present - onLeave);
        return Ok(new { totalEmployees = total, present, late, onLeave, absent, pendingLeaves = pending, sharing });
    }

    // Điểm chuyên cần 30 ngày gần nhất: đúng giờ +10, đi trễ +6, thêm +1 mỗi giờ làm đủ (tối đa 9)
    private async Task<List<LeaderRow>> BuildBoard()
    {
        var from = DateTime.Today.AddDays(-30);
        var emps = await _db.Employees.Include(e => e.Department).Where(e => e.IsActive).ToListAsync();
        var atts = await _db.Attendances.Where(a => a.WorkDate >= from).ToListAsync();
        var rows = emps.Select(e =>
        {
            var mine = atts.Where(a => a.EmployeeId == e.Id).ToList();
            var onTime = mine.Count(a => a.Status == "DungGio");
            var late = mine.Count(a => a.Status == "DiTre");
            var minutes = mine.Sum(a => a.WorkedMinutes);
            var bonus = mine.Sum(a => Math.Min(9, a.WorkedMinutes / 60));
            return new LeaderRow
            {
                EmployeeId = e.Id, Name = e.FullName, Department = e.Department?.Name ?? "",
                OnTime = onTime, Late = late, WorkedHours = Math.Round(minutes / 60.0, 1),
                Points = onTime * 10 + late * 6 + bonus
            };
        }).OrderByDescending(r => r.Points).ThenBy(r => r.Late).ToList();
        for (int i = 0; i < rows.Count; i++) rows[i].Rank = i + 1;
        return rows;
    }

    [HttpGet("leaderboard")]
    public async Task<IActionResult> Leaderboard() => Ok(await BuildBoard());

    [HttpGet("me"), Authorize(Roles = "NhanVien")]
    public async Task<IActionResult> Me()
    {
        var emp = await _db.Employees.FirstOrDefaultAsync(e => e.UserId == CurrentUserId);
        if (emp == null) return BadRequest(new { message = "Không tìm thấy hồ sơ nhân viên" });
        var board = await BuildBoard();
        var row = board.FirstOrDefault(r => r.EmployeeId == emp.Id);
        return Ok(new { row, totalPeople = board.Count });
    }
}

public class LeaderRow
{
    public int Rank { get; set; }
    public int EmployeeId { get; set; }
    public string Name { get; set; }
    public string Department { get; set; }
    public int OnTime { get; set; }
    public int Late { get; set; }
    public double WorkedHours { get; set; }
    public int Points { get; set; }
}

// ======================= ĐÁNH GIÁ CỦA KHÁCH HÀNG =======================
public class FeedbackDto { public int? EmployeeId { get; set; } public int Rating { get; set; } = 5; public string Content { get; set; } }

[ApiController, Authorize, Route("api/[controller]")]
public class FeedbacksController : ApiBase
{
    private readonly AppDbContext _db;
    public FeedbacksController(AppDbContext db) { _db = db; }

    private static object Map(Feedback f) => new
    {
        f.Id, f.CustomerName, f.EmployeeId,
        employeeName = f.Employee != null ? f.Employee.FullName : null,
        f.Rating, f.Content, f.CreatedAt
    };

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var q = _db.Feedbacks.Include(f => f.Employee).AsQueryable();
        if (!User.IsInRole("Admin")) q = q.Where(f => f.UserId == CurrentUserId);
        return Ok((await q.OrderByDescending(f => f.CreatedAt).ToListAsync()).Select(Map));
    }

    [HttpPost, Authorize(Roles = "KhachHang")]
    public async Task<IActionResult> Create(FeedbackDto d)
    {
        if (d.Rating < 1 || d.Rating > 5) return BadRequest(new { message = "Số sao phải từ 1 đến 5" });
        if (string.IsNullOrWhiteSpace(d.Content)) return BadRequest(new { message = "Vui lòng nhập nội dung" });
        var name = User.FindFirst("full_name")?.Value ?? User.Identity?.Name ?? "Khách";
        var f = new Feedback { UserId = CurrentUserId, CustomerName = name, EmployeeId = d.EmployeeId, Rating = d.Rating, Content = d.Content.Trim() };
        _db.Feedbacks.Add(f); await _db.SaveChangesAsync();
        await _db.Entry(f).Reference(x => x.Employee).LoadAsync();
        return Ok(Map(f));
    }

    [HttpPut("{id}"), Authorize(Roles = "KhachHang")]
    public async Task<IActionResult> Update(int id, FeedbackDto d)
    {
        var f = await _db.Feedbacks.Include(x => x.Employee).FirstOrDefaultAsync(x => x.Id == id && x.UserId == CurrentUserId);
        if (f == null) return NotFound(new { message = "Không tìm thấy đánh giá" });
        if (d.Rating < 1 || d.Rating > 5) return BadRequest(new { message = "Số sao phải từ 1 đến 5" });
        f.EmployeeId = d.EmployeeId; f.Rating = d.Rating; f.Content = d.Content ?? "";
        await _db.SaveChangesAsync();
        await _db.Entry(f).Reference(x => x.Employee).LoadAsync();
        return Ok(Map(f));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var f = await _db.Feedbacks.FindAsync(id);
        if (f == null) return NotFound(new { message = "Không tìm thấy đánh giá" });
        if (!User.IsInRole("Admin") && f.UserId != CurrentUserId) return Forbid();
        _db.Feedbacks.Remove(f); await _db.SaveChangesAsync();
        return Ok(new { message = "Đã xóa đánh giá" });
    }
}
