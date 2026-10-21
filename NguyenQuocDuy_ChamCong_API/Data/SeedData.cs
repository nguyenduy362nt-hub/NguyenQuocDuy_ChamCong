using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using NguyenQuocDuy_ChamCong_API.Models;

namespace NguyenQuocDuy_ChamCong_API.Data;

public static class SeedData
{
    public const string Admin = "Admin";
    public const string NhanVien = "NhanVien";
    public const string KhachHang = "KhachHang";

    public static async Task InitAsync(IServiceProvider sp)
    {
        var db = sp.GetRequiredService<AppDbContext>();
        var um = sp.GetRequiredService<UserManager<AppUser>>();
        var rm = sp.GetRequiredService<RoleManager<IdentityRole>>();

        foreach (var r in new[] { Admin, NhanVien, KhachHang })
            if (!await rm.RoleExistsAsync(r)) await rm.CreateAsync(new IdentityRole(r));

        if (!await db.Departments.AnyAsync())
        {
            db.Departments.AddRange(
                new Department { Name = "Kinh doanh", Description = "Bán hàng & chăm sóc khách hàng" },
                new Department { Name = "Kỹ thuật", Description = "Phát triển phần mềm" },
                new Department { Name = "Nhân sự", Description = "Tuyển dụng & chấm công" });
            await db.SaveChangesAsync();
        }

        if (!await db.Shifts.AnyAsync())
        {
            db.Shifts.AddRange(
                new Shift { Name = "Ca hành chính", StartTime = new TimeSpan(8, 0, 0), EndTime = new TimeSpan(17, 0, 0), LateGraceMinutes = 10 },
                new Shift { Name = "Ca chiều", StartTime = new TimeSpan(13, 0, 0), EndTime = new TimeSpan(22, 0, 0), LateGraceMinutes = 10 });
            await db.SaveChangesAsync();
        }

        if (!await db.WorkSites.AnyAsync())
        {
            // Trùng vị trí mặc định của máy ảo Android (Googleplex) để demo chạy ngay.
            db.WorkSites.Add(new WorkSite { Name = "Văn phòng chính", Latitude = 37.4219983, Longitude = -122.084, RadiusMeters = 300 });
            await db.SaveChangesAsync();
        }

        await EnsureUser(um, "admin", "admin@nguyenquocduy.com", "Admin@123", "Nguyễn Quốc Duy (Admin)", Admin);
        var u1 = await EnsureUser(um, "nvan", "nvan@nguyenquocduy.com", "Nv@123456", "Nguyễn Văn An", NhanVien);
        var u2 = await EnsureUser(um, "nvbinh", "nvbinh@nguyenquocduy.com", "Nv@123456", "Trần Thị Bình", NhanVien);
        await EnsureUser(um, "khach1", "khach1@nguyenquocduy.com", "Kh@123456", "Lê Khách Hàng", KhachHang);

        if (!await db.Employees.AnyAsync())
        {
            var deps = await db.Departments.ToListAsync();
            db.Employees.AddRange(
                new Employee { Code = "NV001", FullName = u1.FullName, Phone = "0901000001", Position = "Lập trình viên", DepartmentId = deps[1].Id, UserId = u1.Id },
                new Employee { Code = "NV002", FullName = u2.FullName, Phone = "0901000002", Position = "Nhân viên kinh doanh", DepartmentId = deps[0].Id, UserId = u2.Id });
            await db.SaveChangesAsync();
        }

        if (!await db.Attendances.AnyAsync())
        {
            var emps = await db.Employees.OrderBy(e => e.Id).ToListAsync();
            var rnd = new Random(23);
            for (int back = 1; back <= 20; back++)
            {
                var day = DateTime.Today.AddDays(-back);
                if (day.DayOfWeek == DayOfWeek.Saturday || day.DayOfWeek == DayOfWeek.Sunday) continue;
                for (int i = 0; i < emps.Count; i++)
                {
                    bool late = i == 1 ? rnd.Next(100) < 40 : rnd.Next(100) < 10;
                    var cin = day.AddHours(8).AddMinutes(late ? 15 + rnd.Next(30) : rnd.Next(8));
                    var cout = day.AddHours(17).AddMinutes(rnd.Next(30));
                    db.Attendances.Add(new Attendance
                    {
                        EmployeeId = emps[i].Id, WorkDate = day, CheckInTime = cin, CheckOutTime = cout,
                        CheckInLat = 37.4219983, CheckInLng = -122.084, Method = i == 0 ? "QR" : "GPS",
                        Status = late ? "DiTre" : "DungGio", MotionVerified = true,
                        WorkedMinutes = (int)(cout - cin).TotalMinutes
                    });
                }
            }
            await db.SaveChangesAsync();
        }
    }

    private static async Task<AppUser> EnsureUser(UserManager<AppUser> um, string name, string email, string pwd, string full, string role)
    {
        var u = await um.FindByNameAsync(name);
        if (u != null) return u;
        u = new AppUser { UserName = name, Email = email, EmailConfirmed = true, FullName = full };
        var r = await um.CreateAsync(u, pwd);
        if (!r.Succeeded) throw new Exception("Seed user lỗi: " + string.Join("; ", r.Errors.Select(e => e.Description)));
        await um.AddToRoleAsync(u, role);
        return u;
    }
}
