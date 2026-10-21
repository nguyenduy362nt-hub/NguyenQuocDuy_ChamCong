using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NguyenQuocDuy_ChamCong_API.Data;
using NguyenQuocDuy_ChamCong_API.Models;
using NguyenQuocDuy_ChamCong_API.Services;

namespace NguyenQuocDuy_ChamCong_API.Controllers;

public class CheckInDto
{
    public string Method { get; set; } = "GPS";   // GPS | QR
    public string QrToken { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public bool MotionVerified { get; set; }
}
public class CheckOutDto { public double Latitude { get; set; } public double Longitude { get; set; } }
public class ManualAttendanceDto
{
    public int EmployeeId { get; set; }
    public string WorkDate { get; set; }     // yyyy-MM-dd
    public string CheckIn { get; set; }      // HH:mm
    public string CheckOut { get; set; }     // HH:mm hoặc rỗng
    public string Status { get; set; } = "DungGio";
    public string Note { get; set; }
}

[ApiController, Authorize, Route("api/[controller]")]
public class AttendanceController : ApiBase
{
    private readonly AppDbContext _db;
    private readonly QrTokenService _qr;
    public AttendanceController(AppDbContext db, QrTokenService qr) { _db = db; _qr = qr; }

    private static object Map(Attendance a) => new
    {
        a.Id, a.EmployeeId,
        employeeName = a.Employee != null ? a.Employee.FullName : null,
        employeeCode = a.Employee != null ? a.Employee.Code : null,
        workDate = a.WorkDate.ToString("yyyy-MM-dd"),
        a.CheckInTime, a.CheckOutTime, a.CheckInLat, a.CheckInLng, a.CheckOutLat, a.CheckOutLng,
        a.Method, a.Status, a.Note, a.MotionVerified, a.WorkedMinutes
    };

    private Task<Employee> MyEmployee() => _db.Employees.FirstOrDefaultAsync(e => e.UserId == CurrentUserId);

    // Hôm nay của tôi
    [HttpGet("today"), Authorize(Roles = "NhanVien")]
    public async Task<IActionResult> Today()
    {
        var emp = await MyEmployee();
        if (emp == null) return BadRequest(new { message = "Không tìm thấy hồ sơ nhân viên" });
        var a = await _db.Attendances.Include(x => x.Employee)
            .FirstOrDefaultAsync(x => x.EmployeeId == emp.Id && x.WorkDate == DateTime.Today);
        var shift = await _db.Shifts.OrderBy(s => s.StartTime).FirstOrDefaultAsync();
        return Ok(new
        {
            record = a == null ? null : Map(a),
            shift = shift == null ? null : new { shift.Name, startTime = shift.StartTime.ToString(@"hh\:mm"), endTime = shift.EndTime.ToString(@"hh\:mm") }
        });
    }

    // Chấm công VÀO (GPS + xác thực chuyển động, hoặc QR động)
    [HttpPost("check-in"), Authorize(Roles = "NhanVien")]
    public async Task<IActionResult> CheckIn(CheckInDto d)
    {
        var emp = await MyEmployee();
        if (emp == null) return BadRequest(new { message = "Không tìm thấy hồ sơ nhân viên" });
        if (!emp.IsActive) return BadRequest(new { message = "Nhân viên đã ngưng hoạt động" });

        WorkSite site;
        var method = d.Method == "QR" ? "QR" : "GPS";
        if (method == "QR")
        {
            var siteId = _qr.Validate(d.QrToken);
            if (siteId == null) return BadRequest(new { message = "Mã QR không hợp lệ hoặc đã hết hạn (đổi mỗi 30 giây)" });
            site = await _db.WorkSites.FindAsync(siteId.Value);
        }
        else
        {
            if (!d.MotionVerified)
                return BadRequest(new { message = "Cần hoàn thành thử thách chuyển động (lắc điện thoại) trước khi chấm công GPS" });
            site = await _db.WorkSites.OrderBy(s => s.Id).FirstOrDefaultAsync();
        }
        if (site == null) return BadRequest(new { message = "Chưa cấu hình điểm làm việc" });

        var dist = Geo.DistanceMeters(d.Latitude, d.Longitude, site.Latitude, site.Longitude);
        if (dist > site.RadiusMeters)
            return BadRequest(new { message = $"Bạn đang cách {site.Name} {dist:0} m, ngoài bán kính cho phép {site.RadiusMeters} m" });

        if (await _db.Attendances.AnyAsync(x => x.EmployeeId == emp.Id && x.WorkDate == DateTime.Today))
            return BadRequest(new { message = "Hôm nay bạn đã chấm công vào rồi" });

        var shift = await _db.Shifts.OrderBy(s => s.StartTime).FirstOrDefaultAsync();
        var now = DateTime.Now;
        var late = shift != null && now.TimeOfDay > shift.StartTime.Add(TimeSpan.FromMinutes(shift.LateGraceMinutes));

        var a = new Attendance
        {
            EmployeeId = emp.Id, WorkDate = DateTime.Today, CheckInTime = now,
            CheckInLat = d.Latitude, CheckInLng = d.Longitude, Method = method,
            MotionVerified = d.MotionVerified, Status = late ? "DiTre" : "DungGio",
            Note = late ? "Đi trễ" : ""
        };
        _db.Attendances.Add(a); await _db.SaveChangesAsync();
        a.Employee = emp;
        return Ok(Map(a));
    }

    [HttpPost("check-out"), Authorize(Roles = "NhanVien")]
    public async Task<IActionResult> CheckOut(CheckOutDto d)
    {
        var emp = await MyEmployee();
        if (emp == null) return BadRequest(new { message = "Không tìm thấy hồ sơ nhân viên" });
        var a = await _db.Attendances.Include(x => x.Employee)
            .FirstOrDefaultAsync(x => x.EmployeeId == emp.Id && x.WorkDate == DateTime.Today);
        if (a == null) return BadRequest(new { message = "Hôm nay bạn chưa chấm công vào" });
        if (a.CheckOutTime != null) return BadRequest(new { message = "Bạn đã chấm công ra rồi" });
        a.CheckOutTime = DateTime.Now; a.CheckOutLat = d.Latitude; a.CheckOutLng = d.Longitude;
        a.WorkedMinutes = (int)(a.CheckOutTime.Value - a.CheckInTime).TotalMinutes;
        await _db.SaveChangesAsync();
        return Ok(Map(a));
    }

    // Lịch sử của tôi
    [HttpGet("mine"), Authorize(Roles = "NhanVien")]
    public async Task<IActionResult> Mine([FromQuery] int days = 60)
    {
        var emp = await MyEmployee();
        if (emp == null) return BadRequest(new { message = "Không tìm thấy hồ sơ nhân viên" });
        var from = DateTime.Today.AddDays(-days);
        var list = await _db.Attendances.Include(x => x.Employee)
            .Where(x => x.EmployeeId == emp.Id && x.WorkDate >= from)
            .OrderByDescending(x => x.WorkDate).ToListAsync();
        return Ok(list.Select(Map));
    }

    // ---------- Admin CRUD ----------
    [HttpGet, Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll([FromQuery] string date, [FromQuery] int? employeeId)
    {
        var q = _db.Attendances.Include(x => x.Employee).AsQueryable();
        if (!string.IsNullOrWhiteSpace(date) && DateTime.TryParse(date, out var dt)) q = q.Where(x => x.WorkDate == dt.Date);
        if (employeeId.HasValue) q = q.Where(x => x.EmployeeId == employeeId.Value);
        var list = await q.OrderByDescending(x => x.WorkDate).ThenByDescending(x => x.CheckInTime).Take(300).ToListAsync();
        return Ok(list.Select(Map));
    }

    [HttpPost("manual"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(ManualAttendanceDto d)
    {
        var emp = await _db.Employees.FindAsync(d.EmployeeId);
        if (emp == null) return BadRequest(new { message = "Nhân viên không tồn tại" });
        if (!DateTime.TryParse(d.WorkDate, out var date)) return BadRequest(new { message = "Ngày không hợp lệ (yyyy-MM-dd)" });
        date = date.Date;
        if (!TimeSpan.TryParse(d.CheckIn, out var tin)) return BadRequest(new { message = "Giờ vào không hợp lệ (HH:mm)" });
        if (await _db.Attendances.AnyAsync(x => x.EmployeeId == emp.Id && x.WorkDate == date))
            return BadRequest(new { message = "Nhân viên này đã có chấm công ngày đó" });

        var a = new Attendance
        {
            EmployeeId = emp.Id, WorkDate = date, CheckInTime = date + tin, Method = "Manual",
            Status = string.IsNullOrWhiteSpace(d.Status) ? "DungGio" : d.Status, Note = d.Note ?? ""
        };
        if (!string.IsNullOrWhiteSpace(d.CheckOut))
        {
            if (!TimeSpan.TryParse(d.CheckOut, out var tout)) return BadRequest(new { message = "Giờ ra không hợp lệ (HH:mm)" });
            a.CheckOutTime = date + tout;
            a.WorkedMinutes = Math.Max(0, (int)(a.CheckOutTime.Value - a.CheckInTime).TotalMinutes);
        }
        _db.Attendances.Add(a); await _db.SaveChangesAsync();
        a.Employee = emp;
        return Ok(Map(a));
    }

    [HttpPut("{id}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(int id, ManualAttendanceDto d)
    {
        var a = await _db.Attendances.Include(x => x.Employee).FirstOrDefaultAsync(x => x.Id == id);
        if (a == null) return NotFound(new { message = "Không tìm thấy bản ghi" });
        if (!DateTime.TryParse(d.WorkDate, out var date)) return BadRequest(new { message = "Ngày không hợp lệ" });
        date = date.Date;
        if (!TimeSpan.TryParse(d.CheckIn, out var tin)) return BadRequest(new { message = "Giờ vào không hợp lệ (HH:mm)" });
        a.WorkDate = date; a.CheckInTime = date + tin;
        if (string.IsNullOrWhiteSpace(d.CheckOut)) { a.CheckOutTime = null; a.WorkedMinutes = 0; }
        else
        {
            if (!TimeSpan.TryParse(d.CheckOut, out var tout)) return BadRequest(new { message = "Giờ ra không hợp lệ (HH:mm)" });
            a.CheckOutTime = date + tout;
            a.WorkedMinutes = Math.Max(0, (int)(a.CheckOutTime.Value - a.CheckInTime).TotalMinutes);
        }
        if (!string.IsNullOrWhiteSpace(d.Status)) a.Status = d.Status;
        a.Note = d.Note ?? "";
        await _db.SaveChangesAsync();
        return Ok(Map(a));
    }

    [HttpDelete("{id}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var a = await _db.Attendances.FindAsync(id);
        if (a == null) return NotFound(new { message = "Không tìm thấy bản ghi" });
        _db.Attendances.Remove(a); await _db.SaveChangesAsync();
        return Ok(new { message = "Đã xóa bản ghi chấm công" });
    }
}
